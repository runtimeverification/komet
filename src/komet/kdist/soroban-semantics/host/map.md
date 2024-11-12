# Map

```k
requires "../configuration.md"
requires "../switch.md"
requires "../wasm-ops.md"
requires "integer.md"
requires "symbol.md"
requires "vector.md"

module HOST-MAP
    imports CONFIG-OPERATIONS
    imports WASM-OPERATIONS
    imports HOST-INTEGER
    imports HOST-SYMBOL
    imports HOST-VECTOR
    imports SWITCH-SYNTAX
```

## map_new

```k
    rule [hostfun-map-new]:
        <instrs> hostCall ( "m" , "_" , [ .ValTypes ] -> [ i64  .ValTypes ] )
              => allocObject(ScMap(.Map))
              ~> returnHostVal
                 ...
        </instrs>
        <locals> .Map </locals>
```

## map_put

```k
    rule [hostfun-map-put]:
        <instrs> hostCall ( "m" , "0" , [ i64  i64  i64  .ValTypes ] -> [ i64  .ValTypes ] )
              => pushStack(HostVal(VAL))
              ~> loadObjectFull(HostVal(KEY))
              ~> loadObject(HostVal(M))
              ~> hostCallAux("m", "0")
                 ...
        </instrs>
        <locals>
          0 |-> < i64 > M
          1 |-> < i64 > KEY
          2 |-> < i64 > VAL
        </locals>

    rule [hostCallAux-map-put]:
        <instrs> hostCallAux("m", "0")
              => allocObject(ScMap( M [ KEY <- VAL ] ))
              ~> returnHostVal
                 ...
        </instrs>
        <hostStack> ScMap(M) : KEY:ScVal : VAL:HostVal : S => S </hostStack>

```

## map_get

```k
    rule [hostfun-map-get]:
        <instrs> hostCall ( "m" , "1" , [ i64  i64  .ValTypes ] -> [ i64  .ValTypes ] )
              => loadObjectFull(HostVal(KEY))
              ~> loadObject(HostVal(M))
              ~> hostCallAux("m", "1")
                 ...
        </instrs>
        <locals>
          0 |-> < i64 > M
          1 |-> < i64 > KEY
        </locals>

    rule [hostCallAux-map-get]:
        <instrs> hostCallAux("m", "1")
              => pushStack( M {{ KEY }} orDefault HostVal(-1) )
              ~> returnHostVal
                 ...
        </instrs>
        <hostStack> ScMap(M) : KEY:ScVal : S => S </hostStack>
      requires KEY in_keys(M)

    rule [hostCallAux-map-get-not-found]:
        <instrs> hostCallAux("m", "1") => trap ... </instrs>
        <hostStack> ScMap(M) : KEY:ScVal : S => S </hostStack>
      requires notBool( KEY in_keys(M) )

```

## map_del

```k
    rule [hostfun-map-del]:
        <instrs> hostCall ( "m" , "2" , [ i64  i64  .ValTypes ] -> [ i64  .ValTypes ] )
              => loadObjectFull(HostVal(KEY))
              ~> loadObject(HostVal(M))
              ~> hostCallAux("m", "2")
                 ...
        </instrs>
        <locals>
          0 |-> < i64 > M
          1 |-> < i64 > KEY
        </locals>

    rule [hostCallAux-map-del]:
        <instrs> hostCallAux("m", "2")
              => allocObject(ScMap( M [ KEY <- undef ] ))
              ~> returnHostVal
                 ...
        </instrs>
        <hostStack> ScMap(M) : KEY:ScVal : S => S </hostStack>
      requires KEY in_keys(M)

    rule [hostCallAux-map-del-not-found]:
        <instrs> hostCallAux("m", "2") => trap ... </instrs>
        <hostStack> ScMap(M) : KEY:ScVal : S => S </hostStack>
      requires notBool( KEY in_keys(M) )

```

## map_len

```k
    rule [hostCallAux-map-len]:
        <instrs> hostCallAux("m", "3") => toSmall(U32(size(M))) ... </instrs>
        <hostStack> ScMap(M) : S => S </hostStack>
```

## map_has

