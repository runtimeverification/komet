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
```

## symbol_new_from_linear_memory

```k
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

  // TODO add validity check
    syntax InternalInstr ::= "mkSymbolFromStack"   [symbol(mkSymbolFromStack)]
 // ---------------------------------------------------------------------------------
    rule [mkSymbolFromStack]:
        <instrs> mkSymbolFromStack => .K ... </instrs>
        <hostStack> (BS => Symbol(Bytes2String(BS))) : _ </hostStack>
```

## symbol_len

```k
    rule [hostCallAux-symbol-len]:
        <instrs> hostCallAux ( "b" , "l" )
              => toSmall(U32(lengthString(SYM)))
                 ...
        </instrs>
        <hostStack> Symbol(SYM) : S => S </hostStack>
```

## symbol_index_in_linear_memory

Linear search a `Symbol` in an array of byte slices. Return the index of the element or trap if not found.

```k
    rule [hostfun-symbol-index-in-linear-memory]:
        <instrs> hostCall ( "b" , "m" , [ i64  i64  i64  .ValTypes ] -> [ i64  .ValTypes ] )
              => loadObject(HostVal(SYMBOL))
              ~> #memLoad(getMajor(HostVal(POS)), 8 *Int getMajor(HostVal(LEN)))
              ~> loadSlices
              ~> symbolIndexInLinearMemory
                 ...
        </instrs>
        <locals>
          0 |-> < i64 > SYMBOL    // Symbol
          1 |-> < i64 > POS       // U32VAL
          2 |-> < i64 > LEN       // U32VAL
        </locals>
      requires fromSmallValid(HostVal(POS))
       andBool fromSmallValid(HostVal(LEN))

    syntax InternalInstr ::= "symbolIndexInLinearMemory"            [symbol(symbolIndexInLinearMemory)]
                           | symbolIndexInLinearMemoryAux(Int)      [symbol(symbolIndexInLinearMemoryAux)]
 // ------------------------------------------------------------------------------------------------------
    rule [symbolIndexInLinearMemory]:
        <instrs> symbolIndexInLinearMemory
              => symbolIndexInLinearMemoryAux(indexOf(HAYSTACK, NEEDLE))
                 ...
        </instrs>
        <hostStack> NEEDLE:List : (Symbol(_) #as HAYSTACK) : S => S </hostStack>

    rule [symbolIndexInLinearMemoryAux-trap]:
        <instrs> symbolIndexInLinearMemoryAux(-1) => trap ... </instrs>

    rule [symbolIndexInLinearMemoryAux]:
        <instrs> symbolIndexInLinearMemoryAux(N) => toSmall(U32(N)) ... </instrs>
      requires N =/=Int -1

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
```

- `indexOf(X, XS)`: returns the index of the first element in `XS` which is equal to `X`, or `-1` if there is no such element.

```k
    syntax Int ::= indexOf   (KItem, List)          [function, total, symbol(indexOf)]
                 | indexOfAux(KItem, List, Int)     [function, total, symbol(indexOfAux)]
 // --------------------------------------------------------------------------
    rule indexOf(X, XS) => indexOfAux(X, XS, 0)
    rule indexOfAux(_, .List,          _) => -1
    rule indexOfAux(X, ListItem(Y) _,  N) => N                              requires X ==K  Y
    rule indexOfAux(X, ListItem(Y) XS, N) => indexOfAux(X, XS, N +Int 1)    requires X =/=K Y

endmodule
```