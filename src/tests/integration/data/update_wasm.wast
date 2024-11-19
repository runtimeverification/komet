
setExitCode(1)

uploadWasm( b"test-wasm",
(module
  (import "l" "6" (func $update_current_contract_wasm (param i64) (result i64)))
  (func $update (param i64) (result i64)
    local.get 0
    call $update_current_contract_wasm)
  (func $foo (result i64)
    i64.const 0)    ;; SCBool(false)
  (export "update" (func $update))
  (export "foo" (func $foo))
)
)

uploadWasm( b"test-wasm-2",
(module
  (import "l" "6" (func $update_current_contract_wasm (param i64) (result i64)))
  (func $foo (result i64)
    i64.const 1)    ;; SCBool(true)
  (export "foo" (func $foo))
)
)

setAccount(Account(b"test-account"), 9876543210)

deployContract(
  Account(b"test-account"),
  Contract(b"test-sc"),
  b"test-wasm"
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "foo",
  .List,
  SCBool(false)
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "update",
  ListItem(ScBytes(b"test-wasm-2")),
  Void
)


callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "foo",
  .List,
  SCBool(true)
)

setExitCode(0)