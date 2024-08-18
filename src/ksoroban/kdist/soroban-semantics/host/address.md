# ADDRESS

```k
requires "../configuration.md"
requires "../switch.md"
requires "../wasm-ops.md"
requires "integer.md"

module HOST-ADDRESS
    imports CONFIG-OPERATIONS
    imports WASM-OPERATIONS
    imports HOST-INTEGER
    imports SWITCH-SYNTAX

```

## require_auth

```k
    // TODO This is just a placeholder, as the auth system is out of scope for now.
    // This function needs to be properly implemented to handle the authorization.
    rule [hostfun-require-auth]:
        <instrs> hostCall ( "a" , "0" , [ i64  .ValTypes ] -> [ i64  .ValTypes ] )
              => toSmall(Void)
                 ...
        </instrs>
        <locals>
          0 |-> < i64 > _      // Address
        </locals>

endmodule
```