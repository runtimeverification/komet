
setExitCode(1)

uploadWasm( b"test-wasm",

;; Increment contract with two integer counters and one endpoint, `increment`.
;; `increment` takes a boolean to select a counter, increments the chosen counter by one, and returns the updated value.

;; #![no_std]
;; use soroban_sdk::{contract, contractimpl, log, symbol_short, Env, Symbol};

;; const COUNTER1: Symbol = symbol_short!("COUNTER1");
;; const COUNTER2: Symbol = symbol_short!("COUNTER2");

;; #[contract]
;; pub struct IncrementContract;

;; #[contractimpl]
;; impl IncrementContract {
;;     pub fn increment(env: Env, p: bool) -> u32 {
;;         let counter = if p { COUNTER1 } else { COUNTER2 };
;;         let mut count: u32 = env.storage().instance().get(&counter).unwrap_or(0);

;;         count += 1;

;;         log!(&env, "count: {}", count);

;;         env.storage().instance().set(&counter, &count);

;;         count
;;     }
;; }
(module $soroban_increment_contract.wasm
  (type (;0;) (func (param i64 i64) (result i64)))
  (type (;1;) (func (param i64 i64 i64) (result i64)))
  (type (;2;) (func (param i64) (result i64)))
  (type (;3;) (func))
  (import "l" "0" (func $_ZN17soroban_env_guest5guest6ledger17has_contract_data17h79546e647e9b20a7E (type 0)))
  (import "l" "1" (func $_ZN17soroban_env_guest5guest6ledger17get_contract_data17h472f93112d86127fE (type 0)))
  (import "l" "_" (func $_ZN17soroban_env_guest5guest6ledger17put_contract_data17h6938c7a297250993E (type 1)))
  (func $increment (type 2) (param i64) (result i64)
    (local i32 i32 i64)
    block  ;; label = @1
      block  ;; label = @2
        local.get 0
        i32.wrap_i64
        i32.const 255
        i32.and
        local.tee 1
        i32.const 2
        i32.ge_u
        br_if 0 (;@2;)
        i32.const 0
        local.set 2
        block  ;; label = @3
          i64.const 16228901097784078
          i64.const 16228901097784334
          local.get 1
          select
          local.tee 0
          i64.const 2
          call $_ZN17soroban_env_guest5guest6ledger17has_contract_data17h79546e647e9b20a7E
          i64.const 1
          i64.ne
          br_if 0 (;@3;)
          local.get 0
          i64.const 2
          call $_ZN17soroban_env_guest5guest6ledger17get_contract_data17h472f93112d86127fE
          local.tee 3
          i64.const 255
          i64.and
          i64.const 4
          i64.ne
          br_if 1 (;@2;)
          local.get 3
          i64.const 32
          i64.shr_u
          i32.wrap_i64
          local.set 2
        end
        local.get 2
        i32.const 1
        i32.add
        local.tee 2
        i32.eqz
        br_if 1 (;@1;)
        local.get 0
        local.get 2
        i64.extend_i32_u
        i64.const 32
        i64.shl
        i64.const 4
        i64.or
        local.tee 3
        i64.const 2
        call $_ZN17soroban_env_guest5guest6ledger17put_contract_data17h6938c7a297250993E
        drop
        local.get 3
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
  (export "increment" (func $increment))
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

;; assert_eq!(client.increment(&true), 1);
;; assert_eq!(client.increment(&true), 2);
;; assert_eq!(client.increment(&false), 1);
;; assert_eq!(client.increment(&true), 3);
;; assert_eq!(client.increment(&false), 2);

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "increment",
  ListItem(SCBool(true)),
  U32(1)
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "increment",
  ListItem(SCBool(true)),
  U32(2)
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "increment",
  ListItem(SCBool(false)),
  U32(1)
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "increment",
  ListItem(SCBool(true)),
  U32(3)
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "increment",
  ListItem(SCBool(false)),
  U32(2)
)

setExitCode(0)