
setExitCode(1)

uploadWasm( b"test-wasm",
;; #![no_std]
;; use soroban_sdk::{contract, contractimpl, Env, Symbol};
;; 
;; #[contract]
;; pub struct IncrementContract;
;; 
;; #[contractimpl]
;; impl IncrementContract {
;;     pub fn symbol_small(env: Env) -> Symbol {
;;         Symbol::new(&env, "_ABCabc0")
;;     }
;;     
;;     pub fn symbol_object(env: Env) -> Symbol {
;;         Symbol::new(&env, "_ABCabc0123456789qwerty")
;;     }
;; }
(module $soroban_increment_contract.wasm
  (type (;0;) (func (param i64 i64) (result i64)))
  (type (;1;) (func (result i64)))
  (type (;2;) (func (param i32 i32) (result i64)))
  (type (;3;) (func))
  (import "b" "j" (func $_ZN17soroban_env_guest5guest3buf29symbol_new_from_linear_memory17h79212fcc6ba452faE (type 0)))
  (func $symbol_small (type 1) (result i64)
    i32.const 1048576
    i32.const 8
    call $_ZN11soroban_sdk6symbol6Symbol3new17hd0e466fd0e8d4f8eE)
  (func $_ZN11soroban_sdk6symbol6Symbol3new17hd0e466fd0e8d4f8eE (type 2) (param i32 i32) (result i64)
    (local i32 i64 i64 i32)
    i32.const 0
    local.set 2
    i64.const 0
    local.set 3
    block  ;; label = @1
      block  ;; label = @2
        loop  ;; label = @3
          local.get 1
          local.get 2
          i32.eq
          br_if 1 (;@2;)
          local.get 2
          i32.const 9
          i32.eq
          br_if 2 (;@1;)
          i64.const 1
          local.set 4
          block  ;; label = @4
            local.get 0
            local.get 2
            i32.add
            i32.load8_u
            local.tee 5
            i32.const 95
            i32.eq
            br_if 0 (;@4;)
            local.get 5
            i64.extend_i32_u
            local.set 4
            block  ;; label = @5
              local.get 5
              i32.const -48
              i32.add
              i32.const 10
              i32.lt_u
              br_if 0 (;@5;)
              block  ;; label = @6
                local.get 5
                i32.const -65
                i32.add
                i32.const 26
                i32.lt_u
                br_if 0 (;@6;)
                local.get 5
                i32.const -97
                i32.add
                i32.const 25
                i32.gt_u
                br_if 5 (;@1;)
                local.get 4
                i64.const -59
                i64.add
                local.set 4
                br 2 (;@4;)
              end
              local.get 4
              i64.const -53
              i64.add
              local.set 4
              br 1 (;@4;)
            end
            local.get 4
            i64.const -46
            i64.add
            local.set 4
          end
          local.get 2
          i32.const 1
          i32.add
          local.set 2
          local.get 4
          local.get 3
          i64.const 6
          i64.shl
          i64.or
          local.set 3
          br 0 (;@3;)
        end
      end
      local.get 3
      i64.const 8
      i64.shl
      i64.const 14
      i64.or
      return
    end
    local.get 0
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
    call $_ZN17soroban_env_guest5guest3buf29symbol_new_from_linear_memory17h79212fcc6ba452faE)
  (func $symbol_object (type 1) (result i64)
    i32.const 1048584
    i32.const 23
    call $_ZN11soroban_sdk6symbol6Symbol3new17hd0e466fd0e8d4f8eE)
  (func $_ (type 3))
  (memory (;0;) 17)
  (global $__stack_pointer (mut i32) (i32.const 1048576))
  (global (;1;) i32 (i32.const 1048607))
  (global (;2;) i32 (i32.const 1048608))
  (export "memory" (memory 0))
  (export "symbol_small" (func $symbol_small))
  (export "symbol_object" (func $symbol_object))
  (export "_" (func $_))
  (export "__data_end" (global 1))
  (export "__heap_base" (global 2))
  (data $.rodata (i32.const 1048576) "_ABCabc0_ABCabc0123456789qwerty"))
)

setAccount(Account(b"test-account"), 9876543210)

deployContract(
  Account(b"test-account"),
  Contract(b"test-sc"),
  b"test-wasm",
  .List
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "symbol_small",
  .List,
  Symbol(str("_ABCabc0"))
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "symbol_object",
  .List,
  Symbol(str("_ABCabc0123456789qwerty"))
)

setExitCode(0)