from pathlib import Path

import pytest
from pyk.kdist import kdist
from pyk.ktool.krun import _krun

from komet.kasmer import Kasmer
from komet.komet import _read_config_file
from komet.utils import KSorobanError, concrete_definition, symbolic_definition

TEST_DATA = (Path(__file__).parent / 'data').resolve(strict=True)
TEST_FILES = TEST_DATA.glob('*.wast')

SOROBAN_CONTRACTS_DIR = TEST_DATA / 'soroban' / 'contracts'
SOROBAN_TEST_CONTRACTS = SOROBAN_CONTRACTS_DIR.glob('test_*')

DEFINITION_DIR = kdist.get('soroban-semantics.llvm')


@pytest.fixture
def concrete_kasmer() -> Kasmer:
    return Kasmer(concrete_definition)


@pytest.fixture
def symbolic_kasmer() -> Kasmer:
    return Kasmer(symbolic_definition)


@pytest.mark.parametrize('program', TEST_FILES, ids=str)
def test_run(program: Path, tmp_path: Path) -> None:
    _krun(input_file=program, definition_dir=DEFINITION_DIR, check=True)


@pytest.mark.parametrize('contract_path', SOROBAN_TEST_CONTRACTS, ids=lambda p: str(p.stem))
def test_komet(contract_path: Path, tmp_path: Path, concrete_kasmer: Kasmer) -> None:
    # Given
    contract_wasm = concrete_kasmer.build_soroban_contract(contract_path, tmp_path)
    child_wasms = _read_config_file(concrete_kasmer, contract_path)

    # Then
    if contract_path.stem.endswith('_fail'):
        with pytest.raises(KSorobanError):
            concrete_kasmer.deploy_and_run(contract_wasm, child_wasms)
    else:
        concrete_kasmer.deploy_and_run(contract_wasm, child_wasms)


def test_prove_adder(tmp_path: Path, symbolic_kasmer: Kasmer) -> None:
    # Given
    contract_wasm = symbolic_kasmer.build_soroban_contract(SOROBAN_CONTRACTS_DIR / 'test_adder', tmp_path)

    # Then
    symbolic_kasmer.deploy_and_prove(contract_wasm, (), 'test_add', tmp_path)


def test_bindings(tmp_path: Path, concrete_kasmer: Kasmer) -> None:
    # Given
    contract_path = SOROBAN_CONTRACTS_DIR / 'valtypes'
    contract_wasm = concrete_kasmer.build_soroban_contract(contract_path, tmp_path)

    # Then
    # Just run this and make sure it doesn't throw an error
    concrete_kasmer.contract_bindings(contract_wasm)
