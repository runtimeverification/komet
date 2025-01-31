
setExitCode(1)

uploadWasm( b"test-wasm",
(module
  (import "b" "1" (func $bytes_copy_to_linear_memory   (param i64 i64 i64 i64) (result i64)))
  (import "b" "2" (func $bytes_copy_from_linear_memory (param i64 i64 i64 i64) (result i64)))
  (import "b" "4" (func $bytes_new                                             (result i64)))
  (import "b" "5" (func $bytes_put                     (param i64 i64 i64)     (result i64)))
  (import "b" "8" (func $bytes_len                     (param i64)             (result i64)))
  (func $u32 (param i32) (result i64)
    local.get 0
    i64.extend_i32_u
    i64.const 32
    i64.shl
    i64.const 4
    i64.or
  )
  (func $to_and_from (param (; SRC ;) i64 (; DEST ;) i64 (; POS ;) i64) (result i64)
    (call $bytes_copy_to_linear_memory
      (local.get 0) (call $u32 (i32.const 0)) (call $u32 (i32.const 0)) (call $bytes_len (local.get 0))
    )
    drop
    (call $bytes_copy_from_linear_memory
      (local.get 1) (local.get 2) (call $u32 (i32.const 0)) (call $bytes_len (local.get 0))
    )
  )
  (memory (;0;) 16)
  (export "to_and_from" (func $to_and_from))
  (export "bytes_new" (func $bytes_new))
  (export "bytes_put" (func $bytes_put))
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
  "to_and_from",
  ListItem(ScBytes(b"abc")) ListItem(ScBytes(b"def")) ListItem(U32(0)),
  ScBytes(b"abc")
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "to_and_from",
  ListItem(ScBytes(b"abc")) ListItem(ScBytes(b"def")) ListItem(U32(1)),
  ScBytes(b"dabc")
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "to_and_from",
  ListItem(ScBytes(b"abc")) ListItem(ScBytes(b"def")) ListItem(U32(3)),
  ScBytes(b"defabc")
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "to_and_from",
  ListItem(ScBytes(b"abc")) ListItem(ScBytes(b"def")) ListItem(U32(5)),
  ScBytes(b"def\x00\x00abc")
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "bytes_new",
  .List,
  ScBytes(b"")
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "bytes_put",
  ListItem(ScBytes(b"abc")) ListItem(U32(0)) ListItem(U32(0)),
  ScBytes(b"\x00bc")
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "bytes_put",
  ListItem(ScBytes(b"abc")) ListItem(U32(1)) ListItem(U32(0)),
  ScBytes(b"a\x00c")
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "bytes_put",
  ListItem(ScBytes(b"abc")) ListItem(U32(2)) ListItem(U32(0)),
  ScBytes(b"ab\x00")
)

setExitCode(0)