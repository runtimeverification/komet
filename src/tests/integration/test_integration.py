from pathlib import Path

import pytest
from pyk.kdist import kdist
from pyk.kore.prelude import str_dv
from pyk.ktool.krun import _krun

from komet.kasmer import Kasmer
from komet.komet import _read_config_file
from komet.utils import KSorobanError, concrete_definition, concrete_tracing_definition, symbolic_definition

TEST_DATA = (Path(__file__).parent / 'data').resolve(strict=True)
TEST_FILES = tuple(TEST_DATA.glob('*.wast'))

SOROBAN_CONTRACTS_DIR = TEST_DATA / 'soroban' / 'contracts'
SOROBAN_TEST_CONTRACTS = tuple(SOROBAN_CONTRACTS_DIR.glob('test_*'))

DEFINITION_DIR = kdist.get('soroban-semantics.llvm')
TRACING_DEFINITION_DIR = kdist.get('soroban-semantics.llvm-tracing')


@pytest.fixture
def concrete_kasmer() -> Kasmer:
    return Kasmer(concrete_definition)


@pytest.fixture
def symbolic_kasmer() -> Kasmer:
    return Kasmer(symbolic_definition)


@pytest.fixture
def tracing_kasmer() -> Kasmer:
    return Kasmer(concrete_tracing_definition)


@pytest.mark.parametrize('program', TEST_FILES, ids=str)
def test_run(program: Path, tmp_path: Path) -> None:
    # Runs wast files with the LLVM backend.
    _krun(input_file=program, definition_dir=DEFINITION_DIR, check=True)


@pytest.mark.parametrize('program', TEST_FILES, ids=str)
def test_run_tracing_smoke(program: Path, tmp_path: Path) -> None:
    """
    Runs .wast files with tracing enabled semantics using the LLVM backend.

    Smoke test: only checks that execution succeeds.
    Does not validate the generated trace.
    """
    trace_file = tmp_path / 'trace.txt'
    cmap = {'TRACE': str_dv(str(trace_file)).text}
    pmap = {'TRACE': 'cat'}
    _krun(input_file=program, definition_dir=TRACING_DEFINITION_DIR, cmap=cmap, pmap=pmap, check=True)
    assert trace_file.is_file(), 'Could not generate trace file'


@pytest.mark.parametrize('contract_path', SOROBAN_TEST_CONTRACTS, ids=lambda p: str(p.stem))
def test_komet(contract_path: Path, tmp_path: Path, concrete_kasmer: Kasmer) -> None:
    # Given
    child_wasms = _read_config_file(concrete_kasmer, contract_path)
    contract_wasm = concrete_kasmer.build_soroban_contract(contract_path, tmp_path)

    # Then
    if contract_path.stem.endswith('_fail'):
        with pytest.raises(KSorobanError):
            concrete_kasmer.deploy_and_run(contract_wasm, child_wasms)
    else:
        concrete_kasmer.deploy_and_run(contract_wasm, child_wasms)


@pytest.mark.parametrize('contract_path', SOROBAN_TEST_CONTRACTS, ids=lambda p: str(p.stem))
def test_komet_tracing(contract_path: Path, tmp_path: Path) -> None:
    # Given
    trace_file = tmp_path / 'trace.txt'
    kasmer = Kasmer(definition=concrete_tracing_definition, trace_file=trace_file)
    child_wasms = _read_config_file(kasmer, contract_path)
    contract_wasm = kasmer.build_soroban_contract(contract_path, tmp_path)

    # Then
    if contract_path.stem.endswith('_fail'):
        with pytest.raises(KSorobanError):
            kasmer.deploy_and_run(contract_wasm, child_wasms)
    else:
        kasmer.deploy_and_run(contract_wasm, child_wasms)

    assert trace_file.is_file(), 'Could not generate trace file'


def test_prove_adder(tmp_path: Path, symbolic_kasmer: Kasmer) -> None:
    # Given
    contract_wasm = symbolic_kasmer.build_soroban_contract(SOROBAN_CONTRACTS_DIR / 'test_adder', tmp_path)

    # Then
    symbolic_kasmer.deploy_and_prove(contract_wasm, (), 'test_add', False, tmp_path)


def test_prove_adder_with_always_allocate(tmp_path: Path, symbolic_kasmer: Kasmer) -> None:
    # Given
    contract_wasm = symbolic_kasmer.build_soroban_contract(SOROBAN_CONTRACTS_DIR / 'test_adder', tmp_path)

    # Then
    symbolic_kasmer.deploy_and_prove(contract_wasm, (), 'test_add_i64_comm', True, tmp_path)


def test_bindings(tmp_path: Path, concrete_kasmer: Kasmer) -> None:
    # Given
    contract_path = SOROBAN_CONTRACTS_DIR / 'valtypes'
    contract_wasm = concrete_kasmer.build_soroban_contract(contract_path, tmp_path)

    # Then
    # Just run this and make sure it doesn't throw an error
    concrete_kasmer.contract_bindings(contract_wasm)
