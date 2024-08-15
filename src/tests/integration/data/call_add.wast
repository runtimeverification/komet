
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
;;     pub fn add(_env: Env, x: u32, y: u32) -> u32 {
;;         x + y
;;     }
;;     pub fn call_other(env: Env, addr: Address, x: u32, y: u32) -> u32 {
;;         let client = IncrementContractClient::new(&env, &addr);
;;         client.add(&x, &y)
;;     }
;; }
(module $soroban_increment_contract.wasm
  (type (;0;) (func (param i64 i64) (result i64)))
  (type (;1;) (func (param i64 i64 i64) (result i64)))
  (type (;2;) (func))
  (type (;3;) (func (param i32)))
  (import "b" "j" (func $_ZN17soroban_env_guest5guest3buf29symbol_new_from_linear_memory17h35ac7f14f9817888E (type 0)))
  (import "v" "g" (func $_ZN17soroban_env_guest5guest3vec26vec_new_from_linear_memory17h70c58232833beea9E (type 0)))
  (import "d" "_" (func $_ZN17soroban_env_guest5guest4call4call17hb799ec77dfde2c11E (type 1)))
  (func $add (type 0) (param i64 i64) (result i64)
    (local i32 i32)
    block  ;; label = @1
      block  ;; label = @2
        local.get 0
        i64.const 255
        i64.and
        i64.const 4
        i64.ne
        br_if 0 (;@2;)
        local.get 1
        i64.const 255
        i64.and
        i64.const 4
        i64.ne
        br_if 0 (;@2;)
        local.get 0
        i64.const 32
        i64.shr_u
        i32.wrap_i64
        local.tee 2
        local.get 1
        i64.const 32
        i64.shr_u
        i32.wrap_i64
        i32.add
        local.tee 3
        local.get 2
        i32.lt_u
        br_if 1 (;@1;)
        local.get 3
        i64.extend_i32_u
        i64.const 32
        i64.shl
        i64.const 4
        i64.or
        return
      end
      unreachable
      unreachable
    end
    call $_ZN4core9panicking11panic_const24panic_const_add_overflow17hde776086e9d58b0fE
    unreachable)
  (func $_ZN4core9panicking11panic_const24panic_const_add_overflow17hde776086e9d58b0fE (type 2)
    call $_ZN4core9panicking9panic_fmt17h5c7ce52813e94bcdE
    unreachable)
  (func $call_other (type 1) (param i64 i64 i64) (result i64)
    (local i32 i64 i32 i32 i32)
    global.get $__stack_pointer
    i32.const 32
    i32.sub
    local.tee 3
    global.set $__stack_pointer
    block  ;; label = @1
      local.get 0
      i64.const 255
      i64.and
      i64.const 77
      i64.ne
      br_if 0 (;@1;)
      local.get 1
      i64.const 255
      i64.and
      i64.const 4
      i64.ne
      br_if 0 (;@1;)
      local.get 2
      i64.const 255
      i64.and
      i64.const 4
      i64.ne
      br_if 0 (;@1;)
      i64.const 0
      local.set 4
      i32.const -3
      local.set 5
      block  ;; label = @2
        block  ;; label = @3
          block  ;; label = @4
            loop  ;; label = @5
              local.get 5
              i32.eqz
              br_if 1 (;@4;)
              i32.const 1
              local.set 6
              block  ;; label = @6
                local.get 5
                i32.const 1048579
                i32.add
                i32.load8_u
                local.tee 7
                i32.const 95
                i32.eq
                br_if 0 (;@6;)
                block  ;; label = @7
                  local.get 7
                  i32.const -48
                  i32.add
                  i32.const 255
                  i32.and
                  i32.const 10
                  i32.lt_u
                  br_if 0 (;@7;)
                  block  ;; label = @8
                    local.get 7
                    i32.const -65
                    i32.add
                    i32.const 255
                    i32.and
                    i32.const 26
                    i32.lt_u
                    br_if 0 (;@8;)
                    local.get 7
                    i32.const -97
                    i32.add
                    i32.const 255
                    i32.and
                    i32.const 25
                    i32.gt_u
                    br_if 5 (;@3;)
                    local.get 7
                    i32.const -59
                    i32.add
                    local.set 6
                    br 2 (;@6;)
                  end
                  local.get 7
                  i32.const -53
                  i32.add
                  local.set 6
                  br 1 (;@6;)
                end
                local.get 7
                i32.const -46
                i32.add
                local.set 6
              end
              local.get 4
              i64.const 6
              i64.shl
              local.get 6
              i64.extend_i32_u
              i64.const 255
              i64.and
              i64.or
              local.set 4
              local.get 5
              i32.const 1
              i32.add
              local.set 5
              br 0 (;@5;)
            end
          end
          local.get 4
          i64.const 8
          i64.shl
          i64.const 14
          i64.or
          local.set 4
          br 1 (;@2;)
        end
        i32.const 1048576
        i64.extend_i32_u
        i64.const 32
        i64.shl
        i64.const 4
        i64.or
        i64.const 12884901892
        call $_ZN17soroban_env_guest5guest3buf29symbol_new_from_linear_memory17h35ac7f14f9817888E
        local.set 4
      end
      local.get 3
      local.get 2
      i64.const -4294967292
      i64.and
      i64.store offset=8
      local.get 3
      local.get 1
      i64.const -4294967292
      i64.and
      i64.store
      i32.const 0
      local.set 5
      block  ;; label = @2
        loop  ;; label = @3
          block  ;; label = @4
            local.get 5
            i32.const 16
            i32.ne
            br_if 0 (;@4;)
            i32.const 0
            local.set 5
            block  ;; label = @5
              loop  ;; label = @6
                local.get 5
                i32.const 16
                i32.eq
                br_if 1 (;@5;)
                local.get 3
                i32.const 16
                i32.add
                local.get 5
                i32.add
                local.get 3
                local.get 5
                i32.add
                i64.load
                i64.store
                local.get 5
                i32.const 8
                i32.add
                local.set 5
                br 0 (;@6;)
              end
            end
            local.get 0
            local.get 4
            local.get 3
            i32.const 16
            i32.add
            i64.extend_i32_u
            i64.const 32
            i64.shl
            i64.const 4
            i64.or
            i64.const 8589934596
            call $_ZN17soroban_env_guest5guest3vec26vec_new_from_linear_memory17h70c58232833beea9E
            call $_ZN17soroban_env_guest5guest4call4call17hb799ec77dfde2c11E
            local.tee 4
            i64.const 255
            i64.and
            i64.const 4
            i64.ne
            br_if 2 (;@2;)
            local.get 3
            i32.const 32
            i32.add
            global.set $__stack_pointer
            local.get 4
            i64.const -4294967292
            i64.and
            return
          end
          local.get 3
          i32.const 16
          i32.add
          local.get 5
          i32.add
          i64.const 2
          i64.store
          local.get 5
          i32.const 8
          i32.add
          local.set 5
          br 0 (;@3;)
        end
      end
      local.get 3
      i32.const 16
      i32.add
      call $_ZN4core6result13unwrap_failed17h4ed86702351a3017E
      unreachable
    end
    unreachable
    unreachable)
  (func $_ZN4core6result13unwrap_failed17h4ed86702351a3017E (type 3) (param i32)
    call $_ZN4core9panicking9panic_fmt17h5c7ce52813e94bcdE
    unreachable)
  (func $_ZN4core9panicking9panic_fmt17h5c7ce52813e94bcdE (type 2)
    unreachable
    unreachable)
  (func $_ (type 2))
  (memory (;0;) 17)
  (global $__stack_pointer (mut i32) (i32.const 1048576))
  (global (;1;) i32 (i32.const 1048579))
  (global (;2;) i32 (i32.const 1048592))
  (export "memory" (memory 0))
  (export "add" (func $add))
  (export "call_other" (func $call_other))
  (export "_" (func $_))
  (export "__data_end" (global 1))
  (export "__heap_base" (global 2))
  (data $.rodata (i32.const 1048576) "add"))
)

setAccount(Account(b"test-account"), 9876543210)

;; let c1 = env.register_contract(None, IncrementContract);
;; let c2 = env.register_contract(None, IncrementContract);

deployContract(
  Account(b"test-account"),
  Contract(b"test-sc-1"),
  b"test-wasm"
)

deployContract(
  Account(b"test-account"),
  Contract(b"test-sc-2"),
  b"test-wasm"
)

;; let client = IncrementContractClient::new(&env, &c1);
;; assert_eq!(client.call_other(&c2, &3, &5), 8);

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc-1"),
  "call_other",
  ListItem(ScAddress(Contract(b"test-sc-2"))) ListItem(U32(3)) ListItem(U32(5)),
  U32(8)
)


setExitCode(0)