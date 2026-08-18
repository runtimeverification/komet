
```k
requires "../configuration.md"

module HOST-INTEGER
    imports CONFIG-OPERATIONS
    imports WASM-OPERATIONS

    syntax InternalInstr ::= "returnU64"       [symbol(returnU64)]
                           | "returnI64"       [symbol(returnI64)]
                           | "returnHostVal"   [symbol(returnHostVal)]
 // ------------------------------------------------------------
    rule [returnU64]:
        <instrs> returnU64 => i64.const I ... </instrs>
        <hostStack> U64(I) : S => S </hostStack>

    rule [returnI64]:
        <instrs> returnI64 => i64.const #unsigned(i64, I) ... </instrs>
        <hostStack> I64(I) : S => S </hostStack>
      requires definedUnsigned(i64, I)
      [preserves-definedness] // definedness of '#unsigned(,)' is checked

    rule [returnHostVal]:
        <instrs> returnHostVal => i64.const I ... </instrs>
        <hostStack> HostVal(I) : S => S </hostStack>

    rule [hostfun-obj-to-u64]:
        <instrs> hostCall ( "i" , "0" , [ i64  .ValTypes ] -> [ i64  .ValTypes ] )
              => loadObject(HostVal(VAL))
              ~> returnU64
                 ...
        </instrs>
        <locals>
          0 |-> < i64 > VAL
        </locals>

    rule [hostfun-obj-from-u64]:
        <instrs> hostCall ( "i" , "_" , [ i64  .ValTypes ] -> [ i64  .ValTypes ] )
              => allocObject(U64(I))
              ~> returnHostVal
                 ...
        </instrs>
        <locals>
          0 |-> < i64 > I
        </locals>

    rule [hostfun-obj-from-i64]:
        <instrs> hostCall ( "i" , "1" , [ i64  .ValTypes ] -> [ i64  .ValTypes ] )
              => allocObject(I64(#signed(i64, VAL)))
              ~> returnHostVal
                 ...
        </instrs>
        <locals>
          0 |-> < i64 > VAL
        </locals>
      requires definedSigned(i64, VAL)

    rule [hostfun-obj-to-i64]:
        <instrs> hostCall ( "i" , "2" , [ i64  .ValTypes ] -> [ i64  .ValTypes ] )
              => loadObject(HostVal(VAL))
              ~> returnI64
                 ...
        </instrs>
        <locals>
          0 |-> < i64 > VAL
        </locals>

    rule [hostfun-obj-from-u128-pieces]:
        <instrs> hostCall ( "i" , "3" , [ i64  i64  .ValTypes ] -> [ i64  .ValTypes ] )
              => #waitCommands
              ~> returnHostVal
                 ...
        </instrs>
        <locals>
          0 |-> < i64 > HIGH
          1 |-> < i64 > LOW
        </locals>
        <k> (.K => allocObject( U128((HIGH <<Int 64) |Int LOW)) ) ... </k>

    rule [hostCallAux-obj-to-u128-lo64]:
        <instrs> hostCallAux ( "i" , "4" ) => i64.const I ... </instrs> // 'i64.const N' chops N to 64 bits
        <hostStack> U128(I) : S => S </hostStack>

    rule [hostCallAux-obj-to-u128-hi64]:
        <instrs> hostCallAux ( "i" , "5" ) => i64.const (I >>Int 64) ... </instrs>
        <hostStack> U128(I) : S => S </hostStack>
      [preserves-definedness] // 'X >>Int K' is defined for positive K

    rule [hostfun-obj-from-i128-pieces]:
        <instrs> hostCall ( "i" , "6" , [ i64  i64 .ValTypes ] -> [ i64  .ValTypes ] )
              => allocObject(I128(#signed(i128, (HIGH <<Int 64) |Int LOW )))
              ~> returnHostVal
                 ...
        </instrs>
        <locals>
          0 |-> < i64 > HIGH
          1 |-> < i64 > LOW
        </locals>
      requires definedSigned(i128, (HIGH <<Int 64) |Int LOW )

    rule [hostCallAux-obj-to-i128-lo64]:
        <instrs> hostCallAux ( "i" , "7" ) => i64.const (#unsigned(i128, I)) ... </instrs>
        <hostStack> I128(I) : S => S </hostStack>
      requires definedUnsigned(i128, I)
      [preserves-definedness]

    rule [hostCallAux-obj-to-i128-hi64]:
        <instrs> hostCallAux ( "i" , "8" ) => i64.const (I >>Int 64) ... </instrs>
        <hostStack> I128(I) : S => S </hostStack>
```

