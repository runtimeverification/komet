"""Golden test for in-K per-step WebAssembly globals tracing.

Deploys the `increment` example contract and invokes `increment(5)` with tracing
enabled, then asserts every instruction record carries a `globals` object: the
executing module's globals keyed by MODULE-RELATIVE global index.

A debugger needs these to resolve Rust variables whose DWARF location (or whose
frame base) reads a global rather than the shadow stack in linear memory — at
-O0 that is the `__stack_pointer` global, so without this field those variables
degrade to `<optimized out>`. The index space matters: DWARF's
`DW_OP_WASM_location` global operand is a module index, not the store-level
`<gAddr>` the semantics allocate, so the two must not be confused.

Companion to test_memory_tracing.py, which covers the `mem` field the same way.
"""

from __future__ import annotations

import json
from pathlib import Path

from pyk.kast.inner import KSort
from pyk.ktool.krun import KRunOutput

from komet.kasmer import Kasmer
from komet.kast.syntax import (
    account_id,
    call_tx,
    contract_id,
    deploy_contract,
    sc_u32,
    set_account,
    set_exit_code,
    steps_of,
    upload_wasm,
)
from komet.utils import concrete_tracing_definition

WASM = Path(__file__).parent / 'data' / 'increment.wasm'


def _run_trace(tmp_path: Path) -> list[dict]:
    trace_file = tmp_path / 'trace.jsonl'
    kasmer = Kasmer(definition=concrete_tracing_definition(), trace_file=trace_file)

    contract = kasmer.kast_from_wasm(WASM)
    steps = steps_of(
        [
            set_exit_code(1),
            upload_wasm(b'test', contract),
            set_account(b'test-account', 9876543210),
            deploy_contract(b'test-account', b'test-contract', b'test'),
            call_tx(
                account_id(b'test-account'),
                contract_id(b'test-contract'),
                'increment',
                [sc_u32(5)],
                sc_u32(5),
            ),
            set_exit_code(0),
        ]
    )
    cmap, pmap = kasmer.config_vars()
    proc = kasmer.concrete_definition.krun_with_kast(
        steps, sort=KSort('Steps'), output=KRunOutput.KORE, cmap=cmap, pmap=pmap
    )
    assert proc.returncode == 0, proc.stderr
    assert trace_file.is_file(), 'no trace produced'
    return [json.loads(line) for line in trace_file.read_text().splitlines() if line.strip()]


def _instruction_records(records: list[dict]) -> list[dict]:
    """Instruction records carry a value stack; VM event records do not."""
    return [r for r in records if 'stack' in r]


def test_globals_field_present_and_wellformed(tmp_path: Path) -> None:
    records = _run_trace(tmp_path)
    instr = _instruction_records(records)
    assert instr, 'expected instruction records'

    for record in instr:
        assert 'globals' in record, f'instruction record missing globals: {record}'
        globals_ = record['globals']
        assert isinstance(globals_, dict), f'globals must be an object: {globals_}'
        for key, value in globals_.items():
            # Keys are decimal module-relative indices, as strings (like `locals`).
            assert key.isdigit(), f'global key must be a decimal index: {key!r}'
            # Values are [type, value] pairs, exactly like locals and stack entries.
            assert isinstance(value, list) and len(value) == 2, f'bad global value: {value}'
            assert isinstance(value[0], str), f'global type must be a string: {value}'


def test_globals_use_module_relative_indices(tmp_path: Path) -> None:
    """The keys are module indices (dense from 0), not store-level addresses."""
    records = _run_trace(tmp_path)
    instr = _instruction_records(records)

    seen_nonempty = False
    for record in instr:
        indices = sorted(int(k) for k in record['globals'])
        if not indices:
            continue
        seen_nonempty = True
        # A module's globals are indexed 0..n-1, so the set must be exactly that
        # range. A store-level <gAddr> keying would drift once a second module
        # (the Soroban host's own, or another contract) allocates globals.
        assert indices == list(range(len(indices))), f'non-dense global indices: {indices}'

    assert seen_nonempty, 'expected at least one record with a global (the shadow-stack pointer)'


def test_shadow_stack_pointer_moves(tmp_path: Path) -> None:
    """The contract's -O0 prologue moves __stack_pointer, so global 0 changes."""
    records = _run_trace(tmp_path)
    instr = _instruction_records(records)

    values = [r['globals']['0'][1] for r in instr if '0' in r['globals']]
    assert values, 'expected a global 0 (the shadow-stack pointer)'
    assert len(set(values)) > 1, f'expected global 0 to change during execution, saw {set(values)}'


def test_globals_are_repeated_every_step(tmp_path: Path) -> None:
    """Unlike `mem`, globals are never change-suppressed: there are only a few,
    so a consumer reads them off the current record with no scan."""
    records = _run_trace(tmp_path)
    instr = _instruction_records(records)

    # No record uses `null` to mean "unchanged" the way `mem` does.
    assert all(r['globals'] is not None for r in instr)
    # And the field is present on every single instruction record, not just some.
    assert all('globals' in r for r in instr)
