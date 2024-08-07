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
from pyk.proof.reachability import APRProof
from pyk.proof.tui import APRProofViewer
from pyk.utils import ensure_dir_path
from pykwasm.scripts.preprocessor import preprocess

from .kasmer import Kasmer
from .utils import haskell_definition, llvm_definition

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
        wasm = Path(args.wasm.name) if args.wasm is not None else None
        _exec_test(wasm=wasm)
    elif args.command == 'prove':
        if args.prove_command is None or args.prove_command == 'run':
            wasm = Path(args.wasm.name) if args.wasm is not None else None
            _exec_prove_run(wasm=wasm, proof_dir=args.proof_dir)
        if args.prove_command == 'view':
            assert args.proof_dir is not None
            _exec_prove_view(proof_dir=args.proof_dir, id=args.id)

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


def _exec_test(*, wasm: Path | None) -> None:
    """Run a soroban test contract given its compiled wasm file.

    This will get the bindings for the contract and run all of the test functions.
    The test functions are expected to be named with a prefix of 'test_' and return a boolean value.

    Exits successfully when all the tests pass.
    """
    kasmer = Kasmer(llvm_definition)

    if wasm is None:
        # We build the contract here, specifying where it's saved so we know where to find it.
        # Knowing where the compiled contract is saved by default when building it would eliminate
        # the need for this step, but at the moment I don't know how to retrieve that information.
        wasm = kasmer.build_soroban_contract(Path.cwd())

    kasmer.deploy_and_run(wasm)

    sys.exit(0)


def _exec_prove_run(*, wasm: Path | None, proof_dir: Path | None) -> None:
    kasmer = Kasmer(haskell_definition)

    if wasm is None:
        wasm = kasmer.build_soroban_contract(Path.cwd())

    kasmer.deploy_and_run(wasm, proof_dir)

    sys.exit(0)


def _exec_prove_view(*, proof_dir: Path, id: str) -> None:
    proof = APRProof.read_proof_data(proof_dir, id)
    viewer = APRProofViewer(proof, haskell_definition.krun)
    viewer.run()
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

    test_parser = command_parser.add_parser('test', help='Test the soroban contract in the current working directory')
    test_parser.add_argument('--wasm', type=FileType('r'), help='Test a specific contract wasm file instead')

    prove_parser = command_parser.add_parser('prove', help='Test the soroban contract in the current working directory')
    prove_parser.add_argument(
        'prove_command',
        default='run',
        choices=('run', 'view'),
        metavar='COMMAND',
        help='Proof command to run. One of (%(choices)s)',
    )
    prove_parser.add_argument('--wasm', type=FileType('r'), help='Prove a specific contract wasm file instead')
    prove_parser.add_argument('--proof-dir', type=ensure_dir_path, default=None, help='Output directory for proofs')
    prove_parser.add_argument('--id', help='Name of the test function in the testing contract')

    return parser


def _add_common_arguments(parser: ArgumentParser) -> None:
    parser.add_argument('program', metavar='PROGRAM', type=file_path, help='path to test file')
    parser.add_argument('--backend', metavar='BACKEND', type=Backend, default=Backend.LLVM, help='K backend to use')
