"""Golden test for in-K per-step linear-memory tracing.

Deploys the `increment` example contract and invokes `increment(5)` with tracing
enabled. Unlike the pure-arithmetic adder (which never touches linear memory), this
contract reads and writes instance storage, so its `-O0` code spills to the shadow
stack — exercising the `mem` field: a full sparse snapshot of the current module's
linear memory (a list of `{addr, bytes(hex)}` runs) emitted only when memory changed
since the previous snapshot, `null` otherwise. This is what the simbolik-komet debugger
folds into a per-step memory image to resolve shadow-stack Rust variables.
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
            # First call against empty storage: unwrap_or(0) + 5 => 5.
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


def _is_hex(s: str) -> bool:
    return len(s) % 2 == 0 and all(c in '0123456789abcdef' for c in s)


def test_mem_field_present_and_wellformed(tmp_path: Path) -> None:
    records = _run_trace(tmp_path)
    instr = [r for r in records if 'stack' in r]  # instruction records
    assert instr, 'expected instruction records'

    # Every instruction record carries a `mem` field: null, or a list of runs.
    for r in instr:
        assert 'mem' in r, f'instruction record missing mem: {r}'
        assert r['mem'] is None or isinstance(r['mem'], list), f'mem must be null or a list: {r["mem"]}'


def test_memory_snapshots_emitted_on_change(tmp_path: Path) -> None:
    records = _run_trace(tmp_path)
    instr = [r for r in records if 'stack' in r]

    snapshots = [r for r in instr if r['mem'] is not None]
    assert snapshots, 'expected at least one non-null memory snapshot (contract writes the shadow stack)'

    # Every run is well-formed and, within a snapshot, runs are disjoint and ascending.
    seen_nonempty_run = False
    for r in snapshots:
        ranges = []
        for run in r['mem']:
            assert set(run.keys()) == {'addr', 'bytes'}, f'unexpected run shape: {run}'
            assert isinstance(run['addr'], int) and run['addr'] >= 0, run
            assert isinstance(run['bytes'], str) and _is_hex(run['bytes']), run
            data = bytes.fromhex(run['bytes'])
            if data:
                seen_nonempty_run = True
            ranges.append((run['addr'], run['addr'] + len(data)))
        ranges.sort()
        for (_, end), (nxt, _) in zip(ranges, ranges[1:], strict=False):
            assert end <= nxt, f'overlapping/mis-ordered runs in snapshot: {r["mem"]}'
    assert seen_nonempty_run, 'expected at least one non-empty memory run'

    # Change-detection: most instructions do not write memory, so many records are null.
    assert any(r['mem'] is None for r in instr), 'expected some unchanged (null) records'


def test_memory_image_reconstructs(tmp_path: Path) -> None:
    """Folding the latest snapshot <= each record yields a non-empty, consistent image."""
    records = _run_trace(tmp_path)
    instr = [r for r in records if 'stack' in r]

    image: dict[int, int] = {}
    for r in instr:
        if r['mem'] is None:
            continue
        image = {}  # a snapshot is the whole memory: replace, don't merge
        for run in r['mem']:
            for i, b in enumerate(bytes.fromhex(run['bytes'])):
                image[run['addr'] + i] = b

    assert image, 'expected a non-empty reconstructed memory image'
    # The written counter value (5) marshaled onto the shadow stack should appear as a
    # byte somewhere in memory at some point; at minimum the image has real content.
    assert any(v != 0 for v in image.values()), 'reconstructed memory is unexpectedly all zeros'
