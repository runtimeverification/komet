# Kasmer Cheatcodes (Kasmer Host Functions)


```k
requires "host/hostfuns.md"
requires "kasmer.md"

module CHEATCODES
    imports HOSTFUNS
    imports KASMER-SYNTAX-COMMON

    // TODO: Add a check to ensure these host functions are only called from a Kasmer test contract.

```

## kasmer_set_ledger_sequence

```rust
    extern "C" {
        fn kasmer_set_ledger_sequence(x : u64);
    }
```

```k
    rule [kasmer-set-ledger-sequence]:
        <instrs> hostCall ( "env" , "kasmer_set_ledger_sequence" , [ i64  .ValTypes ] -> [ .ValTypes ] )
              => toSmall(Void)
                 ...
        </instrs>
        <locals>
          0 |-> < i64 > NEW_SEQ_NUM // U32 HostVal
        </locals>
        <ledgerSequenceNumber> _ => getMajor(HostVal(NEW_SEQ_NUM)) </ledgerSequenceNumber>
      requires getTag(HostVal(NEW_SEQ_NUM)) ==Int getTag(U32(0)) // check `NEW_SEQ_NUM` is a U32
```

## kasmer_set_ledger_timestamp

```rust
    extern "C" {
        fn kasmer_set_ledger_timestamp(x : u64);
    }
```

```k
    rule [kasmer-set-ledger-timestamp]:
        <instrs> hostCall ( "env" , "kasmer_set_ledger_timestamp" , [ i64  .ValTypes ] -> [ .ValTypes ] )
              => loadObject(HostVal(TIMESTAMP))
              ~> setLedgerTimestamp
              ~> toSmall(Void)
                 ...
        </instrs>
        <locals>
          0 |-> < i64 > TIMESTAMP // U64 HostVal
        </locals>
      requires getTag(HostVal(TIMESTAMP)) ==Int 6 // check `NEW_SEQ_NUM` is a U64
        orBool getTag(HostVal(TIMESTAMP)) ==Int 64
    
    syntax InternalInstr ::= "setLedgerTimestamp"
 // ---------------------------------------------
    rule [setLedgerTimestamp]:
        <instrs> setLedgerTimestamp => .K ... </instrs>
        <hostStack> U64(TIMESTAMP) : S => S </hostStack>
        <ledgerTimestamp> _ => TIMESTAMP </ledgerTimestamp>

```

## kasmer_create_contract

```rust
extern "C" {
    fn kasmer_create_contract(addr_val: u64, hash_val: u64) -> u64;
}

fn create_contract(env: &Env, addr: &Bytes, hash: &Bytes) -> Address {
    unsafe {
        let res = kasmer_create_contract(addr.as_val().get_payload(), hash.as_val().get_payload());
        Address::from_val(env, &Val::from_payload(res))
    }
}
```

```k
    rule [kasmer-create-contract]:
        <instrs> hostCall ( "env" , "kasmer_create_contract" , [ i64  i64  .ValTypes ] -> [ i64  .ValTypes ] )
              => loadObject(HostVal(HASH))
              ~> loadObject(HostVal(ADDR))
              ~> kasmerCreateContract
                 ...
        </instrs>
        <locals>
          0 |-> < i64 > ADDR // ScBytes HostVal
          1 |-> < i64 > HASH // ScBytes HostVal
        </locals>

    syntax InternalInstr ::= "kasmerCreateContract"   [symbol(kasmerCreateContract)]
 // --------------------------------------------------------------------------------
    rule [kasmerCreateContract]:
        <instrs> kasmerCreateContract
              => #waitCommands
              ~> allocObject(ScAddress(Contract(ADDR)))
              ~> returnHostVal
                 ...
        </instrs>
        <k> (.K => deployContract(CONTRACT, Contract(ADDR), HASH)) ... </k>
        <hostStack> ScBytes(ADDR) : ScBytes(HASH) : S => S </hostStack>
        <callee> CONTRACT </callee>


endmodule
```