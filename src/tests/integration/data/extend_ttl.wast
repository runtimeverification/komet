
setExitCode(1)

uploadWasm( b"test-wasm",
;; #![no_std]
;; use soroban_sdk::{contract, contractimpl, Env};
;; 
;; #[contract]
;; pub struct IncrementContract;
;; 
;; #[contractimpl]
;; impl IncrementContract {
;;     pub fn extend_ttl(env: Env, threshold: u32, extend_to: u32) {
;;         env.storage().instance().extend_ttl(threshold, extend_to);
;;     }
;; }
(module $soroban_increment_contract.wasm
  (type (;0;) (func (param i64 i64) (result i64)))
  (type (;1;) (func))
  (import "l" "8" (func $_ZN17soroban_env_guest5guest6ledger45extend_current_contract_instance_and_code_ttl17h6e6604048593c195E (type 0)))
  (func $extend_ttl (type 0) (param i64 i64) (result i64)
    block  ;; label = @1
      local.get 0
      i64.const 255
      i64.and
      i64.const 4
      i64.ne
      br_if 0 (;@1;)
      local.get 1
      i64.const 255
      i64.and
      i64.const 4
      i64.ne
      br_if 0 (;@1;)
      local.get 0
      i64.const -4294967292
      i64.and
      local.get 1
      i64.const -4294967292
      i64.and
      call $_ZN17soroban_env_guest5guest6ledger45extend_current_contract_instance_and_code_ttl17h6e6604048593c195E
      drop
      i64.const 2
      return
    end
    unreachable
    unreachable)
  (func $_ (type 1))
  (memory (;0;) 16)
  (global $__stack_pointer (mut i32) (i32.const 1048576))
  (global (;1;) i32 (i32.const 1048576))
  (global (;2;) i32 (i32.const 1048576))
  (export "memory" (memory 0))
  (export "extend_ttl" (func $extend_ttl))
  (export "_" (func $_))
  (export "__data_end" (global 1))
  (export "__heap_base" (global 2)))
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
  "extend_ttl",
  ListItem(U32(100)) ListItem(U32(100)),
  Void
)

setExitCode(0)