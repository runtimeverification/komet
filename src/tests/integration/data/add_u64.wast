
setExitCode(1)

uploadWasm( b"arith",
(module $add_u64
  (type (;0;) (func (param i64) (result i64)))
  (type (;1;) (func (param i32 i64)))
  (type (;2;) (func (param i64 i64) (result i64)))
  (type (;3;) (func))
  (import "i" "0" (func $_ZN17soroban_env_guest5guest3int10obj_to_u6417hb6825d7c3a487396E (type 0)))
  (import "i" "_" (func $_ZN17soroban_env_guest5guest3int12obj_from_u6417h29c7b3c8a36f37d1E (type 0)))
  (func $_ZN103_$LT$u64$u20$as$u20$soroban_env_common..convert..TryFromVal$LT$E$C$soroban_env_common..val..Val$GT$$GT$12try_from_val17ha8dbd27463855d40E (type 1) (param i32 i64)
    (local i32 i64)
    block  ;; label = @1
      block  ;; label = @2
        local.get 1
        i32.wrap_i64
        i32.const 255
        i32.and
        local.tee 2
        i32.const 64
        i32.eq
        br_if 0 (;@2;)
        block  ;; label = @3
          local.get 2
          i32.const 6
          i32.eq
          br_if 0 (;@3;)
          i64.const 1
          local.set 3
          i64.const 34359740419
          local.set 1
          br 2 (;@1;)
        end
        local.get 1
        i64.const 8
        i64.shr_u
        local.set 1
        i64.const 0
        local.set 3
        br 1 (;@1;)
      end
      i64.const 0
      local.set 3
      local.get 1
      call $_ZN17soroban_env_guest5guest3int10obj_to_u6417hb6825d7c3a487396E
      local.set 1
    end
    local.get 0
    local.get 1
    i64.store offset=8
    local.get 0
    local.get 3
    i64.store)
  (func $add (type 2) (param i64 i64) (result i64)
    (local i32)
    global.get $__stack_pointer
    i32.const 32
    i32.sub
    local.tee 2
    global.set $__stack_pointer
    local.get 2
    i32.const 16
    i32.add
    local.get 0
    call $_ZN103_$LT$u64$u20$as$u20$soroban_env_common..convert..TryFromVal$LT$E$C$soroban_env_common..val..Val$GT$$GT$12try_from_val17ha8dbd27463855d40E
    block  ;; label = @1
      block  ;; label = @2
        local.get 2
        i32.load offset=16
        br_if 0 (;@2;)
        local.get 2
        i64.load offset=24
        local.set 0
        local.get 2
        local.get 1
        call $_ZN103_$LT$u64$u20$as$u20$soroban_env_common..convert..TryFromVal$LT$E$C$soroban_env_common..val..Val$GT$$GT$12try_from_val17ha8dbd27463855d40E
        local.get 2
        i64.load
        i32.wrap_i64
        br_if 0 (;@2;)
        local.get 0
        local.get 2
        i64.load offset=8
        i64.add
        local.tee 1
        local.get 0
        i64.lt_u
        br_if 1 (;@1;)
        block  ;; label = @3
          block  ;; label = @4
            local.get 1
            i64.const 72057594037927935
            i64.gt_u
            br_if 0 (;@4;)
            local.get 1
            i64.const 8
            i64.shl
            i64.const 6
            i64.or
            local.set 0
            br 1 (;@3;)
          end
          local.get 1
          call $_ZN17soroban_env_guest5guest3int12obj_from_u6417h29c7b3c8a36f37d1E
          local.set 0
        end
        local.get 2
        i32.const 32
        i32.add
        global.set $__stack_pointer
        local.get 0
        return
      end
      unreachable
      unreachable
    end
    call $_ZN4core9panicking11panic_const24panic_const_add_overflow17hde776086e9d58b0fE
    unreachable)
  (func $_ZN4core9panicking11panic_const24panic_const_add_overflow17hde776086e9d58b0fE (type 3)
    call $_ZN4core9panicking9panic_fmt17h5c7ce52813e94bcdE
    unreachable)
  (func $_ZN4core9panicking9panic_fmt17h5c7ce52813e94bcdE (type 3)
    unreachable
    unreachable)
  (func $_ (type 3))
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
  b"arith",
  .List
)

callTx(
  Account(b"test-caller"),
  Contract(b"calculator"),
  "add",
  ListItem(U64(3)) ListItem(U64(5)),
  U64(8)
)

callTx(
  Account(b"test-caller"),
  Contract(b"calculator"),
  "add",
  ListItem(U64(1152921504606846976)) ListItem(U64(1152921504606846976)),
  U64(2305843009213693952)
)

setExitCode(0)