```k
    rule [hostfun-map-has]:
        <instrs> hostCall ( "m" , "4" , [ i64  i64  .ValTypes ] -> [ i64  .ValTypes ] )
              => loadObjectFull(HostVal(KEY))
              ~> loadObject(HostVal(M))
              ~> hostCallAux("m", "4")
                 ...
        </instrs>
        <locals>
          0 |-> < i64 > M
          1 |-> < i64 > KEY
        </locals>

    rule [hostCallAux-map-has]:
        <instrs> hostCallAux("m", "4") => toSmall(SCBool( KEY in_keys(M) )) ... </instrs>
        <hostStack> ScMap(M) : KEY:ScVal : S => S </hostStack>

```

## map_unpack_to_linear_memory

Writes values from a map (`ScMap`) to a specified memory address.
Given a map (`MAPOBJ`) and an array of byte slices (`KEYS_POS`) for keys, it retrieves corresponding values from the map
and writes them sequentially to the address (`VALS_POS`).

```k
    rule [hostfun-map-unpack-to-linear-memory]:
        <instrs> hostCall ( "m" , "a" , [ i64  i64  i64  i64  .ValTypes ] -> [ i64  .ValTypes ] )
              => loadObject(HostVal(VALS_POS))
              ~> loadObject(HostVal(MAPOBJ))
              ~> #memLoad(getMajor(HostVal(KEYS_POS)), 8 *Int getMajor(HostVal(LEN)))
              ~> loadSlices
              ~> mapUnpackToLinearMemory
              ~> toSmall(Void)
                 ...
        </instrs>
        <locals>
          0 |-> < i64 > MAPOBJ           // ScMap
          1 |-> < i64 > KEYS_POS         // U32
          2 |-> < i64 > VALS_POS         // U32
          3 |-> < i64 > LEN              // U32
        </locals>
      requires fromSmallValid(HostVal(KEYS_POS))
       andBool fromSmallValid(HostVal(LEN))

    syntax InternalInstr ::= "mapUnpackToLinearMemory"     [symbol(mapUnpackToLinearMemory)]
 // -----------------------------------------------------------------------------------------
    rule [mapUnpackToLinearMemory]:
        <instrs> mapUnpackToLinearMemory
              => #memStore(
                    VALS_POS,
                    Vals2Bytes(
                      lookupMany(OBJS, KEYS, 0)
                    )
                  )
                  ...
        </instrs>
        <hostStack> KEYS : ScMap(OBJS) : U32(VALS_POS) : S => S </hostStack>

```

## map_new_from_linear_memory

Creates a map (`ScMap`) from specified keys and values.
Given an array of byte slices (`KEYS_POS`) for keys and an array of values (`VALS_POS`),
it constructs a map where keys are `Symbol`s created from the byte slices.
The function returns a `HostVal` pointing to the new map object.

```k
    rule [hostfun-map-new-from-linear-memory]:
        <instrs> hostCall ( "m" , "9" , [ i64  i64  i64  .ValTypes ] -> [ i64  .ValTypes ] )
              => #memLoad(getMajor(HostVal(VALS_POS)), 8 *Int getMajor(HostVal(LEN)))
              ~> #memLoad(getMajor(HostVal(KEYS_POS)), 8 *Int getMajor(HostVal(LEN)))
              ~> loadSlices
              ~> mapNewFromLinearMemory
                 ...
        </instrs>
        <locals>
          0 |-> < i64 > KEYS_POS         // U32
          1 |-> < i64 > VALS_POS         // U32
          2 |-> < i64 > LEN              // U32
        </locals>
      requires fromSmallValid(HostVal(KEYS_POS))
       andBool fromSmallValid(HostVal(LEN))

    syntax InternalInstr ::= "mapNewFromLinearMemory"    [symbol(mapNewFromLinearMemory)]
 // ----------------------------------------------------------------------------------------
    rule [mapNewFromLinearMemory]:
        <instrs> mapNewFromLinearMemory
              => allocObject(
                    ScMap(
                      mapFromLists(
                        KEYS,
                        rel2absMany(RELS, Bytes2Vals(VALS_BS))
                      )
                    )
                  )
              ~> returnHostVal
                 ...
        </instrs>
        <hostStack> KEYS : VALS_BS : S => S </hostStack>
        <relativeObjects> RELS </relativeObjects>
      requires size(KEYS) ==Int lengthBytes(VALS_BS) /Int 8

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