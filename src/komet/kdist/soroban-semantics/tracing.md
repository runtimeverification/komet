# Tracing

This module adds execution tracing to the WebAssembly semantics.
When tracing is enabled, it logs the VM state at each source-level instruction: the instruction itself, its position in the binary (if available), the value stack, and the local variables.
The trace is written as newline-separated JSON records to the file specified by the `<ioDir>` cell.

Tracing is enabled by setting `<ioDir>` to a non-empty file path. When `<ioDir>` is empty, all tracing rules are disabled and execution proceeds normally.

```k
requires "configuration.md"
requires "fs.md"
requires "json-utils.md"
requires "host/hostfuns.md"
requires "soroban.md"

module TRACING
    imports CONFIG-OPERATIONS
    imports FILE-SYSTEM
    imports JSON-UTILS
    imports HOSTFUNS
    imports SOROBAN
```

## Sort Declarations

`TraceableItem` is the sort of execution steps that can be traced.
It is currently equivalent to `Instr`, but defined as a separate sort to make the intent explicit and allow future extension.

```k
    syntax TraceableItem ::= Instr
```

## Internal Instructions

Two internal instructions drive the tracing mechanism:

- `#traceInstr(I, POS)` -- performs the actual logging of instruction `I` at binary offset `POS` (`.Int` when no offset is available, e.g. for text format programs).
- `#resetAlreadyTraced` -- resets `<alreadyTraced>` to `false` after an instruction has been traced and executed, re-enabling tracing for the next instruction.

```k
    syntax InternalInstr ::= #traceInstr(Instr, OptionalInt)         [symbol("#traceInstr")]
    syntax HelperInstr   ::= "#resetAlreadyTraced"                   [symbol(resetAlreadyTraced)]
```

## Tracing Rules

### Logging

The `traceInstr` rule performs the actual logging. It:

1. Generates the trace data for instruction `I` using the current value stack and locals.
2. Appends it as a JSON record to the trace file.

```k
    rule [traceInstr]:
        <instrs> #traceInstr(I, POS)
              => #appendFileJSONLn(PATH, generateInstrTrace(I, POS, STACK, LOCALS))
                 ...
        </instrs>
        <ioDir> PATH </ioDir>
        <valstack> STACK </valstack>
        <locals> LOCALS </locals>
```

### The `<alreadyTraced>` Mechanism

The `<alreadyTraced>` boolean cell prevents double-logging.
The problem it solves is the following: the `insert-traceInstr` rule intercepts an instruction `I` on top of `<instrs>` and replaces it with `#traceInstr(I, .Int) ~> I ~> #resetAlreadyTraced`.
This means `I` is left on top of `<instrs>` after `#traceInstr` executes — exactly where it started.
Without a guard, `insert-traceInstr` would fire again on the same `I`, producing an infinite logging loop.

The guard works as follows:

1. `insert-traceInstr` only fires when `<alreadyTraced>` is `false`, and immediately sets it to `true`.
2. `I` then executes normally. Because `<alreadyTraced>` is `true`, `insert-traceInstr` cannot fire again on it.
3. The `#resetAlreadyTraced` instruction appended after `I` resets the flag to `false`, re-enabling tracing for the next instruction.

The `resetAlreadyTraced` rule uses `_ => false` so it is safe to fire even when `<alreadyTraced>` is already `false`.
This is necessary because `#block` and `#loop` expansion (see below) prepend an additional `#resetAlreadyTraced`,
which may fire when the flag is already `false` after the block body finishes.

```k
    rule [resetAlreadyTraced]:
        <instrs> #resetAlreadyTraced => .K ... </instrs>
        <alreadyTraced> _ => false </alreadyTraced>

    rule [resetAlreadyTraced-k]:
        <k> #resetAlreadyTraced => .K ... </k>
        <alreadyTraced> _ => false </alreadyTraced>
```

### Intercepting Instructions

There are two interception rules, handling binary and text format programs respectively.

**Binary format** programs have their instructions wrapped in `#instrWithPos(I, OFFSET, SIZE)` during parsing,
which carries the byte offset and size of each instruction in the binary.
The `insert-traceInstr-withPos` rule intercepts these at priority 10, and replaces them with `#traceInstr(I, OFFSET) ~> I ~> #resetAlreadyTraced` — mirroring the standard unwrapping rule defined in `wasm-semantics` but with tracing prepended.
It sets `<alreadyTraced>` to `true` so that `insert-traceInstr` does not double-log the unwrapped `I`.

