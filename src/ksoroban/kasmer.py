from __future__ import annotations

import json
import shutil
from dataclasses import dataclass
from functools import cached_property
from pathlib import Path
from tempfile import mkdtemp
from typing import TYPE_CHECKING

from hypothesis import strategies
from pyk.kast.inner import KSort, KVariable
from pyk.kast.manip import Subst, split_config_from
from pyk.konvert import kast_to_kore, kore_to_kast
from pyk.kore.parser import KoreParser
from pyk.kore.syntax import EVar, SortApp
from pyk.ktool.kfuzz import fuzz
from pyk.ktool.krun import KRunOutput
from pyk.utils import run_process
from pykwasm.wasm2kast import wasm2kast

from .kast.syntax import (
    account_id,
    call_tx,
    contract_id,
    deploy_contract,
    sc_bool,
    set_account,
    set_exit_code,
    steps_of,
    upload_wasm,
)
from .scval import SCType

if TYPE_CHECKING:
    from typing import Any

    from hypothesis.strategies import SearchStrategy
    from pyk.kast.inner import KInner
    from pyk.kore.syntax import Pattern

    from .utils import SorobanDefinitionInfo


class Kasmer:
    """Reads soroban contracts, and runs tests for them."""

    definition_info: SorobanDefinitionInfo

    def __init__(self, definition_info: SorobanDefinitionInfo) -> None:
        self.definition_info = definition_info

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
        contract_stem = self.contract_manifest(contract_path)['name']
        contract_name = f'{contract_stem}.wasm'
        if out_dir is None:
            out_dir = Path(mkdtemp(f'ksoroban_{str(contract_path.stem)}'))

        run_process([str(self._soroban_bin), 'contract', 'build', '--out-dir', str(out_dir)], cwd=contract_path)

        return out_dir / contract_name

    def kast_from_wasm(self, wasm: Path) -> KInner:
        """Get a kast term from a wasm program."""
        return wasm2kast(open(wasm, 'rb'))

    def deploy_test(self, contract: KInner) -> tuple[KInner, dict[str, KInner]]:
        """Takes a wasm soroban contract as a kast term and deploys it in a fresh configuration.

        Returns:
            A configuration with the contract deployed.
        """

        # Set up the steps that will deploy the contract
        steps = steps_of(
            [
                set_exit_code(1),
                upload_wasm(b'test', contract),
                set_account(b'test-account', 9876543210),
                deploy_contract(b'test-account', b'test-contract', b'test'),
                set_exit_code(0),
            ]
        )

        # Run the steps and grab the resulting config as a starting place to call transactions
        proc_res = self.definition_info.krun_with_kast(steps, sort=KSort('Steps'), output=KRunOutput.KORE)
        kore_result = KoreParser(proc_res.stdout).pattern()
        kast_result = kore_to_kast(self.definition_info.kdefinition, kore_result)

        conf, subst = split_config_from(kast_result)

        return conf, subst

    def run_test(self, conf: KInner, subst: dict[str, KInner], binding: ContractBinding) -> None:
        """Given a configuration with a deployed test contract, fuzz over the tests for the supplied binding.

        Raises:
            CalledProcessError if the test fails
        """

        from_acct = account_id(b'test-account')
        to_acct = contract_id(b'test-contract')
        name = binding.name
        result = sc_bool(True)

        def make_steps(*args: KInner) -> Pattern:
            steps_kast = steps_of([set_exit_code(1), call_tx(from_acct, to_acct, name, args, result), set_exit_code(0)])
            return kast_to_kore(self.definition_info.kdefinition, steps_kast, KSort('Steps'))

        subst['PROGRAM_CELL'] = KVariable('STEPS')
        template_config = Subst(subst).apply(conf)
        template_config_kore = kast_to_kore(
            self.definition_info.kdefinition, template_config, KSort('GeneratedTopCell')
        )

        steps_strategy = binding.strategy.map(lambda args: make_steps(*args))
        template_subst = {EVar('VarSTEPS', SortApp('SortSteps')): steps_strategy}

        fuzz(self.definition_info.path, template_config_kore, template_subst, check_exit_code=True)

    def deploy_and_run(self, contract_wasm: Path) -> None:
        """Run all of the tests in a soroban test contract.

        Args:
            contract_wasm: The path to the compiled wasm contract.

        Raises:
            CalledProcessError if any of the tests fail
        """
        contract_kast = self.kast_from_wasm(contract_wasm)
        conf, subst = self.deploy_test(contract_kast)

        bindings = self.contract_bindings(contract_wasm)

        for binding in bindings:
            if not binding.name.startswith('test_'):
                continue
            self.run_test(conf, subst, binding)


@dataclass(frozen=True)
class ContractBinding:
    """Represents one of the function bindings for a soroban contract."""

    name: str
    inputs: tuple[SCType, ...]
    outputs: tuple[SCType, ...]

    @cached_property
    def strategy(self) -> SearchStrategy[tuple[KInner, ...]]:
        return strategies.tuples(*(arg.strategy().map(lambda x: x.to_kast()) for arg in self.inputs))
