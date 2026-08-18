setExitCode(1)

uploadWasm( b"test-wasm",
(module $test_wasm
  ;; The cheatcode takes a U32 HostVal payload and returns nothing; see
  ;; ledger_sequence_get_set.wast for the Rust side of this declaration.
  (import "env" "kasmer_set_ledger_sequence" (func $kasmer_set_ledger_sequence (param i64)))
  (import "x" "8" (func $get_max_live_until_ledger (result i64)))
  (func $max_live (result i64)
    (call $get_max_live_until_ledger)
  )
  (func $max_live_at (param i64) (result i64)
    (call $kasmer_set_ledger_sequence (local.get 0))
    (call $get_max_live_until_ledger)
  )
  (export "max_live" (func $max_live))
  (export "max_live_at" (func $max_live_at))
))

setAccount(Account(b"test-account"), 9876543210)

deployContract(
  Account(b"test-account"),
  Contract(b"test-sc"),
  b"test-wasm"
)

;; The max entry TTL is 6312000 ledgers and the bound is inclusive, so at
;; ledger 0 an entry can live until ledger 6311999.
callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "max_live",
  .List,
  U32(6311999)
)

;; It tracks the current ledger, rather than being a constant.
callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "max_live_at",
  ListItem(U32(100)),
  U32(6312099)
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "max_live_at",
  ListItem(U32(987654321)),
  U32(993966320)
)

setExitCode(0)
