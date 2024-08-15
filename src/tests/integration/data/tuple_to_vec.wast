
setExitCode(1)

uploadWasm( b"test-wasm",

;; /// `tuple_to_vec` takes a tuple and returns elements in reverse order

;; #![no_std]
;; use soroban_sdk::{contract, contractimpl, Env, contracttype, Vec};
;; 
;; #[contract]
;; pub struct IncrementContract;
;; 
;; #[contracttype]
;; #[derive(Debug, Clone)]
;; pub struct Point(u32, u32, u32);
;; 
;; #[contractimpl]
;; impl IncrementContract {
;; 
;;     pub fn tuple_to_vec(env: Env, p: Point) -> Vec<u32> {
;;         Vec::from_array(&env, [p.2, p.1, p.0])
;;     } 
;; }

(module $tuple_to_vec.wasm
  (type (;0;) (func (param i64 i64 i64) (result i64)))
  (type (;1;) (func (param i64 i64) (result i64)))
  (type (;2;) (func (param i64) (result i64)))
  (type (;3;) (func))
  (import "v" "h" (func $_ZN17soroban_env_guest5guest3vec27vec_unpack_to_linear_memory17h43fbd7ea3c12e8b3E (type 0)))
  (import "v" "g" (func $_ZN17soroban_env_guest5guest3vec26vec_new_from_linear_memory17h31f0f68089eaf9f9E (type 1)))
  (func $tuple_to_vec (type 2) (param i64) (result i64)
    (local i32 i32 i64 i64 i64 i32)
    global.get $__stack_pointer
    i32.const 48
    i32.sub
    local.tee 1
    global.set $__stack_pointer
    block  ;; label = @1
      local.get 0
      i64.const 255
      i64.and
      i64.const 75
      i64.ne
      br_if 0 (;@1;)
      i32.const 0
      local.set 2
      block  ;; label = @2
        loop  ;; label = @3
          local.get 2
          i32.const 24
          i32.eq
          br_if 1 (;@2;)
          local.get 1
          i32.const 24
          i32.add
          local.get 2
          i32.add
          i64.const 2
          i64.store
          local.get 2
          i32.const 8
          i32.add
          local.set 2
          br 0 (;@3;)
        end
      end
      local.get 0
      local.get 1
      i32.const 24
      i32.add
      i64.extend_i32_u
      local.tee 3
      i64.const 32
      i64.shl
      i64.const 4
      i64.or
      i64.const 12884901892
      call $_ZN17soroban_env_guest5guest3vec27vec_unpack_to_linear_memory17h43fbd7ea3c12e8b3E
      drop
      local.get 1
      i64.load offset=24
      local.tee 0
      i64.const 255
      i64.and
      i64.const 4
      i64.ne
      br_if 0 (;@1;)
      local.get 1
      i64.load offset=32
      local.tee 4
      i64.const 255
      i64.and
      i64.const 4
      i64.ne
      br_if 0 (;@1;)
      local.get 1
      i64.load offset=40
      local.tee 5
      i64.const 255
      i64.and
      i64.const 4
      i64.ne
      br_if 0 (;@1;)
      local.get 1
      local.get 0
      i64.const 32
      i64.shr_u
      i32.wrap_i64
      i32.store offset=20
      local.get 1
      local.get 4
      i64.const 32
      i64.shr_u
      i32.wrap_i64
      i32.store offset=16
      local.get 1
      local.get 5
      i64.const 32
      i64.shr_u
      i64.store32 offset=12
      i32.const 0
      local.set 2
      loop  ;; label = @2
        block  ;; label = @3
          local.get 2
          i32.const 24
          i32.ne
          br_if 0 (;@3;)
          local.get 1
          i32.const 24
          i32.add
          local.set 6
          i32.const 0
          local.set 2
          block  ;; label = @4
            loop  ;; label = @5
              local.get 2
              i32.const 12
              i32.eq
              br_if 1 (;@4;)
              local.get 6
              local.get 1
              i32.const 12
              i32.add
              local.get 2
              i32.add
              i64.load32_u
              i64.const 32
              i64.shl
              i64.const 4
              i64.or
              i64.store
              local.get 2
              i32.const 4
              i32.add
              local.set 2
              local.get 6
              i32.const 8
              i32.add
              local.set 6
              br 0 (;@5;)
            end
          end
          local.get 3
          i64.const 32
          i64.shl
          i64.const 4
          i64.or
          i64.const 12884901892
          call $_ZN17soroban_env_guest5guest3vec26vec_new_from_linear_memory17h31f0f68089eaf9f9E
          local.set 0
          local.get 1
          i32.const 48
          i32.add
          global.set $__stack_pointer
          local.get 0
          return
        end
        local.get 1
        i32.const 24
        i32.add
        local.get 2
        i32.add
        i64.const 2
        i64.store
        local.get 2
        i32.const 8
        i32.add
        local.set 2
        br 0 (;@2;)
      end
    end
    unreachable
    unreachable)
  (func $_ (type 3))
  (memory (;0;) 16)
  (global $__stack_pointer (mut i32) (i32.const 1048576))
  (global (;1;) i32 (i32.const 1048576))
  (global (;2;) i32 (i32.const 1048576))
  (export "memory" (memory 0))
  (export "tuple_to_vec" (func $tuple_to_vec))
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
  "tuple_to_vec",
  ListItem(
    ScVec(
      ListItem(U32(1))
      ListItem(U32(2))
      ListItem(U32(3))
    )
  ),
  ScVec(
    ListItem(U32(3))
    ListItem(U32(2))
    ListItem(U32(1))
  )
)

setExitCode(0)