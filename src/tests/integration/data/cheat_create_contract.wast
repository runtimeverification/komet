
setExitCode(1)

uploadWasm( b"test-wasm",
;; #![no_std]
;; use soroban_sdk::{contract, contractimpl, Address, Bytes, Env, FromVal, Val};
;; 
;; extern "C" {
;;     fn kasmer_create_contract(addr_val: u64, hash_val: u64) -> u64;
;; }
;; 
;; fn create_contract(env: &Env, addr: &Bytes, hash: &Bytes) -> Address {
;;     unsafe {
;;         let res = kasmer_create_contract(addr.as_val().get_payload(), hash.as_val().get_payload());
;;         Address::from_val(env, &Val::from_payload(res))
;;     }
;; }
;; 
;; #[contract]
;; pub struct IncrementContract;
;; 
;; #[contractimpl]
;; impl IncrementContract {
;;     pub fn create_contract(env: Env, addr: Bytes, hash: Bytes) -> Address {
;;         create_contract(&env, &addr, &hash)
;;     }
;; }
(module $soroban_increment_contract.wasm
  (type (;0;) (func (param i64 i64) (result i64)))
  (type (;1;) (func))
  (import "env" "kasmer_create_contract" (func $kasmer_create_contract (type 0)))
  (func $create_contract (type 0) (param i64 i64) (result i64)
    block  ;; label = @1
      local.get 0
      i64.const 255
      i64.and
      i64.const 72
      i64.ne
      br_if 0 (;@1;)
      local.get 1
      i64.const 255
      i64.and
      i64.const 72
      i64.ne
      br_if 0 (;@1;)
      local.get 0
      local.get 1
      call $kasmer_create_contract
      local.tee 0
      i64.const 255
      i64.and
      i64.const 77
      i64.ne
      br_if 0 (;@1;)
      local.get 0
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
  (export "create_contract" (func $create_contract))
  (export "_" (func $_))
  (export "__data_end" (global 1))
  (export "__heap_base" (global 2)))
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
  "create_contract",
  ListItem(ScBytes(b"child-ctr")) ListItem(ScBytes(b"test-wasm")),
  ScAddress(Contract(b"child-ctr"))
)

setExitCode(0)