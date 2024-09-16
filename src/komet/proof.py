from __future__ import annotations

from contextlib import contextmanager
from typing import TYPE_CHECKING

from pyk.cterm import cterm_symbolic
from pyk.kcfg import KCFGExplore
from pyk.kcfg.semantics import DefaultSemantics
from pyk.proof import APRProof, APRProver

from .utils import symbolic_definition, library_definition

if TYPE_CHECKING:
    from collections.abc import Iterator
    from pathlib import Path

    from pyk.kast.outer import KClaim
    from pyk.utils import BugReport


@contextmanager
def _explore_context(id: str, bug_report: BugReport | None) -> Iterator[KCFGExplore]:
    with cterm_symbolic(
        definition=symbolic_definition.kdefinition,
        definition_dir=symbolic_definition.path,
        llvm_definition_dir=library_definition.path,
        id=id if bug_report else None,
        bug_report=bug_report,
    ) as cts:
        yield KCFGExplore(cts)


class SorobanSemantics(DefaultSemantics): ...


def run_claim(id: str, claim: KClaim, proof_dir: Path | None = None, bug_report: BugReport | None = None) -> APRProof:
    if proof_dir is not None and APRProof.proof_data_exists(id, proof_dir):
        proof = APRProof.read_proof_data(proof_dir, id)
    else:
        proof = APRProof.from_claim(symbolic_definition.kdefinition, claim=claim, logs={}, proof_dir=proof_dir)

    with _explore_context(id, bug_report) as kcfg_explore:
        prover = APRProver(kcfg_explore)
        prover.advance_proof(proof)

    proof.write_proof_data()
    return proof
