from __future__ import annotations

from typing import TYPE_CHECKING

from pyk.kast.inner import KApply, KSort, KToken, build_cons
from pyk.prelude.collections import list_of, map_of
from pyk.prelude.utils import token
from pykwasm.kwasm_ast import wasm_string

if TYPE_CHECKING:
    from collections.abc import Iterable
    from typing import Final

    from pyk.kast.inner import KInner


def steps_of(steps: Iterable[KInner]) -> KInner:
    return build_cons(KApply('.List{"kasmerSteps"}'), 'kasmerSteps', steps)


def account_id(acct_id: bytes) -> KApply:
    return KApply('AccountId', [token(acct_id)])


def contract_id(contract_id: bytes) -> KApply:
    return KApply('ContractId', [token(contract_id)])


def set_exit_code(i: int) -> KInner:
    return KApply('setExitCode', [token(i)])


def set_account(acct: bytes, i: int) -> KInner:
    return KApply('setAccount', [account_id(acct), token(i)])


def upload_wasm(name: bytes, contract: KInner) -> KInner:
    return KApply('uploadWasm', [token(name), contract])


def deploy_contract(from_addr: bytes, address: bytes, wasm_hash: bytes, args: list[KInner] | None = None) -> KInner:
    args = args if args is not None else []
    return KApply('deployContract', [account_id(from_addr), contract_id(address), token(wasm_hash), list_of(args)])


def call_tx(from_addr: KInner, to_addr: KInner, func: str, args: list[KInner], result: KInner) -> KInner:
    return KApply('callTx', [from_addr, to_addr, wasm_string(func), list_of(args), result])


# SCVals


def sc_bool(b: bool) -> KInner:
    return KApply('SCVal:Bool', [token(b)])


def sc_u32(i: int) -> KInner:
    return KApply('SCVal:U32', [token(i)])


def sc_u64(i: int) -> KInner:
    return KApply('SCVal:U64', [token(i)])


def sc_u128(i: int) -> KInner:
    return KApply('SCVal:U128', [token(i)])


def sc_u256(i: int) -> KInner:
    return KApply('SCVal:U256', [token(i)])


def sc_i32(i: int) -> KInner:
    return KApply('SCVal:I32', [token(i)])


def sc_i64(i: int) -> KInner:
    return KApply('SCVal:I64', [token(i)])


def sc_i128(i: int) -> KInner:
    return KApply('SCVal:I128', [token(i)])


def sc_i256(i: int) -> KInner:
    return KApply('SCVal:I256', [token(i)])


def sc_symbol(s: str) -> KInner:
    return KApply('SCVal:Symbol', [token(s)])


def sc_vec(l: Iterable[KInner]) -> KInner:
    return KApply('SCVal:Vec', list_of(l))


def sc_map(m: dict[KInner, KInner] | Iterable[tuple[KInner, KInner]]) -> KInner:
    return KApply('SCVal:Map', map_of(m))


SC_VOID: Final = KToken('Void', KSort('ScVal'))
