from pathlib import Path

import pytest
from pyk.kast.outer import KClaim
from pyk.kdist import kdist
from pyk.ktool.kprove import KProve

from komet.kasmer import Kasmer
from komet.utils import symbolic_definition

SYMBOLIC_DEFINITION_DIR = kdist.get('soroban-semantics.haskell')


def parse_kclaims(claim_path: Path) -> list[KClaim]:
    modules = KProve(SYMBOLIC_DEFINITION_DIR).parse_modules(claim_path).modules
    return [sent for module in modules for sent in module.sentences if isinstance(sent, KClaim)]


SPEC_DATA = (Path(__file__).parent / 'specs').resolve(strict=True)
SPEC_FILES = SPEC_DATA.glob('*.k')


@pytest.fixture
def symbolic_kasmer() -> Kasmer:
    return Kasmer(symbolic_definition)


@pytest.mark.parametrize('claim_file', SPEC_FILES, ids=str)
def test_run(claim_file: Path, tmp_path: Path, symbolic_kasmer: Kasmer) -> None:
    symbolic_kasmer.prove_raw(claim_file=claim_file, proof_dir=tmp_path)
