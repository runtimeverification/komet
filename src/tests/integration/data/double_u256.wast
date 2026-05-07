setExitCode(1)

uploadWasm( b"test-wasm",
(module $test_wasm
  (import "i" "n" (func $add (param i64 i64) (result i64)))
  (func $double (param i64) (result i64)
    (local i32)

    block
      local.get 0
      local.get 0
      call $add
      local.set 1
    end
    local.get 1
  )
  (export "double" (func $double))
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
  "double",
  ListItem(U256(123)),
  U256(246)
)

setExitCode(0)
