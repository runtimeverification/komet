# Instruction-Level Execution Tracing

## Overview

Komet supports instruction-level execution tracing for WebAssembly programs. When tracing is enabled, komet records the VM state at each executed instruction and writes it to a file. These trace logs are intended to be consumed by a debugger, which uses them to provide debugging features such as stepping through execution and examining the value stack and local variables at each point.

## Usage

Tracing is enabled via the `--trace-file` option, available on both `komet run` and `komet test`. When provided, komet builds and uses the tracing-enabled backend and writes one JSON record per instruction to the specified file. Tracing is currently only supported on the LLVM backend.

```
komet run --trace-file <output_file> <program>
komet test --trace-file <output_file> [options]
```

Examples:

```sh
komet run --trace-file trace.jsonl src/tests/integration/data/errors.wast

komet test -C src/tests/integration/data/soroban/contracts/test_adder/ \
  --id test_add --trace-file trace.jsonl --max-examples 1
```

## Trace Format

Each line in the trace file is a self-contained JSON record representing a single instruction execution:

```json
{"pos": 597, "instr": ["block"], "stack": [], "locals": {"0": ["i64", 4]}}
```

For the formal specification of how each value and type is serialized, see [`json-utils.md`](../src/komet/kdist/soroban-semantics/json-utils.md).

| Field    | Type             | Description |
|----------|------------------|-------------|
| `pos`    | integer or null  | Zero-indexed byte offset of the instruction in the binary. `null` for instructions that are inserted by the semantics during execution rather than decoded from the binary (e.g. during global initialization, or synthetic control flow). |
| `instr`  | array            | The instruction and its operands. |
| `stack`  | array            | The value stack at the time of execution. Each entry is a `[type, value]` pair, e.g. `["i64", 4]`. |
| `locals` | object           | The local variable bindings at the time of execution, keyed by index. Each value is a `[type, value]` pair. |

### Example

The following excerpt is from a binary wasm execution. Most instructions have a `pos` value; entries with `"pos": null` are semantics-inserted instructions.

```jsonl
{"pos": null, "instr": ["const", "i64", 4], "stack": [], "locals": {}}
{"pos": null, "instr": ["block"], "stack": [], "locals": {"0": ["i64", 4]}}
{"pos": 597, "instr": ["block"], "stack": [], "locals": {"0": ["i64", 4]}}
{"pos": 599, "instr": ["local.get", 0], "stack": [], "locals": {"0": ["i64", 4]}}
{"pos": 601, "instr": ["const", "i64", 255], "stack": [["i64", 4]], "locals": {"0": ["i64", 4]}}
{"pos": 604, "instr": ["and", "i64"], "stack": [["i64", 255], ["i64", 4]], "locals": {"0": ["i64", 4]}}
{"pos": 605, "instr": ["const", "i64", 4], "stack": [["i64", 4]], "locals": {"0": ["i64", 4]}}
{"pos": 607, "instr": ["eq", "i64"], "stack": [["i64", 4], ["i64", 4]], "locals": {"0": ["i64", 4]}}
{"pos": 608, "instr": ["br_if", 0], "stack": [["i32", 1]], "locals": {"0": ["i64", 4]}}
```

## How It Works

Tracing is implemented as a separate build target (`soroban-semantics.llvm-tracing`) using K's md selectors for conditional compilation. It does not affect the default `soroban-semantics.llvm` build target.

The tracing semantics introduce a `<trace>` configuration cell that holds tracing-related state. During execution, the tracing rules intercept each instruction before it is executed and log the current VM state (instruction, byte offset, value stack, locals) to the output file as a JSON record.

The implementation is split across three modules:

- [`tracing.md`](../src/komet/kdist/soroban-semantics/tracing.md) — core tracing rules; intercepts instructions and coordinates log emission. See this file for a detailed explanation of the tracing mechanism.
- `fs.md` — file operation functions used to append records to the output file
- [`json-utils.md`](../src/komet/kdist/soroban-semantics/json-utils.md) — JSON serialization for WebAssembly values, types, instructions, and runtime structures. See this file for the full serialization format of each field in the trace records.

## Limitations

Consecutive identical instructions may not be logged correctly for **text format** programs. This is a known limitation of the `<lastTraced>` deduplication mechanism: when two identical instructions appear back-to-back and the first does not leave or rewrite to an intermediate value in `<instrs>`, the second will not be logged.

This limitation does not affect **binary format** programs, where each instruction is wrapped with its byte position and traced unconditionally.
