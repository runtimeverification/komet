from __future__ import annotations

import json
import shutil
from dataclasses import dataclass
from functools import cached_property
from pathlib import Path
from tempfile import mkdtemp
from typing import TYPE_CHECKING, Iterable

from hypothesis import strategies
from pyk.cterm import CTerm, cterm_build_claim
from pyk.kast.inner import KSort, KVariable
from pyk.kast.manip import Subst, split_config_from
from pyk.konvert import kast_to_kore, kore_to_kast
from pyk.kore.parser import KoreParser
from pyk.kore.syntax import EVar, SortApp
from pyk.ktool.kfuzz import KFuzzHandler, fuzz
from pyk.ktool.krun import KRunOutput
from pyk.prelude.ml import mlEqualsTrue
from pyk.prelude.utils import token
from pyk.proof import ProofStatus
from pyk.utils import run_process
from pykwasm.wasm2kast import wasm2kast
from rich.progress import BarColumn, MofNCompleteColumn, Progress, TextColumn, TimeElapsedColumn

from .kast.syntax import (
    SC_VOID,
    STEPS_TERMINATOR,
    account_id,
    call_tx,
    contract_id,
    deploy_contract,
    sc_bool,
    sc_bytes,
    set_account,
    set_exit_code,
    steps_of,
    upload_wasm,
)
from .proof import run_claim
from .scval import SCType
from .utils import KSorobanError, concrete_definition

if TYPE_CHECKING:
    from typing import Any, Mapping

    from hypothesis.strategies import SearchStrategy
    from pyk.kast.inner import KInner
    from pyk.kore.syntax import Pattern
    from pyk.proof import APRProof
    from pyk.utils import BugReport
    from rich.progress import TaskID

    from .utils import SorobanDefinition


