
setExitCode(1)

uploadWasm( b"test-wasm",
;; #![no_std]
;; use soroban_sdk::{contract, contractimpl, Env, Bytes};
;; 
;; #[contract]
;; pub struct IncrementContract;
;; 
;; #[contractimpl]
;; impl IncrementContract {
;;     pub fn get_len(_env: Env, bs: Bytes) -> u32 {
;;         bs.len()
;;     }
;; 
;;     pub fn encode_u64(env: Env, x: u64) -> Bytes {
;;         Bytes::from_array(&env, &x.to_be_bytes())
;;     }
;; }
(module $soroban_increment_contract.wasm
  (type (;0;) (func (param i64) (result i64)))
  (type (;1;) (func (param i64 i64) (result i64)))
  (type (;2;) (func))
  (import "b" "8" (func $_ZN17soroban_env_guest5guest3buf9bytes_len17h05a915be159e6975E (type 0)))
  (import "i" "0" (func $_ZN17soroban_env_guest5guest3int10obj_to_u6417hb6825d7c3a487396E (type 0)))
  (import "b" "3" (func $_ZN17soroban_env_guest5guest3buf28bytes_new_from_linear_memory17hd0615159a54bda25E (type 1)))
  (func $get_len (type 0) (param i64) (result i64)
    block  ;; label = @1
      local.get 0
      i64.const 255
      i64.and
      i64.const 72
      i64.eq
      br_if 0 (;@1;)
      unreachable
      unreachable
    end
    local.get 0
    call $_ZN17soroban_env_guest5guest3buf9bytes_len17h05a915be159e6975E
    i64.const -4294967296
    i64.and
    i64.const 4
    i64.or)
  (func $encode_u64 (type 0) (param i64) (result i64)
    (local i32 i32)
    global.get $__stack_pointer
    i32.const 16
    i32.sub
    local.tee 1
    global.set $__stack_pointer
    block  ;; label = @1
      block  ;; label = @2
        local.get 0
        i32.wrap_i64
        i32.const 255
        i32.and
        local.tee 2
        i32.const 64
        i32.eq
        br_if 0 (;@2;)
        block  ;; label = @3
          local.get 2
          i32.const 6
          i32.ne
          br_if 0 (;@3;)
          local.get 0
          i64.const 8
          i64.shr_u
          local.set 0
          br 2 (;@1;)
        end
        unreachable
        unreachable
      end
      local.get 0
      call $_ZN17soroban_env_guest5guest3int10obj_to_u6417hb6825d7c3a487396E
      local.set 0
    end
    local.get 1
    local.get 0
    i64.const 56
    i64.shl
    local.get 0
    i64.const 65280
    i64.and
    i64.const 40
    i64.shl
    i64.or
    local.get 0
    i64.const 16711680
    i64.and
    i64.const 24
    i64.shl
    local.get 0
    i64.const 4278190080
    i64.and
    i64.const 8
    i64.shl
    i64.or
    i64.or
    local.get 0
    i64.const 8
    i64.shr_u
    i64.const 4278190080
    i64.and
    local.get 0
    i64.const 24
    i64.shr_u
    i64.const 16711680
    i64.and
    i64.or
    local.get 0
    i64.const 40
    i64.shr_u
    i64.const 65280
    i64.and
    local.get 0
    i64.const 56
    i64.shr_u
    i64.or
    i64.or
    i64.or
    i64.store offset=8
    local.get 1
    i32.const 8
    i32.add
    i64.extend_i32_u
    i64.const 32
    i64.shl
    i64.const 4
    i64.or
    i64.const 34359738372
    call $_ZN17soroban_env_guest5guest3buf28bytes_new_from_linear_memory17hd0615159a54bda25E
    local.set 0
    local.get 1
    i32.const 16
    i32.add
    global.set $__stack_pointer
    local.get 0)
  (func $_ (type 2))
  (memory (;0;) 16)
  (global $__stack_pointer (mut i32) (i32.const 1048576))
  (global (;1;) i32 (i32.const 1048576))
  (global (;2;) i32 (i32.const 1048576))
  (export "memory" (memory 0))
  (export "get_len" (func $get_len))
  (export "encode_u64" (func $encode_u64))
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
  "get_len",
  ListItem(ScBytes(b"1234")),
  U32(4)
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "get_len",
  ListItem(ScBytes(b"")),
  U32(0)
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "encode_u64",
  ListItem(U64(0)),
  ScBytes(b"\x00\x00\x00\x00\x00\x00\x00\x00")
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "encode_u64",
  ListItem(U64(123)),
  ScBytes(b"\x00\x00\x00\x00\x00\x00\x00\x7b")
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "encode_u64",
  ListItem(U64(12379813812177893520)),
  ScBytes(b"\xab\xcd\xef\x12\x34\x56\x78\x90")
)

setExitCode(0)