
setExitCode(1)

uploadWasm( b"arith",
(module $add_i32
  (type (;0;) (func (param i64 i64) (result i64)))
  (type (;1;) (func))
  (func $add (type 0) (param i64 i64) (result i64)
    (local i32 i32)
    block  ;; label = @1
      block  ;; label = @2
        local.get 0
        i64.const 255
        i64.and
        i64.const 5
        i64.ne
        br_if 0 (;@2;)
        local.get 1
        i64.const 255
        i64.and
        i64.const 5
        i64.ne
        br_if 0 (;@2;)
        local.get 1
        i64.const 32
        i64.shr_u
        i32.wrap_i64
        local.tee 2
        i32.const 0
        i32.lt_s
        local.get 0
        i64.const 32
        i64.shr_u
        i32.wrap_i64
        local.tee 3
        local.get 2
        i32.add
        local.tee 2
        local.get 3
        i32.lt_s
        i32.ne
        br_if 1 (;@1;)
        local.get 2
        i64.extend_i32_u
        i64.const 32
        i64.shl
        i64.const 5
        i64.or
        return
      end
      unreachable
      unreachable
    end
    call $_ZN4core9panicking11panic_const24panic_const_add_overflow17hde776086e9d58b0fE
    unreachable)
  (func $_ZN4core9panicking11panic_const24panic_const_add_overflow17hde776086e9d58b0fE (type 1)
    call $_ZN4core9panicking9panic_fmt17h5c7ce52813e94bcdE
    unreachable)
  (func $_ZN4core9panicking9panic_fmt17h5c7ce52813e94bcdE (type 1)
    unreachable
    unreachable)
  (func $_ (type 1))
  (memory (;0;) 16)
  (global $__stack_pointer (mut i32) (i32.const 1048576))
  (global (;1;) i32 (i32.const 1048576))
  (global (;2;) i32 (i32.const 1048576))
  (export "memory" (memory 0))
  (export "add" (func $add))
  (export "_" (func $_))
  (export "__data_end" (global 1))
  (export "__heap_base" (global 2)))

)

setAccount(Account(b"test-account"), 9876543210)

deployContract(
  Account(b"test-account"),
  Contract(b"calculator"),
  b"arith"
)

callTx(
  Account(b"test-caller"),
  Contract(b"calculator"),
  "add",
  ListItem(I32(3)) ListItem(I32(5)),
  I32(8)
)

callTx(
  Account(b"test-caller"),
  Contract(b"calculator"),
  "add",
  ListItem(I32(30000)) ListItem(I32(-50000)),
  I32(-20000)
)

setExitCode(0)