
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
            <caller> Account(.Bytes) </caller>
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
            <instanceStorage> .Map </instanceStorage>
          </contract>
        </contracts>
        <accounts>
          <account multiplicity="*" type="Map">
            <accountId> Account(.Bytes) </accountId>
            <balance> 0 </balance>
          </account>
        </accounts>
        <contractCodes> .Map </contractCodes>
        <logging> .List </logging>
      </soroban>

    syntax HostStack ::= List{HostStackVal, ":"}  [symbol(hostStackList)]
    syntax HostStackVal ::= ScVal | HostVal


    syntax InternalCmd ::= #callResult(ValStack, List)   [symbol(#callResult)]

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

    syntax Accounts ::= "{" AccountsCellFragment "," ContractsCellFragment "}"
 // --------------------------------------------------------

    syntax InternalCmd ::= "pushWorldState"  [symbol(pushWorldState)]
 // ---------------------------------------
    rule [pushWorldState]:
         <k> pushWorldState => .K ... </k>
         <interimStates> (.List => ListItem({ ACCTDATA , CONTRACTS })) ... </interimStates>
         <contracts> CONTRACTS </contracts>
         <accounts> ACCTDATA </accounts>
      [priority(60)]

    syntax InternalCmd ::= "popWorldState"  [symbol(popWorldState)]
 // --------------------------------------
    rule [popWorldState]:
         <k> popWorldState => .K ... </k>
         <interimStates> (ListItem({ ACCTDATA , CONTRACTS }) => .List) ... </interimStates>
         <contracts> _ =>  CONTRACTS </contracts>
         <accounts> _ => ACCTDATA </accounts>
      [priority(60)]

    syntax InternalCmd ::= "dropWorldState"  [symbol(dropWorldState)]
 // ---------------------------------------
    rule [dropWorldState]:
         <k> dropWorldState => .K ... </k>
         <interimStates> (ListItem(_) => .List) ... </interimStates>
      [priority(60)]
```

## `ScVal` Operations

```k
    syntax InternalCmd ::= allocObject(ScVal)             [symbol(allocObject)]
 // ---------------------------------------------------------------------------
    rule [allocObject-small]:
        <k> allocObject(SCV) => .K ... </k>
        <hostStack> STACK => toSmall(SCV) : STACK </hostStack>
      requires toSmallValid(SCV)

    rule [allocObject]:
        <k> allocObject(SCV) => .K ... </k>
        <hostObjects> OBJS => OBJS ListItem(SCV) </hostObjects>
        <hostStack> STACK => fromHandleAndTag(indexToHandle(size(OBJS), false), getTag(SCV)) : STACK </hostStack>
      [owise]

    syntax InternalCmd ::= allocObjects       (List)       [symbol(allocObjects)]
                         | allocObjectsAux    (List)       [symbol(allocObjectsAux)]
                         | allocObjectsCollect(Int)        [symbol(allocObjectsCollect)]
 // ---------------------------------------------------------------------------
    rule [allocObjects]:
        <k> allocObjects(L) => allocObjectsAux(L) ~> allocObjectsCollect(size(L))  ... </k>

    rule [allocObjectsAux-empty]:
        <k> allocObjectsAux(.List) => .K ... </k>

    rule [allocObjectsAux]:
        <k> allocObjectsAux(ListItem(SCV:ScVal) L) 
         => allocObjectsAux(L)
         ~> allocObject(SCV)
            ...
        </k>

    rule [allocObjectsCollect]:
        <k> allocObjectsCollect(LENGTH) => .K ... </k> 
        <hostStack> STACK => ScVec(take(LENGTH, STACK)) : drop(LENGTH, STACK) </hostStack>

    syntax HostStack ::= drop(Int, HostStack)   [function, total, symbol(HostStack:drop)]
 // -------------------------------------------------------------------------------------
    rule drop(N, _ : S) => drop(N -Int 1, S)                requires N >Int 0
    rule drop(_,     S) => S                                [owise]
    
    syntax List ::= take(Int, HostStack)        [function, total, symbol(HostStack:take)]
 // -------------------------------------------------------------------------------------
    rule take(N, X : S) => ListItem(X) take(N -Int 1, S)    requires N >Int 0
    rule take(_,     _) => .List                            [owise]

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
              => loadObject(RELS {{ getIndex(VAL) }} orDefault HostVal(0))
                 ...
        </instrs>
        <relativeObjects> RELS </relativeObjects>
      requires isObject(VAL)
       andBool isRelativeObjectHandle(VAL)
       andBool 0 <=Int getIndex(VAL)
       andBool getIndex(VAL) <Int size(RELS)
```

## Call result handling

```k
    rule [callResult-empty]:
        <k> #callResult(.ValStack, _RELS) => .K ... </k>
    
    rule [callResult]:
        <k> #callResult(<i64> I : SS, RELS)
         => #callResult(SS, RELS)
         ~> HostVal2ScVal(HostVal(I), RELS)
            ...
        </k>
    
    syntax InternalCmd ::= HostVal2ScVal(HostVal, List)      [symbol(HostVal2ScVal)]
 // --------------------------------------------------------------------------
    rule [HostVal2ScVal-obj-abs]:
        <k> HostVal2ScVal(VAL, _RELS) => .K ... </k>
        <hostObjects> OBJS </hostObjects>
        <hostStack> S => OBJS {{ getIndex(VAL) }} orDefault Void : S </hostStack>
      requires isObject(VAL)
       andBool notBool(isRelativeObjectHandle(VAL))
       andBool getIndex(VAL) <Int size(OBJS)

    rule [HostVal2ScVal-obj-rel]:
        <k> HostVal2ScVal(VAL, RELS)
         => HostVal2ScVal(RELS {{ getIndex(VAL) }} orDefault HostVal(0), RELS)
            ...
        </k>
      requires isObject(VAL)
       andBool isRelativeObjectHandle(VAL)
       andBool getIndex(VAL) <Int size(RELS)
      [preserves-definedness]

    rule [HostVal2ScVal-small]:
        <k> HostVal2ScVal(VAL, _RELS) => .K ... </k>
        <hostStack> S => fromSmall(VAL) : S </hostStack>
      requires notBool isObject(VAL)
       andBool fromSmallValid(VAL)

```

```k
endmodule
```