
setExitCode(1)

uploadWasm( b"test-wasm",
(module
  (import "v" "_" (func $vec_new (result i64)))
  (import "v" "0" (func $vec_put (param i64 i64 i64) (result i64)))
  (import "v" "1" (func $vec_get (param i64 i64) (result i64)))
  (import "v" "2" (func $vec_del (param i64 i64) (result i64)))
  (import "v" "3" (func $vec_len (param i64) (result i64)))
  (import "v" "4" (func $vec_push_front (param i64 i64) (result i64)))
  (import "v" "5" (func $vec_pop_front (param i64) (result i64)))
  (import "v" "6" (func $vec_push_back (param i64 i64) (result i64)))
  (import "v" "7" (func $vec_pop_back (param i64) (result i64)))
  (func $push_back_immutable (param i64 i64) (result i64)
    ;; push back and return the original vector
    local.get 0
    local.get 1
    call $vec_push_back
    drop
    local.get 0)
  (export "vec_new" (func $vec_new))
  (export "vec_len" (func $vec_len))
  (export "vec_put" (func $vec_put))
  (export "vec_get" (func $vec_get))
  (export "vec_del" (func $vec_del))
  (export "vec_push_front" (func $vec_push_front))
  (export "vec_pop_front" (func $vec_pop_front))
  (export "vec_push_back" (func $vec_push_back))
  (export "vec_pop_back" (func $vec_pop_back))
  (export "push_back_immutable" (func $push_back_immutable))
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
  "vec_new",
  .List,
  ScVec(.List)
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "vec_len",
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
  "vec_len",
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
  "vec_put",
  ListItem(
    ScVec(
      ListItem(U32(1))
      ListItem(U32(2))
      ListItem(U32(3))
      ListItem(U32(4))
      ListItem(U32(5))
    )
  )
  ListItem(U32(3))
  ListItem(U32(777)),
  ScVec(
    ListItem(U32(1))
    ListItem(U32(2))
    ListItem(U32(3))
    ListItem(U32(777))
    ListItem(U32(5))
  )
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "vec_get",
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
  "vec_del",
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
  ScVec(
    ListItem(U32(1))
    ListItem(U32(2))
    ListItem(U32(3))
    ListItem(U32(5))
  )
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "vec_del",
  ListItem(
    ScVec(
      ListItem(U32(1))
    )
  )
  ListItem(U32(0)),
  ScVec(.List)
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "vec_push_front",
  ListItem(
    ScVec(
      ListItem(U32(1))
      ListItem(U32(2))
      ListItem(U32(3))
    )
  )
  ListItem(U32(0)),
  ScVec(
    ListItem(U32(0))
    ListItem(U32(1))
    ListItem(U32(2))
    ListItem(U32(3))
  )
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "vec_push_front",
  ListItem(
    ScVec(.List)
  )
  ListItem(U32(0)),
  ScVec(
    ListItem(U32(0))
  )
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "vec_pop_front",
  ListItem(
    ScVec(
      ListItem(U32(1))
      ListItem(U32(2))
      ListItem(U32(3))
    )
  ),
  ScVec(
    ListItem(U32(2))
    ListItem(U32(3))
  )
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "vec_push_back",
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
  "vec_push_back",
  ListItem(ScVec(.List))
  ListItem(U32(1)),
  ScVec(ListItem(U32(1)))
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "vec_pop_back",
  ListItem(
    ScVec(
      ListItem(U32(1))
      ListItem(U32(2))
      ListItem(U32(3))
    )
  ),
  ScVec(
    ListItem(U32(1))
    ListItem(U32(2))
  )
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