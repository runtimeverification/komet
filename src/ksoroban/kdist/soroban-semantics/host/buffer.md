# Buffer

```k
requires "../configuration.md"
requires "../switch.md"
requires "../wasm-ops.md"
requires "integer.md"

module HOST-BUFFER
    imports CONFIG-OPERATIONS
    imports WASM-OPERATIONS
    imports HOST-INTEGER
    imports SWITCH-SYNTAX

```

## bytes_new_from_linear_memory

```k
    rule [hostfun-bytes-new-from-linear-memory]:
        <instrs> hostCall ( "b" , "3" , [ i64  i64  .ValTypes ] -> [ i64  .ValTypes ] )
              => #memLoad(getMajor(HostVal(LM_POS)), getMajor(HostVal(LEN)))
              ~> bytesNewFromLinearMemory
                 ...
        </instrs>
        <locals>
          0 |-> < i64 > LM_POS      // U32
          1 |-> < i64 > LEN         // U32
        </locals>
      requires fromSmallValid(HostVal(LM_POS))
       andBool fromSmallValid(HostVal(LEN))

    syntax InternalInstr ::= "bytesNewFromLinearMemory"      [symbol(bytesNewFromLinearMemory)]
 // ---------------------------------------------------------------------------------
    rule [bytesNewFromLinearMemory]:
        <instrs> bytesNewFromLinearMemory
              => allocObject(ScBytes(BS))
              ~> returnHostVal
                 ...
        </instrs>
        <hostStack> BS:Bytes : S => S </hostStack>

```

## bytes_len

```k

    rule [hostfun-bytes-len]:
        <instrs> hostCall ( "b" , "8" , [ i64  .ValTypes ] -> [ i64  .ValTypes ] )
              => loadObject(HostVal(BYTES))
              ~> bytesLen
                 ...
        </instrs>
        <locals>
          0 |-> < i64 > BYTES      // Bytes HostVal
        </locals>

    syntax InternalInstr ::= "bytesLen"      [symbol(bytesLen)]
 // ---------------------------------------------------------------------------------
    rule [bytesLen]:
        <instrs> bytesLen
              => toSmall(U32(lengthBytes(BS)))
                 ...
        </instrs>
        <hostStack> ScBytes(BS) : S => S </hostStack>

endmodule
```