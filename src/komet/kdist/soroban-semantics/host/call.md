# Call

```k
requires "../configuration.md"
requires "../switch.md"
requires "../soroban.md"
requires "integer.md"

module HOST-CALL
    imports WASM-OPERATIONS
    imports SOROBAN-SYNTAX
    imports HOST-INTEGER

```

## call

```k
    // TODO Check reentry
    rule [hostCallAux-call]:
        <instrs> hostCallAux ( "d" , "_" )
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