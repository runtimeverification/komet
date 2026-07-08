# Instruction-Level Execution Tracing

## Overview

Komet supports instruction-level execution tracing for WebAssembly programs. When tracing is enabled, komet records the VM state at each executed instruction and writes it to a file. These trace logs are intended to be consumed by a debugger, which uses them to provide debugging features such as stepping through execution and examining the value stack and local variables at each point.

Alongside per-instruction traces, higher-level Soroban VM events are also logged: host function calls, storage reads/writes, host object allocation, and the start/end of every contract call. See [Soroban VM Events](#soroban-vm-events) below.

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
| `pos`    | integer or null  | Zero-indexed byte offset of the instruction in the binary. `null` for text format programs (which carry no byte offset information), or for instructions inserted by the semantics during execution rather than decoded from the binary (e.g. during global initialization, or synthetic control flow). |
| `instr`  | array            | The instruction and its operands encoded as a JSON array. The first element is the instruction name, followed by its operands, e.g. `i64.const 255` is encoded as `["const", "i64", 255]`. |
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

## Soroban VM Events

Besides per-instruction traces, several higher-level Soroban VM events are logged as their own JSON records, shaped for that specific event rather than the four-field `pos`/`instr`/`stack`/`locals` format above. All of them share the `instr` field as a tag (its first element names the event) and `pos: null`, since none of them come from a specific position in the binary.

For the full serialization format of any `ScVal`-typed field below (`args`, `value`, `result`, storage `key`/`value`), see `ScVal2JSON` in [`json-utils.md`](../src/komet/kdist/soroban-semantics/json-utils.md). Addresses (`from`, `to`, `contract`) are serialized the same way as in `komet-node`'s `#decodeArg`: `{"type": "address", "addrType": "account"/"contract", "value": <hex>}`.

### Host Calls

Logged once per host function invocation.

```json
{"pos": null, "instr": ["hostCall", "v", "g"], "locals": {"0": ["i64", 4503530907893764], "1": ["i64", 8589934596]}}
```

| Field    | Type   | Description |
|----------|--------|-------------|
| `instr`  | array  | `["hostCall", module, function]`. |
| `locals` | object | Local variable bindings at the time of the call, same shape as instruction-level traces. |

### Storage Writes

Logged for every `put`/`del` on contract storage, for all three durabilities.

```json
{"pos": null, "instr": ["contractData", "put", "temporary"], "contract": {"type": "address", "addrType": "contract", "value": "746573742d7363"}, "args": [{"type": "symbol", "value": "foo"}, {"type": "u32", "value": 123456789}]}
```

| Field      | Type   | Description |
|------------|--------|-------------|
| `instr`    | array  | `["contractData", op, durability]` — `op` is `"put"` or `"del"`; `durability` is `"instance"`, `"persistent"`, or `"temporary"`. |
| `contract` | object | The contract the write targets. |
| `args`     | array  | `[key, value]` for `put`, `[key]` for `del`. |

### Host Object Allocation

Logged before a new host object is allocated.

```json
{"pos": null, "instr": ["addObject"], "value": {"type": "address", "addrType": "contract", "value": "746573742d73632d32"}, "index": 0}
```

| Field   | Type    | Description |
|---------|---------|-------------|
| `instr` | array   | `["addObject"]`. |
| `value` | object  | The resolved value being allocated. |
| `index` | integer | The host object table index it will be assigned. |

### Contract Calls

Logged at the start and end of every contract call.

**Start** (`callContract`):

```json
{"pos": null, "instr": ["callContract"], "from": {"type": "address", "addrType": "account", "value": "746573742d63616c6c6572"}, "to": {"type": "address", "addrType": "contract", "value": "746573742d73632d31"}, "function": "call_other", "args": [{"type": "address", "addrType": "contract", "value": "746573742d73632d32"}, {"type": "u32", "value": 3}, {"type": "u32", "value": 5}], "depth": 1, "storage": []}
```

| Field     | Type    | Description |
|-----------|---------|-------------|
| `instr`   | array   | `["callContract"]`. |
| `from`    | object  | The caller's address. |
| `to`      | object  | The callee's address. |
| `function`| string  | The name of the function being called. |
| `args`    | array   | The resolved arguments passed to the call. |
| `depth`   | integer | Call nesting depth; the outermost call is `1`. |
| `storage` | array   | The callee's full storage as it stands *before* the call runs — every entry across all three durabilities, each an object with `durability`, `key`, `value`, and `liveUntil` (for `instance` entries, `liveUntil` is the contract's own instance TTL, since instance storage has no per-key TTL). |

