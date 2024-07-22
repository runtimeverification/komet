from __future__ import annotations

from functools import cached_property
from typing import TYPE_CHECKING

from pyk.ktool.kompile import DefinitionInfo

if TYPE_CHECKING:
    from pathlib import Path


class SorobanDefinitionInfo:
    definition_info: DefinitionInfo

    def __init__(self, path: Path) -> None:
        self.definition_info = DefinitionInfo(path)

    @cached_property
    def path(self) -> Path:
        return self.definition_info.path
