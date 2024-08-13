
setExitCode(1)

uploadWasm( b"test-wasm",
;; #![no_std]
;; use soroban_sdk::{contract, contracterror, contractimpl, panic_with_error,  Env};
;; 
;; #[contracterror]
;; #[derive(Copy, Clone, Debug, Eq, PartialEq, PartialOrd, Ord)]
;; #[repr(u32)]
;; pub enum CustomError {
;;     CustomErrorCode1 = 1,
;;     CustomErrorCode2 = 2,
;; }
;; 
;; #[contract]
;; pub struct IncrementContract;
;; 
;; #[contractimpl]
;; impl IncrementContract {
;;     /// Increment increments an internal counter, and returns the value. Errors
;;     /// if the value is attempted to be incremented past 5.
;;     pub fn custom_fail(_env: Env, p: bool) -> Result<u32, CustomError> {
;;         Err(
;;             match p {
;;                 false => CustomError::CustomErrorCode1,
;;                 true => CustomError::CustomErrorCode2
;;             }
;;         )
;;     }
;; 
;;     pub fn panic_fail(_env: Env) {
;;         panic!()
;;     }
;; 
;;     pub fn panic_with_error_fail(env: Env, p: bool) {
;;         panic_with_error!(env, match p {
;;             false => CustomError::CustomErrorCode1,
;;             true => CustomError::CustomErrorCode2
;;         })
;;     }
;; }
;; mod test;
(module $soroban_errors_contract.wasm
  (type (;0;) (func (param i64) (result i64)))
  (type (;1;) (func (result i64)))
  (type (;2;) (func))
  (type (;3;) (func (param i64)))
  (import "x" "5" (func $_ZN17soroban_env_guest5guest7context15fail_with_error17h712c0ad18a303073E (type 0)))
  (func $custom_fail (type 0) (param i64) (result i64)
    (local i32)
    block  ;; label = @1
      local.get 0
      i32.wrap_i64
      i32.const 255
      i32.and
      local.tee 1
      i32.const 2
      i32.lt_u
      br_if 0 (;@1;)
      unreachable
      unreachable
    end
    i64.const 8589934595
    i64.const 4294967299
    local.get 1
    select)
  (func $panic_fail (type 1) (result i64)
    call $_ZN23soroban_errors_contract17IncrementContract10panic_fail19panic_cold_explicit17h500069efcbed89a3E
    unreachable)
  (func $_ZN23soroban_errors_contract17IncrementContract10panic_fail19panic_cold_explicit17h500069efcbed89a3E (type 2)
    call $_ZN4core9panicking14panic_explicit17h47855c360709a39dE
    unreachable)
  (func $panic_with_error_fail (type 0) (param i64) (result i64)
    (local i32)
    block  ;; label = @1
      local.get 0
      i32.wrap_i64
      i32.const 255
      i32.and
      local.tee 1
      i32.const 2
      i32.ge_u
      br_if 0 (;@1;)
      i64.const 8589934595
      i64.const 4294967299
      local.get 1
      select
      call $_ZN70_$LT$soroban_sdk..env..Env$u20$as$u20$soroban_env_common..env..Env$GT$15fail_with_error17h4649cb3441ec7f31E
    end
    unreachable
    unreachable)
  (func $_ZN70_$LT$soroban_sdk..env..Env$u20$as$u20$soroban_env_common..env..Env$GT$15fail_with_error17h4649cb3441ec7f31E (type 3) (param i64)
    local.get 0
    call $_ZN17soroban_env_guest5guest7context15fail_with_error17h712c0ad18a303073E
    drop)
  (func $_ZN4core9panicking14panic_explicit17h47855c360709a39dE (type 2)
    call $_ZN4core9panicking13panic_display17hbd841ae85eb3dff4E
    unreachable)
  (func $_ZN4core9panicking9panic_fmt17h5c7ce52813e94bcdE (type 2)
    unreachable
    unreachable)
  (func $_ZN4core9panicking13panic_display17hbd841ae85eb3dff4E (type 2)
    call $_ZN4core9panicking9panic_fmt17h5c7ce52813e94bcdE
    unreachable)
  (func $_ (type 2))
  (memory (;0;) 16)
  (global $__stack_pointer (mut i32) (i32.const 1048576))
  (global (;1;) i32 (i32.const 1048576))
  (global (;2;) i32 (i32.const 1048576))
  (export "memory" (memory 0))
  (export "custom_fail" (func $custom_fail))
  (export "panic_fail" (func $panic_fail))
  (export "panic_with_error_fail" (func $panic_with_error_fail))
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
  "panic_fail",
  .List,
  Error(ErrContext, InvalidAction)
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "custom_fail",
  ListItem(SCBool(false)),
  Error(ErrContract, 1)
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "custom_fail",
  ListItem(SCBool(true)),
  Error(ErrContract, 2)
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "panic_with_error_fail",
  ListItem(SCBool(false)),
  Error(ErrContract, 1)
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "panic_with_error_fail",
  ListItem(SCBool(true)),
  Error(ErrContract, 2)
)

setExitCode(0)