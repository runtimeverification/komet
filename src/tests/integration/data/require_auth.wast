
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
;;     pub fn require_auth(env: Env) {
;;         let a = env.current_contract_address();
;;         a.require_auth();
;;     }
;; }
(module $soroban_increment_contract.wasm
  (type (;0;) (func (result i64)))
  (type (;1;) (func (param i64) (result i64)))
  (type (;2;) (func))
  (import "x" "7" (func $_ZN17soroban_env_guest5guest7context28get_current_contract_address17hd0d5b3707078d502E (type 0)))
  (import "a" "0" (func $_ZN17soroban_env_guest5guest7address12require_auth17hd692125619c6dd23E (type 1)))
  (func $require_auth (type 0) (result i64)
    call $_ZN17soroban_env_guest5guest7context28get_current_contract_address17hd0d5b3707078d502E
    call $_ZN17soroban_env_guest5guest7address12require_auth17hd692125619c6dd23E
    drop
    i64.const 2)
  (func $_ (type 2))
  (memory (;0;) 16)
  (global $__stack_pointer (mut i32) (i32.const 1048576))
  (global (;1;) i32 (i32.const 1048576))
  (global (;2;) i32 (i32.const 1048576))
  (export "memory" (memory 0))
  (export "require_auth" (func $require_auth))
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

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "require_auth",
  .List,
  Void
)

setExitCode(0)