setExitCode(1)

uploadWasm( b"test-wasm",
;; A minimal contract with two consecutive nop instructions.
;; Used to expose the <lastTraced> deduplication limitation:
;; the second nop should be logged but is not, because nop leaves
;; no intermediate value in <instrs>, so resetLastTraced never fires.
(module $consecutive_nop
  (type (;0;) (func (result i64)))
  (type (;1;) (func))
  (func $test_nop (type 0) (result i64)
    nop
    nop
    i64.const 0)
  (func $_ (type 1))
  (memory (;0;) 16)
  (global $__stack_pointer (mut i32) (i32.const 1048576))
  (global (;1;) i32 (i32.const 1048576))
  (global (;2;) i32 (i32.const 1048576))
  (export "memory" (memory 0))
  (export "test_nop" (func $test_nop))
  (export "_" (func $_))
  (export "__data_end" (global 1))
  (export "__heap_base" (global 2)))
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
  "test_nop",
  .List,
  SCBool(false)
)

setExitCode(0)
