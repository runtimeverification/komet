# Symbol

```k
requires "../configuration.md"
requires "../switch.md"
requires "../wasm-ops.md"
requires "integer.md"

module HOST-SYMBOL
    imports CONFIG-OPERATIONS
    imports WASM-OPERATIONS
    imports HOST-INTEGER
    imports SWITCH-SYNTAX

    // symbol_new_from_linear_memory
    rule [hostfun-symbol-new-from-linear-memory]:
        <instrs> hostCall ( "b" , "j" , [ i64  i64  .ValTypes ] -> [ i64  .ValTypes ] )
              => #memLoad(getMajor(HostVal(LM_POS)), getMajor(HostVal(LEN)))
              ~> symbolNewFromLinearMemory
                 ...
        </instrs>
        <locals>
          0 |-> < i64 > LM_POS      // U32
          1 |-> < i64 > LEN         // U32
        </locals>
      requires fromSmallValid(HostVal(LM_POS))
       andBool fromSmallValid(HostVal(LEN))


    syntax InternalInstr ::= "symbolNewFromLinearMemory"      [symbol(symbolNewFromLinearMemory)]
 // ---------------------------------------------------------------------------------
    rule [symbolNewFromLinearMemory]:
        <instrs> symbolNewFromLinearMemory
              => allocObject(Symbol(Bytes2String(BS)))
              ~> returnHostVal
                 ...
        </instrs>
        <hostStack> BS:Bytes : S => S </hostStack>
      requires validSymbol(Bytes2String(BS))

    syntax InternalInstr ::= "mkSymbolFromStack"   [symbol(mkSymbolFromStack)]
 // ---------------------------------------------------------------------------------
    rule [mkSymbolFromStack]:
        <instrs> mkSymbolFromStack => .K ... </instrs>
        <hostStack> (BS => Symbol(Bytes2String(BS))) : _ </hostStack>
```

## Helpers


```k

    syntax List ::= Bytes2U32List(Bytes)    [function, total, symbol(Bytes2U32List)]
 // --------------------------------------------------------------------------------
    rule Bytes2U32List(BS) => ListItem(Bytes2Int(substrBytes(BS, 0, 4), LE, Unsigned))
                              Bytes2U32List(substrBytes(BS, 4, lengthBytes(BS)))
      requires lengthBytes(BS) >=Int 4
    rule Bytes2U32List(BS) => .List
      requires lengthBytes(BS) <Int 4

```

- `loadSlices`: Load symbols stored as byte slices in Wasm memory.

```k
    syntax InternalInstr ::= "loadSlices"                     [symbol(loadSlices)]
                           | loadSlicesAux(List)              [symbol(loadSlicesAux)]
 // ---------------------------------------------------------------------------------
    rule [loadSlices]:
        <instrs> loadSlices
              => loadSlicesAux(Bytes2U32List(KEY_SLICES))
              ~> collectStackObjects(lengthBytes(KEY_SLICES) /Int 8)
                 ...
        </instrs>
        <hostStack> KEY_SLICES : S => S </hostStack>

    rule [loadSlicesAux-empty]:
        <instrs> loadSlicesAux(.List) => .K ... </instrs>

    rule [loadSlicesAux]:
        <instrs> loadSlicesAux(REST ListItem(OFFSET) ListItem(LEN))
              => #memLoad(OFFSET, LEN)
              ~> mkSymbolFromStack
              ~> loadSlicesAux(REST)
                 ...
        </instrs>

endmodule
```