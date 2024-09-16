
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

## vec_unpack_to_linear_memory

```k
    rule [hostfun-vec-unpack-to-linear-memory]:
        <instrs> hostCall ( "v" , "h" , [ i64  i64  i64  .ValTypes ] -> [ i64  .ValTypes ] )
              => loadObject(HostVal(LEN))
              ~> loadObject(HostVal(VALS_POS))
              ~> loadObject(HostVal(VEC))
              ~> vecUnpackToLinearMemory
              ~> toSmall(Void)
                 ...
        </instrs>
        <locals>
          0 |-> < i64 > VEC         // Vec
          1 |-> < i64 > VALS_POS    // U32
          2 |-> < i64 > LEN         // U32
        </locals>

    syntax InternalInstr ::= "vecUnpackToLinearMemory"    [symbol(vecUnpackToLinearMemory)]
 // ---------------------------------------------------------------------------------------
    rule [vecUnpackToLinearMemory]:
        <instrs> vecUnpackToLinearMemory => #memStore(VALS_POS, Vals2Bytes(VEC)) ... </instrs>
        <hostStack> ScVec(VEC) : U32(VALS_POS) : U32(LEN) : S => S </hostStack>
      requires size(VEC) ==Int LEN

    // vec_new_from_linear_memory
    rule [hostfun-vec-new-from-linear-memory]:
        <instrs> hostCall ( "v" , "g" , [ i64  i64  .ValTypes ] -> [ i64  .ValTypes ] )
              => loadObject(HostVal(LEN))
              ~> loadObject(HostVal(VALS_POS))
              ~> vecNewFromLinearMemory
              ~> returnHostVal
                 ...
        </instrs>
        <locals>
          0 |-> < i64 > VALS_POS    // U32
          1 |-> < i64 > LEN         // U32
        </locals>

    syntax InternalInstr ::= "vecNewFromLinearMemory"      [symbol(vecNewFromLinearMemory)]
                           | "vecNewFromLinearMemoryAux"   [symbol(vecNewFromLinearMemoryAux)]
    
 // --------------------------------------------------------------------------------------------------------------------
    rule [vecNewFromLinearMemory]:
        <instrs> vecNewFromLinearMemory
              => #memLoad(VALS_POS, LEN *Int 8)
              ~> vecNewFromLinearMemoryAux
                 ...
        </instrs>
        <hostStack> U32(VALS_POS) : U32(LEN) : S => S </hostStack>

    rule [vecNewFromLinearMemoryAux]:
        <instrs> vecNewFromLinearMemoryAux
              => allocObject(
                    ScVec(
                      rel2absMany(RELS, Bytes2Vals(BS))
                    )
                  ) ...
        </instrs>
        <hostStack> BS : S => S </hostStack>
        <relativeObjects> RELS </relativeObjects>


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