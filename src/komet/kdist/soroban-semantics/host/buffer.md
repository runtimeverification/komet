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
    rule [hostCallAux-bytes-new-from-linear-memory]:
        <instrs> hostCallAux ( "b" , "3" )
              => #memLoad(LM_POS, LEN)
              ~> bytesNewFromLinearMemory
                 ...
        </instrs>
        <hostStack> U32(LM_POS) : U32(LEN) : S => S </hostStack>

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
    rule [hostCallAux-bytes-len]:
        <instrs> hostCallAux ( "b" , "8" )
              => toSmall(U32(lengthBytes(BS)))
                 ...
        </instrs>
        <hostStack> ScBytes(BS) : S => S </hostStack>

```

## bytes_push

Add an element to the back of the `Bytes` object

```k
    rule [hostCallAux-bytes-push]:
        <instrs> hostCallAux ( "b" , "9" )
              => allocObject(ScBytes( BYTES +Bytes Int2Bytes(1, V, LE) ))
              ~> returnHostVal
                 ...
        </instrs>
        <hostStack> ScBytes(BYTES) : U32(V) : S => S </hostStack>
      requires 0 <=Int V
       andBool V <Int 256
```

## bytes_pop

Removes the last byte of a `Bytes` object and returns the new object.

```k
    rule [hostCallAux-bytes-pop]:
        <instrs> hostCallAux ( "b" , "a" )
              => allocObject(ScBytes( substrBytes(BYTES, 0, lengthBytes(BYTES) -Int 1) ))
              ~> returnHostVal
                 ...
        </instrs>
        <hostStack> ScBytes(BYTES) : S => S </hostStack>
      requires 0 <Int lengthBytes(BYTES)
```

## bytes_front

Returns the first byte of a `Bytes` object.

```k
    rule [hostCallAux-bytes-front]:
        <instrs> hostCallAux ( "b" , "b" )
              => toSmall(U32( BYTES[0] ))
                 ...
        </instrs>
        <hostStack> ScBytes(BYTES) : S => S </hostStack>
      requires 0 <Int lengthBytes(BYTES)
```

## bytes_back

Returns the last byte of a `Bytes` object.

```k
    rule [hostCallAux-bytes-last]:
        <instrs> hostCallAux ( "b" , "c" )
              => toSmall(U32( BYTES[lengthBytes(BYTES) -Int 1] ))
                 ...
        </instrs>
        <hostStack> ScBytes(BYTES) : S => S </hostStack>
      requires 0 <Int lengthBytes(BYTES)
```

## bytes_insert

Inserts a byte at given index. Shifts rest of the bytes to the right.

```k
    rule [hostCallAux-bytes-insert]:
        <instrs> hostCallAux ( "b" , "d" )
              => allocObject(
                  ScBytes( substrBytes(BYTES, 0, I)
                    +Bytes Int2Bytes(1, V, LE)
                    +Bytes substrBytes(BYTES, I, lengthBytes(BYTES))
                  )
                )
              ~> returnHostVal
                 ...
        </instrs>
        <hostStack> ScBytes(BYTES) : U32(I) : U32(V) : S => S </hostStack>
      requires 0 <=Int I
       andBool I <=Int lengthBytes(BYTES)
       andBool 0 <=Int V
       andBool V <Int 256
```

## bytes_append

Concatenate two `Bytes` objects. Ensures that the total length fits in `u32`.

```k
    rule [hostCallAux-bytes-append]:
        <instrs> hostCallAux ( "b" , "e" )
              => allocObject(
                  ScBytes( BYTES1 +Bytes BYTES2 )
                )
              ~> returnHostVal
                 ...
        </instrs>
        <hostStack> ScBytes(BYTES1) : ScBytes(BYTES2) : S => S </hostStack>
      requires lengthBytes(BYTES1) +Int lengthBytes(BYTES2) <Int #pow(i32) // total length should be less than max u32
```

## bytes_slice

Returns a slice of the `Bytes` object from the given start index (inclusive) to the end index (exclusive).

```k
    rule [hostCallAux-bytes-slice]:
        <instrs> hostCallAux ( "b" , "f" )
              => allocObject( ScBytes( substrBytes(BYTES, START, END) ) )
              ~> returnHostVal
                 ...
        </instrs>
        <hostStack> ScBytes(BYTES) : U32(START) : U32(END) : S => S </hostStack>
      requires 0     <=Int START
       andBool START <=Int END
       andBool END   <=Int lengthBytes(BYTES)
```

## string_new_from_linear_memory

```k
    rule [hostfun-string-new-from-linear-memory]:
        <instrs> hostCall ( "b" , "i" , [ i64  i64  .ValTypes ] -> [ i64  .ValTypes ] )
              => #memLoad(getMajor(HostVal(LM_POS)), getMajor(HostVal(LEN)))
              ~> hostCallAux( "b" , "i" )
                 ...
        </instrs>
        <locals>
          0 |-> < i64 > LM_POS      // U32
          1 |-> < i64 > LEN         // U32
        </locals>
      requires fromSmallValid(HostVal(LM_POS))
       andBool fromSmallValid(HostVal(LEN))

    rule [hostCallAux-string-new-from-linear-memory]:
        <instrs> hostCallAux( "b" , "i" )
              => allocObject(ScString(Bytes2String(BS)))
              ~> returnHostVal
                 ...
        </instrs>
        <hostStack> BS:Bytes : S => S </hostStack>
```

```k
endmodule
```