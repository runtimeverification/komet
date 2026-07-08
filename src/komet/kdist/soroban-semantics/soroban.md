

```k
requires "configuration.md"
requires "switch.md"
requires "host/hostfuns.md"

module SOROBAN-SYNTAX
    imports HOST-OBJECT-SYNTAX

    syntax InternalCmd ::= callContract ( Address, ContractId, String, List ) [symbol(callContractString), function, total]

endmodule


module SOROBAN
    imports SOROBAN-SYNTAX
    imports CONFIG-OPERATIONS
    imports SWITCH
    imports HOSTFUNS
```

## Contract Call

Invoking a contract is split across three commands that hand off to one another:

- `callContract` orchestrates the call: saves the caller's state and arranges for it to be restored (or discarded)
  once the callee is done.
- `callContractAux` resolves the callee's code and instantiates a fresh Wasm module for it.
- `mkCall` performs the actual invocation against that instance.

Once the callee's Wasm finishes executing, `#endWasm` (see `switch.md`) switches control back to `<k>` and restores
the caller.

**WARNING**: `trace-callContract` in `tracing.md` duplicates the transition of `callContract` below to log a call's
start. If you change this rule, you must update that too, or tracing will silently drift out of sync with the real
semantics.

```k

    syntax InternalCmd ::= callContract    ( Address, ContractId, WasmString, List ) [symbol(callContractWasmString)]
                         | callContractAux ( Address, ContractId, WasmString, List ) [symbol(callContractAux)]
 // -------------------------------------------------------------------------------------
    rule callContract(FROM, TO, FUNCNAME:String, ARGS)
      => callContract(FROM, TO, #quoteUnparseWasmString(FUNCNAME), ARGS)

    // Orchestrates a contract call: saves the caller's world/call state so it can be restored afterwards,
    // resets the active call state for the callee, delegates to `callContractAux` to set up and invoke the
    // callee, and queues `#endWasm` to switch back to `<k>` and restore the caller once the callee finishes.
    rule [callContract]:
        <k> callContract(FROM, TO, FUNCNAME:WasmStringToken, ARGS)
         => pushWorldState
         ~> pushCallState
         ~> resetCallstate
         ~> callContractAux(FROM, TO, FUNCNAME, ARGS)
         ~> #endWasm
            ...
        </k>

    // Looks up the callee's code and instantiates a fresh Wasm module for it, then delegates to `mkCall`
    // to actually invoke the requested function once that instance exists.
    rule [callContractAux]:
        <k> callContractAux(FROM, TO, FUNCNAME, ARGS)
         => newWasmInstance(TO, CODE)
         ~> mkCall(FROM, TO, FUNCNAME, ARGS)
            ...
        </k>
        <contract>
          <contractId> TO </contractId>
          <wasmHash> HASH </wasmHash>
          ...
        </contract>
        <contractCode>
          <codeHash> HASH </codeHash>
          <codeWasm> CODE </codeWasm>
          ...
        </contractCode>
        <instrs> .K </instrs>

    // rule [callContractAux-not-contract]:
    //     <k> callContractAux(_, TO, _:WasmString, _)
    //             => #exception(b"not a contract: " +Bytes TO) ...
    //     </k>
    //     <account>
    //       <address> TO </address>
    //       <code> .Code </code>
    //       ...
    //     </account>
    //     <instrs> .K </instrs>

    syntax WasmCell
    syntax InternalCmd ::= newWasmInstance   (ContractId, ModuleDecl)     [symbol(newWasmInstance)]
                         | newWasmInstanceAux(ContractId, ModuleDecl)     [symbol(newWasmInstanceAux)]

    rule [newWasmInstance]:
        <k> newWasmInstance(ADDR, CODE) => newWasmInstanceAux(ADDR, CODE) ... </k>
        <instrs> .K </instrs>

    rule [newWasmInstanceAux]:
        <k> newWasmInstanceAux(_, CODE) => #waitWasm ~> setContractModIdx ... </k>
        ( _:WasmCell => <wasm>
          <instrs> initContractModule(CODE) </instrs>
          ...
        </wasm>)
      // TODO: It is fairly hard to check that this rule preserves definedness.
      // However, if that's not the case, then this axiom is invalid. We should
      // figure this out somehow. Preferably, we should make initContractModule
      // a total function. Otherwise, we should probably make a
      // `definedInitContractModule` function that we should use in the requires
      // clause.

    syntax InternalCmd ::= "setContractModIdx"
 // ------------------------------------------------------
    rule [setContractModIdx]:
        <k> setContractModIdx => .K ... </k>
        <contractModIdx> _ => NEXTIDX -Int 1 </contractModIdx>
        <nextModuleIdx> NEXTIDX </nextModuleIdx>
        <instrs> .K </instrs>

    syntax K ::= initContractModule(ModuleDecl)   [function]
 // ------------------------------------------------------------------------
    rule initContractModule((module _:OptionalId _:Defns):ModuleDecl #as M)
      => sequenceStmts(text2abstract(M .Stmts))

    rule initContractModule(M:ModuleDecl) => M              [owise]


    syntax InternalCmd ::= mkCall( Address, ContractId, WasmString, List )  [symbol(mkCall)]
 // ------------------------------------------------------------------------
    // Performs the actual invocation once the callee's Wasm instance exists: populates the (already-reset)
    // call state with caller/callee/function/args, resolves FUNCNAME to a function index in the instance's
    // exports, and sets `<instrs>` to push the (HostVal) args and invoke that function.
    rule [mkCall]:
        <k> mkCall(FROM, TO, FUNCNAME:WasmStringToken, ARGS) => .K ... </k>
        <callState>
          <caller> _ => FROM </caller>
          <callee> _ => TO   </callee>
          <function> _ => FUNCNAME </function>
          <args> _ => ARGS </args>
          <wasm>
            <instrs> .K => pushArgs(ARGS) ~> (invoke (FUNCADDRS {{ FUNCIDX }} orDefault -1 )) </instrs>
            <moduleInst>
              <modIdx> MODIDX </modIdx>
              <exports> ... FUNCNAME |-> FUNCIDX:Int ... </exports>
              <funcAddrs> FUNCADDRS </funcAddrs>
              ...
            </moduleInst>
            ...
          </wasm>
          <contractModIdx> MODIDX:Int </contractModIdx>
          ...
        </callState>
        requires isListIndex(FUNCIDX, FUNCADDRS)
      [priority(60)]

    syntax InternalInstr ::= pushArgs(List)      [symbol(pushArgs)]
                           | pushArg(HostVal)    [symbol(pushArg)]
 // ---------------------------------------------------------------------
    rule [pushArgs-empty]:
        <instrs> pushArgs(.List) => .K ... </instrs>

    rule [pushArgs]:
        <instrs> pushArgs(ListItem(ARG:HostVal) ARGS) => pushArg(ARG) ~> pushArgs(ARGS) ... </instrs>
    
    rule [pushArg-not-obj]:
        <instrs> pushArg(VAL) => VAL ... </instrs>
      requires notBool isObject(VAL)

    rule [pushArg-obj-rel]:
        <instrs> pushArg(VAL) => trap ... </instrs>
      requires isObject(VAL)
       andBool isRelativeObjectHandle(VAL) // there should not be any relative objects in this context

    rule [pushArg-obj-abs]:
        <instrs> pushArg(VAL) 
              => fromHandleAndTag(indexToHandle(size(RELS), true) , getTag(VAL)) 
                 ...
        </instrs>
        <relativeObjects> RELS => RELS ListItem(VAL) </relativeObjects>
      requires isObject(VAL)
       andBool (notBool isRelativeObjectHandle(VAL))

    rule [push-HostVal]:
        <instrs> HostVal(I) => i64.const I ... </instrs>

```


```k
endmodule
```
