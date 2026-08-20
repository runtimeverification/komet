setExitCode(1)

;; `extend_ttl.wast` covers the host call at ledger 0, where a contract deployed
;; with `contractLiveUntil = 0` still counts as alive. This file covers the same
;; host call at a LATER ledger: an upload/deploy must start the code and instance
;; entries at the minimum persistent TTL, otherwise every extension past ledger 0
;; sees an expired entry.
uploadWasm( b"test-wasm",
(module $test_wasm
  ;; The cheatcode takes a U32 HostVal payload and returns nothing; see
  ;; ledger_sequence_get_set.wast for the Rust side of this declaration.
  (import "env" "kasmer_set_ledger_sequence" (func $kasmer_set_ledger_sequence (param i64)))
  (import "l" "8" (func $extend_current_contract_instance_and_code_ttl (param i64 i64) (result i64)))
  ;; extend_at(seq, threshold, extend_to): move the ledger to `seq`, then extend
  ;; this contract's instance and code TTL. Returns the host call's Void.
  (func $extend_at (param i64 i64 i64) (result i64)
    (call $kasmer_set_ledger_sequence (local.get 0))
    (call $extend_current_contract_instance_and_code_ttl (local.get 1) (local.get 2))
  )
  (export "extend_at" (func $extend_at))
))

setAccount(Account(b"test-account"), 9876543210)

deployContract(
  Account(b"test-account"),
  Contract(b"test-sc"),
  b"test-wasm"
)

;; Deployed at ledger 0, so both entries live until 4095 (minimum persistent TTL
;; of 4096, inclusive bound). At ledger 100 they are alive, and the current TTL
;; (3995) already exceeds the threshold, so this is a successful no-op.
callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "extend_at",
  ListItem(U32(100)) ListItem(U32(50)) ListItem(U32(200)),
  Void
)

;; At ledger 4090 the remaining TTL (5) is below the threshold, so the entries
;; are extended to ledger 4290.
callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "extend_at",
  ListItem(U32(4090)) ListItem(U32(50)) ListItem(U32(200)),
  Void
)

;; Past that, the entries have expired: there is nothing to extend, and the host
;; call fails rather than leaving the interpreter stuck.
callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "extend_at",
  ListItem(U32(5000)) ListItem(U32(50)) ListItem(U32(200)),
  Error(ErrStorage, InvalidAction)
)

setExitCode(0)
