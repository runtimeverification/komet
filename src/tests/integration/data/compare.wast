
setExitCode(1)

uploadWasm( b"test-wasm",
(module
  (import "x" "0" (func $obj_cmp (param i64 i64) (result i64)))
  (func $small_i64_to_i64_val (param i64) (result i64)
    local.get 0
    i64.const 8
    i64.shl
    i64.const 7
    i64.or
  )
  (func $is_object (param i64) (result i32)
    local.get 0
    i32.wrap_i64
    i32.const -64
    i32.add
    i32.const 255
    i32.and
    i32.const 14
    i32.lt_u
  )
  (func $compare (param i64 i64) (result i64)
    block
      local.get 0
      call $is_object
      br_if 0
      local.get 1
      call $is_object      
      br_if 0
      i64.const 0
      call $small_i64_to_i64_val
      return
    end
    (call $obj_cmp (local.get 0) (local.get 1))
    call $small_i64_to_i64_val
  )
  (export "compare" (func $compare))
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
  "compare",
  ListItem(U64(1)) ListItem(U64(2)),
  I64(0)
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "compare",
  ListItem(U64(1)) ListItem(U64(1000000000000000000000000000000000)),
  I64(-1)
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "compare",
  ListItem(U64(1000000000000000000000000000000000)) ListItem(U64(1000000000000000000000000000000000)),
  I64(0)
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "compare",
  ListItem(U64(1000000000000000000000000000000000)) ListItem(U64(1)),
  I64(1)
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "compare",
  ListItem(U64(1000000000000000000000000000000000)) ListItem(U64(2000000000000000000000000000000000)),
  I64(-1)
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "compare",
  ListItem(U64(2000000000000000000000000000000000)) ListItem(U64(1000000000000000000000000000000000)),
  I64(1)
)


callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "compare",
  ListItem(ScVec( ListItem(U32(1)) ListItem(U32(2)) ListItem(U32(3)) ))
  ListItem(ScVec( ListItem(U32(1)) ListItem(U32(2)) )),
  I64(1)
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "compare",
  ListItem(ScVec( ListItem(U32(1)) ListItem(U32(2)) ListItem(U32(3)) ))
  ListItem(ScVec( ListItem(U32(2)) ListItem(U32(2)) )),
  I64(-1)
)

setExitCode(0)