```k
    rule [insert-traceInstr-withPos]:
        <instrs> #instrWithPos(I, OFFSET, _)
              => #traceInstr(I, OFFSET)
              ~> I
              ~> #resetAlreadyTraced
                 ...
        </instrs>
        <ioDir> PATH </ioDir>
        <alreadyTraced> false => true </alreadyTraced>
      requires PATH =/=String ""    // Tracing is enabled
      [priority(10)]
```

**Text format** programs have plain `Instr` nodes with no position information.
The `insert-traceInstr` rule intercepts these at priority 15, fires only when `<alreadyTraced>` is `false`, sets the flag to `true`, and appends `#resetAlreadyTraced` after `I` to reset the flag once `I` has executed.
The `shouldTraceInstr` predicate further filters out instructions that should not be traced (see below).

```k
    rule [insert-traceInstr]:
        <instrs> I:Instr
              => #traceInstr(I, .Int)
              ~> I
              ~> #resetAlreadyTraced
                 ...
        </instrs>
        <ioDir> PATH </ioDir>
        <alreadyTraced> false => true </alreadyTraced>
      requires PATH =/=String ""    // Tracing is enabled
       andBool shouldTraceInstr(I)  // Should trace this specific instruction
      [priority(15)]
```

### Block and Loop Expansion

`#block` and `#loop` are consumed by `insert-traceInstr` and logged, but they are then expanded into their body instructions by the wasm-semantics rules.
If `#resetAlreadyTraced` were simply left after the `#block`/`#loop` instruction in the continuation, it would fire only after the entire block body has finished — keeping `<alreadyTraced>` true throughout, and blocking tracing of all body instructions.

The fix is to shadow the wasm-semantics expansion rules with tracing-aware versions at priority 20 (after `insert-traceInstr` at priority 15, but before wasm-semantics at priority 50).
These place `#resetAlreadyTraced` at the *start* of the expansion, so the flag is reset before any body instruction is encountered.
The `#resetAlreadyTraced` appended by `insert-traceInstr` after the `#block`/`#loop` instruction then fires at the end of the block body, where it is a safe no-op (since the flag is already `false`).

```k
    rule [tracing-block]:
        <instrs> #block(VECTYP, IS, _)
              => #resetAlreadyTraced
              ~> sequenceInstrs(IS)
              ~> label VECTYP { .Instrs } VALSTACK
                 ...
        </instrs>
        <valstack> VALSTACK => .ValStack </valstack>
      [priority(20)]

    rule [tracing-loop]:
        <instrs> #loop(VECTYP, IS, BLOCKMETA)
              => #resetAlreadyTraced
              ~> sequenceInstrs(IS)
              ~> label VECTYP { #loop(VECTYP, IS, BLOCKMETA) } VALSTACK
                 ...
        </instrs>
        <valstack> VALSTACK => .ValStack </valstack>
      [priority(20)]
```

## Instruction Filter

`shouldTraceInstr` filters out instructions that should not be traced in text format programs.
It is only used by `insert-traceInstr` — binary format programs are always traced unconditionally by `insert-traceInstr-withPos`.
Some instructions are excluded because they are internal constructs not present in the source program, others (e.g. `#br`) because they cannot be logged correctly.
The default is `true` (trace everything), with explicit exclusions:

- `#br` — a source-level instruction that cannot be logged correctly, as its execution leaves another `#br` on top of `<instrs>` (when branching through nested labels), which would break the `<alreadyTraced>` deduplication mechanism.
- `HelperInstr` — administrative instructions generated internally during execution, not present in the source program. This includes `#resetAlreadyTraced`, which is declared as a `HelperInstr` for this reason.
- `invoke` — also an administrative instruction, excluded explicitly until its sort is corrected in the main wasm-semantics (at which point it will be covered by the `HelperInstr` rule).
- `trap` — another administrative instruction that needs to be corrected.

```k
    syntax Bool ::= shouldTraceInstr(Instr)      [function, total]
 // -----------------------------------------------------------------
    rule shouldTraceInstr(#br(_))         => false
    rule shouldTraceInstr(_:HelperInstr)  => false
    rule shouldTraceInstr((invoke _))     => false // TODO invoke is an administrative (helper) instruction. fix its sort in wasm-semantics
    rule shouldTraceInstr(trap)           => false // TODO fix its sort in wasm-semantics
    rule shouldTraceInstr(_)              => true  [owise]
```

## Soroban VM Tracing

### Storage

