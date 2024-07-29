# Kasmer Cheatcodes (Kasmer Host Functions)


```k
requires "host/hostfuns.md"

module CHEATCODES
    imports HOSTFUNS

    // extern "C" {
    //     fn kasmer_set_ledger_sequence(x : u64);
    // }
    rule [kasmer-set-ledger-sequence]:
        <instrs> hostCall ( "env" , "kasmer_set_ledger_sequence" , [ i64  .ValTypes ] -> [ .ValTypes ] )
              => toSmall(Void)
                 ...
        </instrs>
        <locals>
          0 |-> < i64 > NEW_SEQ_NUM
        </locals>
        <ledgerSequenceNumber> _ => getMajor(HostVal(NEW_SEQ_NUM)) </ledgerSequenceNumber>
      requires getTag(HostVal(NEW_SEQ_NUM)) ==Int getTag(U32(0)) // check `NEW_SEQ_NUM` is a U32

endmodule
```