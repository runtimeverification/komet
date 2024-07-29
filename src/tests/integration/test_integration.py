from pathlib import Path
from subprocess import CalledProcessError

import pytest
from pyk.kdist import kdist
from pyk.ktool.krun import _krun

from ksoroban.kasmer import Kasmer
from ksoroban.utils import SorobanDefinitionInfo

TEST_DATA = (Path(__file__).parent / 'data').resolve(strict=True)
TEST_FILES = TEST_DATA.glob('*.wast')

SOROBAN_CONTRACTS_DIR = TEST_DATA / 'soroban' / 'contracts'
SOROBAN_TEST_CONTRACTS = SOROBAN_CONTRACTS_DIR.glob('test_*')

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


@pytest.mark.parametrize('contract_path', SOROBAN_TEST_CONTRACTS, ids=lambda p: str(p.stem))
def test_ksoroban(contract_path: Path, tmp_path: Path, kasmer: Kasmer) -> None:
    # Given
    contract_wasm = kasmer.build_soroban_contract(contract_path, tmp_path)

    # Then
    if contract_path.stem.endswith('_fail'):
        with pytest.raises(CalledProcessError):
            kasmer.deploy_and_run(contract_wasm)
    else:
        kasmer.deploy_and_run(contract_wasm)


def test_bindings(tmp_path: Path, kasmer: Kasmer) -> None:
    # Given
    contract_path = SOROBAN_CONTRACTS_DIR / 'valtypes'
    contract_wasm = kasmer.build_soroban_contract(contract_path, tmp_path)

    # Then
    # Just run this and make sure it doesn't throw an error
    kasmer.contract_bindings(contract_wasm)
