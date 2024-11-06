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

## del_contract_data

```k
    rule [hostfun-del-contract-data]:
        <instrs> hostCall ( "l" , "2" , [ i64  i64  .ValTypes ] -> [ i64  .ValTypes ] )
              => loadObjectFull(HostVal(KEY))
              ~> delContractData(Int2StorageType(STORAGE_TYPE))
                 ...
        </instrs>
        <locals>
          0 |-> < i64 > KEY            // HostVal
          1 |-> < i64 > STORAGE_TYPE   // 0: temp, 1: persistent, 2: instance
        </locals>
      requires Int2StorageTypeValid(STORAGE_TYPE)

    syntax InternalInstr ::= delContractData(StorageType)   [symbol(delContractData)]
 // ---------------------------------------------------------------------------------
    rule [delContractData-instance]:
        <instrs> delContractData(#instance) => toSmall(Void) ... </instrs>
        <hostStack> KEY : S => S </hostStack>
        <callee> CONTRACT </callee>
        <contract>
          <contractId> CONTRACT </contractId>
          <instanceStorage> MAP => MAP [ KEY <- undef ] </instanceStorage>
          ...
        </contract>
      requires KEY in_keys(MAP)

    rule [delContractData-other]:
        <instrs> delContractData(DUR:Durability) => toSmall(Void) ... </instrs>
        <hostStack> KEY : S => S </hostStack>
        <callee> CONTRACT </callee>
        <contractData> MAP => MAP [#skey(CONTRACT, DUR, KEY) <- undef ] </contractData>
      requires #skey(CONTRACT, DUR, KEY) in_keys(MAP)

```

## extend_current_contract_instance_and_code_ttl

```k
    rule [hostfun-extend-current-contract-instance-and-code-ttl]:
        <instrs> hostCall ( "l" , "8" , [ i64  i64  .ValTypes ] -> [ i64  .ValTypes ] )
              => loadObject(HostVal(EXTEND_TO))
              ~> loadObject(HostVal(THRESHOLD))
              ~> extendContractTtl(CONTRACT)
              ~> loadObject(HostVal(EXTEND_TO))
              ~> loadObject(HostVal(THRESHOLD))
              ~> extendContractCodeTtl(CONTRACT)
              ~> toSmall(Void)
                 ...
        </instrs>
        <locals>
          0 |-> < i64 > THRESHOLD   // U32
          1 |-> < i64 > EXTEND_TO   // U32
        </locals>
        <callee> CONTRACT </callee>

  // If the TTL for the contract is less than or equal to `THRESHOLD`,
  // update <contractLiveUntil>
    syntax InternalInstr ::= extendContractTtl(ContractId)   [symbol(extendContractTtl)]
 // -------------------------------------------------------------------------------
    rule [extendContractTtl]:
        <instrs> extendContractTtl(CONTRACT) => .K ... </instrs>
        <hostStack> U32(THRESHOLD) : U32(EXTEND_TO) : S => S </hostStack>
        <contract>
          <contractId> CONTRACT </contractId>
          <contractLiveUntil> LIVE_UNTIL
                           => extendedLiveUntil(SEQ, LIVE_UNTIL, THRESHOLD, EXTEND_TO)
          </contractLiveUntil>
          ...
        </contract>
        <ledgerSequenceNumber> SEQ </ledgerSequenceNumber>
      requires THRESHOLD <=Int EXTEND_TO   // input is valid
       andBool SEQ <=Int LIVE_UNTIL        // entry is still alive

    syntax Int ::= extendedLiveUntil(Int, Int, Int, Int)    [function, total]
 // -----------------------------------------------------------------------------------
    rule extendedLiveUntil(SEQ, LIVE_UNTIL, THRESHOLD, EXTEND_TO) => SEQ +Int EXTEND_TO
      requires LIVE_UNTIL -Int SEQ <=Int THRESHOLD            // CURRENT_TTL <= THRESHOLD
       andBool LIVE_UNTIL          <Int  SEQ +Int EXTEND_TO   // LIVE_UNTIL  <  NEW_LIVE_UNTIL

    rule extendedLiveUntil(_, LIVE_UNTIL, _, _) => LIVE_UNTIL
      [owise]

    syntax InternalInstr ::= extendContractCodeTtl(ContractId)   [symbol(extendContractCodeTtl)]
 // --------------------------------------------------------------------------------------------
    rule [extendContractCodeTtl]:
        <instrs> extendContractCodeTtl(CONTRACT) => extendCodeTtl(HASH) ... </instrs>
        <contract>
          <contractId> CONTRACT </contractId>
          <wasmHash> HASH </wasmHash>
          ...
        </contract>

  // If the TTL for the contract code is less than `THRESHOLD`, update contractLiveUntil
  //    where TTL is defined as LIVE_UNTIL - SEQ.
    syntax InternalInstr ::= extendCodeTtl(Bytes)   [symbol(extendCodeTtl)]
 // -------------------------------------------------------------------------------
    rule [extendCodeTtl]:
        <instrs> extendCodeTtl(HASH) => .K ... </instrs>
        <hostStack> U32(THRESHOLD) : U32(EXTEND_TO) : S => S </hostStack>
        <contractCode>
          <codeHash> HASH </codeHash>
          <codeLiveUntil> LIVE_UNTIL
                       => extendedLiveUntil(SEQ, LIVE_UNTIL, THRESHOLD, EXTEND_TO)
          </codeLiveUntil>
          ...
        </contractCode>
        <ledgerSequenceNumber> SEQ </ledgerSequenceNumber>
      requires THRESHOLD <=Int EXTEND_TO   // input is valid
       andBool SEQ <=Int LIVE_UNTIL        // entry is still alive

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