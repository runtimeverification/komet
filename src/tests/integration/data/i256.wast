setExitCode(1)

uploadWasm( b"test-wasm",
(module $test_wasm
  (import "i" "g" (func $obj_from_i256_pieces (param i64 i64 i64 i64) (result i64)))
  (import "i" "h" (func $i256_val_from_be_bytes (param i64) (result i64)))
  (import "i" "i" (func $i256_val_to_be_bytes   (param i64) (result i64)))
  (import "i" "j" (func $obj_to_i256_hi_hi (param i64) (result i64)))
  (import "i" "k" (func $obj_to_i256_hi_lo (param i64) (result i64)))
  (import "i" "l" (func $obj_to_i256_lo_hi (param i64) (result i64)))
  (import "i" "m" (func $obj_to_i256_lo_lo (param i64) (result i64)))
  (import "i" "v" (func $i256_add        (param i64 i64) (result i64)))
  (import "i" "w" (func $i256_sub        (param i64 i64) (result i64)))
  (import "i" "x" (func $i256_mul        (param i64 i64) (result i64)))
  (import "i" "y" (func $i256_div        (param i64 i64) (result i64)))
  (import "i" "z" (func $i256_rem_euclid (param i64 i64) (result i64)))

  ;; Split a value into its four 64-bit words and reassemble it.
  (func $roundtrip (param i64) (result i64)
    (call $obj_from_i256_pieces
      (call $obj_to_i256_hi_hi (local.get 0))
      (call $obj_to_i256_hi_lo (local.get 0))
      (call $obj_to_i256_lo_hi (local.get 0))
      (call $obj_to_i256_lo_lo (local.get 0))
    )
  )
  (func $roundtripBytes (param i64) (result i64)
    (call $i256_val_from_be_bytes
      (call $i256_val_to_be_bytes (local.get 0))
    )
  )
  (func $roundtripBytesInv (param i64) (result i64)
    (call $i256_val_to_be_bytes
      (call $i256_val_from_be_bytes (local.get 0))
    )
  )
  ;; The four extractors on their own, widened to i256 so the result is checkable.
  (func $hiHi (param i64) (result i64)
    (call $obj_from_i256_pieces
      (i64.const 0) (i64.const 0) (i64.const 0)
      (call $obj_to_i256_hi_hi (local.get 0))
    )
  )
  (func $loLo (param i64) (result i64)
    (call $obj_from_i256_pieces
      (i64.const 0) (i64.const 0) (i64.const 0)
      (call $obj_to_i256_lo_lo (local.get 0))
    )
  )
  (func $add (param i64 i64) (result i64) (call $i256_add        (local.get 0) (local.get 1)))
  (func $sub (param i64 i64) (result i64) (call $i256_sub        (local.get 0) (local.get 1)))
  (func $mul (param i64 i64) (result i64) (call $i256_mul        (local.get 0) (local.get 1)))
  (func $div (param i64 i64) (result i64) (call $i256_div        (local.get 0) (local.get 1)))
  (func $rem (param i64 i64) (result i64) (call $i256_rem_euclid (local.get 0) (local.get 1)))

  (export "roundtrip" (func $roundtrip))
  (export "roundtripBytes" (func $roundtripBytes))
  (export "roundtripBytesInv" (func $roundtripBytesInv))
  (export "hiHi" (func $hiHi))
  (export "loLo" (func $loLo))
  (export "add" (func $add))
  (export "sub" (func $sub))
  (export "mul" (func $mul))
  (export "div" (func $div))
  (export "rem" (func $rem))
))

setAccount(Account(b"test-account"), 9876543210)

deployContract(
  Account(b"test-account"),
  Contract(b"test-sc"),
  b"test-wasm"
)

;; ---------------------------------------------------------------------------
;; obj_from_i256_pieces / obj_to_i256_*  (i.g, i.j, i.k, i.l, i.m)
;;
;; 0, 1 and -1 are small values (|x| < 2^55, tag 13); the rest are I256 objects
;; (tag 71), so both HostVal representations are covered.
;; ---------------------------------------------------------------------------

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "roundtrip",
  ListItem(I256(0)),
  I256(0)
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "roundtrip",
  ListItem(I256(1)),
  I256(1)
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "roundtrip",
  ListItem(I256(0 -Int 1)),
  I256(0 -Int 1)
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "roundtrip",
  ListItem(I256(1000000000000000000)), ;; 1e18: a Wad price, as the oracle path uses
  I256(1000000000000000000)
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "roundtrip",
  ListItem(I256(0 -Int 12345678901234567890123456789)),
  I256(0 -Int 12345678901234567890123456789)
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "roundtrip",
  ListItem(I256(2 ^Int 255 -Int 1)), ;; i256::MAX
  I256(2 ^Int 255 -Int 1)
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "roundtrip",
  ListItem(I256(0 -Int 2 ^Int 255)), ;; i256::MIN
  I256(0 -Int 2 ^Int 255)
)

