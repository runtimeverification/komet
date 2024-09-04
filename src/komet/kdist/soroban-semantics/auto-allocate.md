Auto Allocate Host Modules
==========================

When `AUTO-ALLOCATE` is imported, an new module will be automatically created and registered whenever necessary to resolve an import.
This makes it possible to implement host modules easily in K.
Accessing the import will result in an instruction being left on the `instrs` cell that can't be resolved in the regular Wasm semantics.
Instead, the embedder can add rules for handling the host import.

Currently, only function imports are supported.
Calling an imported host function will result in `hostCall(MODULE_NAME, FUNCTION_NAME, FUNCTION_TYPE)` being left on the `instrs` cell.

```k
requires "wasm-semantics/wasm-text.md"

module WASM-AUTO-ALLOCATE
    imports WASM-DATA-TOOLS
    imports WASM-TEXT

    syntax Stmt ::= "newEmptyModule" WasmString
 // -------------------------------------------
    rule <instrs> newEmptyModule MODNAME => .K ... </instrs>
         <moduleRegistry> MR => MR [ MODNAME <- NEXT ] </moduleRegistry>
         <nextModuleIdx> NEXT => NEXT +Int 1 </nextModuleIdx>
         <moduleInstances> ( .Bag => <moduleInst> <modIdx> NEXT </modIdx> ... </moduleInst>) ... </moduleInstances>

    syntax Stmts ::=  autoAllocModules ( ModuleDecl, Map ) [function]
                   | #autoAllocModules ( Defns     , Map ) [function]
 // -----------------------------------------------------------------
    rule  autoAllocModules(#module(... importDefns:IS), MR) => #autoAllocModules(IS, MR)
```

In helper function `#autoAllocModules`, the module registry map is passed along to check if the module being imported from is present.
It is treated purely as a key set -- the actual stored values are not used or stored anywhere.

```k
    rule #autoAllocModules(.Defns, _) => .Stmts
    rule #autoAllocModules((#import(MOD, _, _) DS) => DS, MR) requires MOD in_keys(MR)
    rule #autoAllocModules((#import(MOD, _, _) DS), MR)
      => newEmptyModule MOD #autoAllocModules(DS, MR [MOD <- -1])
      requires notBool MOD in_keys(MR)

    rule <instrs> MD:ModuleDecl
               => sequenceStmts(autoAllocModules(MD, MR))
               ~> MD
              ...
         </instrs>
         <moduleRegistry> MR </moduleRegistry>
      requires autoAllocModules(MD, MR) =/=K .Stmts
      [priority(10)]

    syntax Instr ::= hostCall(String, String, FuncType)
 // ---------------------------------------------------
    rule <instrs> (.K => allocfunc(HOSTMOD, NEXTADDR, TYPE, [ .ValTypes ], hostCall(wasmString2StringStripped(MOD), wasmString2StringStripped(NAME), TYPE) .Instrs, #meta(... id: String2Identifier("$auto-alloc:" +String #parseWasmString(MOD) +String ":" +String #parseWasmString(NAME) ), localIds: .Map )))
               ~> #import(MOD, NAME, #funcDesc(... type: TIDX))
              ...
         </instrs>
         <curModIdx> CUR </curModIdx>
         <moduleInst>
           <modIdx> CUR </modIdx>
           <types> ... TIDX |-> TYPE ... </types>
           ...
        </moduleInst>
        <nextFuncAddr> NEXTADDR => NEXTADDR +Int 1 </nextFuncAddr>
        <moduleRegistry> ... MOD |-> HOSTMOD ... </moduleRegistry>
        <moduleInst>
          <modIdx> HOSTMOD </modIdx>
          <exports> EXPORTS => EXPORTS [NAME <- NEXTFUNC ] </exports>
          <funcAddrs> FS => setExtend(FS, NEXTFUNC, NEXTADDR, -1) </funcAddrs>
          <nextFuncIdx> NEXTFUNC => NEXTFUNC +Int 1 </nextFuncIdx>
          <nextTypeIdx> NEXTTYPE => NEXTTYPE +Int 1 </nextTypeIdx>
          <types> TYPES => TYPES [ NEXTTYPE <- TYPE ] </types>
          ...
        </moduleInst>
      requires notBool NAME in_keys(EXPORTS)

    syntax String ::= wasmString2StringStripped ( WasmString ) [function]
                    | #stripQuotes ( String ) [function]
 // ----------------------------------------------------
    rule wasmString2StringStripped(WS) => #stripQuotes(#parseWasmString(WS))

    rule #stripQuotes(S) => replaceAll(S, "\"", "")

endmodule
```
