from __future__ import annotations

import json
import shutil
from dataclasses import dataclass
from functools import cached_property
from pathlib import Path
from typing import TYPE_CHECKING

from pyk.kast.inner import KSort
from pyk.kast.manip import Subst, split_config_from
from pyk.konvert import kast_to_kore, kore_to_kast
from pyk.kore.parser import KoreParser
from pyk.ktool.krun import KRunOutput
from pyk.utils import run_process
from pykwasm.wasm2kast import wasm2kast

from .kast.syntax import (
    SC_VOID,
    account_id,
    call_tx,
    contract_id,
    deploy_contract,
    sc_bool,
    sc_u32,
    set_account,
    set_exit_code,
    steps_of,
    upload_wasm,
)

if TYPE_CHECKING:
    from pyk.kast.inner import KInner

    from .utils import SorobanDefinitionInfo


class Kasmer:
    """Reads soroban contracts, and runs tests for them."""

    definition_info: SorobanDefinitionInfo

    def __init__(self, definition_info: SorobanDefinitionInfo) -> None:
        self.definition_info = definition_info

    @cached_property
    def _soroban_bin(self) -> Path:
        path_str = shutil.which('soroban')
        if path_str is None:
            raise RuntimeError(
                "Couldn't find 'soroban' executable. Please make sure soroban is installed and on your path."
            )
        return Path(path_str)

    def contract_bindings(self, wasm_contract: Path) -> list[ContractBinding]:
        """Reads a soroban wasm contract, and returns a list of the function bindings for it."""
        proc_res = run_process(
            [str(self._soroban_bin), 'contract', 'bindings', 'json', '--wasm', str(wasm_contract)], check=False
        )
        bindings_list = json.loads(proc_res.stdout)
        bindings = []
        for binding_dict in bindings_list:
            # TODO: Properly read and store the type information in the bindings (ie. type parameters for vecs, tuples, etc.)
            if binding_dict['type'] != 'function':
                continue
            name = binding_dict['name']
            inputs = []
            for input_dict in binding_dict['inputs']:
                inputs.append(input_dict['value']['type'])
            outputs = []
            for output_dict in binding_dict['outputs']:
                outputs.append(output_dict['type'])
            bindings.append(ContractBinding(name, tuple(inputs), tuple(outputs)))
        return bindings

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
        """Given a configuration with a deployed test contract, run the tests for the supplied binding.

        Raises:
            CalledProcessError if the test fails
        """

        def getarg(arg: str) -> KInner:
            # TODO: Implement actual argument generation.
            #      That's every possible ScVal in Soroban.
            #      Concrete values for fuzzing/variables for proving.
            if arg == 'u32':
                return sc_u32(10)
            return SC_VOID

        from_acct = account_id(b'test-account')
        to_acct = contract_id(b'test-contract')
        name = binding.name
        args = [getarg(arg) for arg in binding.inputs]
        result = sc_bool(True)

        steps = steps_of([set_exit_code(1), call_tx(from_acct, to_acct, name, args, result), set_exit_code(0)])

        subst['PROGRAM_CELL'] = steps
        test_config = Subst(subst).apply(conf)
        test_config_kore = kast_to_kore(self.definition_info.kdefinition, test_config, KSort('GeneratedTopCell'))

        self.definition_info.krun.run_pattern(test_config_kore, check=True)


@dataclass(frozen=True)
class ContractBinding:
    """Represents one of the function bindings for a soroban contract."""

    name: str
    inputs: tuple[str, ...]
    outputs: tuple[str, ...]
