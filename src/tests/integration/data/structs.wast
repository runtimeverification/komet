
setExitCode(1)

uploadWasm( b"test-wasm",

;; #![no_std]
;; use soroban_sdk::{contract, contractimpl, contracttype, Env, Vec};

;; #[contract]
;; pub struct IncrementContract;

;; #[contracttype]
;; #[derive(PartialEq, Eq, Debug)]
;; pub struct Point {
;;     x: u128,
;;     y: u128
;; }

;; #[contractimpl]
;; impl IncrementContract {
;;     pub fn make_struct(_env: Env, x: u128, y: u128) -> Point {
;;         Point { x, y }
;;     }

;;     pub fn destruct(env: Env, p: Point) -> Vec<u128> {
;;       Vec::from_array(&env, [p.x, p.y])
;;     }
;; }

(module $soroban_increment_contract.wasm
  (type (;0;) (func (param i64 i64) (result i64)))
  (type (;1;) (func (param i64) (result i64)))
  (type (;2;) (func (param i64 i64 i64) (result i64)))
  (type (;3;) (func (param i64 i64 i64 i64) (result i64)))
  (type (;4;) (func (param i32 i64)))
  (type (;5;) (func))
  (import "i" "3" (func $_ZN17soroban_env_guest5guest3int20obj_from_u128_pieces17h5d7cf2ad07a3899bE (type 0)))
  (import "i" "5" (func $_ZN17soroban_env_guest5guest3int16obj_to_u128_hi6417h645b49e080dcfdf6E (type 1)))
  (import "i" "4" (func $_ZN17soroban_env_guest5guest3int16obj_to_u128_lo6417h0c596faaeffbf363E (type 1)))
  (import "m" "9" (func $_ZN17soroban_env_guest5guest3map26map_new_from_linear_memory17h905b0cda6fdc76f0E (type 2)))
  (import "m" "a" (func $_ZN17soroban_env_guest5guest3map27map_unpack_to_linear_memory17hb44f5a6c36f14cf3E (type 3)))
  (import "v" "g" (func $_ZN17soroban_env_guest5guest3vec26vec_new_from_linear_memory17h31f0f68089eaf9f9E (type 0)))
  (func $_ZN104_$LT$soroban_env_common..val..Val$u20$as$u20$soroban_env_common..convert..TryFromVal$LT$E$C$u128$GT$$GT$12try_from_val17h5c3a8408ff9f5a37E (type 0) (param i64 i64) (result i64)
    block  ;; label = @1
      local.get 0
      i64.const 72057594037927935
      i64.gt_u
      local.get 1
      i64.const 0
      i64.ne
      local.get 1
      i64.eqz
      select
      br_if 0 (;@1;)
      local.get 0
      i64.const 8
      i64.shl
      i64.const 10
      i64.or
      return
    end
    local.get 1
    local.get 0
    call $_ZN17soroban_env_guest5guest3int20obj_from_u128_pieces17h5d7cf2ad07a3899bE)
  (func $_ZN104_$LT$u128$u20$as$u20$soroban_env_common..convert..TryFromVal$LT$E$C$soroban_env_common..val..Val$GT$$GT$12try_from_val17h6b320ddacd75d7c2E (type 4) (param i32 i64)
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
  (func $make_struct (type 0) (param i64 i64) (result i64)
    (local i32 i32 i64 i64)
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
      local.get 2
      i64.load offset=8
      i64.eqz
      i32.eqz
      br_if 0 (;@1;)
      local.get 2
      i32.const 24
      i32.add
      local.tee 3
      i64.load
      local.set 0
      local.get 2
      i64.load offset=16
      local.set 4
      local.get 2
      i32.const 8
      i32.add
      local.get 1
      call $_ZN104_$LT$u128$u20$as$u20$soroban_env_common..convert..TryFromVal$LT$E$C$soroban_env_common..val..Val$GT$$GT$12try_from_val17h6b320ddacd75d7c2E
      local.get 2
      i64.load offset=8
      i64.eqz
      i32.eqz
      br_if 0 (;@1;)
      local.get 3
      i64.load
      local.set 1
      local.get 2
      i64.load offset=16
      local.set 5
      local.get 4
      local.get 0
      call $_ZN104_$LT$soroban_env_common..val..Val$u20$as$u20$soroban_env_common..convert..TryFromVal$LT$E$C$u128$GT$$GT$12try_from_val17h5c3a8408ff9f5a37E
      local.set 0
      local.get 2
      local.get 5
      local.get 1
      call $_ZN104_$LT$soroban_env_common..val..Val$u20$as$u20$soroban_env_common..convert..TryFromVal$LT$E$C$u128$GT$$GT$12try_from_val17h5c3a8408ff9f5a37E
      i64.store offset=16
      local.get 2
      local.get 0
      i64.store offset=8
      i32.const 1048580
      i64.extend_i32_u
      i64.const 32
      i64.shl
      i64.const 4
      i64.or
      local.get 2
      i32.const 8
      i32.add
      i64.extend_i32_u
      i64.const 32
      i64.shl
      i64.const 4
      i64.or
      i64.const 8589934596
      call $_ZN17soroban_env_guest5guest3map26map_new_from_linear_memory17h905b0cda6fdc76f0E
      local.set 0
      local.get 2
      i32.const 32
      i32.add
      global.set $__stack_pointer
      local.get 0
      return
    end
    unreachable
    unreachable)
  (func $destruct (type 1) (param i64) (result i64)
    (local i32 i32 i64 i64 i64 i32)
    global.get $__stack_pointer
    i32.const 48
    i32.sub
    local.tee 1
    global.set $__stack_pointer
    i32.const 0
    local.set 2
    block  ;; label = @1
      loop  ;; label = @2
        local.get 2
        i32.const 16
        i32.eq
        br_if 1 (;@1;)
        local.get 1
        i32.const 32
        i32.add
        local.get 2
        i32.add
        i64.const 2
        i64.store
        local.get 2
        i32.const 8
        i32.add
        local.set 2
        br 0 (;@2;)
      end
    end
    block  ;; label = @1
      local.get 0
      i64.const 255
      i64.and
      i64.const 76
      i64.ne
      br_if 0 (;@1;)
      local.get 0
      i32.const 1048580
      i64.extend_i32_u
      i64.const 32
      i64.shl
      i64.const 4
      i64.or
      local.get 1
      i32.const 32
      i32.add
      i64.extend_i32_u
      local.tee 3
      i64.const 32
      i64.shl
      i64.const 4
      i64.or
      i64.const 8589934596
      call $_ZN17soroban_env_guest5guest3map27map_unpack_to_linear_memory17hb44f5a6c36f14cf3E
      drop
      local.get 1
      local.get 1
      i64.load offset=32
      call $_ZN104_$LT$u128$u20$as$u20$soroban_env_common..convert..TryFromVal$LT$E$C$soroban_env_common..val..Val$GT$$GT$12try_from_val17h6b320ddacd75d7c2E
      local.get 1
      i64.load
      i64.eqz
      i32.eqz
      br_if 0 (;@1;)
      local.get 1
      i32.const 16
      i32.add
      local.tee 2
      i64.load
      local.set 0
      local.get 1
      i64.load offset=8
      local.set 4
      local.get 1
      local.get 1
      i64.load offset=40
      call $_ZN104_$LT$u128$u20$as$u20$soroban_env_common..convert..TryFromVal$LT$E$C$soroban_env_common..val..Val$GT$$GT$12try_from_val17h6b320ddacd75d7c2E
      local.get 1
      i64.load
      i64.eqz
      i32.eqz
      br_if 0 (;@1;)
      local.get 1
      i64.load offset=8
      local.set 5
      local.get 1
      i32.const 24
      i32.add
      local.get 2
      i64.load
      i64.store
      local.get 1
      local.get 5
      i64.store offset=16
      local.get 1
      local.get 4
      i64.store
      local.get 1
      local.get 0
      i64.store offset=8
      i32.const 0
      local.set 2
      loop  ;; label = @2
        block  ;; label = @3
          local.get 2
          i32.const 16
          i32.ne
          br_if 0 (;@3;)
          i32.const 0
          local.set 2
          local.get 1
          local.set 6
          block  ;; label = @4
            loop  ;; label = @5
              local.get 2
              i32.const 16
              i32.eq
              br_if 1 (;@4;)
              local.get 1
              i32.const 32
              i32.add
              local.get 2
              i32.add
              local.get 6
              i64.load
              local.get 6
              i32.const 8
              i32.add
              i64.load
              call $_ZN104_$LT$soroban_env_common..val..Val$u20$as$u20$soroban_env_common..convert..TryFromVal$LT$E$C$u128$GT$$GT$12try_from_val17h5c3a8408ff9f5a37E
              i64.store
              local.get 6
              i32.const 16
              i32.add
              local.set 6
              local.get 2
              i32.const 8
              i32.add
              local.set 2
              br 0 (;@5;)
            end
          end
          local.get 3
          i64.const 32
          i64.shl
          i64.const 4
          i64.or
          i64.const 8589934596
          call $_ZN17soroban_env_guest5guest3vec26vec_new_from_linear_memory17h31f0f68089eaf9f9E
          local.set 0
          local.get 1
          i32.const 48
          i32.add
          global.set $__stack_pointer
          local.get 0
          return
        end
        local.get 1
        i32.const 32
        i32.add
        local.get 2
        i32.add
        i64.const 2
        i64.store
        local.get 2
        i32.const 8
        i32.add
        local.set 2
        br 0 (;@2;)
      end
    end
    unreachable
    unreachable)
  (func $_ (type 5))
  (memory (;0;) 17)
  (global $__stack_pointer (mut i32) (i32.const 1048576))
  (global (;1;) i32 (i32.const 1048596))
  (global (;2;) i32 (i32.const 1048608))
  (export "memory" (memory 0))
  (export "make_struct" (func $make_struct))
  (export "destruct" (func $destruct))
  (export "_" (func $_))
  (export "__data_end" (global 1))
  (export "__heap_base" (global 2))
  (data $.rodata (i32.const 1048576) "xy\00\00\00\00\10\00\01\00\00\00\01\00\10\00\01\00\00\00"))

)

setAccount(Account(b"test-account"), 9876543210)

deployContract(
  Account(b"test-account"),
  Contract(b"test-ctr"),
  b"test-wasm",
  .List
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-ctr"),
  "destruct",
  ListItem(
    ScMap(
      Symbol(str("x")) |-> U128(111111111111111111)
      Symbol(str("y")) |-> U128(222222222222222222)
    )
  ),
  ScVec(ListItem(U128(111111111111111111)) ListItem(U128(222222222222222222)))
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-ctr"),
  "make_struct",
  ListItem(U128(111111111111111111)) ListItem(U128(222222222222222222)),
  ScMap(
    Symbol(str("x")) |-> U128(111111111111111111)
    Symbol(str("y")) |-> U128(222222222222222222)
  )
)

setExitCode(0)