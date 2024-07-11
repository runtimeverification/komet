from __future__ import annotations

import shutil
from pathlib import Path
from typing import TYPE_CHECKING

from pyk.kbuild.utils import k_version
from pyk.kdist.api import Target
from pyk.ktool.kompile import kompile

if TYPE_CHECKING:
    from collections.abc import Callable, Mapping
    from typing import Any, Final


class SourceTarget(Target):
    SRC_DIR: Final = Path(__file__).parent

    def build(self, output_dir: Path, deps: dict[str, Path], args: dict[str, Any], verbose: bool) -> None:
        shutil.copytree(deps['wasm-semantics.source'] / 'wasm-semantics', output_dir / 'wasm-semantics')
        shutil.copytree(self.SRC_DIR / 'soroban-semantics', output_dir / 'soroban-semantics')

    def source(self) -> tuple[Path, ...]:
        return (self.SRC_DIR,)

    def deps(self) -> tuple[str]:
        return ('wasm-semantics.source',)


class KompileTarget(Target):
    _kompile_args: Callable[[Path], Mapping[str, Any]]

    def __init__(self, kompile_args: Callable[[Path], Mapping[str, Any]]):
        self._kompile_args = kompile_args

    def build(self, output_dir: Path, deps: dict[str, Path], args: dict[str, Any], verbose: bool) -> None:
        kompile_args = self._kompile_args(deps['soroban-semantics.source'])
        kompile(output_dir=output_dir, verbose=verbose, **kompile_args)

    def context(self) -> dict[str, str]:
        return {'k-version': k_version().text}

    def deps(self) -> tuple[str]:
        return ('soroban-semantics.source',)


__TARGETS__: Final = {
    'source': SourceTarget(),
    'llvm': KompileTarget(
        lambda src_dir: {
            'main_file': src_dir / 'soroban-semantics/kasmer.md',
            'syntax_module': 'KASMER-SYNTAX',
            'include_dirs': [src_dir],
            'md_selector': 'k',
            'warnings_to_errors': True,
        },
    ),
}
