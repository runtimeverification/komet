
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

endmodule
```