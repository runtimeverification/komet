from __future__ import annotations

import logging
from functools import cached_property
from subprocess import CalledProcessError
from typing import TYPE_CHECKING

from pyk.kast.outer import KRule, read_kast_definition
from pyk.kdist import kdist
from pyk.konvert import kast_to_kore
from pyk.ktool.kompile import DefinitionInfo
from pyk.ktool.kprove import KProve
from pyk.ktool.krun import KRun
from pyk.utils import single

if TYPE_CHECKING:
    from pathlib import Path
    from subprocess import CompletedProcess
    from typing import Any, Final

    from pyk.kast.inner import KInner, KSort
    from pyk.kast.outer import KDefinition, KFlatModule
    from pyk.ktool.kompile import KompileBackend

_LOGGER: Final = logging.getLogger(__name__)


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
    def backend(self) -> KompileBackend:
        return self.definition_info.backend

    @cached_property
    def kdefinition(self) -> KDefinition:
        return read_kast_definition(self.path / 'compiled.json')

    @cached_property
    def krun(self) -> KRun:
        return KRun(self.path)

    @cached_property
    def kprove(self) -> KProve:
        return KProve(self.path)

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

    def parse_lemmas_module(self, module_path: Path, module_name: str) -> KFlatModule:
        try:
            modules = self.kprove.parse_modules(module_path, module_name=module_name)
        except CalledProcessError as e:
            _LOGGER.error('Could not parse extra module:')
            _LOGGER.error(e.stderr)
            raise e

        module = single(module for module in modules.modules if module.name == module_name)

        non_rule_sentences = [sent for sent in module.sentences if not isinstance(sent, KRule)]
        if non_rule_sentences:
            raise ValueError(f'Supplied --extra-module contains non-Rule sentences: {non_rule_sentences}')

        return module


concrete_definition = SorobanDefinition(kdist.get('soroban-semantics.llvm'))
library_definition = SorobanDefinition(kdist.get('soroban-semantics.llvm-library'))
symbolic_definition = SorobanDefinition(kdist.get('soroban-semantics.haskell'))