**End** (`endWasm`):

```json
{"pos": null, "instr": ["endWasm"], "success": true, "depth": 2, "result": {"type": "u32", "value": 8}}
```

| Field     | Type              | Description |
|-----------|-------------------|-------------|
| `instr`   | array             | `["endWasm"]`. |
| `success` | boolean           | Whether the call completed normally, as opposed to trapping or producing a host `Error`. |
| `depth`   | integer           | Call nesting depth, matching the depth logged by that call's own `callContract` entry. |
| `result`  | object or null    | The resolved return value on success, the `Error` produced on failure, or `null` for a void return. |

## Examples

`call_add.wast` performs one cross-contract call: the outermost invocation calls `call_other` on one contract, which in turn calls `add` on another. Running it with tracing enabled:

```sh
komet run --trace-file trace.jsonl src/tests/integration/data/call_add.wast
```

produces one line per instruction, plus the Soroban VM events described above — 400 lines in total for this program.

The following excerpt shows the full trace, with instructions and VM events interleaved in the order they occurred:

```sh
$ head -n 8 trace.jsonl
{"pos":null,"instr":["addObject"],"value":{"type":"address","addrType":"contract","value":"746573742d73632d32"},"index":0}
{"pos":null,"instr":["callContract"],"from":{"type":"address","addrType":"account","value":"746573742d63616c6c6572"},"to":{"type":"address","addrType":"contract","value":"746573742d73632d31"},"function":"call_other","args":[{"type":"address","addrType":"contract","value":"746573742d73632d32"},{"type":"u32","value":3},{"type":"u32","value":5}],"depth":1,"storage":[]}
{"pos":null,"instr":["const","i32",1048576],"stack":[],"locals":{}}
{"pos":null,"instr":["const","i32",1048579],"stack":[],"locals":{}}
{"pos":null,"instr":["const","i32",1048592],"stack":[],"locals":{}}
{"pos":null,"instr":["const","i32",1048576],"stack":[],"locals":{}}
{"pos":null,"instr":["const","i64",77],"stack":[],"locals":{}}
{"pos":null,"instr":["const","i64",12884901892],"stack":[["i64",77]],"locals":{}}
```

To restrict the output to the Soroban VM events, excluding instructions, select on the event tags:

```sh
$ jq -c 'select(.instr[0] | IN("callContract", "endWasm", "hostCall", "addObject", "contractData"))' trace.jsonl
{"pos":null,"instr":["addObject"],"value":{"type":"address","addrType":"contract","value":"746573742d73632d32"},"index":0}
{"pos":null,"instr":["callContract"],"from":{"type":"address","addrType":"account","value":"746573742d63616c6c6572"},"to":{"type":"address","addrType":"contract","value":"746573742d73632d31"},"function":"call_other","args":[{"type":"address","addrType":"contract","value":"746573742d73632d32"},{"type":"u32","value":3},{"type":"u32","value":5}],"depth":1,"storage":[]}
{"pos":null,"instr":["hostCall","v","g"],"locals":{"1":["i64",8589934596],"0":["i64",4503530907893764]}}
{"pos":null,"instr":["addObject"],"value":{"type":"vec","value":[{"type":"u32","value":3},{"type":"u32","value":5}]},"index":1}
{"pos":null,"instr":["hostCall","d","_"],"locals":{"2":["i64",12884901963],"1":["i64",40528142],"0":["i64",77]}}
{"pos":null,"instr":["callContract"],"from":{"type":"address","addrType":"contract","value":"746573742d73632d31"},"to":{"type":"address","addrType":"contract","value":"746573742d73632d32"},"function":"add","args":[{"type":"u32","value":3},{"type":"u32","value":5}],"depth":2,"storage":[]}
{"pos":null,"instr":["endWasm"],"success":true,"depth":2,"result":{"type":"u32","value":8}}
{"pos":null,"instr":["endWasm"],"success":true,"depth":1,"result":{"type":"u32","value":8}}
```

