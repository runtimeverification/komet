
setExitCode(1)

uploadWasm( b"arith",
  (module $add_u32
    (type (;0;) (func (param i64 i64) (result i64)))
    (type (;1;) (func))
    (func $add_u32 (type 0) (param i64 i64) (result i64)
      (local i32 i32)
      block  ;; label = @1
        block  ;; label = @2
          local.get 0
          i64.const 255
          i64.and
          i64.const 4
          i64.ne
          br_if 0 (;@2;)
          local.get 1
          i64.const 255
          i64.and
          i64.const 4
          i64.ne
          br_if 0 (;@2;)
          local.get 0
          i64.const 32
          i64.shr_u
          i32.wrap_i64
          local.tee 2
          local.get 1
          i64.const 32
          i64.shr_u
          i32.wrap_i64
          i32.add
          local.tee 3
          local.get 2
          i32.lt_u
          br_if 1 (;@1;)
          local.get 3
          i64.extend_i32_u
          i64.const 32
          i64.shl
          i64.const 4
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
    (export "add_u32" (func $add_u32))
    (export "_" (func $_))
    (export "__data_end" (global 1))
    (export "__heap_base" (global 2)))
)

setAccount(Account(b"test-account"), 9876543210)

deployContract(
  Account(b"test-account"),
  Contract(b"calculator"),
  b"arith",
  .List
)

callTx(
  Account(b"test-caller"),
  Contract(b"calculator"),
  "add_u32",
  ListItem(U32(3)) ListItem(U32(5)),
  U32(8)
)

callTx(
  Account(b"test-caller"),
  Contract(b"calculator"),
  "add_u32",
  ListItem(U32(30000)) ListItem(U32(50000)),
  U32(80000)
)

setExitCode(0)