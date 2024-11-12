
setExitCode(1)

uploadWasm( b"test-wasm",
(module
  (import "m" "_" (func $new                     (result i64)))
  (import "m" "0" (func $put (param i64 i64 i64) (result i64)))
  (import "m" "1" (func $get (param i64 i64)     (result i64)))
  (import "m" "2" (func $del (param i64 i64)     (result i64)))
  (import "m" "3" (func $len (param i64)         (result i64)))
  (import "m" "4" (func $has (param i64 i64)     (result i64)))

  (export "new" (func $new))
  (export "put" (func $put))
  (export "get" (func $get))
  (export "del" (func $del))
  (export "len" (func $len))
  (export "has" (func $has))
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
  "new",
  .List,
  ScMap(.Map)
)

setExitCode(0)