class Kasmer:
    """Reads soroban contracts, and runs tests for them."""

    definition: SorobanDefinition

    def __init__(self, definition: SorobanDefinition) -> None:
        self.definition = definition

    def _which(self, cmd: str) -> Path:
        path_str = shutil.which(cmd)
        if path_str is None:
            raise RuntimeError(
                f"Couldn't find {cmd!r} executable. Please make sure {cmd!r} is installed and on your path."
            )
        return Path(path_str)

    @cached_property
    def _soroban_bin(self) -> Path:
        return self._which('soroban')

    @cached_property
    def _cargo_bin(self) -> Path:
        return self._which('cargo')

    def contract_bindings(self, wasm_contract: Path) -> list[ContractBinding]:
        """Reads a soroban wasm contract, and returns a list of the function bindings for it."""
        proc_res = run_process(
            [str(self._soroban_bin), 'contract', 'bindings', 'json', '--wasm', str(wasm_contract)], check=False
        )
        bindings_list = json.loads(proc_res.stdout)
        bindings = []
        for binding_dict in bindings_list:
            if binding_dict['type'] != 'function':
                continue
            name = binding_dict['name']
            inputs = []
            for input_dict in binding_dict['inputs']:
                inputs.append(SCType.from_dict(input_dict['value']))
            outputs = []
            for output_dict in binding_dict['outputs']:
                outputs.append(SCType.from_dict(output_dict))
            bindings.append(ContractBinding(name, tuple(inputs), tuple(outputs)))
        return bindings

    def contract_manifest(self, contract_path: Path) -> dict[str, Any]:
        """Get the cargo manifest for a given contract.

        Args:
            contract_path: The directory where the contract is located.

        Returns:
            A dictionary representing the json output of `cargo read-manifest` in that contract's directory.
        """
        proc_res = run_process([str(self._cargo_bin), 'read-manifest'], cwd=contract_path)
        return json.loads(proc_res.stdout)

    def build_soroban_contract(self, contract_path: Path, out_dir: Path | None = None) -> Path:
        """Build a soroban contract.

        Args:
            contract_path: The path to the soroban contract folder.
            out_dir: Where to save the compiled wasm. If this isn't passed, then a temporary location is created.

        Returns:
            The path to the compiled wasm contract.
        """
        contract_stem = self.contract_manifest(contract_path)['name'].replace('-', '_')
        contract_name = f'{contract_stem}.wasm'
        if out_dir is None:
            out_dir = Path(mkdtemp(f'komet_{str(contract_path.stem)}'))

        run_process([str(self._soroban_bin), 'contract', 'build', '--out-dir', str(out_dir)], cwd=contract_path)

        return out_dir / contract_name

    def kast_from_wasm(self, wasm: Path) -> KInner:
        """Get a kast term from a wasm program."""
        return wasm2kast(open(wasm, 'rb'))

    @staticmethod
    def deploy_test(
        contract: KInner, child_contracts: tuple[KInner, ...], init: bool
    ) -> tuple[KInner, dict[str, KInner]]:
        """Takes a wasm soroban contract and its dependencies as kast terms and deploys them in a fresh configuration.

        Args:
            contract: The test contract to deploy, represented as a kast term.
            child_contracts: A tuple of child contracts required by the test contract.
            init: Whether to initialize the contract by calling its 'init' function after deployment.

        Returns:
            A configuration with the contract deployed.

        Raises:
            AssertionError if the deployment fails
        """

        def wasm_hash(i: int) -> bytes:
            return str(i).rjust(32, '_').encode()

        def call_init() -> tuple[KInner, ...]:
            hashes = tuple(wasm_hash(i) for i in range(len(child_contracts)))
            upload_wasms = tuple(upload_wasm(h, c) for h, c in zip(hashes, child_contracts, strict=False))

            from_addr = account_id(b'test-account')
            to_addr = contract_id(b'test-contract')
            args = [sc_bytes(h) for h in hashes]
            init_tx = call_tx(from_addr, to_addr, 'init', args, SC_VOID)

            return upload_wasms + (init_tx,)

        # Set up the steps that will deploy the contract
        steps = steps_of(
            [
                set_exit_code(1),
                upload_wasm(b'test', contract),
                set_account(b'test-account', 9876543210),
                deploy_contract(b'test-account', b'test-contract', b'test'),
                *(call_init() if init else ()),
                set_exit_code(0),
            ]
        )

        # Run the steps and grab the resulting config as a starting place to call transactions
        proc_res = concrete_definition.krun_with_kast(steps, sort=KSort('Steps'), output=KRunOutput.KORE)
        assert proc_res.returncode == 0

        kore_result = KoreParser(proc_res.stdout).pattern()
        kast_result = kore_to_kast(concrete_definition.kdefinition, kore_result)

        conf, subst = split_config_from(kast_result)

        return conf, subst

    def run_test(
        self,
        conf: KInner,
        subst: dict[str, KInner],
        binding: ContractBinding,
        max_examples: int,
        task: FuzzTask,
    ) -> None:
        """Given a configuration with a deployed test contract, fuzz over the tests for the supplied binding.

        Args:
            conf: The template configuration.
            subst: A substitution mapping such that 'Subst(subst).apply(conf)' gives the initial configuration with the
                   deployed contract.
            binding: The contract binding that specifies the test name and parameters.
            max_examples: The maximum number of fuzzing test cases to generate and execute.

        Raises:
            AssertionError if the test fails
        """

        from_acct = account_id(b'test-account')
        to_acct = contract_id(b'test-contract')
        name = binding.name
        result = sc_bool(True)

        def make_steps(*args: KInner) -> Pattern:
            steps_kast = steps_of([set_exit_code(1), call_tx(from_acct, to_acct, name, args, result), set_exit_code(0)])
            return kast_to_kore(self.definition.kdefinition, steps_kast, KSort('Steps'))

        subst['PROGRAM_CELL'] = KVariable('STEPS')
        template_config = Subst(subst).apply(conf)
        template_config_kore = kast_to_kore(self.definition.kdefinition, template_config, KSort('GeneratedTopCell'))

        steps_strategy = binding.strategy.map(lambda args: make_steps(*args))
        template_subst = {EVar('VarSTEPS', SortApp('SortSteps')): steps_strategy}

        fuzz(
            self.definition.path,
            template_config_kore,
            template_subst,
            check_exit_code=True,
            max_examples=max_examples,
            handler=KometFuzzHandler(self.definition, task),
        )

    def run_prove(
        self,
        conf: KInner,
        subst: dict[str, KInner],
        binding: ContractBinding,
        proof_dir: Path | None = None,
        bug_report: BugReport | None = None,
    ) -> APRProof:
        """Given a configuration with a deployed test contract, prove the test case defined by the supplied binding.

        Args:
            conf: The template configuration with configuration variables.
            subst: A substitution mapping such that `Subst(subst).apply(conf)` produces the initial configuration with
                   the deployed contract.
            binding: The contract binding specifying the test name and parameters.
            proof_dir: An optional directory to save the generated proof.
            bug_report: An optional object to log and collect details about the proof for debugging purposes.
        """
        from_acct = account_id(b'test-account')
        to_acct = contract_id(b'test-contract')
        name = binding.name
        result = sc_bool(True)

        def make_steps(*args: KInner) -> KInner:
            return steps_of([set_exit_code(1), call_tx(from_acct, to_acct, name, args, result), set_exit_code(0)])

        vars, ctrs = binding.symbolic_args()

        lhs_subst = subst.copy()
        lhs_subst['PROGRAM_CELL'] = make_steps(*vars)
        lhs = CTerm(Subst(lhs_subst).apply(conf), [mlEqualsTrue(c) for c in ctrs])

        rhs_subst = subst.copy()
        rhs_subst['PROGRAM_CELL'] = STEPS_TERMINATOR
        rhs_subst['EXITCODE_CELL'] = token(0)
        del rhs_subst['LOGGING_CELL']
        rhs = CTerm(Subst(rhs_subst).apply(conf))

        claim, _ = cterm_build_claim(name, lhs, rhs)

        return run_claim(name, claim, proof_dir, bug_report)

    def deploy_and_run(
        self, contract_wasm: Path, child_wasms: tuple[Path, ...], max_examples: int = 100, id: str | None = None
    ) -> None:
        """Run all of the tests in a soroban test contract.

        Args:
            contract_wasm: The path to the compiled wasm contract.
            child_wasms: A tuple of paths to the compiled wasm contracts required as dependencies by the test contract.
            max_examples: The maximum number of test inputs to generate for fuzzing.
            id: The specific test function name to run. If None, all tests are executed.

        Raises:
            AssertionError if any of the tests fail
        """
        print(f'Processing contract: {contract_wasm.stem}')

        bindings = self.contract_bindings(contract_wasm)
        has_init = 'init' in (b.name for b in bindings)

        contract_kast = self.kast_from_wasm(contract_wasm)
        child_kasts = tuple(self.kast_from_wasm(c) for c in child_wasms)

        conf, subst = self.deploy_test(contract_kast, child_kasts, has_init)

        test_bindings = [b for b in bindings if b.name.startswith('test_') and (id is None or b.name == id)]

        if id is None:
            print(f'Discovered {len(test_bindings)} test functions:')
        elif not test_bindings:
            raise KeyError(f'Test function {id!r} not found.')
        else:
            print('Selected a single test function:')
        print()

        with FuzzProgress(test_bindings, max_examples) as progress:
            for task in progress.fuzz_tasks:
                task.start()
                self.run_test(conf, subst, task.binding, max_examples, task)
                task.end()

    def deploy_and_prove(
        self,
        contract_wasm: Path,
        child_wasms: tuple[Path, ...],
        id: str | None = None,
        proof_dir: Path | None = None,
        bug_report: BugReport | None = None,
    ) -> None:
        """Prove all of the tests in a soroban test contract.

        Args:
            contract_wasm: The path to the compiled wasm contract.
            child_wasms: A tuple of paths to the compiled wasm contracts required as dependencies by the test contract.
            id: The specific test function name to run. If None, all tests are executed.
            proof_dir: An optional location to save the proof.
            bug_report: An optional BugReport object to log and collect details about the proof for debugging.

        Raises:
            KSorobanError if a proof fails
        """
        bindings = self.contract_bindings(contract_wasm)
        has_init = 'init' in (b.name for b in bindings)

        contract_kast = self.kast_from_wasm(contract_wasm)
        child_kasts = tuple(self.kast_from_wasm(c) for c in child_wasms)

        conf, subst = self.deploy_test(contract_kast, child_kasts, has_init)

        test_bindings = [b for b in bindings if b.name.startswith('test_') and (id is None or b.name == id)]

        for binding in test_bindings:
            proof = self.run_prove(conf, subst, binding, proof_dir, bug_report)
            if proof.status == ProofStatus.FAILED:
                raise KSorobanError(proof.summary)


