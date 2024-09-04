
setExitCode(1)

uploadWasm( b"test-wasm",
(module
  (import "v" "_" (func $vec_new (result i64)))
  (func $create_vec (result i64)
    call $vec_new)
  (export "create_vec" (func $create_vec)))
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
  "create_vec",
  .List,
  ScVec(.List)
)

setExitCode(0)