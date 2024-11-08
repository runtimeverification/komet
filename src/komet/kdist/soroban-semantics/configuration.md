
```k
requires "auto-allocate.md"
requires "wasm-semantics/wasm.md"
requires "data.md"

module CONFIG
    imports HOST-OBJECT
    imports MAP
    imports WASM

    configuration
      <soroban>
        <k> .K </k>
        <host>
          <callState>
            <callee> Contract(.Bytes) </callee>
            <caller> Account(.Bytes):Address </caller>
            <function> .WasmString </function>
            <args> .List </args>
            <wasm/>
            <relativeObjects> .List </relativeObjects> // List of HostVals with absolute handles to host objects
            <contractModIdx> .Int </contractModIdx>
          </callState>
          <hostStack> .HostStack </hostStack>
          <hostObjects> .List </hostObjects> // List of ScVals
          <callStack> .List </callStack>
          <interimStates> .List </interimStates>
        </host>

        <contracts>
          <contract multiplicity="*" type="Map">
            <contractId> Contract(.Bytes) </contractId>
            <wasmHash> .Bytes </wasmHash>
```

- `instanceStorage`: Instance storage is a map from user-provided keys (ScVal) to values (ScVal), and it is tied to the
    contract's lifecycle.
    If the value is a container (e.g., map or vector), the contained values must also be `ScVal`, not `HostVal`.
    Therefore, before storing data, all `HostVal`s in the data should be resolved to `ScVal`s.
    Other storage types (persistent and temporary) are stored separately in `<contractData>`.
    
    - [Stellar Docs](https://developers.stellar.org/docs/learn/encyclopedia/storage/persisting-data#ledger-entries)
    - [CAP 46-05: Instance Storage](https://github.com/stellar/stellar-protocol/blob/master/core/cap-0046-05.md#instance-storage)

```k
            <instanceStorage> .Map </instanceStorage> // Map of ScVal to ScVal
```

- `contractLiveUntil`: The ledger sequence number until which the contract instance will live.
 
```k
            <contractLiveUntil> 0 </contractLiveUntil>
          </contract>
        </contracts>
        <accounts>
          <account multiplicity="*" type="Map">
            <accountId> Account(.Bytes) </accountId>
            <balance> 0 </balance>
          </account>
        </accounts>
```
- `contractData`: Stores persistent and temporary storage items separately from the contract instances.
    The storage entries are identified by `(ContractId, Durability, ScVal)` and contain values of type `ScVal`.
    Keys and values must be fully resolved `ScVal`s as in `<instanceStorage>`.

```k
        <contractData> .Map </contractData> // Map of StorageKey to StorageVal
        <contractCodes>
          <contractCode multiplicity="*" type="Map">
            <codeHash>      .Bytes         </codeHash>
            <codeLiveUntil> 0              </codeLiveUntil>
            <codeWasm>      #emptyModule() </codeWasm> 
          </contractCode>
        </contractCodes>
```

- `ledgerSequenceNumber`: The current block (or "ledger" in Stellar) number.
    Accessible to contracts via the `get_ledger_sequence` host function.
    Set externally using `kasmer_set_ledger_sequence`.

```k
        <ledgerSequenceNumber> 0 </ledgerSequenceNumber>
        <ledgerTimestamp> 0 </ledgerTimestamp>
        <logging> .List </logging>
      </soroban>

    syntax HostStack ::= List{HostStackVal, ":"}  [symbol(hostStackList)]
    syntax HostStackVal ::= ScVal | HostVal | Bytes | List


    syntax InternalCmd ::= #callResult(ValStack, List)   [symbol(#callResult)]

    syntax Durability ::= "#temporary"           [symbol(#temporary)]
                        | "#persistent"          [symbol(#persistent)]

    syntax StorageType ::= Durability
                         | "#instance"           [symbol(#instance)]

    syntax StorageKey ::= #skey( ContractId , Durability , ScVal )   [symbol(StorageKey)]

    syntax StorageVal ::= #sval( ScVal , Int )                       [symbol(StorageVal)]

endmodule
```


```k
module CONFIG-OPERATIONS
    imports WASM-AUTO-ALLOCATE
    imports CONFIG
    imports SWITCH-SYNTAX
```

## Stack operations

```k
    syntax InternalCmd ::= pushStack(HostStackVal)    [symbol(pushStack)]
 // ---------------------------------------------------------------------
    rule [pushStack]:
        <k> pushStack(V) => .K ... </k>
        <hostStack> S => V : S </hostStack>

    syntax InternalCmd ::= "dropStack"    [symbol(dropStack)]
 // ---------------------------------------------------------------------
    rule [dropStack]:
        <k> dropStack => .K ... </k>
        <hostStack> _V : S => S </hostStack>

```

## Call State

The `<callStack>` cell stores a list of previous contract execution states.
These internal commands manages the call stack when calling and returning from a contract.

```k
    syntax InternalCmd ::= "pushCallState"  [symbol(pushCallState)]
 // ---------------------------------------
    rule [pushCallState]:
         <k> pushCallState => .K ... </k>
         <callStack> (.List => ListItem(CALLSTATE)) ... </callStack>
         CALLSTATE:CallStateCell
      [priority(60)]

    syntax InternalCmd ::= "popCallState"  [symbol(popCallState)]
 // --------------------------------------
    rule [popCallState]:
         <k> popCallState => .K ... </k>
         <callStack> (ListItem(CALLSTATE:CallStateCell) => .List) ... </callStack>
         (_:CallStateCell => CALLSTATE)
      [priority(60)]

    syntax InternalCmd ::= "dropCallState"  [symbol(dropCallState)]
 // ---------------------------------------
    rule [dropCallState]:
         <k> dropCallState => .K ... </k>
         <callStack> (ListItem(_) => .List) ... </callStack>
      [priority(60)]

    syntax InternalCmd ::= "resetCallstate"      [symbol(resetCallState)]
 // ---------------------------------------------------------------------------
    rule [resetCallstate]:
        <k> resetCallstate => .K ... </k>
        (_:CallStateCell => <callState> <instrs> .K </instrs> ... </callState>)
      [preserves-definedness] // all constant configuration cells should be defined

```

## World State

```k
    syntax AccountsCellFragment
    syntax ContractsCellFragment

    syntax Accounts ::= "{" AccountsCellFragment "," ContractsCellFragment "," Map "}"
 // --------------------------------------------------------

    syntax InternalCmd ::= "pushWorldState"  [symbol(pushWorldState)]
 // ---------------------------------------
    rule [pushWorldState]:
         <k> pushWorldState => .K ... </k>
         <interimStates> (.List => ListItem({ ACCTDATA , CONTRACTS , CTRDATA })) ... </interimStates>
         <contracts> CONTRACTS </contracts>
         <accounts> ACCTDATA </accounts>
         <contractData> CTRDATA </contractData>
      [priority(60)]

    syntax InternalCmd ::= "popWorldState"  [symbol(popWorldState)]
 // --------------------------------------
    rule [popWorldState]:
         <k> popWorldState => .K ... </k>
         <interimStates> (ListItem({ ACCTDATA , CONTRACTS , CTRDATA }) => .List) ... </interimStates>
         <contracts> _ =>  CONTRACTS </contracts>
         <accounts> _ => ACCTDATA </accounts>
         <contractData> _ => CTRDATA </contractData>
      [priority(60)]

    syntax InternalCmd ::= "dropWorldState"  [symbol(dropWorldState)]
 // ---------------------------------------
    rule [dropWorldState]:
         <k> dropWorldState => .K ... </k>
         <interimStates> (ListItem(_) => .List) ... </interimStates>
      [priority(60)]
```

## `ScVal` Operations

### Creating host objects

If `SCV` is an object (i.e., not a small value), `allocObject(SCV)` creates a new host object
and pushes a `HostVal` onto the `<hostStack>` that points to the newly created object.
If `SCV` is a container such as a Vector or Map, `allocObject` recursively allocates host objects for its content
but only pushes a single `HostVal` for the entire container onto the stack.
If `SCV` is a small value, `allocObject(SCV)` returns a small `HostVal` directly equivalent to `SCV`.

```k
    syntax InternalCmd ::= allocObject(ScVal)             [symbol(allocObject)]
 // ---------------------------------------------------------------------------
    rule [allocObject-small]:
        <k> allocObject(SCV) => .K ... </k>
        <hostStack> STACK => toSmall(SCV) : STACK </hostStack>
      requires toSmallValid(SCV)

    // recursively allocate vector items
    rule [allocObject-vec]:
        <k> allocObject(ScVec(ITEMS))
         => allocObjects(ITEMS)
         ~> allocObjectVecAux
            ...
        </k>

    // recursively allocate map values.
    rule [allocObject-map]:
        <k> allocObject(ScMap(ITEMS))
        // Using `lookupMany` with `keys_list` instead of `values`
        // to ensure the order of values matches the order of keys.
         => allocObjects(lookupMany(ITEMS, keys_list(ITEMS), 0)) 
         ~> allocObjectMapAux(keys_list(ITEMS))
            ...
        </k>

    syntax Map ::= mapFromLists(List, List)      [function, total, symbol(mapFromLists)]
 // --------------------------------------------------------------------------------
    rule mapFromLists(ListItem(KEY) KEYS, ListItem(VAL) VALS)
      => mapFromLists(KEYS, VALS) [ KEY <- VAL]

    rule mapFromLists(_, _) => .Map
      [owise]

    syntax InternalCmd ::= "allocObjectVecAux"    [symbol(allocObjectVecAux)]
 // -------------------------------------------------------------------------
    rule [allocObjectVecAux]:
        <k> allocObjectVecAux => addObject(ScVec(V)) ... </k>
        <hostStack> V : S => S </hostStack>

    syntax InternalCmd ::= allocObjectMapAux(List)    [symbol(allocObjectMapAux)]
 // -------------------------------------------------------------------------
    rule [allocObjectMapAux]:
        <k> allocObjectMapAux(KEYS)
         => addObject(ScMap(mapFromLists(KEYS, VALS)))
            ...
        </k>
        <hostStack> VALS : S => S </hostStack>
      requires size(KEYS) ==Int size(VALS)

    rule [allocObject]:
        <k> allocObject(SCV) => addObject(SCV) ... </k>
      [owise]

    // Allows using `allocObject` in the `<instrs>` cell
    rule [allocObject-instr]:
        <instrs> allocObject(SCV) => #waitCommands ... </instrs>
        <k> (.K => allocObject(SCV)) ... </k>

    syntax InternalCmd ::= addObject(ScVal)                                  [symbol(addObject)]
 // --------------------------------------------------------------------------------------------
    rule [addObject]:
        <k> addObject(SCV) => .K ... </k>
        <hostObjects> OBJS => OBJS ListItem(SCV) </hostObjects>
        <hostStack> STACK
                 => fromHandleAndTag(indexToHandle(size(OBJS), false), getTag(SCV)) : STACK
        </hostStack>

    syntax InternalCmd ::= allocObjects       (List)       [symbol(allocObjects)]
                         | allocObjectsAux    (List)       [symbol(allocObjectsAux)]
 // ---------------------------------------------------------------------------
    rule [allocObjects]:
        <k> allocObjects(L) => allocObjectsAux(L) ~> collectStackObjects(size(L))  ... </k>

    rule [allocObjectsAux-empty]:
        <k> allocObjectsAux(.List) => .K ... </k>

    rule [allocObjectsAux]:
        <k> allocObjectsAux(ListItem(SCV:ScVal) L)
         => allocObjectsAux(L)
         ~> allocObject(SCV)
            ...
        </k>

    rule [allocObjectsAux-HostVal]:
        <k> allocObjectsAux(ListItem(HV:HostVal) L)
         => allocObjectsAux(L)
         ~> pushStack(HV)
            ...
        </k>

    // Collect stack values into a List
    syntax InternalCmd ::= collectStackObjects(Int)        [symbol(collectStackObjects)]
 // ---------------------------------------------------------------------------------------
    rule [collectStackObjects]:
        <k> collectStackObjects(LENGTH) => .K ... </k>
        <hostStack> STACK => take(LENGTH, STACK) : drop(LENGTH, STACK) </hostStack>

    rule [collectStackObjects-instr]:
        <instrs> collectStackObjects(LENGTH) => .K ... </instrs>
        <hostStack> STACK => take(LENGTH, STACK) : drop(LENGTH, STACK) </hostStack>

```

### Accessing host objects

- loadObject: Load a host object from `<hostObjects>` to `<hostStack>`

```k
    syntax InternalInstr ::= loadObject(HostVal)    [symbol(loadObject)]
 // --------------------------------------------------------------------
    rule [loadObject-abs]:
        <instrs> loadObject(VAL) => .K ... </instrs>
        <hostStack> S => OBJS {{ getIndex(VAL) }} orDefault Void : S </hostStack>
        <hostObjects> OBJS </hostObjects>
      requires isObject(VAL)
       andBool notBool isRelativeObjectHandle(VAL)
       andBool 0 <=Int getIndex(VAL)
       andBool getIndex(VAL) <Int size(OBJS)

    rule [loadObject-rel]:
        <instrs> loadObject(VAL)
              => loadObject(rel2abs(RELS, VAL))
                 ...
        </instrs>
        <relativeObjects> RELS </relativeObjects>
      requires isObject(VAL)
       andBool isRelativeObjectHandle(VAL)
       andBool 0 <=Int getIndex(VAL)
       andBool getIndex(VAL) <Int size(RELS)

    rule [loadObject-small]:
        <instrs> loadObject(VAL) => .K ... </instrs>
        <hostStack> S => fromSmall(VAL) : S </hostStack>
      requires notBool isObject(VAL)
       andBool fromSmallValid(VAL)

```

- loadObjectFull: Like `loadObject` but resolves all `HostVal`s in containers recursively using `HostVal2ScValRec`

```k
    syntax InternalInstr ::= loadObjectFull(HostVal)    [symbol(loadObjectFull)]
                           | "loadObjectFullAux"
 // --------------------------------------------------------------------
    rule [loadObjectFull]:
        <instrs> loadObjectFull(VAL)
              => loadObject(VAL)
              ~> loadObjectFullAux
                 ...
        </instrs>

    rule [loadObjectFullAux]:
        <instrs> loadObjectFullAux => .K ... </instrs>
        <hostStack> (SCV => HostVal2ScValRec(SCV, OBJS, RELS)) : _ </hostStack>
        <relativeObjects> RELS </relativeObjects>
        <hostObjects>     OBJS </hostObjects>

```

- rel2abs, rel2absMany: Convert relative handles to absolute handles

```k
    syntax HostVal ::= rel2abs(List, HostVal)   [function, total, symbol(rel2abs)]
 // ------------------------------------------------------------------------
    rule rel2abs(RELS, HV) => RELS {{ getIndex(HV) }} orDefault HV
      requires isObject(HV) andBool isRelativeObjectHandle(HV)
    rule rel2abs(_,    HV) => HV
      [owise]

    syntax List ::= rel2absMany(List, List)    [function, total, symbol(rel2absMany)]
 // --------------------------------------------------------------------------------
    rule rel2absMany(RELS, ListItem(HV) L) => ListItem(rel2abs(RELS, HV)) rel2absMany(RELS, L)
    rule rel2absMany(_,                 L) => L
      [owise]

```

### Auxiliary functions

```k
    syntax HostStack ::= drop(Int, HostStack)   [function, total, symbol(HostStack:drop)]
 // -------------------------------------------------------------------------------------
    rule drop(N, _ : S) => drop(N -Int 1, S)                requires N >Int 0
    rule drop(_,     S) => S                                [owise]

    syntax List ::= take(Int, HostStack)        [function, total, symbol(HostStack:take)]
 // -------------------------------------------------------------------------------------
    rule take(N, X : S) => ListItem(X) take(N -Int 1, S)    requires N >Int 0
    rule take(_,     _) => .List                            [owise]
```

- `lookupMany`: Retrieve values for multiple keys from a map. Return the specified default value for missing keys.

```k
    syntax List ::= lookupMany(Map, List, KItem)   [function, total]
 // ----------------------------------------------------------------
    rule lookupMany(M, ListItem(A) REST, D) => ListItem(M [ A ] orDefault D) lookupMany(M, REST, D)
    rule lookupMany(_, _,                _) => .List
        [owise]
```

## Call result handling

```k
    rule [callResult-empty]:
        <k> #callResult(.ValStack, _RELS) => .K ... </k>

    rule [callResult]:
        <k> #callResult(<i64> I : SS, RELS)
         => #callResult(SS, RELS)
         ~> pushStack(HostVal2ScVal(HostVal(I), OBJS, RELS))
            ...
        </k>
        <hostObjects> OBJS </hostObjects>

    // Convert HostVals to ScVal recursively
    syntax ScVal ::= HostVal2ScVal(HostVal, objs: List, rels: List)      [function, total, symbol(HostVal2ScVal)]
 // -------------------------------------------------------------------------------------------------------------------
    rule HostVal2ScVal(VAL, OBJS, RELS) => HostVal2ScValRec(OBJS {{ getIndex(VAL) }} orDefault Void, OBJS, RELS)
      requires isObject(VAL)
       andBool notBool(isRelativeObjectHandle(VAL))
       andBool getIndex(VAL) <Int size(OBJS)

    rule HostVal2ScVal(VAL, OBJS, RELS) => HostVal2ScVal(RELS {{ getIndex(VAL) }} orDefault HostVal(0), OBJS, RELS)
      requires isObject(VAL)
       andBool isRelativeObjectHandle(VAL)
       andBool getIndex(VAL) <Int size(RELS)
      [preserves-definedness]

    rule HostVal2ScVal(VAL, _OBJS, _RELS) => fromSmall(VAL)
      requires notBool isObject(VAL)
       andBool fromSmallValid(VAL)

    rule HostVal2ScVal(_, _, _) => Void     [owise]

    syntax ScVal ::= HostVal2ScValRec(ScVal, objs: List, rels: List)     [function, total, symbol(HostVal2ScValRec)]
 // -------------------------------------------------------------------------------------------------------------------
    rule HostVal2ScValRec(ScVec(VEC), OBJS, RELS) => ScVec(HostVal2ScValMany(VEC, OBJS, RELS))

    rule HostVal2ScValRec(ScMap(M), OBJS, RELS)
      => ScMap(mapFromLists( keys_list(M), HostVal2ScValMany(values(M), OBJS, RELS)) )

    rule HostVal2ScValRec(SCV, _OBJS, _RELS)      => SCV                                        [owise]

    syntax List  ::= HostVal2ScValMany(List, objs: List, rels: List)     [function, total, symbol(HostVal2ScValMany)]
 // -------------------------------------------------------------------------------------------------------------------
    rule HostVal2ScValMany(ListItem(V:HostVal) REST, OBJS, RELS)
      => ListItem(HostVal2ScVal(V, OBJS, RELS))    HostVal2ScValMany(REST, OBJS, RELS)

    rule HostVal2ScValMany(ListItem(V:ScVal)   REST, OBJS, RELS)
      => ListItem(HostVal2ScValRec(V, OBJS, RELS)) HostVal2ScValMany(REST, OBJS, RELS)

    rule HostVal2ScValMany(_, _, _)
      => .List     [owise]

```

```k
endmodule
```