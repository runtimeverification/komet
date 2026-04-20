# Tracing

This module adds execution tracing to the WebAssembly semantics.
When tracing is enabled, it logs the VM state at each source-level instruction: the instruction itself, its position in the binary (if available), the value stack, and the local variables.
The trace is written as newline-separated JSON records to the file specified by the `<ioDir>` cell.

Tracing is enabled by setting `<ioDir>` to a non-empty file path. When `<ioDir>` is empty, all tracing rules are disabled and execution proceeds normally.

```k
requires "configuration.md"
requires "fs.md"
requires "json-utils.md"

module TRACING
    imports CONFIG-OPERATIONS
    imports FILE-SYSTEM
    imports JSON-UTILS
```

## Sort Declarations

`TraceableItem` is the sort of execution steps that can be traced.
It is currently equivalent to `Instr`, but defined as a separate sort to make the intent explicit and allow future extension.

```k
    syntax TraceableItem ::= Instr
```

`LastTraced` represents the last traced item stored in the `<lastTraced>` cell.
It is either `.LastTraced`, representing the case where nothing has been traced yet, or the last `TraceableItem` that was traced.

```k
    syntax LastTraced ::= TraceableItem
```

## Internal Instructions

Two internal instructions drive the tracing mechanism:

- `#traceInstr(I, POS)` -- performs the actual logging of instruction `I` at binary offset `POS` (`.Int` when no offset is available, e.g. for text format programs).
- `#setLastTraced(I)` -- updates `<lastTraced>` to `I` after logging is complete. 
    It is a separate instruction rather than a direct cell update in the `traceInstr` rule,
    because `<lastTraced>` must only be updated after the file write has finished executing,
    ensuring the deduplication guard is not lifted prematurely.

```k
    syntax InternalInstr ::= #traceInstr(Instr, OptionalInt)         [symbol("#traceInstr")]
                           | #setLastTraced(TraceableItem)
```

## Tracing Rules

### Logging

The `traceInstr` rule performs the actual logging. It:

1. Generates the trace data for instruction `I` using the current value stack and locals.
2. Appends it as a JSON record to the trace file.
3. Sequences `#setLastTraced(I)` to record that `I` has been traced, preventing double-logging.

```k
    rule [traceInstr]:
        <instrs> #traceInstr(I, POS)
              => #let TRACE_LINE = generateTrace(I, POS, STACK, LOCALS) #in
                 #appendFile(PATH, TRACE_LINE +String "\n")
              ~> #setLastTraced(I)
                 ...
        </instrs>
        <ioDir> PATH </ioDir>
        <valstack> STACK </valstack>
        <locals> LOCALS </locals>
```

### The `<lastTraced>` Mechanism

The `<lastTraced>` cell is central to preventing double-logging.
The problem it solves is the following: the `insert-traceInstr` rule intercepts an instruction `I` on top of `<instrs>`and replaces it with `#traceInstr(I, .Int) ~> I`.
This means `I` is left on top of `<instrs>` after `#traceInstr` executes — exactly where it started.
Without a guard, `insert-traceInstr` would fire again on the same `I`, producing an infinite logging loop.

The same problem arises for binary programs: after `insert-traceInstr-withPos` fires, the unwrapped `I` is left on top of `<instrs>`, and without a guard `insert-traceInstr` would pick it up and log it a second time.

The guard works as follows:

1. `insert-traceInstr` only fires when `<lastTraced>` differs from `I`.
2. After logging, `#setLastTraced(I)` sets `<lastTraced>` to `I`, blocking re-insertion.
3. When `I` executes and is consumed, a *different* item appears on top of `<instrs>`.
   The `resetLastTraced` rule detects this and clears `<lastTraced>` back to `.LastTraced`, re-enabling tracing for the next instruction.

The `setLastTraced` rule requires `<lastTraced>` to be `.LastTraced` before updating it.
This ensures `<lastTraced>` is always reset by `resetLastTraced` between two consecutive traced instructions, making the mechanism well-sequenced.

```k
    rule [setLastTraced]:
        <instrs> #setLastTraced(X) => .K ... </instrs>
        <lastTraced> .LastTraced => X </lastTraced> // lastTraced must be reset before the new trace
```

The `resetLastTraced` rule runs at priority 5 (higher than all other rules) so it fires eagerly as soon as a new item appears on top of `<instrs>`, before any other rule gets a chance to match.
This ensures `<lastTraced>` is cleared before `insert-traceInstr` evaluates its guard for the next instruction.

```k
    rule [resetLastTraced]:
        <instrs> I:KItem ... </instrs>
        <lastTraced> LAST:TraceableItem => .LastTraced </lastTraced>
      requires LAST =/=K I
      [priority(5)]
```

**Note**: The `resetLastTraced` rule fires when the item on top of `<instrs>` differs from `<lastTraced>`.
For most instructions, after `I` executes it leaves its result value (e.g. `<i32> X`) on top of `<instrs>` to be pushed to `<valstack>`.
At this intermediate step the `resetLastTraced` rule fires and clears `<lastTraced>` as expected.

