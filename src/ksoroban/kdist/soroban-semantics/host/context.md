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

endmodule
```