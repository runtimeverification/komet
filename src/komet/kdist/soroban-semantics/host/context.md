# Context Host Functions

```k
requires "integer.md"

module HOST-CONTEXT
    imports HOST-INTEGER
```

## obj_cmp

```k
    rule [hostfun-obj-cmp]:
        <instrs> hostCall ( "x" , "0" , [ i64  i64  .ValTypes ] -> [ i64  .ValTypes ] )
              => loadObjectFull(HostVal(OBJ_B))
              ~> loadObjectFull(HostVal(OBJ_A))
              ~> objCmp
                 ...
        </instrs>
        <locals>
            0 |-> <i64> OBJ_A
            1 |-> <i64> OBJ_B
        </locals>
      requires isObject(HostVal(OBJ_A))
        orBool isObject(HostVal(OBJ_B))

    syntax InternalInstr ::= "objCmp"   [symbol(objCmp)]
 // ----------------------------------------------------
    rule [objCmp-equal]:
        <instrs> objCmp => i64.const Ordering2Int(compare(A, B)) ... </instrs>
        <hostStack> A : B : S => S </hostStack>

```

## contract_event

TODO: Revisit this when event handling is needed in tests.
Currently, contract_event is a no-op since there is no mechanism to check event logs.

```k
    rule [hostfun-contract-event]:
        <instrs> hostCall ( "x" , "1" , [ i64  i64  .ValTypes ] -> [ i64  .ValTypes ] )
              => toSmall(Void)
                 ...
        </instrs>
        <locals>
            0 |-> <i64> _TOPICS
            1 |-> <i64> _DATA
        </locals>

```

## get_ledger_sequence

Return the current ledger sequence number as `U32`.

```k
    rule [hostfun-get-ledger-sequence]:
        <instrs> hostCall ( "x" , "3" , [ .ValTypes ] -> [ i64  .ValTypes ] )
              => toSmall(U32(SEQ_NUM))
                 ...
        </instrs>
        <locals> .Map </locals>
        <ledgerSequenceNumber> SEQ_NUM </ledgerSequenceNumber>
```

## get_ledger_timestamp

Return the current ledger timestamp as `U64`.

```k
    rule [hostfun-get-ledger-timestamp]:
        <instrs> hostCall ( "x" , "4" , [ .ValTypes ] -> [ i64  .ValTypes ] )
              => allocObject(U64(TIMESTAMP))
              ~> returnHostVal
                 ...
        </instrs>
        <locals> .Map </locals>
        <ledgerTimestamp> TIMESTAMP </ledgerTimestamp>
```

## fail_with_error

```k
    rule [hostfun-fail-with-error]:
        <instrs> hostCall ( "x" , "5" , [ i64  .ValTypes ] -> [ i64  .ValTypes ] ) ~> _REST
              => .K
        </instrs>
        <k> (.K => pushStack(fromSmall(HostVal(ERR)))) ... </k>
        <locals>
            0 |-> < i64 > ERR
        </locals>
      requires fromSmallValid(HostVal(ERR))
       andBool getTag(HostVal(ERR)) ==Int 3
       andBool Int2ErrorType(getMinor(HostVal(ERR))) ==K ErrContract // error type must be ErrContract

    rule [hostfun-fail-with-error-wrong-type]:
        <instrs> hostCall ( "x" , "5" , [ i64  .ValTypes ] -> [ i64  .ValTypes ] ) ~> _REST
              => .K
        </instrs>
        <k> (.K => pushStack(Error(ErrContext, UnexpectedType))) ... </k>
        <locals>
            0 |-> < i64 > ERR
        </locals>
      requires fromSmallValid(HostVal(ERR))
       andBool getTag(HostVal(ERR)) ==Int 3
       andBool Int2ErrorType(getMinor(HostVal(ERR))) =/=K ErrContract

```

## get_current_contract_address

```k
    rule [hostfun-get-current-contract-address]:
        <instrs> hostCall ( "x" , "7" , [ .ValTypes ] -> [ i64  .ValTypes ] )
              => allocObject(ScAddress(CONTRACT))
              ~> returnHostVal
                 ...
        </instrs>
        <locals> .Map </locals>
        <callee> CONTRACT </callee>

endmodule
```