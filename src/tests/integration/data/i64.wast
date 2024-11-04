
setExitCode(1)

uploadWasm( b"test-wasm",
(module $test_wasm
  (import "i" "1" (func $obj_from_i64 (param i64) (result i64)))
  (import "i" "2" (func $obj_to_i64 (param i64) (result i64)))
  (func $roundtrip (param i64) (result i64)
    (call $obj_from_i64
      (call $obj_to_i64 (local.get 0))
    )
  )
  (export "roundtrip" (func $roundtrip))
))

setAccount(Account(b"test-account"), 9876543210)

deployContract(
  Account(b"test-account"),
  Contract(b"test-sc"),
  b"test-wasm"
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "roundtrip",
  ListItem(I64(1)),
  I64(1)
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "roundtrip",
  ListItem(I64(0)),
  I64(0)
)


callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "roundtrip",
  ListItem(I64(-1)),
  I64(-1)
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "roundtrip",
  ListItem(I64(2 ^Int 63 -Int 1)),
  I64(2 ^Int 63 -Int 1)
)


callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "roundtrip",
  ListItem(I64(0 -Int 2 ^Int 63)),
  I64(0 -Int 2 ^Int 63)
)

setExitCode(0)