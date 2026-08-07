
```k
requires "soroban.md"
requires "cheatcodes.md"
requires "komet-lemmas.md"
```

```k-tracing
requires "tracing.md"
```

```k
module KASMER-SYNTAX
  imports WASM-TEXT-SYNTAX
  imports WASM-TEXT-COMMON-SYNTAX
  imports KASMER-SYNTAX-COMMON
endmodule

module KASMER-SYNTAX-COMMON
    // imports WASM
    imports HOST-OBJECT-SYNTAX

    syntax ModuleDecl
    syntax WasmString

    syntax Step ::= setExitCode(Int)                                                                     [symbol(setExitCode)]
                  | setAccount( address: AccountId, balance: Int)                                        [symbol(setAccount)]
                  | uploadWasm(Bytes, ModuleDecl)                                                        [symbol(uploadWasm)]
                  | deployContract( from: Address, address: ContractId, wasmHash: Bytes )                [symbol(deployContract)]
                  | callTx( from: Address, to: Address, func: WasmString, args: List, result: ScVal)     [symbol(callTx)]


    syntax Steps ::= List{Step, ""} [symbol(kasmerSteps)]

    syntax String ::= str(WasmString)    [function, total]

endmodule

module KASMER
    imports SOROBAN
    imports CHEATCODES
    imports KASMER-SYNTAX-COMMON
    imports KSOROBAN-LEMMAS
```

```k-tracing
    imports TRACING
```

```k

    configuration
      <kasmer>
        <program> $PGM:Steps </program>
        <soroban/>
        <exitCode exit=""> 1 </exitCode>
      </kasmer>

    rule str(WS) => unescape(#parseWasmString(WS))
    rule str(.WasmString) => ""

    rule [load-program]:
        <program> (_S:Step _SS:Steps) #as PGM => .Steps </program>
        <k> _ => PGM </k>

    rule [steps-empty]:
        <k> .Steps => .K </k>
        <instrs> .K </instrs>

    rule [steps-seq]:
        <k> S:Step SS:Steps => S ~> SS ... </k>
        <instrs> .K </instrs>

    syntax Step ::= "#hostTrap"    [symbol(#hostTrap)]

 // --------------------------------------------------------
    rule [setExitCode]:
        <k> setExitCode(I) => .K ... </k>
        <exitCode> _ => I </exitCode>
        <instrs> .K </instrs>


 // -----------------------------------------------------------------------------------
    rule [setAccount-existing]:
        <k> setAccount(ADDR, BAL) => .K ... </k>
        <account>
           <accountId> ADDR </accountId>
           <balance> _ => BAL </balance>
           ...
        </account>
      [priority(50)]

    rule [setAccount-new]:
        <k> setAccount(ADDR, BAL) => .K ... </k>
        ( .Bag =>
          <account>
            <accountId> ADDR </accountId>
            <balance> BAL </balance>
          </account>
        )
      [priority(55)]
```

When tracing is enabled these two rules shadow the pair above, additionally mirroring the
balance into the `<accountBalances>` map so the ledger baseline record can serialize it (the
`<accounts>` cell collection cannot be passed to a function — see `tracing.md`'s
*Trace Format*). `setAccount` is the only rule in the semantics that writes a balance, so
these are the complete set of write sites.

They live here rather than in `tracing.md` because `setAccount` is declared in this module,
and `KASMER` imports `TRACING`, not the other way round.

**WARNING**: they duplicate the transitions of `setAccount-existing`/`setAccount-new` above,
preserving their relative order (an existing account is updated before a new one is created).
Keep them in sync.

```k-tracing
    rule [tracing-setAccount-existing]:
        <k> setAccount(ADDR, BAL) => .K ... </k>
        <account>
           <accountId> ADDR </accountId>
           <balance> _ => BAL </balance>
           ...
        </account>
        <ioDir> PATH </ioDir>
        <accountBalances> AB => AB [ ADDR <- BAL ] </accountBalances>
      requires PATH =/=String ""
      [priority(20)]

    rule [tracing-setAccount-new]:
        <k> setAccount(ADDR, BAL) => .K ... </k>
        ( .Bag =>
          <account>
            <accountId> ADDR </accountId>
            <balance> BAL </balance>
          </account>
        )
        <ioDir> PATH </ioDir>
        <accountBalances> AB => AB [ ADDR <- BAL ] </accountBalances>
      requires PATH =/=String ""
      [priority(25)]
```

```k
//  ----------------------------------------------------------------------------

    rule [uploadWasm-exists]:
        <k> uploadWasm(HASH, _MOD) => .K ... </k>
        <codeHash> HASH </codeHash>  
      
    rule [uploadWasm]:
        <k> uploadWasm(HASH, MOD) => .K ... </k>
        (.Bag => <contractCode>
          <codeHash> HASH </codeHash>
          <codeWasm> MOD </codeWasm>
          ...
        </contractCode>)
      [priority(51)]

 // -----------------------------------------------------------------------------------------------------------------------
    rule [deployContract-existing]:
        <k> deployContract(_OWNER, ADDR, _WASM_HASH) => #hostTrap ... </k>
        <contract>
           <contractId> ADDR </contractId>
           ...
        </contract>
      [priority(50)]

    syntax HostCell

    rule [deployContract]:
        <k> deployContract(_OWNER, ADDR, WASM_HASH) => .K ... </k>
        ( .Bag =>
          <contract>
            <contractId> ADDR </contractId>
            <wasmHash> WASM_HASH </wasmHash>
            ...
          </contract>
        )
      [priority(55)]

    syntax InternalCmd ::= callContractFromStack(Address, ContractId, WasmString)      [symbol(callContractFromStack)]
 // -------------------------------------------------------------------------------------------------------
    rule [callContractFromStack]:
        <k> callContractFromStack(FROM, TO, FUNC) => callContract(FROM, TO, FUNC, ARGS) ... </k>
        <hostStack> ARGS : S => S </hostStack>

 // --------------------------------------------------------------------------------------------------------------
    rule [callTx]:
        <k> callTx(FROM, TO, FUNC, ARGS, RESULT)
         => allocObjects(ARGS)
         ~> callContractFromStack(FROM, TO, FUNC)
         ~> expectResult(RESULT)
         ~> #resetHost
            ...
        </k>
        // clear the host cell before contract calls
        (_:HostCell => <host> <hostStack> .HostStack </hostStack> ... </host>)

    syntax InternalCmd ::= expectResult(ScVal)      [symbol(expectResult)]

    rule [expectResult]:
        <k> expectResult(SCVAL) => .K ... </k>
        <hostStack> SCVAL : .HostStack </hostStack>

    syntax InternalCmd ::= "#resetHost"   [symbol(#resetHost)]
 // --------------------------------------------------------------
    rule [resetHost]:
        <k> #resetHost => .K ... </k>
        (_:HostCell => <host> <hostStack> .HostStack </hostStack> ... </host>)

endmodule
```