## obj_from_u256_pieces

```k
    rule [hostfun-obj-from-u256-pieces]:
        <instrs> hostCall ( "i" , "9" , [ i64 i64 i64  i64  .ValTypes ] -> [ i64  .ValTypes ] )
              => allocObject( U256(
                       (HI_HI <<Int 192) 
                  |Int (HI_LO <<Int 128) 
                  |Int (LO_HI <<Int 64) 
                  |Int  LO_LO
                ))
              ~> returnHostVal
                 ...
        </instrs>
        <locals>
          0 |-> < i64 > HI_HI
          1 |-> < i64 > HI_LO
          2 |-> < i64 > LO_HI
          3 |-> < i64 > LO_LO
        </locals>
```

## u256_val_from_be_bytes

Convert a 32-byte `Bytes` object to `U256`.

```k
    rule [hostCallAux-u256-val-from-be-bytes]:
        <instrs> hostCallAux ( "i" , "a" )
              => allocObject( U256( Bytes2Int(BS, BE, Unsigned) ) )
              ~> returnHostVal
                 ...
        </instrs>
        <hostStack> ScBytes(BS) : S => S </hostStack>
      requires lengthBytes(BS) ==Int 32
```

## u256_val_to_be_bytes

```k
    rule [hostCallAux-u256-val-to-be-bytes]:
        <instrs> hostCallAux ( "i" , "b" )
              => allocObject( ScBytes( Int2Bytes(32, I, BE) ) )
              ~> returnHostVal
                 ...
        </instrs>
        <hostStack> U256(I) : S => S </hostStack>
```

## obj_to_u256_hi_hi

```k
    rule [hostCallAux-obj-to-u256-hi-hi]:
        <instrs> hostCallAux ( "i" , "c" ) => i64.const (I >>Int 192) ... </instrs>
        <hostStack> U256(I) : S => S </hostStack>
```

## obj_to_u256_hi_lo

```k
    rule [hostCallAux-obj-to-u256-hi-lo]:
        <instrs> hostCallAux ( "i" , "d" ) => i64.const (I >>Int 128) ... </instrs>
        <hostStack> U256(I) : S => S </hostStack>
```

## obj_to_u256_lo_hi

```k
    rule [hostCallAux-obj-to-u256-lo-hi]:
        <instrs> hostCallAux ( "i" , "e" ) => i64.const (I >>Int 64) ... </instrs>
        <hostStack> U256(I) : S => S </hostStack>
```

## obj_to_u256_lo_lo

```k
    rule [hostCallAux-obj-to-u256-lo-lo]:
        <instrs> hostCallAux ( "i" , "f" ) => i64.const I ... </instrs>
        <hostStack> U256(I) : S => S </hostStack>
```

## u256_add

```k
    rule [hostCallAux-u256-add]:
        <instrs> hostCallAux ( "i" , "n" )
              => allocObject( U256( A +Int B ) )
              ~> returnHostVal
                 ...
        </instrs>
        <hostStack> U256(A) : U256(B) : S => S </hostStack>
      requires inRangeInt(i256, Unsigned, A +Int B)
```

## u256_sub

```k
    rule [hostCallAux-u256-sub]:
        <instrs> hostCallAux ( "i" , "o" )
              => allocObject( U256( A -Int B ) )
              ~> returnHostVal
                 ...
        </instrs>
        <hostStack> U256(A) : U256(B) : S => S </hostStack>
      requires inRangeInt(i256, Unsigned, A -Int B)
```

## u256_mul

```k
    rule [hostCallAux-u256-mul]:
        <instrs> hostCallAux ( "i" , "p" )
              => allocObject( U256( A *Int B ) )
              ~> returnHostVal
                 ...
        </instrs>
        <hostStack> U256(A) : U256(B) : S => S </hostStack>
      requires inRangeInt(i256, Unsigned, A *Int B)
```

## u256_div

```k
    rule [hostCallAux-u256-div]:
        <instrs> hostCallAux ( "i" , "q" )
              => allocObject( U256( A /Int B ) )
              ~> returnHostVal
                 ...
        </instrs>
        <hostStack> U256(A) : U256(B) : S => S </hostStack>
      requires 0 =/=Int B
```

