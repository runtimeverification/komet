
setExitCode(1)

uploadWasm( b"test-wasm",
(module $test_wasm
  (import "i" "9" (func $obj_from_u256_pieces (param i64 i64 i64 i64) (result i64)))
  (import "i" "a" (func $u256_val_from_be_bytes (param i64) (result i64)))
  (import "i" "b" (func $u256_val_to_be_bytes   (param i64) (result i64)))
  (import "i" "c" (func $obj_to_u256_hi_hi (param i64) (result i64)))
  (import "i" "d" (func $obj_to_u256_hi_lo (param i64) (result i64)))
  (import "i" "e" (func $obj_to_u256_lo_hi (param i64) (result i64)))
  (import "i" "f" (func $obj_to_u256_lo_lo (param i64) (result i64)))
  (func $roundtrip (param i64) (result i64)
    (call $obj_from_u256_pieces
      (call $obj_to_u256_hi_hi (local.get 0))
      (call $obj_to_u256_hi_lo (local.get 0))
      (call $obj_to_u256_lo_hi (local.get 0))
      (call $obj_to_u256_lo_lo (local.get 0))
    )
  )
  (func $roundtripBytes (param i64) (result i64)
    (call $u256_val_from_be_bytes
      (call $u256_val_to_be_bytes (local.get 0))
    )
  )
  (func $roundtripBytesInv (param i64) (result i64)
    (call $u256_val_to_be_bytes
      (call $u256_val_from_be_bytes (local.get 0))
    )
  )
  (export "roundtrip" (func $roundtrip))
  (export "roundtripBytes" (func $roundtripBytes))
  (export "roundtripBytesInv" (func $roundtripBytesInv))
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
  ListItem(U256(0)),
  U256(0)
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "roundtrip",
  ListItem(U256(100000000)),
  U256(100000000)
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "roundtrip",
  ListItem(U256(115792089237316195423570985008687907853269984665640564039457584007913129639935)), ;; MAX U256
  U256(115792089237316195423570985008687907853269984665640564039457584007913129639935)
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "roundtripBytes",
  ListItem(U256(0)),
  U256(0)
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "roundtripBytes",
  ListItem(U256(100000000)),
  U256(100000000)
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "roundtripBytes",
  ListItem(U256(115792089237316195423570985008687907853269984665640564039457584007913129639935)), ;; MAX U256
  U256(115792089237316195423570985008687907853269984665640564039457584007913129639935)
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "roundtripBytesInv",
  ListItem(ScBytes(b"abcdefghabcdefghabcdefghabcdefgh")), ;; 32 bytes
  ScBytes(b"abcdefghabcdefghabcdefghabcdefgh")
)

setExitCode(0)