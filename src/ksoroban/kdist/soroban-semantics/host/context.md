# Context Host Functions

```k
requires "integer.md"

module HOST-CONTEXT
    imports HOST-INTEGER
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


endmodule
```