@dataclass(frozen=True)
class ContractBinding:
    """Represents one of the function bindings for a soroban contract."""

    name: str
    inputs: tuple[SCType, ...]
    outputs: tuple[SCType, ...]

    @cached_property
    def strategy(self) -> SearchStrategy[tuple[KInner, ...]]:
        return strategies.tuples(*(arg.strategy().map(lambda x: x.to_kast()) for arg in self.inputs))

    def symbolic_args(self) -> tuple[tuple[KInner, ...], tuple[KInner, ...]]:
        args: tuple[KInner, ...] = ()
        constraints: tuple[KInner, ...] = ()
        for i, arg in enumerate(self.inputs):
            v, c = arg.as_var(f'ARG_{i}')
            args += (v,)
            constraints += c
        return args, constraints


class FuzzProgress(Progress):
    fuzz_tasks: list[FuzzTask]

    def __init__(self, bindings: Iterable[ContractBinding], max_examples: int):
        super().__init__(
            TextColumn('[progress.description]{task.description}'),
            BarColumn(),
            MofNCompleteColumn(),
            TimeElapsedColumn(),
            TextColumn('{task.fields[status]}'),
        )

        self.fuzz_tasks = []

        # Add all tests to the progress display before running them
        for binding in bindings:
            task_id = self.add_task(binding.name, total=max_examples, start=False, status='Waiting')
            self.fuzz_tasks.append(FuzzTask(binding, task_id, self))