## obj_from_i256_pieces

The four words are the two's-complement representation of the value, most
significant first, so they are reassembled as an unsigned 256-bit number and
then reinterpreted as signed.

```k
    rule [hostfun-obj-from-i256-pieces]:
        <instrs> hostCall ( "i" , "g" , [ i64 i64 i64  i64  .ValTypes ] -> [ i64  .ValTypes ] )
              => allocObject( I256( #signed(i256,
                       (HI_HI <<Int 192)
                  |Int (HI_LO <<Int 128)
                  |Int (LO_HI <<Int 64)
                  |Int  LO_LO
                )))
              ~> returnHostVal
                 ...
        </instrs>
        <locals>
          0 |-> < i64 > HI_HI
          1 |-> < i64 > HI_LO
          2 |-> < i64 > LO_HI
          3 |-> < i64 > LO_LO
        </locals>
      requires definedSigned(i256,
                   (HI_HI <<Int 192)
              |Int (HI_LO <<Int 128)
              |Int (LO_HI <<Int 64)
              |Int  LO_LO
             )
```

## i256_val_from_be_bytes

Convert a 32-byte `Bytes` object to `I256`, sign-extending from the high bit.

```k
    rule [hostCallAux-i256-val-from-be-bytes]:
        <instrs> hostCallAux ( "i" , "h" )
              => allocObject( I256( Bytes2Int(BS, BE, Signed) ) )
              ~> returnHostVal
                 ...
        </instrs>
        <hostStack> ScBytes(BS) : S => S </hostStack>
      requires lengthBytes(BS) ==Int 32
```

## i256_val_to_be_bytes

```k
    rule [hostCallAux-i256-val-to-be-bytes]:
        <instrs> hostCallAux ( "i" , "i" )
              => allocObject( ScBytes( Int2Bytes(32, #unsigned(i256, I), BE) ) )
              ~> returnHostVal
                 ...
        </instrs>
        <hostStack> I256(I) : S => S </hostStack>
      requires definedUnsigned(i256, I)
      [preserves-definedness] // definedness of '#unsigned(,)' is checked
```

## obj_to_i256_hi_hi

The extractors return the words of the two's-complement representation, so a
negative value is converted to its unsigned form before shifting.
(`i64.const N` chops `N` to 64 bits, so the lower words need no masking.)

```k
    rule [hostCallAux-obj-to-i256-hi-hi]:
        <instrs> hostCallAux ( "i" , "j" ) => i64.const (#unsigned(i256, I) >>Int 192) ... </instrs>
        <hostStack> I256(I) : S => S </hostStack>
      requires definedUnsigned(i256, I)
      [preserves-definedness]
```

## obj_to_i256_hi_lo

```k
    rule [hostCallAux-obj-to-i256-hi-lo]:
        <instrs> hostCallAux ( "i" , "k" ) => i64.const (#unsigned(i256, I) >>Int 128) ... </instrs>
        <hostStack> I256(I) : S => S </hostStack>
      requires definedUnsigned(i256, I)
      [preserves-definedness]
```

## obj_to_i256_lo_hi

```k
    rule [hostCallAux-obj-to-i256-lo-hi]:
        <instrs> hostCallAux ( "i" , "l" ) => i64.const (#unsigned(i256, I) >>Int 64) ... </instrs>
        <hostStack> I256(I) : S => S </hostStack>
      requires definedUnsigned(i256, I)
      [preserves-definedness]
```

## obj_to_i256_lo_lo

```k
    rule [hostCallAux-obj-to-i256-lo-lo]:
        <instrs> hostCallAux ( "i" , "m" ) => i64.const (#unsigned(i256, I)) ... </instrs>
        <hostStack> I256(I) : S => S </hostStack>
      requires definedUnsigned(i256, I)
      [preserves-definedness]
```

## i256_add

The i256 arithmetic host functions are *checked*: the result must be
representable, and the divisor must be non-zero. Otherwise the host fails the
call with `(ErrValue, ArithDomain)` rather than wrapping around.

The first Wasm argument is on top of the host stack (`loadArgs` pushes the
arguments in reverse), so `A` is the left-hand side.

