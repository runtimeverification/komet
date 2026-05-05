# Contributing

## Setup

Install dependencies with [uv](https://docs.astral.sh/uv/):

```sh
uv sync
```

Initialize git submodules (required for `test_cross_contract` and other tests that use external contracts):

```sh
git submodule update --init
```

### stellar-cli

Some tests require `stellar` CLI. The project pins to **v23.1.3** — `stellar contract bindings json` was removed in v26. Download the pre-built binary:

```sh
curl -fsSL https://github.com/stellar/stellar-cli/releases/download/v23.1.3/stellar-cli-23.1.3-x86_64-unknown-linux-gnu.tar.gz | tar xz -C ~/.cargo/bin/
```

Verify with:

```sh
stellar --version  # should show 23.1.3
stellar contract bindings json --help
```

## Building the semantics

The K semantics must be compiled before running any tests. This is required on first setup and whenever `.md` files under `src/komet/kdist/` are changed:

```sh
make kdist-build
```

This compiles all targets (`llvm`, `llvm-tracing`, `llvm-library`, `haskell`). It will take several minutes.

To rebuild a single target (e.g. after changing tracing semantics):

```sh
uv run kdist -v build soroban-semantics.llvm-tracing
```

## Running tests

Run the full test suite:

```sh
make test-all
```

Or by category:

```sh
make test-unit         # unit tests only (no compiled semantics required)
make test-integration  # integration tests (requires compiled semantics)
make test-lemmas       # lemma tests
```

To run a specific test or filter by name:

```sh
uv run pytest src/tests/integration -k "tracing" --verbose
```

## Tracing

Komet can produce an execution trace while running a test. Pass `--trace-file` to write one JSON record per instruction to a file.

### With a `.wast` file

```sh
komet run --trace-file trace.txt src/tests/integration/data/errors.wast > out.txt
```

### With a compiled Soroban contract

```sh
komet test -C src/tests/integration/data/soroban/contracts/test_adder/ \
  --id test_add --trace-file trace.txt --max-examples 1
```

### Trace format

Each line is a JSON record:

| Field | Description |
|-------|-------------|
| `pos` | Byte offset of the instruction in the binary, or `null` for instructions inserted by the semantics |
| `instr` | The instruction and its operands |
| `stack` | Value stack at the time of execution |
| `locals` | Local variable bindings at the time of execution |

Example:

```json
{"pos":599,"instr":["local.get",0],"stack":[],"locals":{"0":["i64",4]}}
{"pos":601,"instr":["const","i64",255],"stack":[["i64",4]],"locals":{"0":["i64",4]}}
```

## Code style

Before opening a PR, make sure formatting and type checks pass:

```sh
make check
```

To auto-fix formatting:

```sh
make format
```

## Before opening a PR checklist

- [ ] Semantics rebuilt if any `.md` files under `src/komet/kdist/` were changed
- [ ] `make test-all` passes
- [ ] `make check` passes