However, some instructions execute at one step and do not leave a result value in `<instrs>`,
such as `local.get`, `local.set`, `local.tee`, `global.get`, `global.set`, `elem.drop`, `drop`, `select`, and `nop`.
For these, after `I` executes, the next item on top of `<instrs>` is the following instruction.
If that instruction happens to be identical to `I`, `resetLastTraced` will not fire, and the second occurrence will not be logged.

Note that this is only an issue for text format programs.
For binary format, `insert-traceInstr-withPos` does not check `<lastTraced>` and fires unconditionally on every `#instrWithPos`,
so consecutive identical instructions are always both logged correctly.

### Intercepting Instructions

There are two interception rules, handling binary and text format programs respectively.

**Binary format** programs have their instructions wrapped in `#instrWithPos(I, OFFSET, SIZE)` during parsing,
which carries the byte offset and size of each instruction in the binary.
The `insert-traceInstr-withPos` rule intercepts these at priority 10, and replaces them with `#traceInstr(I, OFFSET) ~> I` — mirroring the standard unwrapping rule defined in `wasm-semantics` but with tracing prepended.

This rule does not need to check `<lastTraced>` because `#instrWithPos` is consumed (unwrapped) by the rule,
so it never appears on top of `<instrs>` after `#traceInstr` executes.

```k
    rule [insert-traceInstr-withPos]:
        <instrs> #instrWithPos(I, OFFSET, _)
              => #traceInstr(I, OFFSET)
              ~> I
                 ...
        </instrs>
        <ioDir> PATH </ioDir>
      requires PATH =/=String ""    // Tracing is enabled
      [priority(10)]
```

**Text format** programs have plain `Instr` nodes with no position information.
The `insert-traceInstr` rule intercepts these at priority 15, and prepends `#traceInstr(I, .Int)` to perform instruction logging.
It uses the `<lastTraced>` guard (`LAST =/=K I`) to prevent re-intercepting the same instruction after `#traceInstr` has executed and left `I` on top of `<instrs>`. The `shouldTraceInstr` predicate further filters out instructions that should not be traced (see below).

```k
    rule [insert-traceInstr]:
        <instrs> I:Instr
              => #traceInstr(I, .Int)
              ~> I
                 ...
        </instrs>
        <ioDir> PATH </ioDir>
        <lastTraced> LAST </lastTraced>
      requires PATH =/=String ""    // Tracing is enabled
       andBool shouldTraceInstr(I)  // Should trace this specific instruction
       andBool LAST =/=K I
      [priority(15)]
```

## Instruction Filter

`shouldTraceInstr` filters out instructions that should not be traced in text format programs.
It is only used by `insert-traceInstr` — binary format programs are always traced unconditionally by `insert-traceInstr-withPos`.
Some instructions are excluded because they are internal constructs not present in the source program, others (e.g. `#br`) because they cannot be logged correctly.
The default is `true` (trace everything), with explicit exclusions:

- `#br` — a source-level instruction that cannot be logged correctly, as its execution leaves another `#br` on top of `<instrs>` (when branching through nested labels), which would break the `<lastTraced>` deduplication mechanism.
- `HelperInstr` — administrative instructions generated internally during execution, not present in the source program.
- `invoke` — also an administrative instruction, excluded explicitly until its sort is corrected in the main wasm-semantics (at which point it will be covered by the `HelperInstr` rule).
- `trap` — another administrative instruction that needs to be corrected.

```k
    syntax Bool ::= shouldTraceInstr(Instr)      [function, total]
 // -----------------------------------------------------------------
    rule shouldTraceInstr(#br(_))         => false
    rule shouldTraceInstr(_:HelperInstr)  => false
    rule shouldTraceInstr((invoke _))     => false // TODO invoke is an administrative (helper) instruction. fix it's sort in wasm-semantics
    rule shouldTraceInstr(trap)           => false // TODO fix it's sort in wasm-semantics
    rule shouldTraceInstr(_)              => true  [owise]
```

## Trace Format

Each trace record is a JSON object with four fields:

- `pos` — the byte offset of the instruction in the binary, or `null` for text format programs.
- `instr` — a JSON representation of the instruction.
- `stack` — the current value stack contents.
- `locals` — the current local variable bindings.

Records are written one per line to the trace file.

```k
    syntax String ::= generateTrace(Instr, OptionalInt, ValStack, Map)   [function]
 // ---------------------------------------------------------
    rule generateTrace(I:Instr, OFFSET, VS:ValStack, LOCALS:Map)
      => JSON2String({
          "pos"    : #if OFFSET ==K .Int #then null #else {OFFSET}:>Int #fi ,
          "instr"  : Instr2JSON(I) ,
          "stack"  : ValStack2JSON(VS) ,
          "locals" : Locals2JSON(LOCALS)
      })

endmodule
```