;; The words are the two's-complement representation: -1 is all ones.
callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "hiHi",
  ListItem(I256(0 -Int 1)),
  I256(2 ^Int 64 -Int 1)
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "loLo",
  ListItem(I256(0 -Int 1)),
  I256(2 ^Int 64 -Int 1)
)

;; i256::MIN is 1 followed by 255 zeros.
callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "hiHi",
  ListItem(I256(0 -Int 2 ^Int 255)),
  I256(2 ^Int 63)
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "loLo",
  ListItem(I256(0 -Int 2 ^Int 255)),
  I256(0)
)

;; ---------------------------------------------------------------------------
;; i256_val_from_be_bytes / i256_val_to_be_bytes  (i.h, i.i)
;; ---------------------------------------------------------------------------

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "roundtripBytes",
  ListItem(I256(0)),
  I256(0)
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "roundtripBytes",
  ListItem(I256(0 -Int 1)),
  I256(0 -Int 1)
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "roundtripBytes",
  ListItem(I256(100000000)),
  I256(100000000)
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "roundtripBytes",
  ListItem(I256(2 ^Int 255 -Int 1)), ;; i256::MAX
  I256(2 ^Int 255 -Int 1)
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "roundtripBytes",
  ListItem(I256(0 -Int 2 ^Int 255)), ;; i256::MIN
  I256(0 -Int 2 ^Int 255)
)

;; A negative value's big-endian bytes are its two's complement: -1 is 32 0xff.
callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "roundtripBytesInv",
  ListItem(ScBytes(b"\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff")),
  ScBytes(b"\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff")
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "roundtripBytesInv",
  ListItem(ScBytes(b"abcdefghabcdefghabcdefghabcdefgh")), ;; 32 bytes
  ScBytes(b"abcdefghabcdefghabcdefghabcdefgh")
)

;; ---------------------------------------------------------------------------
;; Arithmetic (i.v, i.w, i.x, i.y, i.z)
;;
;; The argument order matters for the non-commutative ops: the first Wasm
;; argument is the left-hand side.
;; ---------------------------------------------------------------------------

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "add",
  ListItem(I256(1)) ListItem(I256(2)),
  I256(3)
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "add",
  ListItem(I256(0 -Int 5)) ListItem(I256(3)),
  I256(0 -Int 2)
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "add",
  ListItem(I256(2 ^Int 255 -Int 2)) ListItem(I256(1)),
  I256(2 ^Int 255 -Int 1)
)

;; Overflow past i256::MAX is a checked failure, not a wrap.
callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "add",
  ListItem(I256(2 ^Int 255 -Int 1)) ListItem(I256(1)),
  Error(ErrValue, ArithDomain)
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "sub",
  ListItem(I256(1)) ListItem(I256(2)),
  I256(0 -Int 1)
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "sub",
  ListItem(I256(0 -Int 2 ^Int 255 +Int 1)) ListItem(I256(1)),
  I256(0 -Int 2 ^Int 255)
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "sub",
  ListItem(I256(0 -Int 2 ^Int 255)) ListItem(I256(1)),
  Error(ErrValue, ArithDomain)
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "mul",
  ListItem(I256(0 -Int 3)) ListItem(I256(4)),
  I256(0 -Int 12)
)

;; 1e18 * 1e27: the product `mul_div` forms before dividing.
callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "mul",
  ListItem(I256(1000000000000000000)) ListItem(I256(1000000000000000000000000000)),
  I256(1000000000000000000000000000000000000000000000)
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "mul",
  ListItem(I256(2 ^Int 200)) ListItem(I256(2 ^Int 200)),
  Error(ErrValue, ArithDomain)
)

;; Division truncates toward zero.
callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "div",
  ListItem(I256(7)) ListItem(I256(2)),
  I256(3)
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "div",
  ListItem(I256(0 -Int 7)) ListItem(I256(2)),
  I256(0 -Int 3)
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "div",
  ListItem(I256(7)) ListItem(I256(0 -Int 2)),
  I256(0 -Int 3)
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "div",
  ListItem(I256(0 -Int 7)) ListItem(I256(0 -Int 2)),
  I256(3)
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "div",
  ListItem(I256(1)) ListItem(I256(0)),
  Error(ErrValue, ArithDomain)
)

;; i256::MIN / -1 is the one division that overflows.
callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "div",
  ListItem(I256(0 -Int 2 ^Int 255)) ListItem(I256(0 -Int 1)),
  Error(ErrValue, ArithDomain)
)

;; Euclidean modulo is never negative, whatever the signs of the operands.
callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "rem",
  ListItem(I256(7)) ListItem(I256(3)),
  I256(1)
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "rem",
  ListItem(I256(0 -Int 7)) ListItem(I256(3)),
  I256(2)
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "rem",
  ListItem(I256(7)) ListItem(I256(0 -Int 3)),
  I256(1)
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "rem",
  ListItem(I256(0 -Int 7)) ListItem(I256(0 -Int 3)),
  I256(2)
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "rem",
  ListItem(I256(1)) ListItem(I256(0)),
  Error(ErrValue, ArithDomain)
)

setExitCode(0)