class FuzzTask:
    binding: ContractBinding
    task_id: TaskID
    progress: FuzzProgress

    def __init__(self, binding: ContractBinding, task_id: TaskID, progress: FuzzProgress):
        self.binding = binding
        self.task_id = task_id
        self.progress = progress

    def start(self) -> None:
        self.progress.start_task(self.task_id)
        self.progress.update(self.task_id, status='[bold]Running')

    def end(self) -> None:
        self.progress.update(
            self.task_id, total=self.progress._tasks[self.task_id].completed, status='[bold green]Passed'
        )

    def advance(self) -> None:
        self.progress.advance(self.task_id)

    def fail(self) -> None:
        self.progress.update(self.task_id, status='[bold red]Failed')
        self.progress.stop_task(self.task_id)


class KometFuzzHandler(KFuzzHandler):
    # Fuzz handler with progress tracking

    definition: SorobanDefinition
    task: FuzzTask
    failed: bool

    def __init__(self, definition: SorobanDefinition, task: FuzzTask):
        self.definition = definition
        self.task = task
        self.failed = False

    def handle_test(self, args: Mapping[EVar, Pattern]) -> None:
        # Hypothesis reruns failing examples to confirm the failure.
        # To avoid misleading progress updates, the progress bar is not advanced
        # when a test fails and Hypothesis reruns the same example.
        if not self.failed:
            self.task.advance()

    def handle_failure(self, args: Mapping[EVar, Pattern]) -> None:
        if not self.failed:
            self.failed = True
            self.task.fail()
