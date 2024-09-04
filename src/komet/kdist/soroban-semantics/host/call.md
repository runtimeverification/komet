# Call

```k
requires "../configuration.md"
requires "../switch.md"
requires "../soroban.md"
requires "integer.md"

module HOST-CALL
    imports CONFIG-OPERATIONS
    imports SOROBAN-SYNTAX
    imports HOST-INTEGER
    imports SWITCH-SYNTAX

```

## call

```k
    // TODO Check reentry
    rule [hostfun-require-auth]:
        <instrs> hostCall ( "d" , "_" , [ i64  i64  i64  .ValTypes ] -> [ i64  .ValTypes ] )
              => loadObject(HostVal(ARGS))
              ~> loadObject(HostVal(FUNC))
              ~> loadObject(HostVal(ADDR))
              ~> call
                 ...
        </instrs>
        <locals>
          0 |-> < i64 > ADDR      // Address
          1 |-> < i64 > FUNC      // Symbol
          2 |-> < i64 > ARGS      // Vec
        </locals>

    syntax InternalInstr ::= "call"   [symbol(call)]
 // ------------------------------------------
    rule [call]:
        <instrs> call
              => #waitCommands
              ~> returnCallResult
                 ...
        </instrs>
        <hostStack> ScAddress(TO) : Symbol(FUNC) : ScVec(ARGS) : S => S </hostStack>
        <callee> FROM </callee>
        <k> (.K => callContract(FROM, TO, FUNC, ARGS)) ... </k>


    syntax InternalInstr ::= "returnCallResult"   [symbol(returnCallResult)]
 // ------------------------------------------------------------------------
    rule [returnCallResult-error]:
        <instrs> returnCallResult => trap ... </instrs>
        <hostStack> Error(_,_) : _ </hostStack>
    
    rule [returnCallResult]:
        <instrs> returnCallResult
              => allocObject(RES)
              ~> returnHostVal
                 ...
        </instrs>
        <hostStack> RES:ScVal : S => S </hostStack>
      [owise]

endmodule
```