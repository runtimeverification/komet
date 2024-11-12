
setExitCode(1)

uploadWasm( b"test-wasm",
(module
  (import "v" "_" (func $vec_new (result i64)))
  (import "v" "3" (func $vec_len (param i64) (result i64)))
  (import "v" "1" (func $vec_get (param i64 i64) (result i64)))
  (import "v" "6" (func $vec_push_back (param i64 i64) (result i64)))
  (func $create_vec (result i64)
    call $vec_new)
  (func $get_len (param i64) (result i64)
    local.get 0
    call $vec_len)
  (func $get_item (param i64 i64) (result i64)
    local.get 0
    local.get 1
    call $vec_get)
  (func $push_back (param i64 i64) (result i64)
    local.get 0
    local.get 1
    call $vec_push_back)
  (func $push_back_immutable (param i64 i64) (result i64)
    ;; push back and return the original vector
    local.get 0
    local.get 1
    call $vec_push_back
    drop
    local.get 0)
  (export "create_vec" (func $create_vec))
  (export "get_len" (func $get_len))
  (export "get_item" (func $get_item))
  (export "push_back" (func $push_back))
  (export "push_back_immutable" (func $push_back_immutable)))
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

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "get_len",
  ListItem(
    ScVec(
      ListItem(U32(1))
      ListItem(U32(2))
      ListItem(U32(3))
      ListItem(U32(4))
      ListItem(U32(5))
    )
  ),
  U32(5)
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "get_len",
  ListItem(
    ScVec(
      .List
    )
  ),
  U32(0)
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "get_item",
  ListItem(
    ScVec(
      ListItem(U32(1))
      ListItem(U32(2))
      ListItem(U32(3))
      ListItem(U32(4))
      ListItem(U32(5))
    )
  )
  ListItem(U32(3)),
  U32(4)
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "push_back",
  ListItem(
    ScVec(
      ListItem(U32(1))
      ListItem(U32(2))
      ListItem(U32(3))
    )
  )
  ListItem(U32(4)),
  ScVec(
    ListItem(U32(1))
    ListItem(U32(2))
    ListItem(U32(3))
    ListItem(U32(4))
  )
)


callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "push_back",
  ListItem(ScVec(.List))
  ListItem(U32(1)),
  ScVec(ListItem(U32(1)))
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "push_back_immutable",
  ListItem(
    ScVec(
      ListItem(U32(1))
      ListItem(U32(2))
      ListItem(U32(3))
    )
  )
  ListItem(U32(4)),
  ScVec(
    ListItem(U32(1))
    ListItem(U32(2))
    ListItem(U32(3))
  )
)

setExitCode(0)