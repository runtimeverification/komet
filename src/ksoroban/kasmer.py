from __future__ import annotations

import json
import shutil
from functools import cached_property
from pathlib import Path
from typing import TYPE_CHECKING

from pyk.kast.inner import KSort
from pyk.kast.manip import split_config_from
from pyk.konvert import kore_to_kast
from pyk.kore.parser import KoreParser
from pyk.ktool.krun import KRunOutput
from pyk.utils import run_process

from .kast.syntax import deploy_contract, set_account, set_exit_code, steps_of, upload_wasm

if TYPE_CHECKING:
    from typing import Any

    from pyk.kast.inner import KInner

    from .utils import SorobanDefinitionInfo


class Kasmer:
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

    def contract_bindings(self, wasm_contract: Path) -> dict[str, Any]:
        proc_res = run_process(
            [str(self._soroban_bin), 'contract', 'bindings', 'json', '--wasm', str(wasm_contract)], check=False
        )
        res = json.loads(proc_res.stdout)
        return res

    def deploy_test(self, contract: KInner) -> tuple[KInner, dict[str, KInner]]:

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
        proc_res = self.definition_info.run_process_kast(steps, sort=KSort('Steps'), output=KRunOutput.KORE)
        kore_result = KoreParser(proc_res.stdout).pattern()
        kast_result = kore_to_kast(self.definition_info.kdefinition, kore_result)

        conf, subst = split_config_from(kast_result)

        return conf, subst
