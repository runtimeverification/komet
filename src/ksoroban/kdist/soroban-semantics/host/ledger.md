# Ledger Host Functions

```k
requires "integer.md"

module HOST-LEDGER
    imports HOST-INTEGER

```

## put_contract_data

```k
    rule [hostfun-put-contract-data]:
        <instrs> hostCall ( "l" , "_" , [ i64  i64  i64  .ValTypes ] -> [ i64  .ValTypes ] )
              => loadObjectFull(HostVal(VAL))
              ~> loadObjectFull(HostVal(KEY))
              ~> putContractData(Int2StorageType(STORAGE_TYPE))
                 ...
        </instrs>
        <locals>
          0 |-> < i64 > KEY            // HostVal
          1 |-> < i64 > VAL            // HostVal
          2 |-> < i64 > STORAGE_TYPE   // 0: temp, 1: persistent, 2: instance
        </locals>
      requires Int2StorageTypeValid(STORAGE_TYPE)

    syntax InternalInstr ::= putContractData(StorageType)   [symbol(putContractData)]
 // ---------------------------------------------------------------------------------
    rule [putContractData-instance]:
        <instrs> putContractData(#instance) => toSmall(Void) ... </instrs>
        <hostStack> KEY : VAL : S => S </hostStack>
        <callee> CONTRACT </callee>
        <contract> 
          <contractId> CONTRACT </contractId>
          <instanceStorage> STORAGE => STORAGE [ KEY <- VAL ] </instanceStorage>
          ...
        </contract>

    rule [putContractData-other]:
        <instrs> putContractData(DUR:Durability) => toSmall(Void) ... </instrs>
        <hostStack> KEY : VAL : S => S </hostStack>
        <callee> CONTRACT </callee>
        <contractData>
          STORAGE => STORAGE [ #skey(CONTRACT, DUR, KEY) <- VAL ]
        </contractData>

```

## has_contract_data

```k
    rule [hostfun-has-contract-data]:
        <instrs> hostCall ( "l" , "0" , [ i64  i64  .ValTypes ] -> [ i64  .ValTypes ] )
              => loadObjectFull(HostVal(KEY))
              ~> hasContractData(Int2StorageType(STORAGE_TYPE))
                 ...
        </instrs>
        <locals>
          0 |-> < i64 > KEY            // HostVal
          1 |-> < i64 > STORAGE_TYPE   // 0: temp, 1: persistent, 2: instance
        </locals>
      requires Int2StorageTypeValid(STORAGE_TYPE)

    syntax InternalInstr ::= hasContractData(StorageType)   [symbol(hasContractData)]
 // ---------------------------------------------------------------------------------
    rule [hasContractData-instance]:
        <instrs> hasContractData(#instance)
              => toSmall(SCBool( KEY in_keys(STORAGE) ))
                 ...
        </instrs>
        <hostStack> KEY : S => S </hostStack>
        <callee> CONTRACT </callee>
        <contract> 
          <contractId> CONTRACT </contractId>
          <instanceStorage> STORAGE </instanceStorage>
          ...
        </contract>

    rule [hasContractData-other]:
        <instrs> hasContractData(DUR:Durability)
              => toSmall(SCBool( #skey(CONTRACT, DUR, KEY) in_keys(STORAGE) ))
                 ...
        </instrs>
        <hostStack> KEY : S => S </hostStack>
        <callee> CONTRACT </callee>
        <contractData> STORAGE </contractData>
```

## get_contract_data

```k
    rule [hostfun-get-contract-data]:
        <instrs> hostCall ( "l" , "1" , [ i64  i64  .ValTypes ] -> [ i64  .ValTypes ] )
              => loadObjectFull(HostVal(KEY))
              ~> getContractData(Int2StorageType(STORAGE_TYPE))
                 ...
        </instrs>
        <locals>
          0 |-> < i64 > KEY            // HostVal
          1 |-> < i64 > STORAGE_TYPE   // 0: temp, 1: persistent, 2: instance
        </locals>
      requires Int2StorageTypeValid(STORAGE_TYPE)

    syntax InternalInstr ::= getContractData(StorageType)   [symbol(getContractData)]
 // ---------------------------------------------------------------------------------
    rule [getContractData-instance]:
        <instrs> getContractData(#instance)
              => allocObject(VAL)
              ~> returnHostVal
                 ...
        </instrs>
        <hostStack> KEY : S => S </hostStack>
        <callee> CONTRACT </callee>
        <contract> 
          <contractId> CONTRACT </contractId>
          <instanceStorage> ... KEY |-> VAL ... </instanceStorage>
          ...
        </contract>

    rule [getContractData-other]:
        <instrs> getContractData(DUR:Durability)
              => allocObject(VAL)
              ~> returnHostVal
                 ...
        </instrs>
        <hostStack> KEY : S => S </hostStack>
        <callee> CONTRACT </callee>
        <contractData> ... #skey(CONTRACT, DUR, KEY) |-> VAL ... </contractData>

```

## Helpers

```k
    syntax StorageType ::= Int2StorageType(Int)   [function, total]
 // -------------------------------------------------------------------------------
    rule Int2StorageType(0) => #temporary
    rule Int2StorageType(1) => #persistent
    rule Int2StorageType(_) => #instance      [owise]

    syntax Bool ::= Int2StorageTypeValid(Int)   [function, total]
 // ------------------------------------------------------------
    rule Int2StorageTypeValid(I) => 0 <=Int I andBool I <=Int 2

endmodule
```