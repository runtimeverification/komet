# Wasm and Host Synchronization

The Soroban node operates with two main cells: `<k>` for VM commands
and `<instrs>` for Wasm instructions. Execution begins with `<k>`; and when a
contract is invoked, control switches to `<instrs>` for the contract's Wasm code.
If the contract execution concludes or encounters a failure, the control returns to `<k>`.
Additionally, certain host functions, such as token transfers and contract-to-contract calls, 
necessitate command execution. In these cases, control temporarily shifts to `<k>` until
these operations are completed.
To implement synchronization between the `<k>` and `<instrs>` cells, `#endWasm`, `#waitWasm`,
and `#waitCommands` statements are utilized.

```k
requires "configuration.md"

module SWITCH-SYNTAX

    syntax InternalCmd ::= "#endWasm"           [symbol(#endWasm)]
                         | "#waitWasm"          [symbol(#waitWasm)]

    syntax InternalInstr ::= "#waitCommands"    [symbol(#waitCommands)]

    syntax ValStack

endmodule

module SWITCH
    imports SWITCH-SYNTAX
    imports CONFIG-OPERATIONS
```

- `#endWasm` marks the end of the execution of Wasm instructions within a contract call.
  It initiates the context switch from the current call to its parent call, and captures the Wasm
  stack after the function execution.

```k
    rule [endWasm-error]:
        <k> #endWasm 
         => popCallState
         ~> popWorldState
            ...
        </k>
        <instrs> .K </instrs>
        <hostStack> (Error(_,_) #as ERR) : _ => ERR : .HostStack </hostStack>
      [priority(40)]

    rule [endWasm]:
        <k> #endWasm 
         => popCallState
         ~> dropWorldState
         ~> #callResult(STACK, RELS)
            ...
        </k>
        <instrs> .K </instrs>
        <relativeObjects> RELS </relativeObjects>
        <valstack> STACK </valstack>
      [priority(50)]

    rule [endWasm-trap]:
        <k> #endWasm ... </k>
        <instrs> trap => .K </instrs>
        <hostStack> S => Error(ErrContext, InvalidAction) : S </hostStack>

```

- `#waitWasm` is used after the `newWasmInstance` command to wait for the
  completion of the Wasm module initialization. Unlike #endWasm, it doesn't manipulate the VM output
  or call stack; it simply waits for the VM to finish its execution.

```k
    rule [waitWasm]:
        <k> #waitWasm => .K ... </k>
        <instrs> .K </instrs>
```

- `#waitCommands` is utilized when an instruction initiates a command. Placed in front of the `<instrs>` cell,
  it directs execution to continue from the `<k>` cell until an `#endWasm` command is encountered.

```k
    rule [waitCommands]:
        <instrs> #waitCommands => .K ... </instrs>
        <k> #endWasm ... </k>
```

```k
endmodule
```