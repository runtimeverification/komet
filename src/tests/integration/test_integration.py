import json
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
    return Kasmer(concrete_definition())


@pytest.fixture
def symbolic_kasmer() -> Kasmer:
    return Kasmer(symbolic_definition())


@pytest.fixture
def tracing_kasmer() -> Kasmer:
    return Kasmer(concrete_tracing_definition())


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
    kasmer = Kasmer(definition=concrete_tracing_definition(), trace_file=trace_file)
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


def test_tracing_consecutive_nop(tmp_path: Path) -> None:
    """Regression test for the <alreadyTraced> deduplication mechanism.

    The contract has two consecutive nop instructions. Both must appear in the trace.
    This guards against regressions of the bug fixed by replacing <lastTraced> with
    <alreadyTraced> + explicit #resetAlreadyTraced continuation.
    """
    program = TEST_DATA / 'consecutive_nop.wast'
    trace_file = tmp_path / 'trace.txt'
    cmap = {'TRACE': str_dv(str(trace_file)).text}
    pmap = {'TRACE': 'cat'}
    _krun(input_file=program, definition_dir=TRACING_DEFINITION_DIR, cmap=cmap, pmap=pmap, check=True)

    records = [json.loads(line) for line in trace_file.read_text().splitlines()]
    nop_count = sum(1 for r in records if r['kind'] == 'instr' and r['instr'] == ['nop'])
    assert nop_count == 2, f'Expected 2 nop entries in trace, got {nop_count}'


def test_tracing_double_u256(tmp_path: Path) -> None:
    """Regression test for the <alreadyTraced> mechanism covering two scenarios at once.

    The contract (double_u256.wast) contains:
    - Two consecutive identical instructions: local.get 0 ; local.get 0
      (consecutive no-intermediate instructions that the old <lastTraced> mechanism would deduplicate)
    - A block whose body instructions must all be traced
      (guarding the block-expansion fix: #resetAlreadyTraced at the start of the body)

    Asserts that both local.get 0 entries appear and that instructions inside the
    block (local.set 1) and after it (local.get 1) are also present.
    """
    program = TEST_DATA / 'double_u256.wast'
    trace_file = tmp_path / 'trace.txt'
    cmap = {'TRACE': str_dv(str(trace_file)).text}
    pmap = {'TRACE': 'cat'}
    _krun(input_file=program, definition_dir=TRACING_DEFINITION_DIR, cmap=cmap, pmap=pmap, check=True)

    records = [json.loads(line) for line in trace_file.read_text().splitlines()]
    instrs = [r['instr'] for r in records if r['kind'] == 'instr']

    local_get_0_count = sum(1 for i in instrs if i == ['local.get', 0])
    assert local_get_0_count == 2, f'Expected 2 local.get 0 entries in trace, got {local_get_0_count}'

    assert ['local.set', 1] in instrs, 'local.set 1 (inside block) missing from trace'
    assert ['local.get', 1] in instrs, 'local.get 1 (after block) missing from trace'


def test_tracing_call_contract_and_end_wasm(tmp_path: Path) -> None:
    """call_add.wast makes one cross-contract call (call_other -> add).

    Checks that `callContract`/`endWasm` are each logged once per call (outermost and nested),
    that their depths agree with each other and increase for the nested call, and that the
    resolved args/result match what the contracts actually exchanged.
    """
    program = TEST_DATA / 'call_add.wast'
    trace_file = tmp_path / 'trace.txt'
    cmap = {'TRACE': str_dv(str(trace_file)).text}
    pmap = {'TRACE': 'cat'}
    _krun(input_file=program, definition_dir=TRACING_DEFINITION_DIR, cmap=cmap, pmap=pmap, check=True)

    records = [json.loads(line) for line in trace_file.read_text().splitlines()]
    calls = [r for r in records if r['kind'] == 'callContract']
    ends = [r for r in records if r['kind'] == 'endWasm']

    assert len(calls) == 2, f'Expected 2 callContract entries, got {len(calls)}'
    assert len(ends) == 2, f'Expected 2 endWasm entries, got {len(ends)}'

    outer_call, inner_call = calls
    assert outer_call['depth'] == 1
    assert outer_call['function'] == 'call_other'
    assert inner_call['depth'] == 2
    assert inner_call['function'] == 'add'
    assert inner_call['args'] == [{'type': 'u32', 'value': 3}, {'type': 'u32', 'value': 5}]

    inner_end, outer_end = ends
    assert inner_end['depth'] == inner_call['depth'], 'nested call depth should match its own endWasm'
    assert outer_end['depth'] == outer_call['depth'], 'outer call depth should match its own endWasm'
    assert inner_end['success'] is True
    assert inner_end['result'] == {'type': 'u32', 'value': 8}
    assert outer_end['result'] == inner_end['result'], 'outer call just forwards the inner result'


