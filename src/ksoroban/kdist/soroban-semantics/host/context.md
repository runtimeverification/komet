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

    // TODO This only works for addresses. Implement it properly for other cases.
    // https://github.com/stellar/stellar-protocol/blob/master/core/cap-0046-01.md#comparison
    syntax InternalInstr ::= "objCmp"   [symbol(objCmp)]
 // ----------------------------------------------------
    rule [objCmp-equal]:
        <instrs> objCmp => i64.const compareAddress(A, B) ... </instrs>
        <hostStack> ScAddress(A) : ScAddress(B) : S => S </hostStack>

    syntax Int ::= compareAddress(Address, Address)    [function, total, symbol(compareAddress)]
 // -------------------------------------------------------------------------------------
    rule compareAddress(Account(_),  Contract(_)) => -1
    rule compareAddress(Contract(_), Account(_))  => 1
    rule compareAddress(Contract(A), Contract(B)) => compareBytes(A, B)
    rule compareAddress(Account(A),  Account(B))  => compareBytes(A, B)

    syntax Int ::= compareBytes(Bytes, Bytes)       [function, total, symbol(compareBytes)]
                 | compareString(String, String)    [function, total, symbol(compareString)]
 // -------------------------------------------------------------------------------------
    rule compareBytes(A, B) => compareString(Bytes2String(A), Bytes2String(B))
    rule compareString(A, B) => -1 requires A  <String B
    rule compareString(A, B) =>  0 requires A ==String B
    rule compareString(A, B) =>  1 requires A  >String B

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