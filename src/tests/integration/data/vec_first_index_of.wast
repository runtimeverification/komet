setExitCode(1)

uploadWasm( b"test-wasm",
(module $test_wasm
  (import "v" "d" (func $vec_first_index_of (param i64 i64) (result i64)))
  (func $first_index_of (param i64 i64) (result i64)
    (call $vec_first_index_of (local.get 0) (local.get 1))
  )
  (export "first_index_of" (func $first_index_of))
))

setAccount(Account(b"test-account"), 9876543210)

deployContract(
  Account(b"test-account"),
  Contract(b"test-sc"),
  b"test-wasm"
)

;; Present: the index of the match.
callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "first_index_of",
  ListItem(ScVec(ListItem(U32(10)) ListItem(U32(20)) ListItem(U32(30))))
  ListItem(U32(20)),
  U32(1)
)

;; The first element and the last element.
callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "first_index_of",
  ListItem(ScVec(ListItem(U32(10)) ListItem(U32(20)) ListItem(U32(30))))
  ListItem(U32(10)),
  U32(0)
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "first_index_of",
  ListItem(ScVec(ListItem(U32(10)) ListItem(U32(20)) ListItem(U32(30))))
  ListItem(U32(30)),
  U32(2)
)

;; Duplicates: the FIRST occurrence.
callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "first_index_of",
  ListItem(ScVec(ListItem(U32(7)) ListItem(U32(7)) ListItem(U32(7))))
  ListItem(U32(7)),
  U32(0)
)

;; Absent, and absent from an empty vector: Void.
callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "first_index_of",
  ListItem(ScVec(ListItem(U32(10)) ListItem(U32(20))))
  ListItem(U32(99)),
  Void
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "first_index_of",
  ListItem(ScVec(.List))
  ListItem(U32(1)),
  Void
)

;; Equality is typed: U64(1) is not U32(1).
callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "first_index_of",
  ListItem(ScVec(ListItem(U64(1))))
  ListItem(U32(1)),
  Void
)

;; Object-valued elements: each I128 is a separately allocated host object, so
;; a match can only be found by comparing values, not object handles.
callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "first_index_of",
  ListItem(ScVec(ListItem(I128(2 ^Int 100)) ListItem(I128(0 -Int 2 ^Int 100))))
  ListItem(I128(0 -Int 2 ^Int 100)),
  U32(1)
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "first_index_of",
  ListItem(ScVec(ListItem(I128(2 ^Int 100))))
  ListItem(I128(2 ^Int 100 +Int 1)),
  Void
)

;; Nested containers are compared element by element.
callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "first_index_of",
  ListItem(ScVec(
    ListItem(ScVec(ListItem(U32(1))))
    ListItem(ScVec(ListItem(U32(1)) ListItem(U32(2))))
  ))
  ListItem(ScVec(ListItem(U32(1)) ListItem(U32(2)))),
  U32(1)
)

;; Symbols long enough to become host objects rather than small values.
callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "first_index_of",
  ListItem(ScVec(ListItem(Symbol(str("short"))) ListItem(Symbol(str("a_long_symbol_name")))))
  ListItem(Symbol(str("a_long_symbol_name"))),
  U32(1)
)

setExitCode(0)
