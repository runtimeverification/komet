
setExitCode(1)

uploadWasm( b"test-wasm",
;; #![no_std]
;; use soroban_sdk::{contract, contractimpl, Env, Val};

;; #[contract]
;; pub struct IncrementContract;

;; // To enable the `kasmer_set_ledger_sequence` cheatcode, we first need to declare it as an extern function
;; // The function will appear as an import from the "env" module
;; //
;; //   (import "env" "kasmer_set_ledger_sequence" (func $kasmer_set_ledger_sequence (param i64)))
;; //
;; extern "C" {
;;     fn kasmer_set_ledger_sequence(x : u64);
;; }

;; fn set_ledger_sequence(x: u32) {
;;     unsafe {
;;         kasmer_set_ledger_sequence(Val::from_u32(x).to_val().get_payload());
;;     }
;; }

;; #[contractimpl]
;; impl IncrementContract {
;;     pub fn ledger_seq(env: Env, x: u32) -> u32 {
;;         set_ledger_sequence(x);
;;         env.ledger().sequence()
;;     }
;; }
(module $soroban_increment_contract.wasm
  (type (;0;) (func (param i64)))
  (type (;1;) (func (result i64)))
  (type (;2;) (func (param i64) (result i64)))
  (type (;3;) (func))
  (import "env" "kasmer_set_ledger_sequence" (func $kasmer_set_ledger_sequence (type 0)))
  (import "x" "3" (func $_ZN17soroban_env_guest5guest7context19get_ledger_sequence17hf00ca4c800c2f287E (type 1)))
  (func $ledger_seq (type 2) (param i64) (result i64)
    block  ;; label = @1
      local.get 0
      i64.const 255
      i64.and
      i64.const 4
      i64.eq
      br_if 0 (;@1;)
      unreachable
      unreachable
    end
    local.get 0
    i64.const -4294967292
    i64.and
    call $kasmer_set_ledger_sequence
    call $_ZN17soroban_env_guest5guest7context19get_ledger_sequence17hf00ca4c800c2f287E
    i64.const -4294967296
    i64.and
    i64.const 4
    i64.or)
  (func $_ (type 3))
  (memory (;0;) 16)
  (global $__stack_pointer (mut i32) (i32.const 1048576))
  (global (;1;) i32 (i32.const 1048576))
  (global (;2;) i32 (i32.const 1048576))
  (export "memory" (memory 0))
  (export "ledger_seq" (func $ledger_seq))
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
  "ledger_seq",
  ListItem(U32(1)),
  U32(1)
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "ledger_seq",
  ListItem(U32(987654321)),
  U32(987654321)
)

setExitCode(0)