
setExitCode(1)

uploadWasm( b"test-wasm",
(module
  (import "b" "1" (func $bytes_copy_to_linear_memory   (param i64 i64 i64 i64) (result i64)))
  (import "b" "2" (func $bytes_copy_from_linear_memory (param i64 i64 i64 i64) (result i64)))
  (import "b" "4" (func $bytes_new                                             (result i64)))
  (import "b" "5" (func $bytes_put                     (param i64 i64 i64)     (result i64)))
  (import "b" "6" (func $bytes_get                     (param i64 i64)         (result i64)))
  (import "b" "7" (func $bytes_del                     (param i64 i64)         (result i64)))
  (import "b" "8" (func $bytes_len                     (param i64)             (result i64)))
  (import "b" "9" (func $bytes_push                    (param i64 i64)         (result i64)))
  (import "b" "a" (func $bytes_pop                     (param i64)             (result i64)))
  (import "b" "b" (func $bytes_front                   (param i64)             (result i64)))
  (import "b" "c" (func $bytes_back                    (param i64)             (result i64)))
  (import "b" "d" (func $bytes_insert                  (param i64 i64 i64)     (result i64)))
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
  (func $push_first (param (; SRC ;) i64 (; DEST ;) i64) (result i64)
    ;; get the first byte of SRC and push to DEST
    (call $bytes_push 
      (local.get 1)
      (call $bytes_front (local.get 0))
    )
  )
  (func $u32_to_bytes (param i64) (result i64)
    (call $bytes_push (call $bytes_new) (local.get 0))
  )
  (func $bytes_front_as_bytes (param i64) (result i64)
    (call $u32_to_bytes (call $bytes_front (local.get 0)))
  )
  (func $bytes_back_as_bytes (param i64) (result i64)
    (call $u32_to_bytes (call $bytes_back (local.get 0)))
  )
  (memory (;0;) 16)
  (export "to_and_from" (func $to_and_from))
  (export "bytes_new" (func $bytes_new))
  (export "bytes_put" (func $bytes_put))
  (export "bytes_get" (func $bytes_get))
  (export "bytes_del" (func $bytes_del))
  (export "push_first" (func $push_first))
  (export "bytes_pop"  (func $bytes_pop))
  (export "bytes_front" (func $bytes_front_as_bytes))
  (export "bytes_back"  (func $bytes_back_as_bytes))
  (export "bytes_insert" (func $bytes_insert))
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

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "bytes_get",
  ListItem(ScBytes(b"\x00\x01\x02")) ListItem(U32(0)),
  U32(0)
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "bytes_get",
  ListItem(ScBytes(b"\x00\x01\x02")) ListItem(U32(1)),
  U32(1)
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "bytes_get",
  ListItem(ScBytes(b"\x00\x01\x02")) ListItem(U32(2)),
  U32(2)
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "bytes_del",
  ListItem(ScBytes(b"abc")) ListItem(U32(0)),
  ScBytes(b"bc")
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "bytes_del",
  ListItem(ScBytes(b"abc")) ListItem(U32(1)),
  ScBytes(b"ac")
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "bytes_del",
  ListItem(ScBytes(b"abc")) ListItem(U32(2)),
  ScBytes(b"ab")
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "push_first",
  ListItem(ScBytes(b"komet")) ListItem(ScBytes(b"bura")),
  ScBytes(b"burak")
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "push_first",
  ListItem(ScBytes(b"komet")) ListItem(ScBytes(b"")),
  ScBytes(b"k")
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "bytes_pop",
  ListItem(ScBytes(b"komet")),
  ScBytes(b"kome")
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "bytes_front",
  ListItem(ScBytes(b"komet")),
  ScBytes(b"k")
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "bytes_back",
  ListItem(ScBytes(b"komet")),
  ScBytes(b"t")
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "bytes_insert",
  ListItem(ScBytes(b"komet")) ListItem(U32(0)) ListItem(U32(0)),
  ScBytes(b"\x00komet")
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "bytes_insert",
  ListItem(ScBytes(b"komet")) ListItem(U32(1)) ListItem(U32(7)),
  ScBytes(b"k\x07omet")
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "bytes_insert",
  ListItem(ScBytes(b"komet")) ListItem(U32(4)) ListItem(U32(7)),
  ScBytes(b"kome\x07t")
)

setExitCode(0)