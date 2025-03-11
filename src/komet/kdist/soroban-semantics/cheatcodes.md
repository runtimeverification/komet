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
        <instrs> hostCallAux ( "env" , "kasmer_set_ledger_timestamp" )
              => toSmall(Void)
                 ...
        </instrs>
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
        <instrs> hostCallAux ( "env" , "kasmer_create_contract" )
              => #waitCommands
              ~> allocObject(ScAddress(Contract(ADDR)))
              ~> returnHostVal
                 ...
        </instrs>
        <k> (.K => deployContract(CONTRACT, Contract(ADDR), HASH)) ... </k>
        <hostStack> ScBytes(ADDR) : ScBytes(HASH) : S => S </hostStack>
        <callee> CONTRACT </callee>
```

## kasmer_address_from_bytes

```k
    rule [kasmer-address-from-bytes]:
        <instrs> hostCallAux ( "env" , "kasmer_address_from_bytes" )
              => allocObject(ScAddress(
                    #if IS_CONTRACT
                    #then Contract(ADDR)
                    #else Account(ADDR)
                    #fi
                 ))
              ~> returnHostVal
                 ...
        </instrs>
        <hostStack> ScBytes(ADDR) : SCBool(IS_CONTRACT) : S => S </hostStack>

endmodule
```