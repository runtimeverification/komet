
```k
requires "soroban.md"
requires "cheatcodes.md"

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
                  | deployContract( from: Address, address: ContractId, wasmHash: Bytes, args: List )    [symbol(deployContract)]
                  | callTx( from: Address, to: Address, func: WasmString, args: List, result: ScVal)     [symbol(callTx)]


    syntax Steps ::= List{Step, ""} [symbol(kasmerSteps)]

    syntax String ::= str(WasmString)    [function, total]

endmodule

module KASMER
    imports SOROBAN
    imports CHEATCODES
    imports KASMER-SYNTAX-COMMON

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

//  ----------------------------------------------------------------------------
    rule [uploadWasm]:
        <k> uploadWasm(HASH, MOD) => .K ... </k>
        <contractCodes> MODS => MODS [ HASH <- MOD ] </contractCodes>
      requires notBool( HASH in_keys(MODS) )

    rule [uploadWasm-exists]:
        <k> uploadWasm(HASH, _MOD) => .K ... </k>
        <contractCodes> MODS </contractCodes>
      requires HASH in_keys(MODS)

 // -----------------------------------------------------------------------------------------------------------------------
    rule [deployContract-existing]:
        <k> deployContract(_OWNER, ADDR, _WASM_HASH, _ARGS) => #hostTrap ... </k>
        <contract>
           <contractId> ADDR </contractId>
           ...
        </contract>
      [priority(50)]

    syntax HostCell

    rule [deployContract]:
        <k> deployContract(OWNER, ADDR, WASM_HASH, ARGS)
         => allocObjects(ARGS)
         ~> callContractFromStack(OWNER, ADDR, #quoteUnparseWasmString("init"))
         ~> #resetHost
            ...
        </k>
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