```k
    rule [trace-putContractData]:
        <instrs> putContractData(STORAGE_TYPE)
              => #appendFileJSONLn(
                    PATH,
                    generateContractDataTrace(CONTRACT, STORAGE_TYPE, "put", ListItem(KEY) ListItem(VAL))
                 )
              ~> putContractData(STORAGE_TYPE)
              ~> #resetAlreadyTraced
                 ...
        </instrs>
        <ioDir> PATH </ioDir>
        <hostStack> KEY:ScVal : VAL:ScVal : _S </hostStack>
        <callee> CONTRACT </callee>
        <alreadyTraced> false => true </alreadyTraced>
      requires PATH =/=String ""
      [priority(10)]

    rule [trace-delContractData]:
        <instrs> delContractData(STORAGE_TYPE)
              => #appendFileJSONLn(
                    PATH,
                    generateContractDataTrace(CONTRACT, STORAGE_TYPE, "del", ListItem(KEY))
                 )
              ~> delContractData(STORAGE_TYPE)
              ~> #resetAlreadyTraced
                 ...
        </instrs>
        <ioDir> PATH </ioDir>
        <hostStack> KEY:ScVal : _S </hostStack>
        <callee> CONTRACT </callee>
        <alreadyTraced> false => true </alreadyTraced>
      requires PATH =/=String ""
      [priority(10)]

```

### Host Calls

Host functions prepend `traceHostCall(MOD, FUNC)` to `<instrs>` before each `hostCall` as a logging hook.
When tracing is enabled, this rule fires and appends a host call record to the trace file.
When tracing is disabled, the paired `traceHostCall-skip` rule in `auto-allocate.md` discards it as a no-op.
Because `traceHostCall` is a `HelperInstr`, it is never intercepted by `insert-traceInstr` and does not interact with the `<alreadyTraced>` mechanism.

```k
    rule [traceHostCall]:
        <instrs> traceHostCall(MOD, FUNC)
              => #appendFileJSONLn(PATH, generateHostCallTrace(MOD, FUNC, LOCALS))
                 ...
        </instrs>
        <ioDir> PATH </ioDir>
        <locals> LOCALS </locals>
      requires PATH =/=String ""

```

### Host Objects

Traces `addObject` before it executes, using the pre-insert state to form the log entry.
`size(OBJS)` gives the index that will be assigned to the new object, and `HostVal2ScValRec` recursively resolves any `HostVal` handles nested in `SCV` to their concrete `ScVal` values — both are only correct against the object table before the insert.

```k
    rule [trace-addObject]:
        <k> addObject(SCV)
         => #appendFileJSONLn(
                PATH,
                generateAddObjectTrace(HostVal2ScValRec(SCV, OBJS, RELS), size(OBJS))
            )
         ~> addObject(SCV)
         ~> #resetAlreadyTraced
            ...
        </k>
        <relativeObjects> RELS </relativeObjects>
        <hostObjects>     OBJS </hostObjects>
        <ioDir> PATH </ioDir>
        <alreadyTraced> false => true </alreadyTraced>
      requires PATH =/=String ""
      [priority(10)]
```

### Trace `callContract`

Traces the start of every contract call, outermost and nested alike: the caller, the callee, the function name, the arguments, the call depth, and the callee's storage as it stands before the call runs.
`ARGS` is a `List` of `HostVal` handles (the same type `pushArgs` expects), so `HostVal2ScValMany` resolves it to concrete `ScVal`s before logging.
The depth logged is `size(<callStack>) +Int 1`, i.e. what the call's own `#endWasm` trace will later report, since `pushCallState` hasn't run yet at this point.
Storage is logged as a single flat list, each entry tagged with its durability (`"instance"`, `"persistent"`, or `"temporary"`): `<instanceStorage>` entries share the contract's own `<contractLiveUntil>`, while `<contractData>` (shared across every contract) is filtered down to the callee's own entries by `ContractDataJSONs`.

This duplicates the transition of `callContract` in `soroban.md` (see the warning there) instead of appending `#resetAlreadyTraced` and requeuing, for the same reason as `#endWasm`'s tracing rules.
Its priority (30) runs it ahead of the base rule's default priority (50).

