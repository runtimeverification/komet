A quick example of a contract that can be ran with `ksoroban test`

You will need to have the stellar cli utils installed:
https://developers.stellar.org/docs/build/smart-contracts/getting-started/setup

And the soroban semantics kompiled:
```
kdist build soroban-semantics.llvm
```

And then (from this directory):

```sh
soroban contract build --out-dir output
ksoroban test output/test_storage.wasm
```

`ksoroban test` should exit successfully
