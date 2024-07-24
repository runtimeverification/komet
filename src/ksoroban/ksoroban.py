from __future__ import annotations

import sys
from argparse import ArgumentParser, FileType
from contextlib import contextmanager
from enum import Enum
from pathlib import Path
from tempfile import NamedTemporaryFile
from typing import TYPE_CHECKING

from pyk.cli.utils import file_path
from pyk.kdist import kdist
from pyk.ktool.kprint import KAstOutput, _kast
from pyk.ktool.krun import _krun
from pykwasm.scripts.preprocessor import preprocess

from .kasmer import Kasmer
from .utils import SorobanDefinitionInfo

if TYPE_CHECKING:
    from collections.abc import Iterator
    from subprocess import CompletedProcess


class Backend(Enum):
    LLVM = 'llvm'
    HASKELL = 'haskell'


def main() -> None:
    parser = _argument_parser()
    args, rest = parser.parse_known_args()

    if args.command == 'run':
        _exec_run(program=args.program, backend=args.backend)
    elif args.command == 'kast':
        _exec_kast(program=args.program, backend=args.backend, output=args.output)
    elif args.command == 'test':
        _exec_test(contract=Path(args.contract.name))

    raise AssertionError()


def _exec_run(*, program: Path, backend: Backend) -> None:
    definition_dir = kdist.get(f'soroban-semantics.{backend.value}')

    with _preprocessed(program) as input_file:
        proc_res = _krun(definition_dir=definition_dir, input_file=input_file, check=False)

    _exit_with_output(proc_res)


def _exec_kast(*, program: Path, backend: Backend, output: KAstOutput | None) -> None:
    definition_dir = kdist.get(f'soroban-semantics.{backend.value}')

    with _preprocessed(program) as input_file:
        proc_res = _kast(input_file, definition_dir=definition_dir, output=output, check=False)

    _exit_with_output(proc_res)


def _exec_test(*, contract: Path) -> None:
    """Run a soroban test contract given its compiled wasm file.

    This will get the bindings for the contract and run all of the test functions.
    The test functions are expected to be named with a prefix of 'test_' and return a boolean value.

    Exits successfully when all the tests pass.
    """
    definition_dir = kdist.get('soroban-semantics.llvm')
    definition_info = SorobanDefinitionInfo(definition_dir)
    kasmer = Kasmer(definition_info)

    contract_kast = kasmer.kast_from_wasm(contract)
    conf, subst = kasmer.deploy_test(contract_kast)

    bindings = kasmer.contract_bindings(contract)

    for binding in bindings:
        if not binding.name.startswith('test_'):
            continue
        kasmer.run_test(conf, subst, binding)

    sys.exit(0)


@contextmanager
def _preprocessed(program: Path) -> Iterator[Path]:
    program_text = program.read_text()
    with NamedTemporaryFile() as f:
        tmp_file = Path(f.name)
        tmp_file.write_text(preprocess(program_text))
        yield tmp_file


def _exit_with_output(cp: CompletedProcess) -> None:
    print(cp.stdout, end='', flush=True)
    status = cp.returncode
    if status:
        print(cp.stderr, end='', file=sys.stderr, flush=True)
    sys.exit(status)


def _argument_parser() -> ArgumentParser:
    parser = ArgumentParser(prog='ksoroban')
    command_parser = parser.add_subparsers(dest='command', required=True)

    run_parser = command_parser.add_parser('run', help='run a concrete test')
    _add_common_arguments(run_parser)

    kast_parser = command_parser.add_parser('kast', help='parse a concrete test and output it in a supported format')
    _add_common_arguments(kast_parser)
    kast_parser.add_argument('--output', metavar='FORMAT', type=KAstOutput, help='format to output the term in')

    test_parser = command_parser.add_parser('test', help='Test a soroban contract')
    test_parser.add_argument('contract', type=FileType('r'), help='The contract wasm file')

    return parser


def _add_common_arguments(parser: ArgumentParser) -> None:
    parser.add_argument('program', metavar='PROGRAM', type=file_path, help='path to test file')
    parser.add_argument('--backend', metavar='BACKEND', type=Backend, default=Backend.LLVM, help='K backend to use')
