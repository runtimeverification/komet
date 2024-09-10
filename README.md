# Komet

Komet is a property testing and formal verification tool for Soroban smart contracts.
It allows developers to write tests in Rust and run them via **fuzzing** and **symbolic execution**.
Komet is built on top of [**KWasm**](https://github.com/runtimeverification/wasm-semantics), which provides formal semantics for WebAssembly.

## Installation

### Step 1: Install `kup`

Komet is installed via the `kup` package manager. To install `kup`, run the following command:

```bash
bash <(curl https://kframework.org/install)
```

### Step 2: Install Komet

Once `kup` is installed, you can install Komet with the following command:

```bash
kup install komet
```

### Step 3: Verify Installation

After installation, verify it by checking the help menu:

```bash
komet --help
```

---

## Getting Started

### Writing Tests

Komet tests are written in Rust and designed as contracts that interact with the contract being tested.
Tests (properties) are implemented as endpoints in test contracts, with each endpoint having a name starting with the
`test_` prefix and returning a boolean.

Here is a simple example of a test contract:

```rust
#[contract]
pub struct TestAdderContract;

#[contractimpl]
impl TestAdderContract {
    pub fn init(env: Env, adder_hash: Bytes) {
        let addr_bytes = b"adder_ctr_______________________";
        let adder = komet::create_contract(&env, &Bytes::from_array(&env, addr_bytes), &adder_hash);
        env.storage().instance().set(&ADDR_KEY, &adder);
    }

    pub fn test_add(env: Env, x: u32, y: u32) -> bool {
        // property checks based on 'x' and 'y'
    }
}
```

For a full example project, visit the [Komet demo repository](https://github.com/runtimeverification/komet-demo).

#### `init` functions

Test contracts can optionally include an `init` function, used to initialize the test contract's state before any test
endpoints are executed. Komet automatically calls the `init` function before running the test cases.
In the example above, the `init` function is used to deploy the contract being tested and store its address in the test
contract's storage.

#### `kasmer.json` file

The `init` function takes Wasm hashes as arguments, representing the contracts involved in the tests.
These hashes, such as the one for the adder contract in the example above, are used to deploy the necessary contracts in
the test environment.
The arguments are provided from the `kasmer.json` file, which specifies the relative paths to the compiled Wasm files
for the contracts. Komet registers the Wasm modules and passes their hashes to the `init` function in the order listed.

Example `kasmer.json` file:

```json
{
 "contracts": [
   "../target/wasm32-unknown-unknown/release/adder.wasm"
 ]
}
```

#### Test functions (properties)

Test functions in Komet are used to define the properties you want to verify in your smart contracts.
These functions must start with the `test_` prefix and return a `bool`.
A return value of true indicates that the property holds, while false indicates that it doesn't.

These functions can accept parameters, which is crucial for fuzzing and symbolic execution. By using parameters, test
functions can explore a wide range of input values to thoroughly test the contract’s behavior under various conditions.

Test functions can also interact with other contracts deployed in the `init` function. They typically retrieve contract
addresses from storage, create clients to interact with these contracts, make calls to contract endpoints, and perform
checks based on the results.


Here is an example test function implementation that calls the adder function with variable arguments and checks the result:

```rust
#[contract]
pub struct TestAdderContract;

#[contractimpl]
impl TestAdderContract {
    pub fn init(env: Env, adder_hash: Bytes) {
        // initialisation code
    }
  
    pub fn test_add(env: Env, x: u32, y: u32) -> bool {
        // Retrieve the address of the `adder` contract from storage
        let adder: Address = env.storage().instance().get(&ADDR_KEY).unwrap();
      
        // Create a client for interacting with the `adder` contract
        let adder_client = adder_contract::Client::new(&env, &adder);


        // Call the `add` endpoint of the `adder` contract with the provided numbers
        let sum = adder_client.add(&x, &y);
      
        // Check if the returned sum matches the expected result
        sum == x as u64 + y as u64
    }
}
```

---

## Running Tests

### Compiling the Project
Before running tests, compile the project using the Soroban SDK. Run the following command from the root directory of your project:

```bash
soroban contract build
```

### Fuzzing Tests

Fuzzing executes your test cases with a wide range of randomized inputs. To run your tests with fuzzing, simply use:

```bash
komet test
```

This command will automatically discover all test functions with the `test_` prefix and run them.

**Example Output:**

```
Processing contract: test_adder
Discovered 1 test function:
    - test_add

  Running test_add...
    Test passed.
```

### Proving Tests (Symbolic Execution)

Proving uses symbolic execution to mathematically verify contract behavior for all possible inputs. This provides a high degree of confidence in the correctness of the contract.

To run the tests with proving, use:

```bash
komet prove run
```

### Viewing More Options

You can see additional proving options by running:

```bash
komet prove --help
```

Example output:
```
usage: komet prove [-h] [--wasm WASM] [--proof-dir PROOF_DIR] [--id ID] COMMAND

positional arguments:
  COMMAND               Proof command to run. One of (run, view)

options:
  -h, --help            show this help message and exit
  --wasm WASM           Prove a specific contract wasm file instead
  --proof-dir PROOF_DIR Output directory for proofs
  --id ID               Name of the test function in the testing contract
```