To isolate the call tree — which contract called which, at what depth, with the callee's storage on entry and the result on exit — filter on the `callContract` and `endWasm` events:

```sh
$ jq -c 'select(.instr[0] == "callContract" or .instr[0] == "endWasm")' trace.jsonl
{"pos":null,"instr":["callContract"],"from":{"type":"address","addrType":"account","value":"746573742d63616c6c6572"},"to":{"type":"address","addrType":"contract","value":"746573742d73632d31"},"function":"call_other","args":[{"type":"address","addrType":"contract","value":"746573742d73632d32"},{"type":"u32","value":3},{"type":"u32","value":5}],"depth":1,"storage":[]}
{"pos":null,"instr":["callContract"],"from":{"type":"address","addrType":"contract","value":"746573742d73632d31"},"to":{"type":"address","addrType":"contract","value":"746573742d73632d32"},"function":"add","args":[{"type":"u32","value":3},{"type":"u32","value":5}],"depth":2,"storage":[]}
{"pos":null,"instr":["endWasm"],"success":true,"depth":2,"result":{"type":"u32","value":8}}
{"pos":null,"instr":["endWasm"],"success":true,"depth":1,"result":{"type":"u32","value":8}}
```

To observe every storage write a contract performs during a run — `storage.wast` performs a `put`, a `del`, and then another `put`:

```sh
$ komet run --trace-file trace.jsonl src/tests/integration/data/storage.wast
$ jq -c 'select(.instr[0] == "contractData")' trace.jsonl
{"pos":null,"instr":["contractData","put","temporary"],"contract":{"type":"address","addrType":"contract","value":"746573742d7363"},"args":[{"type":"symbol","value":"foo"},{"type":"u32","value":123456789}]}
{"pos":null,"instr":["contractData","del","temporary"],"contract":{"type":"address","addrType":"contract","value":"746573742d7363"},"args":[{"type":"symbol","value":"foo"}]}
{"pos":null,"instr":["contractData","put","temporary"],"contract":{"type":"address","addrType":"contract","value":"746573742d7363"},"args":[{"type":"symbol","value":"foo"},{"type":"u32","value":123456789}]}
```

## How It Works

Tracing is implemented as a separate build target (`soroban-semantics.llvm-tracing`) using K's md selectors for conditional compilation. It does not affect the default `soroban-semantics.llvm` build target.

The tracing semantics introduce a `<trace>` configuration cell that holds tracing-related state. During execution, the tracing rules intercept each instruction (or, for the Soroban VM events above, each relevant internal command) before it takes effect and log the current VM state to the output file as a JSON record.

The implementation is split across several modules:

- [`tracing.md`](../src/komet/kdist/soroban-semantics/tracing.md) — core tracing rules; intercepts instructions and Soroban VM events, and coordinates log emission. See this file for a detailed explanation of the tracing mechanism.
- `fs.md` — file operation functions used to append records to the output file
- [`json-utils.md`](../src/komet/kdist/soroban-semantics/json-utils.md) — JSON serialization for WebAssembly values, types, instructions, and runtime structures. See this file for the full serialization format of each field in the trace records.
- [`auto-allocate.md`](../src/komet/kdist/soroban-semantics/auto-allocate.md) — prepends a `traceHostCall` hook before every `hostCall`.
