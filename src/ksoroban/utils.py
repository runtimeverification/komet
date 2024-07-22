from __future__ import annotations

from functools import cached_property
from typing import TYPE_CHECKING

from pyk.kast.inner import KSort, Subst
from pyk.kast.outer import read_kast_definition
from pyk.konvert import kast_to_kore
from pyk.ktool.kompile import DefinitionInfo
from pyk.ktool.krun import KRun
from pyk.utils import run_process
from pykwasm.wasm2kast import wasm2kast

if TYPE_CHECKING:
    from pathlib import Path
    from subprocess import CompletedProcess

    from pyk.kast.inner import KInner
    from pyk.kast.outer import KDefinition


class SorobanDefinitionInfo:
    definition_info: DefinitionInfo

    def __init__(self, path: Path) -> None:
        self.definition_info = DefinitionInfo(path)

    @cached_property
    def path(self) -> Path:
        return self.definition_info.path

    @cached_property
    def kdefinition(self) -> KDefinition:
        return read_kast_definition(self.path / 'compiled.json')

    @cached_property
    def krun(self) -> KRun:
        return KRun(self.path)

    def run_process_inner(self, pgm: KInner, term: bool = False) -> CompletedProcess:
        kore_term = kast_to_kore(self.kdefinition, pgm)
        return self.krun.run_process(kore_term, term=term)

    def init_config(self, pgm: KInner) -> KInner:
        config_with_vars = self.kdefinition.init_config(KSort('GeneratedTopCell'))

        final_config = Subst({'$PGM': pgm}).apply(config_with_vars)

        return final_config

    def init_config_from_wasm(self, wasm: Path) -> KInner:
        wasm_kinner = self.inner_from_wasm(wasm)

        return self.init_config(wasm_kinner)

    def inner_from_wasm(self, wasm: Path) -> KInner:
        return wasm2kast(open(wasm, 'rb'))

    def wast_from_wasm(self, wasm: Path) -> str:
        proc_res = run_process(['wasm2wat', str(wasm)])

        return proc_res.stdout
