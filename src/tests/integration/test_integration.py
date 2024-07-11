from pathlib import Path

import pytest
from pyk.kdist import kdist
from pyk.ktool.krun import _krun

TEST_DATA = (Path(__file__).parent / 'data').resolve(strict=True)
TEST_FILES = TEST_DATA.glob('*.wast')

DEFINITION_DIR = kdist.get('soroban-semantics.llvm')


@pytest.mark.parametrize('program', TEST_FILES, ids=str)
def test_run(program: Path, tmp_path: Path) -> None:
    _krun(input_file=program, definition_dir=DEFINITION_DIR, check=True)
