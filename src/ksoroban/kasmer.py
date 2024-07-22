from __future__ import annotations

import json
import shutil
from functools import cached_property
from pathlib import Path
from typing import TYPE_CHECKING

from pyk.utils import run_process

if TYPE_CHECKING:
    from typing import Any


class Kasmer:

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
