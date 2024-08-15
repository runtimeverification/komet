
setExitCode(1)

uploadWasm( b"arith",
(module $add_u128.wasm
  (type (;0;) (func (param i64) (result i64)))
  (type (;1;) (func (param i64 i64) (result i64)))
  (type (;2;) (func (param i32 i64)))
  (type (;3;) (func))
  (import "i" "5" (func $_ZN17soroban_env_guest5guest3int16obj_to_u128_hi6417h645b49e080dcfdf6E (type 0)))
  (import "i" "4" (func $_ZN17soroban_env_guest5guest3int16obj_to_u128_lo6417h0c596faaeffbf363E (type 0)))
  (import "i" "3" (func $_ZN17soroban_env_guest5guest3int20obj_from_u128_pieces17h5d7cf2ad07a3899bE (type 1)))
  (func $_ZN104_$LT$u128$u20$as$u20$soroban_env_common..convert..TryFromVal$LT$E$C$soroban_env_common..val..Val$GT$$GT$12try_from_val17h6b320ddacd75d7c2E (type 2) (param i32 i64)
    (local i32 i64)
    block  ;; label = @1
      block  ;; label = @2
        block  ;; label = @3
          local.get 1
          i32.wrap_i64
          i32.const 255
          i32.and
          local.tee 2
          i32.const 68
          i32.eq
          br_if 0 (;@3;)
          local.get 2
          i32.const 10
          i32.ne
          br_if 1 (;@2;)
          i64.const 0
          local.set 3
          local.get 0
          i32.const 16
          i32.add
          i64.const 0
          i64.store
          local.get 0
          local.get 1
          i64.const 8
          i64.shr_u
          i64.store offset=8
          br 2 (;@1;)
        end
        local.get 1
        call $_ZN17soroban_env_guest5guest3int16obj_to_u128_hi6417h645b49e080dcfdf6E
        local.set 3
        local.get 1
        call $_ZN17soroban_env_guest5guest3int16obj_to_u128_lo6417h0c596faaeffbf363E
        local.set 1
        local.get 0
        i32.const 16
        i32.add
        local.get 3
        i64.store
        local.get 0
        local.get 1
        i64.store offset=8
        i64.const 0
        local.set 3
        br 1 (;@1;)
      end
      local.get 0
      i64.const 34359740419
      i64.store offset=8
      i64.const 1
      local.set 3
    end
    local.get 0
    local.get 3
    i64.store)
  (func $add (type 1) (param i64 i64) (result i64)
    (local i32 i32 i64 i32)
    global.get $__stack_pointer
    i32.const 32
    i32.sub
    local.tee 2
    global.set $__stack_pointer
    local.get 2
    i32.const 8
    i32.add
    local.get 0
    call $_ZN104_$LT$u128$u20$as$u20$soroban_env_common..convert..TryFromVal$LT$E$C$soroban_env_common..val..Val$GT$$GT$12try_from_val17h6b320ddacd75d7c2E
    block  ;; label = @1
      block  ;; label = @2
        local.get 2
        i64.load offset=8
        i64.eqz
        i32.eqz
        br_if 0 (;@2;)
        local.get 2
        i32.const 24
        i32.add
        local.tee 3
        i64.load
        local.set 4
        local.get 2
        i64.load offset=16
        local.set 0
        local.get 2
        i32.const 8
        i32.add
        local.get 1
        call $_ZN104_$LT$u128$u20$as$u20$soroban_env_common..convert..TryFromVal$LT$E$C$soroban_env_common..val..Val$GT$$GT$12try_from_val17h6b320ddacd75d7c2E
        local.get 2
        i64.load offset=8
        i64.eqz
        i32.eqz
        br_if 0 (;@2;)
        local.get 0
        local.get 2
        i64.load offset=16
        i64.add
        local.tee 1
        local.get 0
        i64.lt_u
        local.tee 5
        local.get 4
        local.get 3
        i64.load
        i64.add
        local.get 5
        i64.extend_i32_u
        i64.add
        local.tee 0
        local.get 4
        i64.lt_u
        local.get 0
        local.get 4
        i64.eq
        select
        i32.const 1
        i32.eq
        br_if 1 (;@1;)
        block  ;; label = @3
          block  ;; label = @4
            local.get 1
            i64.const 72057594037927935
            i64.gt_u
            local.get 0
            i64.const 0
            i64.ne
            local.get 0
            i64.eqz
            select
            br_if 0 (;@4;)
            local.get 1
            i64.const 8
            i64.shl
            i64.const 10
            i64.or
            local.set 0
            br 1 (;@3;)
          end
          local.get 0
          local.get 1
          call $_ZN17soroban_env_guest5guest3int20obj_from_u128_pieces17h5d7cf2ad07a3899bE
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
    call $_ZN4core9panicking5panic17hb157b525de3fe68dE
    unreachable)
  (func $_ZN4core9panicking5panic17hb157b525de3fe68dE (type 3)
    call $_ZN4core9panicking9panic_fmt17hc7427f902a13f1a9E
    unreachable)
  (func $_ZN4core9panicking9panic_fmt17hc7427f902a13f1a9E (type 3)
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
  b"arith"
)

callTx(
  Account(b"test-caller"),
  Contract(b"calculator"),
  "add",
  ListItem(U128(3)) ListItem(U128(5)),
  U128(8)
)

callTx(
  Account(b"test-caller"),
  Contract(b"calculator"),
  "add",
  ListItem(U128(1329227995784915872903807060280344576)) ListItem(U128(1152921504606846976)),
  U128(1329227995784915874056728564887191552)
)

callTx(
  Account(b"test-caller"),
  Contract(b"calculator"),
  "add",
  ListItem(U128(1329227995784915872903807060280344576)) ListItem(U128(1329227995784915872903807060280344576)),
  U128(2658455991569831745807614120560689152)
)

setExitCode(0)