```k
    rule [trace-callContract]:
        <k> callContract(FROM, TO, FUNCNAME:WasmStringToken, ARGS)
         => #appendFileJSONLn(
                PATH,
                generateCallContractTrace(
                    FROM, TO, wasmString2StringStripped(FUNCNAME),
                    HostVal2ScValMany(ARGS, OBJS, RELS),
                    size(CALLSTACK) +Int 1,
                    INSTANCE,
                    INSTANCE_LIVE_UNTIL,
                    CTRDATA
                )
            )
         ~> pushWorldState
         ~> pushCallState
         ~> resetCallstate
         ~> callContractAux(FROM, TO, FUNCNAME, ARGS)
         ~> #endWasm
            ...
        </k>
        <relativeObjects> RELS </relativeObjects>
        <hostObjects>     OBJS </hostObjects>
        <callStack> CALLSTACK </callStack>
        <ioDir> PATH </ioDir>
        <contract>
          <contractId> TO </contractId>
          <instanceStorage> INSTANCE </instanceStorage>
          <contractLiveUntil> INSTANCE_LIVE_UNTIL </contractLiveUntil>
          ...
        </contract>
        <contractData> CTRDATA </contractData>
      requires PATH =/=String ""
      [priority(30)]
```

### Trace `#endWasm`

Traces the end of every contract call, outermost and nested alike: whether it succeeded or failed, the call depth, and the result.

`trace-endWasm-error` handles the failure case (top of `<hostStack>` is an `Error`), `trace-endWasm` the success case.
Both duplicate the state transition of `endWasm-error`/`endWasm` instead of requeuing `#endWasm` behind `#resetAlreadyTraced`, since a prior `trap` can discard a queued `#resetAlreadyTraced` and wedge `<alreadyTraced>` at `true`.
Their priorities (35, 45) run them ahead of `endWasm-error` (40) and `endWasm` (50).

```k
    rule [trace-endWasm-error]:
        <k> #endWasm
         => #appendFileJSONLn(
                PATH,
                generateEndWasmTrace(false, size(CALLSTACK), ScVal2JSON(ERR))
            )
         ~> popCallState
         ~> popWorldState
            ...
        </k>
        <instrs> .K </instrs>
        <hostStack> (Error(_,_) #as ERR) : _ => ERR : .HostStack </hostStack>
        <callStack> CALLSTACK </callStack>
        <ioDir> PATH </ioDir>
      requires PATH =/=String ""
      [priority(35)]

    rule [trace-endWasm]:
        <k> #endWasm
         => #appendFileJSONLn(
                PATH,
                generateEndWasmTrace(true, size(CALLSTACK), ValStack2ResultJSON(STACK, OBJS, RELS))
            )
         ~> popCallState
         ~> dropWorldState
         ~> #callResult(STACK, RELS)
            ...
        </k>
        <instrs> .K </instrs>
        <relativeObjects> RELS </relativeObjects>
        <hostObjects>     OBJS </hostObjects>
        <valstack> STACK </valstack>
        <callStack> CALLSTACK </callStack>
        <ioDir> PATH </ioDir>
      requires PATH =/=String ""
      [priority(45)]
```

## JSON Record Format

Every trace record is a JSON object with a `kind` field identifying its type — `"instr"` for an instruction record, or the operation name for a Soroban VM operation (see `## Soroban VM Tracing` above).

Instruction records (`kind: "instr"`) have four further fields:

- `pos` — the byte offset of the instruction in the binary, or `null` for text format programs.
- `instr` — a JSON representation of the instruction.
- `stack` — the current value stack contents.
- `locals` — the current local variable bindings.

Each Soroban VM operation has its own set of fields, built by its own `generate*Trace` function below; see `docs/tracing.md` for the full format of each.

Records are written one per line to the trace file.

```k
    syntax JSON ::= generateInstrTrace(Instr, OptionalInt, ValStack, Map)   [function]
 // ---------------------------------------------------------
    rule generateInstrTrace(I:Instr, OFFSET, VS:ValStack, LOCALS:Map)
      => {
          "kind"   : "instr" ,
          "pos"    : #if OFFSET ==K .Int #then null #else {OFFSET}:>Int #fi ,
          "instr"  : Instr2JSON(I) ,
          "stack"  : ValStack2JSON(VS) ,
          "locals" : Locals2JSON(LOCALS)
      }

    syntax JSON ::= generateHostCallTrace(String, String, Map)   [function]
 // -------------------------------------------------------------------------
    rule generateHostCallTrace(MOD, FUNC, LOCALS)
      => {
          "kind"     : "hostCall" ,
          "module"   : MOD ,
          "function" : FUNC ,
          "locals"   : Locals2JSON(LOCALS)
      }

    syntax JSON ::= generateContractDataTrace(ContractId, StorageType, String, List)   [function]
 // --------------------------------------------------------------------------------------------------
    rule generateContractDataTrace(CONTRACT, S_TYPE, OP, ARGS)
      => {
          "kind"       : "contractData" ,
          "operation"  : OP ,
          "durability" : StorageType2JSON(S_TYPE) ,
          "contract"   : Address2JSON(CONTRACT) ,
          "args"       : [ ScVec2JSONs(ARGS) ]
      }

    syntax JSON ::= generateAddObjectTrace(ScVal, Int)   [function]
 // ---------------------------------------------------------------
    rule generateAddObjectTrace(SCV, INDEX)
      => {
          "kind"  : "addObject" ,
          "value" : ScVal2JSON(SCV) ,
          "index" : INDEX
      }

    syntax JSON ::= generateCallContractTrace(Address, ContractId, String, List, Int, instance: Map, instanceLiveUntil: Int, contractData: Map)   [function]
 // ---------------------------------------------------------------------------------------------------------------------------------------------------------
    rule generateCallContractTrace(FROM, TO, FUNCNAME, ARGS, DEPTH, INSTANCE, INSTANCE_LIVE_UNTIL, CTRDATA)
      => {
          "kind"     : "callContract" ,
          "from"     : Address2JSON(FROM) ,
          "to"       : Address2JSON(TO) ,
          "function" : FUNCNAME ,
          "args"     : [ ScVec2JSONs(ARGS) ] ,
          "depth"    : DEPTH ,
          "storage"  : [ appendJSONs(InstanceStorageJSONs(INSTANCE, INSTANCE_LIVE_UNTIL), ContractDataJSONs(CTRDATA, TO)) ]
      }
```

