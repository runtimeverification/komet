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
              => #let TRACE_LINE = generateTrace(I, POS, STACK, LOCALS) #in
                 #appendFile(PATH, TRACE_LINE +String "\n")
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
