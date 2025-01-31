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

## bytes_copy_to_linear_memory

```k
    rule [hostCallAux-bytes-copy-to-linear-memory]:
        <instrs> hostCallAux ( "b" , "1" )
              => #memStore(LM_POS, substrBytes(BYTES, B_POS, B_POS +Int LEN))
              ~> toSmall(Void)
                  ...
        </instrs>
        <hostStack> ScBytes(BYTES) : U32(B_POS) : U32(LM_POS) : U32(LEN) : S => S </hostStack>
      requires 0 <=Int B_POS
       andBool B_POS <=Int lengthBytes(BYTES)
       andBool 0 <=Int LEN
       andBool B_POS +Int LEN <=Int lengthBytes(BYTES)
```

## bytes_copy_from_linear_memory

Reads a slice from linear memory and writes into a `Bytes` object, returning a new object.
The `Bytes` object expands if needed, and any gap between the starting position and its current size is filled with zeros.

```k
    rule [hostCallAux-bytes-copy-from-linear-memory]:
        <instrs> hostCallAux ( "b" , "2" )
              => #memLoad(LM_POS, LEN)
              ~> bytesCopyFromLinearMemory
                  ...
        </instrs>
        <hostStack> ScBytes(_) : U32(B_POS) : U32(LM_POS) : U32(LEN) : _ </hostStack>
      requires 0 <=Int B_POS
       andBool 0 <=Int LEN

    syntax InternalInstr ::= "bytesCopyFromLinearMemory"  [symbol(bytesCopyFromLinearMemory)]
 // ------------------------------------------------------------------------------------------
    rule [bytesCopyFromLinearMemory]:
        <instrs> bytesCopyFromLinearMemory
              => allocObject(
                    ScBytes(
                      replaceAtBytes(
                        padRightBytes(BYTES, B_POS +Int LEN, 0),
                        B_POS,
                        BS
                      )
                    )
                  )
              ~> returnHostVal
                  ...
        </instrs>
        <hostStack> BS:Bytes : ScBytes(BYTES) : U32(B_POS) : U32(_) : U32(LEN) : S => S </hostStack>

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

## bytes_new

Creates an empty `Bytes` object.

```k
    rule [hostfun-bytes-new]:
        <instrs> hostCall ( "b" , "4" , [ .ValTypes ] -> [ i64  .ValTypes ] )
              => allocObject(ScBytes(.Bytes))
              ~> returnHostVal
                 ...
        </instrs>
        <locals> .Map </locals>
```

## bytes_put

Updates the byte at given index.

```k
    rule [hostCallAux-bytes-put]:
        <instrs> hostCallAux ( "b" , "5" )
              => allocObject(ScBytes( BYTES [ I <- V ] ))
              ~> returnHostVal
                 ...
        </instrs>
        <hostStack> ScBytes(BYTES) : U32(I) : U32(V) : S => S </hostStack>
      requires 0 <=Int I
       andBool I <Int lengthBytes(BYTES)
       andBool 0 <=Int V
       andBool V <Int 256
```

## bytes_get

Gets the byte at given index.

```k
    rule [hostCallAux-bytes-get]:
        <instrs> hostCallAux ( "b" , "6" )
              => toSmall( U32( BYTES [I] ) )
                 ...
        </instrs>
        <hostStack> ScBytes(BYTES) : U32(I) : S => S </hostStack>
      requires 0 <=Int I
       andBool I <Int lengthBytes(BYTES)
```

## bytes_del

Updates the byte at given index.

```k
    rule [hostCallAux-bytes-del]:
        <instrs> hostCallAux ( "b" , "7" )
              => allocObject(
                  ScBytes( substrBytes(BYTES, 0, I) 
                    +Bytes substrBytes(BYTES, I +Int 1, lengthBytes(BYTES))
                  )
                )
              ~> returnHostVal
                 ...
        </instrs>
        <hostStack> ScBytes(BYTES) : U32(I) : S => S </hostStack>
      requires 0 <=Int I
       andBool I <Int lengthBytes(BYTES)
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