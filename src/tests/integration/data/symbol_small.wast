
setExitCode(1)

uploadWasm( b"test-wasm",
(module
  (type (;0;) (func (param i64 i64) (result i64)))
  (type (;1;) (func (result i64)))
  (type (;2;) (func (param i32 i32) (result i64)))
  (type (;3;) (func))
  (import "b" "j" (func $symbol_new_from_linear_memory (type 0)))
  (func $symbol_small (type 1) (result i64)
    ;; address
    i64.const 0
    i64.const 32
    i64.shl
    i64.const 4
    i64.or
    
    ;; size
    i64.const 8
    i64.const 32
    i64.shl
    i64.const 4
    i64.or
    call $symbol_new_from_linear_memory)
  (memory (data "_ABCabc0"))
  (export "symbol_small" (func $symbol_small)))
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
  "symbol_small",
  .List,
  Symbol(str("_ABCabc0"))
)

setExitCode(0)