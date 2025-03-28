
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

## vec_del

```k
    rule [hostCallAux-vec-del]:
        <instrs> hostCallAux ( "v" , "2" )
              => allocObject(ScVec(delListItem(VEC, I)))
              ~> returnHostVal
                 ...
        </instrs>
        <hostStack> ScVec(VEC) : U32(I) : S => S </hostStack>
      requires 0 <=Int I
       andBool I <Int size(VEC)

    syntax List ::= delListItem(List, Int)    [function, total]
 // -----------------------------------------------------------
    rule delListItem(ListItem(X) REST, N) => ListItem(X) delListItem(REST, N -Int 1) requires 0 <Int N
    rule delListItem(ListItem(_) REST, N) => REST                                    requires 0 ==Int N
    // invalid arguments
    rule delListItem(LIST, _N)            => LIST                                    [owise]
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

## vec_push_front

```k
    rule [hostCallAux-vec-push-front]:
        <instrs> hostCallAux ( "v" , "4" )
              => allocObject(
                    ScVec(
                      ListItem(rel2abs(RELS, HostVal(VAL))) VEC
                    )
                 )
              ~> returnHostVal
                 ...
        </instrs>
        <hostStack> ScVec(VEC) : _:ScVal : S => S </hostStack>
        <locals>
          ... 1 |-> < i64 > VAL ...
        </locals>
        <relativeObjects> RELS </relativeObjects>
```

## vec_pop_front

```k
    rule [hostCallAux-vec-pop-front]:
        <instrs> hostCallAux ( "v" , "5" )
              => allocObject( ScVec( VEC ) )
              ~> returnHostVal
                 ...
        </instrs>
        <hostStack> ScVec(ListItem(_) VEC) : S => S </hostStack>
```

## vec_push_back

Creates a new vector by appending a given item to the end of the provided vector.
This function does not modify the original vector, maintaining immutability.
Returns a new vector with the appended item.

```k
    rule [hostCallAux-vec-push-back]:
        <instrs> hostCallAux ( "v" , "6" )
              => allocObject(
                    ScVec(
                      VEC ListItem(rel2abs(RELS, HostVal(VAL)))
                    )
                 )
              ~> returnHostVal
                 ...
        </instrs>
        <hostStack> ScVec(VEC) : _:ScVal : S => S </hostStack>
        <locals>
          ... 1 |-> < i64 > VAL ...
        </locals>
        <relativeObjects> RELS </relativeObjects>
```

## vec_pop_back

```k
    rule [hostCallAux-vec-pop-back]:
        <instrs> hostCallAux ( "v" , "7" )
              => allocObject( ScVec( VEC ) )
              ~> returnHostVal
                 ...
        </instrs>
        <hostStack> ScVec(VEC ListItem(_)) : S => S </hostStack>
```

## vec_front

```k
    rule [hostCallAux-vec-front]:
        <instrs> hostCallAux ( "v" , "8" )
              => HV ...
        </instrs>
        <hostStack> ScVec(ListItem(HV:HostVal) _VEC) : S => S </hostStack>
```

## vec_back

```k
    rule [hostCallAux-vec-back]:
        <instrs> hostCallAux ( "v" , "9" )
              => HV ...
        </instrs>
        <hostStack> ScVec(_VEC ListItem(HV:HostVal)) : S => S </hostStack>
```

## vec_insert

```k
    rule [hostCallAux-vec-insert]:
        <instrs> hostCallAux ( "v" , "a" )
              => allocObject(
                    ScVec(
                      insertList(VEC, I, rel2abs(RELS, HostVal(VAL)))
                    )
                 )
              ~> returnHostVal
                 ...
        </instrs>
        <locals>
          ... 2 |-> < i64 > VAL ...
        </locals>
        <hostStack> ScVec(VEC) : U32(I) : _ : S => S </hostStack>
        <relativeObjects> RELS </relativeObjects>
      requires 0 <=Int I
       andBool I <=Int size(VEC)

    syntax List ::= insertList(List, Int, KItem)    [function, total, symbol(insertList)]
 // -----------------------------------------------------------------
    rule insertList(REST,             N, V) => ListItem(V) REST                          requires 0 ==Int N
    rule insertList(ListItem(X) REST, N, V) => ListItem(X) insertList(REST, N -Int 1, V) requires 0 <Int N
    // invalid arguments
    rule insertList(_, _, _) => .List                                                    [owise]
```

## vec_append

```k
    rule [hostCallAux-vec-append]:
        <instrs> hostCallAux ( "v" , "b" )
              => allocObject(ScVec(VEC1 VEC2))
              ~> returnHostVal
                 ...
        </instrs>
        <hostStack> ScVec(VEC1) : ScVec(VEC2) : S => S </hostStack>
      requires size(VEC1) +Int size(VEC2) <Int #pow(i32) // total length should be less than max u32
```

## vec_slice

Returns a slice of the `Vec` object from the given start index (inclusive) to the end index (exclusive).

```k
    rule [hostCallAux-vec-slice]:
        <instrs> hostCallAux ( "v" , "c" )
              => allocObject(ScVec(
                    range(VEC, START, size(VEC) -Int END)
                 ))
              ~> returnHostVal
                 ...
        </instrs>
        <hostStack> ScVec(VEC) : U32(START) : U32(END) : S => S </hostStack>
      requires 0     <=Int START
       andBool START <=Int END
       andBool END   <=Int size(VEC)
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