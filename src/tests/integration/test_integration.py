from pathlib import Path

import pytest
from pyk.kdist import kdist
from pyk.ktool.krun import _krun

from ksoroban.kasmer import Kasmer
from ksoroban.utils import SorobanDefinitionInfo

TEST_DATA = (Path(__file__).parent / 'data').resolve(strict=True)
TEST_FILES = TEST_DATA.glob('*.wast')

SOROBAN_CONTRACTS_DIR = TEST_DATA / 'soroban' / 'contracts'
SOROBAN_CONTRACTS = SOROBAN_CONTRACTS_DIR.glob('*')

DEFINITION_DIR = kdist.get('soroban-semantics.llvm')


@pytest.fixture
def soroban_definition() -> SorobanDefinitionInfo:
    return SorobanDefinitionInfo(DEFINITION_DIR)


@pytest.fixture
def kasmer(soroban_definition: SorobanDefinitionInfo) -> Kasmer:
    return Kasmer(soroban_definition)


@pytest.mark.parametrize('program', TEST_FILES, ids=str)
def test_run(program: Path, tmp_path: Path) -> None:
    _krun(input_file=program, definition_dir=DEFINITION_DIR, check=True)


@pytest.mark.parametrize('contract_path', SOROBAN_CONTRACTS, ids=lambda p: str(p.stem))
def test_ksoroban(contract_path: Path, tmp_path: Path, kasmer: Kasmer) -> None:
    # Given
    contract_wasm = kasmer.build_soroban_contract(contract_path, tmp_path)

    # Then
    kasmer.deploy_and_run(contract_wasm)
