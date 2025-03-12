
setExitCode(1)

uploadWasm( b"test-wasm",
(module
  (import "env" "kasmer_address_from_bytes" (func $kasmer_address_from_bytes (param i64 i64) (result i64)))
  (export "kasmer_address_from_bytes" (func $kasmer_address_from_bytes))
)
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
  "kasmer_address_from_bytes",
  ListItem(ScBytes(b"the-contract")) ListItem(SCBool(true)),
  ScAddress(Contract(b"the-contract"))
)

callTx(
  Account(b"test-caller"),
  Contract(b"test-sc"),
  "kasmer_address_from_bytes",
  ListItem(ScBytes(b"the-account")) ListItem(SCBool(false)),
  ScAddress(Account(b"the-account"))
)

setExitCode(0)