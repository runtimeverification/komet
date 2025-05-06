UV     := uv
UV_RUN := $(UV) run


default: check test-unit

all: check cov

.PHONY: clean
clean:
	rm -rf dist .coverage cov-* .mypy_cache .pytest_cache
	find -type d -name __pycache__ -prune -exec rm -rf {} \;

# Semantics

kdist-build:
	$(UV) run kdist -v build -j2 soroban-semantics.*

kdist-clean:
	$(UV) run kdist clean

# Tests

TEST_ARGS :=

test: test-all

test-all:
	$(UV_RUN) pytest src/tests --maxfail=1 --verbose --durations=0 --numprocesses=4 --dist=worksteal $(TEST_ARGS)

test-unit:
	$(UV_RUN) pytest src/tests/unit --maxfail=1 --verbose $(TEST_ARGS)

test-integration:
	$(UV_RUN) pytest src/tests/integration --maxfail=1 --verbose --durations=0 --numprocesses=4 --dist=worksteal $(TEST_ARGS)

test-lemmas:
	$(UV_RUN) pytest src/tests/lemmas --maxfail=1 --verbose --durations=0 --numprocesses=4 --dist=worksteal $(TEST_ARGS)

# Coverage

COV_ARGS :=

cov: cov-all

cov-%: TEST_ARGS += --cov=komet --no-cov-on-fail --cov-branch --cov-report=term

cov-all: TEST_ARGS += --cov-report=html:cov-all-html $(COV_ARGS)
cov-all: test-all

cov-unit: TEST_ARGS += --cov-report=html:cov-unit-html $(COV_ARGS)
cov-unit: test-unit

cov-integration: TEST_ARGS += --cov-report=html:cov-integration-html $(COV_ARGS)
cov-integration: test-integration


# Checks and formatting

format: autoflake isort black
check: check-flake8 check-mypy check-autoflake check-isort check-black

check-flake8:
	$(UV_RUN) flake8 src

check-mypy:
	$(UV_RUN) mypy src

autoflake:
	$(UV_RUN) autoflake --quiet --in-place src

check-autoflake:
	$(UV_RUN) autoflake --quiet --check src

isort:
	$(UV_RUN) isort src

check-isort:
	$(UV_RUN) isort --check src

black:
	$(UV_RUN) black src

check-black:
	$(UV_RUN) black --check src


# Optional tools

SRC_FILES := $(shell find src -type f -name '*.py')

pyupgrade:
	$(UV_RUN) pyupgrade --py310-plus $(SRC_FILES)
