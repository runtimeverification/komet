
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
      [preserves-definedness]

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
endmodule
```