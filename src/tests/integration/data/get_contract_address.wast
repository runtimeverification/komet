
setExitCode(1)

uploadWasm( b"test-wasm",
;; #![no_std]
;; use soroban_sdk::{contract, contractimpl, Address, Env};
;; 
;; #[contract]
;; pub struct IncrementContract;
;; 
;; #[contractimpl]
;; impl IncrementContract {
;;     pub fn get_address(env: Env) -> Address {
;;         env.current_contract_address()
;;     }
;; }
(module $soroban_increment_contract.wasm
  (type (;0;) (func (result i64)))
  (type (;1;) (func))
  (import "x" "7" (func $_ZN17soroban_env_guest5guest7context28get_current_contract_address17hd0d5b3707078d502E (type 0)))
  (func $get_address (type 0) (result i64)
    call $_ZN17soroban_env_guest5guest7context28get_current_contract_address17hd0d5b3707078d502E)
  (func $_ (type 1))
  (memory (;0;) 16)
  (global $__stack_pointer (mut i32) (i32.const 1048576))
  (global (;1;) i32 (i32.const 1048576))
  (global (;2;) i32 (i32.const 1048576))
  (export "memory" (memory 0))
  (export "get_address" (func $get_address))
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
  "get_address",
  .List,
  ScAddress(Contract(b"test-sc"))
)

setExitCode(0)