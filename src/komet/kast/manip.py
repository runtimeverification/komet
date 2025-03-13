from __future__ import annotations

from typing import TYPE_CHECKING

from pyk.kast.inner import KApply, KLabel

if TYPE_CHECKING:
    from pyk.kast.inner import KInner


def get_soroban_cell(config: KInner) -> KInner:
    match config:
        case KApply(
            KLabel('<generatedTop>'),
            (
                KApply(
                    KLabel('<kasmer>'),
                    (
                        _,
                        soroban_cell,
                        _,
                    ),
                ),
                _,
            ),
        ):
            match soroban_cell:
                case KApply(KLabel('<soroban>'), _):
                    return soroban_cell

    raise ValueError('Malformed config term')
