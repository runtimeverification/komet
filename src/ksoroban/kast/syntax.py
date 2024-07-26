from __future__ import annotations

from typing import TYPE_CHECKING

from pyk.kast.inner import KApply, KSort, KToken, build_cons
from pyk.prelude.bytes import bytesToken
from pyk.prelude.collections import list_of
from pyk.prelude.kbool import boolToken
from pyk.prelude.kint import intToken
from pykwasm.kwasm_ast import wasm_string

if TYPE_CHECKING:
    from collections.abc import Iterable
    from typing import Final

    from pyk.kast.inner import KInner


def steps_of(steps: Iterable[KInner]) -> KInner:
    return build_cons(KApply('.List{"kasmerSteps"}'), 'kasmerSteps', steps)


def account_id(acct_id: bytes) -> KApply:
    return KApply('AccountId', [bytesToken(acct_id)])


def contract_id(contract_id: bytes) -> KApply:
    return KApply('ContractId', [bytesToken(contract_id)])


def set_exit_code(i: int) -> KInner:
    return KApply('setExitCode', [intToken(i)])


def set_account(acct: bytes, i: int) -> KInner:
    return KApply('setAccount', [account_id(acct), intToken(i)])


def upload_wasm(name: bytes, contract: KInner) -> KInner:
    return KApply('uploadWasm', [bytesToken(name), contract])


def deploy_contract(from_addr: bytes, address: bytes, wasm_hash: bytes, args: list[KInner] | None = None) -> KInner:
    args = args if args is not None else []
    return KApply('deployContract', [account_id(from_addr), contract_id(address), bytesToken(wasm_hash), list_of(args)])


def call_tx(from_addr: KInner, to_addr: KInner, func: str, args: list[KInner], result: KInner) -> KInner:
    return KApply('callTx', [from_addr, to_addr, wasm_string(func), list_of(args), result])


# SCVals


def sc_bool(b: bool) -> KInner:
    return KApply('SCVal:Bool', [boolToken(b)])


def sc_u32(i: int) -> KInner:
    return KApply('SCVal:U32', [intToken(i)])


SC_VOID: Final = KToken('Void', KSort('ScVal'))
