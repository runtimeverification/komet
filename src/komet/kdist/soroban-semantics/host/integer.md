
```k
requires "../configuration.md"

module HOST-INTEGER
    imports CONFIG-OPERATIONS

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
              => #waitCommands
              ~> returnHostVal
                 ...
        </instrs>
        <locals>
          0 |-> < i64 > I
        </locals>
        <k> (.K => allocObject(U64(I))) ... </k>

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

    rule [hostfun-obj-to-u128-lo64]:
        <instrs> hostCall ( "i" , "4" , [ i64  .ValTypes ] -> [ i64  .ValTypes ] )
              => loadObject(HostVal(VAL))
              ~> u128low64
                 ...
        </instrs>
        <locals>
          0 |-> < i64 > VAL
        </locals>

    syntax InternalInstr ::= "u128low64"      [symbol(u128low64)]
 // ---------------------------------------------------------------
    rule [u128-low64]:
        <instrs> u128low64 => i64.const I ... </instrs> // 'i64.const N' chops N to 64 bits
        <hostStack> U128(I) : S => S </hostStack>

    rule [hostfun-obj-to-u128-hi64]:
        <instrs> hostCall ( "i" , "5" , [ i64  .ValTypes ] -> [ i64  .ValTypes ] )
              => loadObject(HostVal(VAL))
              ~> u128high64
                 ...
        </instrs>
        <locals>
          0 |-> < i64 > VAL
        </locals>

    syntax InternalInstr ::= "u128high64"      [symbol(u128high64)]
 // ---------------------------------------------------------------
    rule [u128-high64]:
        <instrs> u128high64 => i64.const (I >>Int 64) ... </instrs>
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

    rule [hostfun-obj-to-i128-lo64]:
        <instrs> hostCall ( "i" , "7" , [ i64 .ValTypes ] -> [ i64  .ValTypes ] )
              => loadObject(HostVal(VAL))
              ~> i128lo64
                 ...
        </instrs>
        <locals>
          0 |-> < i64 > VAL
        </locals>

    syntax InternalInstr ::= "i128lo64"   [symbol(i128lo64)]
 // --------------------------------------------------------
    rule [i128lo64]:
        <instrs> i128lo64 => i64.const (#unsigned(i128, I)) ... </instrs>
        <hostStack> I128(I) : S => S </hostStack>
      requires definedUnsigned(i128, I)
      [preserves-definedness]

    rule [hostfun-obj-to-i128-hi64]:
        <instrs> hostCall ( "i" , "8" , [ i64 .ValTypes ] -> [ i64  .ValTypes ] )
              => loadObject(HostVal(VAL))
              ~> i128hi64
                 ...
        </instrs>
        <locals>
          0 |-> < i64 > VAL
        </locals>

    syntax InternalInstr ::= "i128hi64"   [symbol(i128hi64)]
 // --------------------------------------------------------
    rule [i128hi64]:
        <instrs> i128hi64 => i64.const (I >>Int 64) ... </instrs>
        <hostStack> I128(I) : S => S </hostStack>

endmodule
```