`InstanceStorageJSONs` serializes `<instanceStorage>` entries with durability `"instance"`, all sharing the contract's own `<contractLiveUntil>` since instance storage has no per-key TTL.
`ContractDataJSONs` filters `<contractData>` (shared across every contract) down to the entries whose key belongs to `CONTRACT`, serializing each as its durability, key, value, and TTL.
`appendJSONs` joins the two independently-produced `JSONs` sequences into one flat list — plain `,` only conses a single `JSON` onto a `JSONs`, it doesn't join two `JSONs` together.

```k
    syntax JSONs ::= appendJSONs(JSONs, JSONs)   [function, total]
 // ------------------------------------------------------------------
    rule appendJSONs(.JSONs, JS2) => JS2
    rule appendJSONs((J:JSON, JS1), JS2) => J, appendJSONs(JS1, JS2)

    syntax JSONs ::= InstanceStorageJSONs(Map, liveUntil: Int)   [function]
 // -------------------------------------------------------------------------
    rule InstanceStorageJSONs(K:ScVal |-> V:ScVal REST, LIVE_UNTIL)
      => {
            "durability" : "instance" ,
            "key"        : ScVal2JSON(K) ,
            "value"      : ScVal2JSON(V) ,
            "liveUntil"  : LIVE_UNTIL
         } , InstanceStorageJSONs(REST, LIVE_UNTIL)

    rule InstanceStorageJSONs(.Map, _LIVE_UNTIL) => .JSONs

    syntax JSONs ::= ContractDataJSONs(Map, ContractId)   [function]
 // ------------------------------------------------------------------
    rule ContractDataJSONs(#skey(CONTRACT, DUR, KEY) |-> #sval(VAL, LIVE_UNTIL) REST, CONTRACT)
      => {
            "durability" : StorageType2JSON(DUR) ,
            "key"        : ScVal2JSON(KEY) ,
            "value"      : ScVal2JSON(VAL) ,
            "liveUntil"  : LIVE_UNTIL
         } , ContractDataJSONs(REST, CONTRACT)

    rule ContractDataJSONs(_ |-> _ REST, CONTRACT)
      => ContractDataJSONs(REST, CONTRACT)
      [owise]

    rule ContractDataJSONs(.Map, _) => .JSONs
```

`ValStack2ResultJSON` resolves a contract call's return value to JSON: `null` for a void return (empty stack), or the `ScVal` the top `i64` handle resolves to.

```k
    syntax JSON ::= ValStack2ResultJSON(ValStack, objs: List, rels: List)   [function]
 // -------------------------------------------------------------------------------------
    rule ValStack2ResultJSON(.ValStack, _, _) => null
    rule ValStack2ResultJSON(<i64> I : _, OBJS, RELS)
      => ScVal2JSON(HostVal2ScVal(HostVal(I), OBJS, RELS))

    syntax JSON ::= generateEndWasmTrace(Bool, Int, JSON)   [function]
 // -------------------------------------------------------------------
    rule generateEndWasmTrace(SUCCESS, DEPTH, RESULT)
      => {
          "kind"    : "endWasm" ,
          "success" : SUCCESS ,
          "depth"   : DEPTH ,
          "result"  : RESULT
      }


endmodule
```
