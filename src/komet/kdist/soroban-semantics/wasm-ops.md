
```k
requires "configuration.md"
module WASM-OPERATIONS
    imports CONFIG-OPERATIONS
```

## Memory Operations

```k
    syntax InternalInstr ::= #memStore ( offset: Int , bytes: Bytes )
 // -----------------------------------------------------------------
    rule [memStore]:
        <instrs> #memStore(OFFSET, BS) => .K ... </instrs>
        <contractModIdx> MODIDX:Int </contractModIdx>
        <moduleInst>
          <modIdx> MODIDX </modIdx>
          <memAddrs> 0 |-> MEMADDR </memAddrs>
          ...
        </moduleInst>
        <memInst>
          <mAddr> MEMADDR </mAddr>
          <msize> SIZE </msize>
          <mdata> DATA => #setBytesRange(DATA, OFFSET, BS) </mdata>
          ...
        </memInst>
      requires #signed(i32 , OFFSET) +Int lengthBytes(BS) <=Int (SIZE *Int #pageSize())
       andBool 0 <=Int #signed(i32 , OFFSET)
      [preserves-definedness] // setBytesRange total, MEMADDR key existed prior in <mems> map

    rule [memStore-trap]:
        <instrs> #memStore(_, _) => trap ... </instrs>
      [owise]

    syntax InternalInstr ::= #memLoad ( offset: Int , length: Int )
 // ---------------------------------------------------------------
    rule [memLoad-zero-length]:
        <instrs> #memLoad(_, 0) => .K ... </instrs>
        <hostStack> STACK => .Bytes : STACK </hostStack>

    rule [memLoad]:
         <instrs> #memLoad(OFFSET, LENGTH) => .K ... </instrs>
         <hostStack> STACK => #getBytesRange(DATA, OFFSET, LENGTH) : STACK </hostStack>
         <contractModIdx> MODIDX:Int </contractModIdx>
         <moduleInst>
           <modIdx> MODIDX </modIdx>
           <memAddrs> 0 |-> MEMADDR </memAddrs>
           ...
         </moduleInst>
         <memInst>
           <mAddr> MEMADDR </mAddr>
           <msize> SIZE </msize>
           <mdata> DATA </mdata>
           ...
         </memInst>
      requires #signed(i32 , LENGTH) >Int 0
       andBool #signed(i32 , OFFSET) >=Int 0
       andBool #signed(i32 , OFFSET) +Int #signed(i32 , LENGTH) <=Int (SIZE *Int #pageSize())

    rule [memLoad-trap]:
        <instrs> #memLoad(_, _) => trap ... </instrs>
      [owise]
```

## Host function operations

- `hostCallAux(MOD,FUNC)`: Helper instruction for implementing host functions with arguments already loaded onto the
  host stack. Reduces the need for defining `InternalInstr`s for host functions. Reduces the need to define custom
  `InternalInstr` productions for each host function. The `hostCall-default` rule provides default behavior for host
  functions without complex argument handling, allowing `hostCallAux` to streamline the process further.
- `loadArgs(N)`: Loads the first `N` arguments onto the host stack using `loadObject` starting from the last argument.
  This positions the first argument at the top of the stack at the end.

```k
    syntax InternalInstr ::= hostCallAux(String, String)        [symbol(hostCallAux)]
                           | loadArgs(Int)                      [symbol(loadArgs)] 

    // Default implementation for `hostCall`. Loads the arguments to the host stack using `loadObject`
    rule [hostCall-default]:
        <instrs> hostCall(MOD, FUNC, [ _ARGS ] -> [ _RET ])
              => loadArgs(size(LOCALS))
              ~> hostCallAux(MOD, FUNC)
                 ...
        </instrs>
        <locals> LOCALS </locals>
      [owise]

    rule [loadArgs-empty]:
        <instrs> loadArgs(0) => .K ... </instrs>
    
    rule [loadArgs]:
        <instrs> loadArgs(I)
              => loadObject(HostVal(X))
              ~> loadArgs(I -Int 1)
                 ...
        </instrs>
        <locals> ... (I -Int 1) |-> <i64> X ... </locals>

```

```k
endmodule
```