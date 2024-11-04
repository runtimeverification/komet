
setExitCode(1)

uploadWasm( b"test-wasm",
(module $test_wasm
  (import "i" "_" (func $obj_from_u64 (param i64) (result i64)))
  (import "i" "1" (func $obj_from_i64 (param i64) (result i64)))
  (import "i" "6" (func $obj_from_i128_pieces (param i64 i64) (result i64)))
  (import "i" "7" (func $obj_to_i128_lo64 (param i64) (result i64)))
  (import "i" "8" (func $obj_to_i128_hi64 (param i64) (result i64)))
  (func $lo (param i64) (result i64)
    local.get 0
    call $obj_to_i128_lo64
    call $obj_from_u64
  )
  (func $hi (param i64) (result i64)
    local.get 0
    call $obj_to_i128_hi64
    call $obj_from_i64
  )
  (func $roundtrip (param i64) (result i64)
    (call $obj_from_i128_pieces
      (call $obj_to_i128_hi64 (local.get 0))
      (call $obj_to_i128_lo64 (local.get 0))
    )
  )
  (export "lo" (func $lo))
  (export "hi" (func $hi))
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
  "lo",
  ;; i128::MAX
  ListItem(I128(2 ^Int 127 -Int 1)),
  U64(2 ^Int 64 -Int 1)
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "lo",
  ListItem(I128(0 -Int 2 ^Int 127)), ;; i128::MIN
  U64(0)
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "lo",
  ListItem(I128(0)),
  U64(0)
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "lo",
  ListItem(I128(-1)),
  U64(2 ^Int 64 -Int 1)
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "hi",
  ;; 2^127-1 (i128::MAX)
  ListItem(I128(2 ^Int 127 -Int 1)),
  I64(9223372036854775807)
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "hi",
  ListItem(I128(0 -Int 2 ^Int 127)), ;; i128::MIN
  I64(0 -Int 2 ^Int 63)
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "hi",
  ListItem(I128(0)),
  I64(0)
)


callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "hi",
  ListItem(I128(-1)),
  I64(-1)
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "hi",
  ListItem(I128(-2)),
  I64(-1)
)


callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "roundtrip",
  ListItem(I128(0)),
  I128(0)
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "roundtrip",
  ListItem(I128(170141183460469231731687303715884105727)),
  I128(170141183460469231731687303715884105727)
)


callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "roundtrip",
  ListItem(I128(-1)),
  I128(-1)
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "roundtrip",
  ListItem(I128(-170141183460469231731687303715884105727)),
  I128(-170141183460469231731687303715884105727)
)


setExitCode(0)