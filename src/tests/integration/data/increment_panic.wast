
setExitCode(1)

uploadWasm( b"test-wasm",
;; pub struct IncrementContract;
;; 
;; #[contractimpl]
;; impl IncrementContract {
;;     pub fn increment(env: Env) -> u32 {
;;         let mut count: u32 = env.storage().instance().get(&COUNTER).unwrap_or(0);
;;         count += 1;
;;         env.storage().instance().set(&COUNTER, &count);
;;         count
;;     }
;; 
;;     pub fn increment_panic(env: Env) -> u32 {
;;         let mut count: u32 = env.storage().instance().get(&COUNTER).unwrap_or(0);
;;         count += 1;
;;         env.storage().instance().set(&COUNTER, &count);
;;         panic!()
;;     }
;; }
(module $soroban_increment_contract.wasm
  (type (;0;) (func (param i64 i64) (result i64)))
  (type (;1;) (func (param i64 i64 i64) (result i64)))
  (type (;2;) (func (param i32)))
  (type (;3;) (func (result i64)))
  (type (;4;) (func))
  (import "l" "0" (func $_ZN17soroban_env_guest5guest6ledger17has_contract_data17he4c980238e117d85E (type 0)))
  (import "l" "1" (func $_ZN17soroban_env_guest5guest6ledger17get_contract_data17h4f075bb2afc11861E (type 0)))
  (import "l" "_" (func $_ZN17soroban_env_guest5guest6ledger17put_contract_data17hbcf4a2a09b350844E (type 1)))
  (func $_ZN11soroban_sdk7storage8Instance3get17hbc53ccbc4676241bE (type 2) (param i32)
    (local i32 i64 i32)
    block  ;; label = @1
      block  ;; label = @2
        block  ;; label = @3
          i64.const 253576579652878
          i64.const 2
          call $_ZN17soroban_env_guest5guest6ledger17has_contract_data17he4c980238e117d85E
          i64.const 1
          i64.eq
          br_if 0 (;@3;)
          i32.const 0
          local.set 1
          br 1 (;@2;)
        end
        i64.const 253576579652878
        i64.const 2
        call $_ZN17soroban_env_guest5guest6ledger17get_contract_data17h4f075bb2afc11861E
        local.tee 2
        i64.const 255
        i64.and
        i64.const 4
        i64.ne
        br_if 1 (;@1;)
        local.get 2
        i64.const 32
        i64.shr_u
        i32.wrap_i64
        local.set 3
        i32.const 1
        local.set 1
      end
      local.get 0
      local.get 3
      i32.store offset=4
      local.get 0
      local.get 1
      i32.store
      return
    end
    unreachable
    unreachable)
  (func $_ZN11soroban_sdk7storage8Instance3set17h1e50b5daa6d5db02E (type 2) (param i32)
    i64.const 253576579652878
    local.get 0
    i64.extend_i32_u
    i64.const 32
    i64.shl
    i64.const 4
    i64.or
    i64.const 2
    call $_ZN17soroban_env_guest5guest6ledger17put_contract_data17hbcf4a2a09b350844E
    drop)
  (func $increment (type 3) (result i64)
    (local i32 i32)
    global.get $__stack_pointer
    i32.const 16
    i32.sub
    local.tee 0
    global.set $__stack_pointer
    local.get 0
    i32.const 8
    i32.add
    call $_ZN11soroban_sdk7storage8Instance3get17hbc53ccbc4676241bE
    block  ;; label = @1
      local.get 0
      i32.load offset=12
      i32.const 0
      local.get 0
      i32.load offset=8
      select
      i32.const 1
      i32.add
      local.tee 1
      br_if 0 (;@1;)
      call $_ZN4core9panicking11panic_const24panic_const_add_overflow17hde776086e9d58b0fE
      unreachable
    end
    local.get 1
    call $_ZN11soroban_sdk7storage8Instance3set17h1e50b5daa6d5db02E
    local.get 0
    i32.const 16
    i32.add
    global.set $__stack_pointer
    local.get 1
    i64.extend_i32_u
    i64.const 32
    i64.shl
    i64.const 4
    i64.or)
  (func $_ZN4core9panicking11panic_const24panic_const_add_overflow17hde776086e9d58b0fE (type 4)
    call $_ZN4core9panicking9panic_fmt17h5c7ce52813e94bcdE
    unreachable)
  (func $increment_panic (type 3) (result i64)
    (local i32)
    global.get $__stack_pointer
    i32.const 16
    i32.sub
    local.tee 0
    global.set $__stack_pointer
    local.get 0
    i32.const 8
    i32.add
    call $_ZN11soroban_sdk7storage8Instance3get17hbc53ccbc4676241bE
    block  ;; label = @1
      local.get 0
      i32.load offset=12
      i32.const 0
      local.get 0
      i32.load offset=8
      select
      i32.const 1
      i32.add
      local.tee 0
      i32.eqz
      br_if 0 (;@1;)
      local.get 0
      call $_ZN11soroban_sdk7storage8Instance3set17h1e50b5daa6d5db02E
      call $_ZN26soroban_increment_contract17IncrementContract15increment_panic19panic_cold_explicit17h2e1d9a10feff35b7E
      unreachable
    end
    call $_ZN4core9panicking11panic_const24panic_const_add_overflow17hde776086e9d58b0fE
    unreachable)
  (func $_ZN26soroban_increment_contract17IncrementContract15increment_panic19panic_cold_explicit17h2e1d9a10feff35b7E (type 4)
    call $_ZN4core9panicking14panic_explicit17h47855c360709a39dE
    unreachable)
  (func $_ZN4core9panicking14panic_explicit17h47855c360709a39dE (type 4)
    call $_ZN4core9panicking13panic_display17hbd841ae85eb3dff4E
    unreachable)
  (func $_ZN4core9panicking9panic_fmt17h5c7ce52813e94bcdE (type 4)
    unreachable
    unreachable)
  (func $_ZN4core9panicking13panic_display17hbd841ae85eb3dff4E (type 4)
    call $_ZN4core9panicking9panic_fmt17h5c7ce52813e94bcdE
    unreachable)
  (func $_ (type 4))
  (memory (;0;) 16)
  (global $__stack_pointer (mut i32) (i32.const 1048576))
  (global (;1;) i32 (i32.const 1048576))
  (global (;2;) i32 (i32.const 1048576))
  (export "memory" (memory 0))
  (export "increment" (func $increment))
  (export "increment_panic" (func $increment_panic))
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
  "increment",
  .List,
  U32(1)
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "increment",
  .List,
  U32(2)
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "increment_panic",
  .List,
  Error(ErrContext, InvalidAction)
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "increment",
  .List,
  U32(3)
)

setExitCode(0)