from __future__ import annotations

from functools import cached_property
from typing import TYPE_CHECKING

from pyk.kast.outer import read_kast_definition
from pyk.kdist import kdist
from pyk.konvert import kast_to_kore
from pyk.ktool.kompile import DefinitionInfo
from pyk.ktool.krun import KRun

if TYPE_CHECKING:
    from pathlib import Path
    from subprocess import CompletedProcess
    from typing import Any

    from pyk.kast.inner import KInner, KSort
    from pyk.kast.outer import KDefinition


class KSorobanError(RuntimeError): ...


class SorobanDefinition:
    """Anything related to the Soroban K definition goes here."""

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

    def krun_with_kast(self, pgm: KInner, sort: KSort | None = None, **kwargs: Any) -> CompletedProcess:
        """Run the semantics on a kast term.

        This will convert the kast term to kore.

        Args:
            pgm: The kast term to run
            sort: The target sort of `pgm`. This should normally be `Steps`, but can be `GeneratedTopCell` if kwargs['term'] is True
            kwargs: Any arguments to pass to KRun.run_process

        Returns:
            The CompletedProcess of the interpreter
        """
        kore_term = kast_to_kore(self.kdefinition, pgm, sort=sort)
        return self.krun.run_process(kore_term, **kwargs)


llvm_definition = SorobanDefinition(kdist.get('soroban-semantics.llvm'))
haskell_definition = SorobanDefinition(kdist.get('soroban-semantics.haskell'))
