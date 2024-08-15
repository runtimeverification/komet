
setExitCode(1)

uploadWasm( b"test-wasm",
;; A contract that stores a struct containing a u64 and a vector of Points.
;; It has three endpoints: one for setting the storage, one for retrieving the vector of Points,
;; and one for retrieving the u64.

;; #![no_std]
;; use soroban_sdk::{contract, contractimpl, contracttype, log, symbol_short, Env, Symbol, Vec};

;; #[contracttype]
;; #[derive(Debug, Clone)]
;; pub struct Point(u64, u64);

;; #[contracttype]
;; #[derive(Debug)]
;; pub struct State {
;;     x: u128,
;;     points: Vec<Point>
;; }

;; const STATE: Symbol = symbol_short!("STATE");

;; #[contract]
;; pub struct IncrementContract;

;; #[contractimpl]
;; impl IncrementContract {
;;     pub fn set(env: Env, s: State) {
;;         env.storage().instance().set(&STATE, &s);
;;     }
;;     pub fn get_x(env: Env) -> u128 {
;;       let s: State = env.storage().instance().get(&STATE).unwrap();
;;       s.x
;;     }
;;     pub fn get_points(env: Env) -> Vec<Point> {
;;       let s: State = env.storage().instance().get(&STATE).unwrap();
;;       s.points
;;     }
;; }

(module $soroban_increment_contract.wasm
  (type (;0;) (func (param i64 i64) (result i64)))
  (type (;1;) (func (param i64 i64 i64 i64) (result i64)))
  (type (;2;) (func (param i64) (result i64)))
  (type (;3;) (func (param i64 i64 i64) (result i64)))
  (type (;4;) (func (param i32)))
  (type (;5;) (func (param i32 i64)))
  (type (;6;) (func (result i64)))
  (type (;7;) (func))
  (import "i" "3" (func $_ZN17soroban_env_guest5guest3int20obj_from_u128_pieces17h5d7cf2ad07a3899bE (type 0)))
  (import "l" "0" (func $_ZN17soroban_env_guest5guest6ledger17has_contract_data17h79546e647e9b20a7E (type 0)))
  (import "l" "1" (func $_ZN17soroban_env_guest5guest6ledger17get_contract_data17h472f93112d86127fE (type 0)))
  (import "m" "a" (func $_ZN17soroban_env_guest5guest3map27map_unpack_to_linear_memory17hb44f5a6c36f14cf3E (type 1)))
  (import "i" "5" (func $_ZN17soroban_env_guest5guest3int16obj_to_u128_hi6417h645b49e080dcfdf6E (type 2)))
  (import "i" "4" (func $_ZN17soroban_env_guest5guest3int16obj_to_u128_lo6417h0c596faaeffbf363E (type 2)))
  (import "m" "9" (func $_ZN17soroban_env_guest5guest3map26map_new_from_linear_memory17h905b0cda6fdc76f0E (type 3)))
  (import "l" "_" (func $_ZN17soroban_env_guest5guest6ledger17put_contract_data17h6938c7a297250993E (type 3)))
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
  (func $_ZN11soroban_sdk7storage8Instance3get17hd62867e0a50c0338E (type 4) (param i32)
    (local i32 i64 i64)
    global.get $__stack_pointer
    i32.const 32
    i32.sub
    local.tee 1
    global.set $__stack_pointer
    i64.const 0
    local.set 2
    block  ;; label = @1
      block  ;; label = @2
        i64.const 130942488590
        i64.const 2
        call $_ZN17soroban_env_guest5guest6ledger17has_contract_data17h79546e647e9b20a7E
        i64.const 1
        i64.ne
        br_if 0 (;@2;)
        local.get 1
        i64.const 130942488590
        i64.const 2
        call $_ZN17soroban_env_guest5guest6ledger17get_contract_data17h472f93112d86127fE
        call $_ZN153_$LT$soroban_increment_contract..State$u20$as$u20$soroban_env_common..convert..TryFromVal$LT$soroban_sdk..env..Env$C$soroban_env_common..val..Val$GT$$GT$12try_from_val17h8d7857b7998f70f4E
        local.get 1
        i64.load
        i64.eqz
        i32.eqz
        br_if 1 (;@1;)
        local.get 1
        i64.load offset=24
        local.set 2
        local.get 1
        i64.load offset=8
        local.set 3
        local.get 0
        i32.const 16
        i32.add
        local.get 1
        i32.const 16
        i32.add
        i64.load
        i64.store
        local.get 0
        local.get 3
        i64.store offset=8
        local.get 0
        local.get 2
        i64.store offset=24
        i64.const 1
        local.set 2
      end
      local.get 0
      local.get 2
      i64.store
      local.get 1
      i32.const 32
      i32.add
      global.set $__stack_pointer
      return
    end
    unreachable
    unreachable)
  (func $_ZN153_$LT$soroban_increment_contract..State$u20$as$u20$soroban_env_common..convert..TryFromVal$LT$soroban_sdk..env..Env$C$soroban_env_common..val..Val$GT$$GT$12try_from_val17h8d7857b7998f70f4E (type 5) (param i32 i64)
    (local i32 i32 i64 i64)
    global.get $__stack_pointer
    i32.const 16
    i32.sub
    local.tee 2
    global.set $__stack_pointer
    i32.const 0
    local.set 3
    block  ;; label = @1
      loop  ;; label = @2
        local.get 3
        i32.const 16
        i32.eq
        br_if 1 (;@1;)
        local.get 2
        local.get 3
        i32.add
        i64.const 2
        i64.store
        local.get 3
        i32.const 8
        i32.add
        local.set 3
        br 0 (;@2;)
      end
    end
    block  ;; label = @1
      block  ;; label = @2
        local.get 1
        i64.const 255
        i64.and
        i64.const 76
        i64.ne
        br_if 0 (;@2;)
        local.get 1
        i32.const 1048584
        i64.extend_i32_u
        i64.const 32
        i64.shl
        i64.const 4
        i64.or
        local.get 2
        i64.extend_i32_u
        i64.const 32
        i64.shl
        i64.const 4
        i64.or
        i64.const 8589934596
        call $_ZN17soroban_env_guest5guest3map27map_unpack_to_linear_memory17hb44f5a6c36f14cf3E
        drop
        block  ;; label = @3
          block  ;; label = @4
            block  ;; label = @5
              block  ;; label = @6
                local.get 2
                i64.load
                local.tee 1
                i64.const 255
                i64.and
                i64.const 75
                i64.ne
                br_if 0 (;@6;)
                local.get 2
                i64.load offset=8
                local.tee 4
                i32.wrap_i64
                i32.const 255
                i32.and
                local.tee 3
                i32.const 68
                i32.eq
                br_if 1 (;@5;)
                local.get 3
                i32.const 10
                i32.ne
                br_if 3 (;@3;)
                local.get 4
                i64.const 8
                i64.shr_u
                local.set 4
                i64.const 0
                local.set 5
                br 2 (;@4;)
              end
              local.get 0
              i64.const 1
              i64.store
              br 4 (;@1;)
            end
            local.get 4
            call $_ZN17soroban_env_guest5guest3int16obj_to_u128_hi6417h645b49e080dcfdf6E
            local.set 5
            local.get 4
            call $_ZN17soroban_env_guest5guest3int16obj_to_u128_lo6417h0c596faaeffbf363E
            local.set 4
          end
          local.get 0
          local.get 4
          i64.store offset=8
          local.get 0
          local.get 1
          i64.store offset=24
          local.get 0
          i64.const 0
          i64.store
          local.get 0
          i32.const 16
          i32.add
          local.get 5
          i64.store
          br 2 (;@1;)
        end
        local.get 0
        i64.const 1
        i64.store
        br 1 (;@1;)
      end
      local.get 0
      i64.const 1
      i64.store
    end
    local.get 2
    i32.const 16
    i32.add
    global.set $__stack_pointer)
  (func $set (type 2) (param i64) (result i64)
    (local i32)
    global.get $__stack_pointer
    i32.const 32
    i32.sub
    local.tee 1
    global.set $__stack_pointer
    local.get 1
    local.get 0
    call $_ZN153_$LT$soroban_increment_contract..State$u20$as$u20$soroban_env_common..convert..TryFromVal$LT$soroban_sdk..env..Env$C$soroban_env_common..val..Val$GT$$GT$12try_from_val17h8d7857b7998f70f4E
    block  ;; label = @1
      local.get 1
      i64.load
      i64.eqz
      br_if 0 (;@1;)
      unreachable
      unreachable
    end
    local.get 1
    i64.load offset=24
    local.set 0
    local.get 1
    local.get 1
    i64.load offset=8
    local.get 1
    i32.const 16
    i32.add
    i64.load
    call $_ZN104_$LT$soroban_env_common..val..Val$u20$as$u20$soroban_env_common..convert..TryFromVal$LT$E$C$u128$GT$$GT$12try_from_val17h5c3a8408ff9f5a37E
    i64.store offset=8
    local.get 1
    local.get 0
    i64.store
    i64.const 130942488590
    i32.const 1048584
    i64.extend_i32_u
    i64.const 32
    i64.shl
    i64.const 4
    i64.or
    local.get 1
    i64.extend_i32_u
    i64.const 32
    i64.shl
    i64.const 4
    i64.or
    i64.const 8589934596
    call $_ZN17soroban_env_guest5guest3map26map_new_from_linear_memory17h905b0cda6fdc76f0E
    i64.const 2
    call $_ZN17soroban_env_guest5guest6ledger17put_contract_data17h6938c7a297250993E
    drop
    local.get 1
    i32.const 32
    i32.add
    global.set $__stack_pointer
    i64.const 2)
  (func $get_x (type 6) (result i64)
    (local i32 i64)
    global.get $__stack_pointer
    i32.const 32
    i32.sub
    local.tee 0
    global.set $__stack_pointer
    local.get 0
    call $_ZN11soroban_sdk7storage8Instance3get17hd62867e0a50c0338E
    block  ;; label = @1
      local.get 0
      i64.load
      i64.const 0
      i64.ne
      br_if 0 (;@1;)
      call $_ZN4core6option13unwrap_failed17hb5bacfb0dd292085E
      unreachable
    end
    local.get 0
    i64.load offset=8
    local.get 0
    i32.const 16
    i32.add
    i64.load
    call $_ZN104_$LT$soroban_env_common..val..Val$u20$as$u20$soroban_env_common..convert..TryFromVal$LT$E$C$u128$GT$$GT$12try_from_val17h5c3a8408ff9f5a37E
    local.set 1
    local.get 0
    i32.const 32
    i32.add
    global.set $__stack_pointer
    local.get 1)
  (func $_ZN4core6option13unwrap_failed17hb5bacfb0dd292085E (type 7)
    call $_ZN4core9panicking5panic17hb157b525de3fe68dE
    unreachable)
  (func $get_points (type 6) (result i64)
    (local i32 i64)
    global.get $__stack_pointer
    i32.const 32
    i32.sub
    local.tee 0
    global.set $__stack_pointer
    local.get 0
    call $_ZN11soroban_sdk7storage8Instance3get17hd62867e0a50c0338E
    block  ;; label = @1
      local.get 0
      i64.load
      i64.const 0
      i64.ne
      br_if 0 (;@1;)
      call $_ZN4core6option13unwrap_failed17hb5bacfb0dd292085E
      unreachable
    end
    local.get 0
    i64.load offset=24
    local.set 1
    local.get 0
    i32.const 32
    i32.add
    global.set $__stack_pointer
    local.get 1)
  (func $_ZN4core9panicking9panic_fmt17hc7427f902a13f1a9E (type 7)
    unreachable
    unreachable)
  (func $_ZN4core9panicking5panic17hb157b525de3fe68dE (type 7)
    call $_ZN4core9panicking9panic_fmt17hc7427f902a13f1a9E
    unreachable)
  (func $_ (type 7))
  (memory (;0;) 17)
  (global $__stack_pointer (mut i32) (i32.const 1048576))
  (global (;1;) i32 (i32.const 1048600))
  (global (;2;) i32 (i32.const 1048608))
  (export "memory" (memory 0))
  (export "set" (func $set))
  (export "get_x" (func $get_x))
  (export "get_points" (func $get_points))
  (export "_" (func $_))
  (export "__data_end" (global 1))
  (export "__heap_base" (global 2))
  (data $.rodata (i32.const 1048576) "pointsx\00\00\00\10\00\06\00\00\00\06\00\10\00\01\00\00\00"))

)

setAccount(Account(b"test-account"), 9876543210)

deployContract(
  Account(b"test-account"),
  Contract(b"test-ctr"),
  b"test-wasm"
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-ctr"),
  "set",
  ListItem(
    ScMap(
      Symbol(str("x")) |-> U128(1329227995784915872903807060280344576)
      Symbol(str("points")) |-> ScVec(
        ListItem(ScVec(ListItem(U64(1)) ListItem(U64(2))))
        ListItem(ScVec(ListItem(U64(10)) ListItem(U64(20))))
      )
    )
  ),
  Void
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-ctr"),
  "get_x",
  .List,
  U128(1329227995784915872903807060280344576)
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-ctr"),
  "get_points",
  .List,
  ScVec(
    ListItem(ScVec(ListItem(U64(1)) ListItem(U64(2))))
    ListItem(ScVec(ListItem(U64(10)) ListItem(U64(20))))
  )
)

setExitCode(0)