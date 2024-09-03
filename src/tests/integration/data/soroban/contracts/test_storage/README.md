A quick example of a contract that can be ran with `komet test`

You will need to have the stellar cli utils installed:
https://developers.stellar.org/docs/build/smart-contracts/getting-started/setup

And the soroban semantics kompiled:
```
kdist build soroban-semantics.llvm
```

And then (from this directory):

```sh
soroban contract build --out-dir output
komet test output/test_storage.wasm
```

`komet test` should exit successfully
