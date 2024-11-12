
setExitCode(1)

uploadWasm( b"test-wasm",
(module
  (import "m" "_" (func $new                     (result i64)))
  (import "m" "0" (func $put (param i64 i64 i64) (result i64)))
  (import "m" "1" (func $get (param i64 i64)     (result i64)))
  (import "m" "2" (func $del (param i64 i64)     (result i64)))
  (import "m" "3" (func $len (param i64)         (result i64)))
  (import "m" "4" (func $has (param i64 i64)     (result i64)))

  (export "new" (func $new))
  (export "put" (func $put))
  (export "get" (func $get))
  (export "del" (func $del))
  (export "len" (func $len))
  (export "has" (func $has))
)
)

setAccount(Account(b"test-account"), 9876543210)

deployContract(
  Account(b"test-account"),
  Contract(b"test-sc"),
  b"test-wasm"
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; map_new
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "new",
  .List,
  ScMap(.Map)
)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; map_has
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "has",
  ListItem(ScMap(.Map)) ListItem(Symbol(str("foo"))),
  SCBool(false)
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "has",
  ListItem(ScMap(
    Symbol(str("foo")) |-> U32(123)
    Symbol(str("bar")) |-> Symbol(str("456"))
    Symbol(str("baz")) |-> U128(789)
  ))
  ListItem(Symbol(str("foo"))),
  SCBool(true)
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "has",
  ListItem(ScMap(
    Symbol(str("foo")) |-> U32(123)
    Symbol(str("bar")) |-> Symbol(str("456"))
    Symbol(str("baz")) |-> U128(789)
  ))
  ListItem(Symbol(str("qux"))),
  SCBool(false)
)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; map_len
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "len",
  ListItem(ScMap(.Map)),
  U32(0)
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "len",
  ListItem(ScMap(
    Symbol(str("foo")) |-> U32(123)
    Symbol(str("bar")) |-> Symbol(str("456"))
    Symbol(str("baz")) |-> U128(789)
  )),
  U32(3)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; map_get
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "get",
  ListItem(ScMap(
    Symbol(str("foo")) |-> U32(123)
    Symbol(str("bar")) |-> Symbol(str("456"))
    Symbol(str("baz")) |-> U128(789)
  ))
  ListItem(Symbol(str("foo"))),
  U32(123)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; map_del
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "del",
  ListItem(ScMap(
    Symbol(str("foo")) |-> U32(123)
    Symbol(str("bar")) |-> Symbol(str("456"))
    Symbol(str("baz")) |-> U128(789)
  ))
  ListItem(Symbol(str("foo"))),
  ScMap(
    Symbol(str("bar")) |-> Symbol(str("456"))
    Symbol(str("baz")) |-> U128(789)
  )
)

setExitCode(0)