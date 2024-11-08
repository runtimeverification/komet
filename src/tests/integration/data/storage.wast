
setExitCode(1)

uploadWasm( b"test-wasm",
(module $soroban_increment_contract.wasm
  (import "l" "_" (func $put_contract_data        (param i64 i64 i64)     (result i64)))
  (import "l" "0" (func $has_contract_data        (param i64 i64)         (result i64)))
  (import "l" "1" (func $get_contract_data        (param i64 i64)         (result i64)))
  (import "l" "2" (func $del_contract_data        (param i64 i64)         (result i64)))
  (import "l" "7" (func $extend_contract_data_ttl (param i64 i64 i64 i64) (result i64)))
  
  (func $storage_type (param i64) (result i64)
    local.get 0
    i64.const 32
    i64.shr_u
  )
  
  (func $put (export "put") (param i64 i64 i64) (result i64)
    (call $put_contract_data
      (local.get 0)
      (local.get 1)
      (call $storage_type (local.get 2))
    )
  )
  
  (func $has (export "has") (param i64 i64) (result i64)
    (call $has_contract_data
      (local.get 0)
      (call $storage_type (local.get 1))
    )
  )

  (func $get (export "get") (param i64 i64) (result i64)
    (call $get_contract_data
      (local.get 0)
      (call $storage_type (local.get 1))
    )
  )

  (func $del (export "del") (param i64 i64) (result i64)
    (call $del_contract_data
      (local.get 0)
      (call $storage_type (local.get 1))
    )
  )


  (func $extend_ttl (export "extend_ttl") (param i64 i64 i64 i64) (result i64)
    (call $extend_contract_data_ttl
      (local.get 0)
      (call $storage_type (local.get 1))
      (local.get 2)
      (local.get 3)
    )
  )
)
)

setAccount(Account(b"test-account"), 9876543210)

deployContract( Account(b"test-account"), Contract(b"test-sc"), b"test-wasm" )

;; Test put/has/get/del
;; 1. has                           -> false
;; 2. put "foo" U32(123456789) temp -> void
;; 3. has "foo" temp                -> true
;; 4. get "foo" temp                -> U32(123456789)
;; 5. del "foo" temp                -> void
;; 6. has "foo" temp                -> false

callTx(
  Account(b"test-caller"), Contract(b"test-sc"),
  "has", ListItem(Symbol(str("foo"))) ListItem(U32(0)),
  SCBool(false)
)

callTx(
  Account(b"test-caller"), Contract(b"test-sc"),
  "put", ListItem(Symbol(str("foo"))) ListItem(U32(123456789)) ListItem(U32(0)),
  Void
)

callTx(
  Account(b"test-caller"), Contract(b"test-sc"),
  "has", ListItem(Symbol(str("foo"))) ListItem(U32(0)),
  SCBool(true)
)

callTx(
  Account(b"test-caller"), Contract(b"test-sc"),
  "get", ListItem(Symbol(str("foo"))) ListItem(U32(0)),
  U32(123456789)
)

callTx(
  Account(b"test-caller"), Contract(b"test-sc"),
  "del", ListItem(Symbol(str("foo"))) ListItem(U32(0)),
  Void
)

callTx(
  Account(b"test-caller"), Contract(b"test-sc"),
  "has", ListItem(Symbol(str("foo"))) ListItem(U32(0)),
  SCBool(false)
)

;; Test extend TTL
callTx(
  Account(b"test-caller"), Contract(b"test-sc"),
  "put", ListItem(Symbol(str("foo"))) ListItem(U32(123456789)) ListItem(U32(0)),
  Void
)

callTx(
  Account(b"test-caller"), Contract(b"test-sc"),
  "extend_ttl", ListItem(Symbol(str("foo"))) ListItem(U32(0)) ListItem(U32(100)) ListItem(U32(200)),
  Void
)


setExitCode(0)