```k
    rule [hostCallAux-i256-add]:
        <instrs> hostCallAux ( "i" , "v" )
              => allocObject( I256( A +Int B ) )
              ~> returnHostVal
                 ...
        </instrs>
        <hostStack> I256(A) : I256(B) : S => S </hostStack>
      requires inRangeInt(i256, Signed, A +Int B)

    rule [hostCallAux-i256-add-overflow]:
        <instrs> hostCallAux ( "i" , "v" ) => #throw(ErrValue, ArithDomain) ... </instrs>
        <hostStack> I256(A) : I256(B) : S => S </hostStack>
      requires notBool inRangeInt(i256, Signed, A +Int B)
```

## i256_sub

```k
    rule [hostCallAux-i256-sub]:
        <instrs> hostCallAux ( "i" , "w" )
              => allocObject( I256( A -Int B ) )
              ~> returnHostVal
                 ...
        </instrs>
        <hostStack> I256(A) : I256(B) : S => S </hostStack>
      requires inRangeInt(i256, Signed, A -Int B)

    rule [hostCallAux-i256-sub-overflow]:
        <instrs> hostCallAux ( "i" , "w" ) => #throw(ErrValue, ArithDomain) ... </instrs>
        <hostStack> I256(A) : I256(B) : S => S </hostStack>
      requires notBool inRangeInt(i256, Signed, A -Int B)
```

## i256_mul

```k
    rule [hostCallAux-i256-mul]:
        <instrs> hostCallAux ( "i" , "x" )
              => allocObject( I256( A *Int B ) )
              ~> returnHostVal
                 ...
        </instrs>
        <hostStack> I256(A) : I256(B) : S => S </hostStack>
      requires inRangeInt(i256, Signed, A *Int B)

    rule [hostCallAux-i256-mul-overflow]:
        <instrs> hostCallAux ( "i" , "x" ) => #throw(ErrValue, ArithDomain) ... </instrs>
        <hostStack> I256(A) : I256(B) : S => S </hostStack>
      requires notBool inRangeInt(i256, Signed, A *Int B)
```

## i256_div

Division truncates toward zero (K's `/Int`), matching Rust's `i256` division.
`i256::MIN / -1` is the one quotient that leaves the range; it is named directly
rather than range-checking `A /Int B`, so no side condition divides.

```k
    rule [hostCallAux-i256-div]:
        <instrs> hostCallAux ( "i" , "y" )
              => allocObject( I256( A /Int B ) )
              ~> returnHostVal
                 ...
        </instrs>
        <hostStack> I256(A) : I256(B) : S => S </hostStack>
      requires B =/=Int 0
       andBool notBool (A ==Int minInt(i256, Signed) andBool B ==Int -1)
      [preserves-definedness] // 'A /Int B' is defined for non-zero B

    rule [hostCallAux-i256-div-by-zero]:
        <instrs> hostCallAux ( "i" , "y" ) => #throw(ErrValue, ArithDomain) ... </instrs>
        <hostStack> I256(_A) : I256(B) : S => S </hostStack>
      requires B ==Int 0

    rule [hostCallAux-i256-div-overflow]:
        <instrs> hostCallAux ( "i" , "y" ) => #throw(ErrValue, ArithDomain) ... </instrs>
        <hostStack> I256(A) : I256(B) : S => S </hostStack>
      requires A ==Int minInt(i256, Signed) andBool B ==Int -1
```

## i256_rem_euclid

Euclidean modulo: the result is always non-negative, whatever the signs of the
operands. K's `modInt` takes the sign of its divisor, so dividing by `absInt(B)`
gives exactly Rust's `rem_euclid`. The quotient never leaves the range, so a
zero divisor is the only failure.

```k
    rule [hostCallAux-i256-rem-euclid]:
        <instrs> hostCallAux ( "i" , "z" )
              => allocObject( I256( A modInt absInt(B) ) )
              ~> returnHostVal
                 ...
        </instrs>
        <hostStack> I256(A) : I256(B) : S => S </hostStack>
      requires B =/=Int 0
      [preserves-definedness] // 'A modInt absInt(B)' is defined for non-zero B

    rule [hostCallAux-i256-rem-euclid-error]:
        <instrs> hostCallAux ( "i" , "z" ) => #throw(ErrValue, ArithDomain) ... </instrs>
        <hostStack> I256(_A) : I256(B) : S => S </hostStack>
      requires B ==Int 0
```

```k
endmodule
```