def test_tracing_end_wasm_error(tmp_path: Path) -> None:
    """increment_panic.wast calls increment, increment_panic (traps), then increment again.

    Checks that the panicking call's endWasm is logged as a failure with the trap's Error,
    and that execution (and tracing) continues normally for the call after it.
    """
    program = TEST_DATA / 'increment_panic.wast'
    trace_file = tmp_path / 'trace.txt'
    cmap = {'TRACE': str_dv(str(trace_file)).text}
    pmap = {'TRACE': 'cat'}
    _krun(input_file=program, definition_dir=TRACING_DEFINITION_DIR, cmap=cmap, pmap=pmap, check=True)

    records = [json.loads(line) for line in trace_file.read_text().splitlines()]
    ends = [r for r in records if r['kind'] == 'endWasm']

    assert len(ends) == 4, f'Expected 4 endWasm entries (one per callTx), got {len(ends)}'
    assert [e['success'] for e in ends] == [True, True, False, True]

    failure = ends[2]
    assert failure['result']['type'] == 'error'
    assert failure['result']['errType'] == 'context'


def test_tracing_call_contract_storage(tmp_path: Path) -> None:
    """storage.wast makes sequential calls to the same contract: has, put, has, get, del, has, put, extend_ttl.

    Checks that each callContract entry's storage snapshot reflects what the previous call left behind,
    i.e. tracing sees genuinely pre-call state rather than a post-call one. Also checks that the individual
    put/del storage writes (trace-putContractData/trace-delContractData) are logged, matching the two puts
    and one del the test program performs.
    """
    program = TEST_DATA / 'storage.wast'
    trace_file = tmp_path / 'trace.txt'
    cmap = {'TRACE': str_dv(str(trace_file)).text}
    pmap = {'TRACE': 'cat'}
    _krun(input_file=program, definition_dir=TRACING_DEFINITION_DIR, cmap=cmap, pmap=pmap, check=True)

    records = [json.loads(line) for line in trace_file.read_text().splitlines()]
    calls = [r for r in records if r['kind'] == 'callContract']
    storages = [(c['function'], c['storage']) for c in calls]

    expected_entry = {
        'durability': 'temporary',
        'key': {'type': 'symbol', 'value': 'foo'},
        'value': {'type': 'u32', 'value': 123456789},
        'liveUntil': 15,
    }
    assert storages == [
        ('has', []),
        ('put', []),
        ('has', [expected_entry]),
        ('get', [expected_entry]),
        ('del', [expected_entry]),
        ('has', []),
        ('put', []),
        ('extend_ttl', [expected_entry]),
    ]

    contract = calls[0]['to']
    key_arg = {'type': 'symbol', 'value': 'foo'}
    value_arg = {'type': 'u32', 'value': 123456789}
    contract_data = [r for r in records if r['kind'] == 'contractData']
    contract_data_ops = [r['operation'] for r in contract_data]
    assert contract_data_ops == ['put', 'del', 'put'], f'Expected put, del, put in order, got {contract_data_ops}'

    puts = [r for r in contract_data if r['operation'] == 'put']
    dels = [r for r in contract_data if r['operation'] == 'del']
    for put in puts:
        assert put['durability'] == 'temporary'
        assert put['contract'] == contract
        assert put['args'] == [key_arg, value_arg]
    for delete in dels:
        assert delete['durability'] == 'temporary'
        assert delete['contract'] == contract
        assert delete['args'] == [key_arg]


def test_bindings(tmp_path: Path, concrete_kasmer: Kasmer) -> None:
    # Given
    contract_path = SOROBAN_CONTRACTS_DIR / 'valtypes'
    contract_wasm = concrete_kasmer.build_soroban_contract(contract_path, tmp_path)

    # Then
    # Just run this and make sure it doesn't throw an error
    concrete_kasmer.contract_bindings(contract_wasm)
