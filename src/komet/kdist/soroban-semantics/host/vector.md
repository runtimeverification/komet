
```k
requires "../configuration.md"
requires "../switch.md"
requires "../wasm-ops.md"
requires "integer.md"

module HOST-VECTOR
    imports CONFIG-OPERATIONS
    imports WASM-OPERATIONS
    imports HOST-INTEGER
    imports SWITCH-SYNTAX
```

## vec_new

```k
    rule [hostfun-vec-new]:
        <instrs> hostCall ( "v" , "_" , [ .ValTypes ] -> [ i64  .ValTypes ] )
              => allocObject(ScVec(.List))
              ~> returnHostVal
                 ...
        </instrs>
        <locals> .Map </locals>
```

## vec_put

Updates the vector item at the given index.

```k
    rule [hostCallAux-vec-put]:
        <instrs> hostCallAux ( "v" , "0" )
              => allocObject(
                    ScVec(
                      VEC [ I <- rel2abs(RELS, HostVal(VAL) ) ]
                    )
                 )
              ~> returnHostVal
                 ...
        </instrs>
        <hostStack> ScVec(VEC) : U32(I) : _:ScVal : S => S </hostStack>
        <locals>
          ... 2 |-> < i64 > VAL ...
        </locals>
        <relativeObjects> RELS </relativeObjects>
      requires 0 <=Int I
       andBool I <Int size(VEC)
```

## vec_get

```k
    rule [hostCallAux-vec-get]:
        <instrs> hostCallAux ( "v" , "1" )
              => VEC {{ I }} orDefault HostVal(0)
                 ...
        </instrs>
        <hostStack> ScVec(VEC) : U32(I) : S => S </hostStack>
      requires 0 <=Int I
       andBool I <Int size(VEC)
```

## vec_len

```k
    rule [hostCallAux-vec-len]:
        <instrs> hostCallAux ( "v" , "3" )
              => toSmall(U32(size(VEC)))
                 ...
        </instrs>
        <hostStack> ScVec(VEC) : S => S </hostStack>
```

## vec_push_back

Creates a new vector by appending a given item to the end of the provided vector.
This function does not modify the original vector, maintaining immutability.
Returns a new vector with the appended item.

```k
    rule [hostfun-vec-push-back]:
        <instrs> hostCall ( "v" , "6" , [ i64  i64  .ValTypes ] -> [ i64  .ValTypes ] )
              => loadObject(HostVal(VEC))
              ~> vecPushBack(HostVal(ITEM))
                 ...
        </instrs>
        <locals>
          0 |-> < i64 > VEC
          1 |-> < i64 > ITEM
        </locals>

    syntax InternalInstr ::= vecPushBack(HostVal)   [symbol(vecPushBack)]
 // ----------------------------------------------------
    rule [vecPushBack]:
        <instrs> vecPushBack(ITEM)
              => allocObject(
                  ScVec(
                    VEC ListItem(rel2abs(RELS, ITEM))
                  )
                 )
              ~> returnHostVal
              ...
        </instrs>
        <hostStack> ScVec(VEC) : S => S </hostStack>
        <relativeObjects> RELS </relativeObjects>
```

## vec_unpack_to_linear_memory

```k
    rule [hostCallAux-vec-unpack-to-linear-memory]:
        <instrs> hostCallAux ( "v" , "h" )
              => #memStore(VALS_POS, Vals2Bytes(VEC))
              ~> toSmall(Void)
                 ...
        </instrs>
        <hostStack> ScVec(VEC) : U32(VALS_POS) : U32(LEN) : S => S </hostStack>
      requires size(VEC) ==Int LEN

    syntax InternalInstr ::= "vecUnpackToLinearMemory"    [symbol(vecUnpackToLinearMemory)]
 // ---------------------------------------------------------------------------------------
    rule [vecUnpackToLinearMemory]:
        <instrs> vecUnpackToLinearMemory => #memStore(VALS_POS, Vals2Bytes(VEC)) ... </instrs>
        <hostStack> ScVec(VEC) : U32(VALS_POS) : U32(LEN) : S => S </hostStack>
      requires size(VEC) ==Int LEN
```

## vec_new_from_linear_memory

```k
    rule [hostCallAux-vec-new-from-linear-memory]:
        <instrs> hostCallAux( "v" , "g" )
              => #memLoad(VALS_POS, LEN *Int 8)
              ~> vecNewFromLinearMemoryAux
                 ...
        </instrs>
        <hostStack> U32(VALS_POS) : U32(LEN) : S => S </hostStack>

    syntax InternalInstr ::= "vecNewFromLinearMemoryAux"   [symbol(vecNewFromLinearMemoryAux)]
 // --------------------------------------------------------------------------------------------------------------------
    rule [vecNewFromLinearMemoryAux]:
        <instrs> vecNewFromLinearMemoryAux
              => allocObject(
                    ScVec(
                      rel2absMany(RELS, Bytes2Vals(BS))
                    )
                  )
              ~> returnHostVal
                 ...
        </instrs>
        <hostStack> BS : S => S </hostStack>
        <relativeObjects> RELS </relativeObjects>
```

## Helper Functions

```k

    syntax Bytes ::= Vals2Bytes(List)    [function, total]
 // -----------------------------------------------------------------------------------------
    rule Vals2Bytes(ListItem(HostVal(V)) REST) => Int2Bytes(8, V, LE) +Bytes Vals2Bytes(REST)
    rule Vals2Bytes(_) => .Bytes
      [owise]

    syntax List ::= Bytes2Vals(Bytes)    [function, total]
 // -----------------------------------------------------------------------------------------
    rule Bytes2Vals(BS) => ListItem(parseHostVal(substrBytes(BS, 0, 8)))
                           Bytes2Vals(substrBytes(BS, 8, lengthBytes(BS))) 
      requires lengthBytes(BS) >=Int 8

    rule Bytes2Vals(_) => .List
      [owise]

    syntax HostVal ::= parseHostVal(Bytes)      [function, total]
 // -------------------------------------------------------------
    rule parseHostVal(BS) => HostVal(Bytes2Int(BS, LE, Unsigned))

endmodule
```