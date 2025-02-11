from __future__ import annotations

from contextlib import contextmanager
from typing import TYPE_CHECKING

from pyk.cterm import cterm_symbolic
from pyk.kast.outer import KApply, KRewrite
from pyk.kcfg import KCFGExplore
from pyk.kcfg.semantics import DefaultSemantics
from pyk.konvert import kast_to_kore, kore_to_kast
from pyk.proof import APRProof, APRProver
from pyk.proof.implies import EqualityProof, ImpliesProver

from .utils import library_definition, symbolic_definition

if TYPE_CHECKING:
    from collections.abc import Iterator
    from pathlib import Path

    from pyk.kast.inner import KInner
    from pyk.kast.outer import KClaim, KFlatModule
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


def run_claim(
    id: str,
    claim: KClaim,
    extra_module: KFlatModule | None = None,
    proof_dir: Path | None = None,
    bug_report: BugReport | None = None,
) -> APRProof:
    if proof_dir is not None and APRProof.proof_data_exists(id, proof_dir):
        proof = APRProof.read_proof_data(proof_dir, id)
    else:
        proof = APRProof.from_claim(symbolic_definition.kdefinition, claim=claim, logs={}, proof_dir=proof_dir)

    with _explore_context(id, bug_report) as kcfg_explore:
        prover = APRProver(kcfg_explore, extra_module=extra_module)
        prover.advance_proof(proof)

    proof.write_proof_data()
    return proof


def is_functional(claim: KClaim) -> bool:
    claim_lhs = claim.body
    if type(claim_lhs) is KRewrite:
        claim_lhs = claim_lhs.lhs
    return not (type(claim_lhs) is KApply and claim_lhs.label.name == '<generatedTop>')


def run_functional_claim(
    claim: KClaim, proof_dir: Path | None = None, bug_report: BugReport | None = None
) -> EqualityProof:
    if proof_dir is not None and EqualityProof.proof_exists(claim.label, proof_dir):
        proof = EqualityProof.read_proof_data(proof_dir, claim.label)
    else:
        proof = EqualityProof.from_claim(claim, symbolic_definition.kdefinition, proof_dir=proof_dir)

    with _explore_context(claim.label, bug_report) as kcfg_explore:
        prover = ImpliesProver(proof, kcfg_explore=kcfg_explore)
        prover.advance_proof(proof)

    proof.write_proof_data()
    return proof


def simplify(kast: KInner, bug_report: BugReport | None = None) -> KInner:
    pat = kast_to_kore(symbolic_definition.kdefinition, kast)
    with _explore_context('', bug_report=bug_report) as kcfg_explore:
        simplified, _ = kcfg_explore.cterm_symbolic._kore_client.simplify(pat)
        return kore_to_kast(symbolic_definition.kdefinition, simplified)
