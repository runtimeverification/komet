from __future__ import annotations

import json
import sys
from argparse import ArgumentParser, FileType
from contextlib import contextmanager
from enum import Enum
from pathlib import Path
from tempfile import NamedTemporaryFile
from typing import TYPE_CHECKING

from pyk.cli.args import bug_report_arg
from pyk.cli.utils import file_path
from pyk.kdist import kdist
from pyk.ktool.kprint import KAstOutput, _kast
from pyk.ktool.krun import _krun
from pyk.proof.reachability import APRProof
from pyk.proof.tui import APRProofViewer
from pyk.utils import abs_or_rel_to, ensure_dir_path
from pykwasm.scripts.preprocessor import preprocess

from .kasmer import Kasmer
from .utils import KSorobanError, concrete_definition, symbolic_definition

if TYPE_CHECKING:
    from collections.abc import Iterator
    from subprocess import CompletedProcess

    from pyk.utils import BugReport


sys.setrecursionlimit(4000)


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
        if args.max_examples < 1:
            raise ValueError(f'--max-examples must be a positive integer (greater than 0), given {args.max_examples}')
        _exec_test(dir_path=args.directory, wasm=wasm, max_examples=args.max_examples, id=args.id)
    elif args.command == 'prove':
        if args.prove_command is None or args.prove_command == 'run':
            wasm = Path(args.wasm.name) if args.wasm is not None else None
            _exec_prove_run(
                dir_path=args.directory,
                wasm=wasm,
                id=args.id,
                always_allocate=args.always_allocate,
                proof_dir=args.proof_dir,
                bug_report=args.bug_report,
            )
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


def _exec_test(*, dir_path: Path | None, wasm: Path | None, max_examples: int, id: str | None) -> None:
    """Run a soroban test contract given its compiled wasm file.

    This will get the bindings for the contract and run all of the test functions.
    The test functions are expected to be named with a prefix of 'test_' and return a boolean value.

    Exits successfully when all the tests pass.
    """
    dir_path = Path.cwd() if dir_path is None else dir_path
    kasmer = Kasmer(concrete_definition)

    child_wasms: tuple[Path, ...] = ()

    if wasm is None:
        # We build the contract here, specifying where it's saved so we know where to find it.
        # Knowing where the compiled contract is saved by default when building it would eliminate
        # the need for this step, but at the moment I don't know how to retrieve that information.
        child_wasms = _read_config_file(kasmer, dir_path)
        wasm = kasmer.build_soroban_contract(dir_path)

    try:
        kasmer.deploy_and_run(wasm, child_wasms, max_examples, id)
        sys.exit(0)
    except KSorobanError:
        sys.exit(1)


def _exec_prove_run(
    *,
    dir_path: Path | None,
    wasm: Path | None,
    id: str | None,
    always_allocate: bool,
    proof_dir: Path | None,
    bug_report: BugReport | None = None,
) -> None:
    dir_path = Path.cwd() if dir_path is None else dir_path
    kasmer = Kasmer(symbolic_definition)

    child_wasms: tuple[Path, ...] = ()

    if wasm is None:
        child_wasms = _read_config_file(kasmer, dir_path)
        wasm = kasmer.build_soroban_contract(dir_path)

    kasmer.deploy_and_prove(wasm, child_wasms, id, always_allocate, proof_dir, bug_report)

    sys.exit(0)


def _read_config_file(kasmer: Kasmer, dir_path: Path | None = None) -> tuple[Path, ...]:
    dir_path = Path.cwd() if dir_path is None else dir_path
    config_path = dir_path / 'kasmer.json'

    def get_wasm_path(c: Path) -> Path:
        c = abs_or_rel_to(c, dir_path)
        if c.is_file() and c.suffix == '.wasm':
            return c
        if c.is_dir():
            return kasmer.build_soroban_contract(c)
        raise ValueError(f'Invalid child contract path: {c}')

    if config_path.is_file():
        with open(config_path) as f:
            config = json.load(f)
            return tuple(get_wasm_path(Path(c)) for c in config['contracts'])

    return ()


def _exec_prove_view(*, proof_dir: Path, id: str) -> None:
    proof = APRProof.read_proof_data(proof_dir, id)
    viewer = APRProofViewer(proof, symbolic_definition.krun)
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
    parser = ArgumentParser(prog='komet')
    command_parser = parser.add_subparsers(dest='command', required=True)

    run_parser = command_parser.add_parser('run', help='run a concrete test')
    _add_common_arguments(run_parser)

    kast_parser = command_parser.add_parser('kast', help='parse a concrete test and output it in a supported format')
    _add_common_arguments(kast_parser)
    kast_parser.add_argument('--output', metavar='FORMAT', type=KAstOutput, help='format to output the term in')

    test_parser = command_parser.add_parser('test', help='Test the soroban contract in the current working directory')
    test_parser.add_argument(
        '--max-examples', type=int, default=100, help='Maximum number of inputs for fuzzing (default: 100)'
    )
    _add_common_test_arguments(test_parser)

    prove_parser = command_parser.add_parser(
        'prove', help='Prove the soroban contract in the current working directory'
    )
    prove_parser.add_argument('--always-allocate', default=False, action='store_true')
    prove_parser.add_argument(
        'prove_command',
        default='run',
        choices=('run', 'view'),
        metavar='COMMAND',
        help='Proof command to run. One of (%(choices)s)',
    )
    prove_parser.add_argument('--proof-dir', type=ensure_dir_path, default=None, help='Output directory for proofs')
    prove_parser.add_argument('--bug-report', type=bug_report_arg, default=None, help='Bug report directory for proofs')
    _add_common_test_arguments(prove_parser)

    return parser


def _add_common_arguments(parser: ArgumentParser) -> None:
    parser.add_argument('program', metavar='PROGRAM', type=file_path, help='path to test file')
    parser.add_argument('--backend', metavar='BACKEND', type=Backend, default=Backend.LLVM, help='K backend to use')


def _add_common_test_arguments(parser: ArgumentParser) -> None:
    parser.add_argument('--id', help='Name of the test function in the testing contract')
    parser.add_argument('--wasm', type=FileType('r'), help='Use a specific contract wasm file instead')
    parser.add_argument(
        '--directory',
        '-C',
        type=ensure_dir_path,
        default=None,
        help='The working directory for the command (defaults to the current working directory).',
    )
