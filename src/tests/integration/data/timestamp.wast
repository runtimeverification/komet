
setExitCode(1)
;; #![no_std]
;; use soroban_sdk::{contract, contractimpl, Env, FromVal, Val};
;; 
;; #[contract]
;; pub struct TtlContract;
;; 
;; extern "C" {
;;     fn kasmer_set_ledger_timestamp(x : u64);
;; }
;; 
;; fn set_ledger_timestamp(env: &Env, x: u64) {
;;     unsafe {
;;         kasmer_set_ledger_timestamp(Val::from_val(env, &x).get_payload());
;;     }
;; }
;; 
;; #[contractimpl]
;; impl TtlContract {
;;     pub fn test_timestamp(env: Env, t: u64) -> bool {
;;         set_ledger_timestamp(&env, t);
;;         env.ledger().timestamp() == t as u64
;;     }
;; }
uploadWasm( b"test-wasm",
(module
  (type (;0;) (func (param i64) (result i64)))
  (type (;1;) (func (param i64)))
  (type (;2;) (func (result i64)))
  (type (;3;) (func (param i32)))
  (type (;4;) (func))
  (import "i" "0" (func (;0;) (type 0)))
  (import "i" "_" (func (;1;) (type 0)))
  (import "env" "kasmer_set_ledger_timestamp" (func (;2;) (type 1)))
  (import "x" "4" (func (;3;) (type 2)))
  (func (;4;) (type 0) (param i64) (result i64)
    (local i32 i32 i64)
    global.get 0
    i32.const 16
    i32.sub
    local.tee 1
    global.set 0
    block  ;; label = @1
      block  ;; label = @2
        block  ;; label = @3
          block  ;; label = @4
            local.get 0
            i32.wrap_i64
            i32.const 255
            i32.and
            local.tee 2
            i32.const 64
            i32.eq
            br_if 0 (;@4;)
            block  ;; label = @5
              local.get 2
              i32.const 6
              i32.ne
              br_if 0 (;@5;)
              local.get 0
              i64.const 8
              i64.shr_u
              local.set 0
              br 2 (;@3;)
            end
            unreachable
            unreachable
          end
          local.get 0
          call 0
          local.tee 0
          i64.const 72057594037927935
          i64.gt_u
          br_if 1 (;@2;)
        end
        local.get 0
        i64.const 8
        i64.shl
        i64.const 6
        i64.or
        local.set 3
        br 1 (;@1;)
      end
      local.get 0
      call 1
      local.set 3
    end
    local.get 3
    call 2
    block  ;; label = @1
      block  ;; label = @2
        call 3
        local.tee 3
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
          i32.ne
          br_if 0 (;@3;)
          local.get 3
          i64.const 8
          i64.shr_u
          local.set 3
          br 2 (;@1;)
        end
        local.get 1
        i32.const 8
        i32.add
        call 5
        unreachable
      end
      local.get 3
      call 0
      local.set 3
    end
    local.get 1
    i32.const 16
    i32.add
    global.set 0
    local.get 3
    local.get 0
    i64.eq
    i64.extend_i32_u)
  (func (;5;) (type 3) (param i32)
    call 6
    unreachable)
  (func (;6;) (type 4)
    unreachable
    unreachable)
  (func (;7;) (type 4))
  (memory (;0;) 16)
  (global (;0;) (mut i32) (i32.const 1048576))
  (global (;1;) i32 (i32.const 1048576))
  (global (;2;) i32 (i32.const 1048576))
  (export "memory" (memory 0))
  (export "test_timestamp" (func 4))
  (export "_" (func 7))
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
  "test_timestamp",
  ListItem(U64(123)),
  SCBool(true)
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "test_timestamp",
  ListItem(U64(90000000000000000)),
  SCBool(true)
)

setExitCode(0)