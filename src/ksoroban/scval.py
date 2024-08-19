from __future__ import annotations

from abc import ABC, abstractmethod
from dataclasses import dataclass
from typing import TYPE_CHECKING

from hypothesis import strategies
from pyk.kast.inner import KApply, KSort, KVariable
from pyk.prelude.kint import leInt
from pyk.prelude.utils import token

from .kast.syntax import (
    sc_bool,
    sc_bytes,
    sc_i32,
    sc_i64,
    sc_i128,
    sc_i256,
    sc_map,
    sc_symbol,
    sc_u32,
    sc_u64,
    sc_u128,
    sc_u256,
    sc_vec,
)
from .utils import KSorobanError

if TYPE_CHECKING:
    from typing import Any, Final, TypeVar

    from hypothesis.strategies import SearchStrategy
    from pyk.kast.inner import KInner

    SCT = TypeVar('SCT', bound='SCType')

# SCVals


@dataclass(frozen=True)
class SCValue(ABC):
    @abstractmethod
    def to_kast(self) -> KInner: ...


@dataclass(frozen=True)
class SCBool(SCValue):
    val: bool

    def to_kast(self) -> KInner:
        return sc_bool(self.val)


@dataclass(frozen=True)
class SCIntegral(SCValue):
    val: int


@dataclass(frozen=True)
class SCI32(SCIntegral):
    def to_kast(self) -> KInner:
        return sc_i32(self.val)


@dataclass(frozen=True)
class SCI64(SCIntegral):
    def to_kast(self) -> KInner:
        return sc_i64(self.val)


@dataclass(frozen=True)
class SCI128(SCIntegral):
    def to_kast(self) -> KInner:
        return sc_i128(self.val)


@dataclass(frozen=True)
class SCI256(SCIntegral):
    def to_kast(self) -> KInner:
        return sc_i256(self.val)


@dataclass(frozen=True)
class SCU32(SCIntegral):
    def to_kast(self) -> KInner:
        return sc_u32(self.val)


@dataclass(frozen=True)
class SCU64(SCIntegral):
    def to_kast(self) -> KInner:
        return sc_u64(self.val)


@dataclass(frozen=True)
class SCU128(SCIntegral):
    def to_kast(self) -> KInner:
        return sc_u128(self.val)


@dataclass(frozen=True)
class SCU256(SCIntegral):
    def to_kast(self) -> KInner:
        return sc_u256(self.val)


@dataclass(frozen=True)
class SCSymbol(SCValue):
    val: str

    def to_kast(self) -> KInner:
        return sc_symbol(self.val)


@dataclass(frozen=True)
class SCBytes(SCValue):
    val: bytes

    def to_kast(self) -> KInner:
        return sc_bytes(self.val)


@dataclass(frozen=True)
class SCVec(SCValue):
    val: tuple[SCValue]

    def to_kast(self) -> KInner:
        return sc_vec(v.to_kast() for v in self.val)


@dataclass(frozen=True)
class SCMap(SCValue):
    val: dict[SCValue, SCValue]

    def to_kast(self) -> KInner:
        return sc_map(((k.to_kast(), v.to_kast()) for k, v in self.val.items()))


# SCTypes

_NAME_TO_CLASSNAME: Final = {
    'bool': 'SCBoolType',
    'i32': 'SCI32Type',
    'i64': 'SCI64Type',
    'i128': 'SCI128Type',
    'i256': 'SCI256Type',
    'u32': 'SCU32Type',
    'u64': 'SCU64Type',
    'u128': 'SCU128Type',
    'u256': 'SCU256Type',
    'symbol': 'SCSymbolType',
    'bytes': 'SCBytesType',
    'vec': 'SCVecType',
    'map': 'SCMapType',
}


@dataclass
class SCType(ABC):
    @staticmethod
    def from_dict(d: dict[str, Any]) -> SCType:
        type_name = d['type']
        try:
            cls_name = _NAME_TO_CLASSNAME[type_name]
        except KeyError:
            raise KSorobanError(f'Unsupported SC value type: {type_name!r}') from None
        cls = globals()[cls_name]
        return cls._from_dict(d)

    @classmethod
    @abstractmethod
    def _from_dict(cls: type[SCT], d: dict[str, Any]) -> SCT: ...

    @abstractmethod
    def strategy(self) -> SearchStrategy: ...

    @classmethod
    @abstractmethod
    def as_var(cls, name: str) -> tuple[KInner, tuple[KInner, ...]]: ...


@dataclass
class SCMonomorphicType(SCType):
    @classmethod
    def _from_dict(cls: type[SCT], d: dict[str, Any]) -> SCT:
        return cls()


@dataclass
class SCBoolType(SCMonomorphicType):
    def strategy(self) -> SearchStrategy:
        return strategies.booleans().map(SCBool)

    @classmethod
    def as_var(cls, name: str) -> tuple[KInner, tuple[KInner, ...]]:
        return KApply('SCVal:Bool', [KVariable(name, KSort('Bool'))]), ()


@dataclass
class SCIntegralType(SCMonomorphicType):
    @staticmethod
    @abstractmethod
    def _range() -> tuple[int, int]: ...

    @staticmethod
    @abstractmethod
    def _val_class() -> type[SCIntegral]: ...

    def strategy(self) -> SearchStrategy:
        min, max = self._range()
        return strategies.integers(min_value=min, max_value=max).map(self._val_class())

    @classmethod
    def as_var(cls, name: str) -> tuple[KInner, tuple[KInner, ...]]:
        var = KVariable(name, KSort('Int'))
        label = f'SCVal:{cls.__name__[2:-4]}'
        k = KApply(label, [var])
        min, max = cls._range()
        constraints = (leInt(token(min), var), leInt(var, token(max)))
        return k, constraints


@dataclass
class SCI32Type(SCIntegralType):
    @staticmethod
    def _range() -> tuple[int, int]:
        return -(2**31), (2**31) - 1

    @staticmethod
    def _val_class() -> type[SCI32]:
        return SCI32


@dataclass
class SCI64Type(SCIntegralType):
    @staticmethod
    def _range() -> tuple[int, int]:
        return -(2**63), (2**63) - 1

    @staticmethod
    def _val_class() -> type[SCI64]:
        return SCI64


@dataclass
class SCI128Type(SCIntegralType):
    @staticmethod
    def _range() -> tuple[int, int]:
        return -(2**127), (2**127) - 1

    @staticmethod
    def _val_class() -> type[SCI128]:
        return SCI128


@dataclass
class SCI256Type(SCIntegralType):
    @staticmethod
    def _range() -> tuple[int, int]:
        return -(2**255), (2**255) - 1

    @staticmethod
    def _val_class() -> type[SCI256]:
        return SCI256


@dataclass
class SCU32Type(SCIntegralType):
    @staticmethod
    def _range() -> tuple[int, int]:
        return 0, (2**32) - 1

    @staticmethod
    def _val_class() -> type[SCU32]:
        return SCU32


@dataclass
class SCU64Type(SCIntegralType):
    @staticmethod
    def _range() -> tuple[int, int]:
        return 0, (2**64) - 1

    @staticmethod
    def _val_class() -> type[SCU64]:
        return SCU64


@dataclass
class SCU128Type(SCIntegralType):
    @staticmethod
    def _range() -> tuple[int, int]:
        return 0, (2**128) - 1

    @staticmethod
    def _val_class() -> type[SCU128]:
        return SCU128


@dataclass
class SCU256Type(SCIntegralType):
    @staticmethod
    def _range() -> tuple[int, int]:
        return 0, (2**256) - 1

    @staticmethod
    def _val_class() -> type[SCU256]:
        return SCU256


@dataclass
class SCSymbolType(SCMonomorphicType):
    def strategy(self) -> SearchStrategy:
        return strategies.text(
            alphabet='_0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ', max_size=32
        ).map(SCSymbol)

    @classmethod
    def as_var(cls, name: str) -> tuple[KInner, tuple[KInner, ...]]:
        return KApply('SCVal:Symbol', [KVariable(name, KSort('String'))]), ()


@dataclass
class SCBytesType(SCMonomorphicType):
    def strategy(self) -> SearchStrategy:
        return strategies.binary().map(SCBytes)

    @classmethod
    def as_var(cls, name: str) -> tuple[KInner, tuple[KInner, ...]]:
        return KApply('SCVal:Bytes', [KVariable(name, KSort('Bytes'))]), ()


@dataclass
class SCVecType(SCType):
    element: SCType

    def __init__(self, element: SCType) -> None:
        self.element = element

    @classmethod
    def _from_dict(cls: type[SCVecType], d: dict[str, Any]) -> SCVecType:
        return SCVecType(SCType.from_dict(d['element']))

    def strategy(self) -> SearchStrategy:
        return strategies.lists(elements=self.element.strategy()).map(tuple).map(SCVec)

    @classmethod
    def as_var(cls, name: str) -> tuple[KInner, tuple[KInner, ...]]:
        return KApply('SCVal:Vec', [KVariable(name, KSort('List'))]), ()


@dataclass
class SCMapType(SCType):
    key: SCType
    value: SCType

    def __init__(self, key: SCType, value: SCType) -> None:
        self.key = key
        self.value = value

    @classmethod
    def _from_dict(cls: type[SCMapType], d: dict[str, Any]) -> SCMapType:
        key = SCType.from_dict(d['key'])
        value = SCType.from_dict(d['value'])
        return SCMapType(key, value)

    def strategy(self) -> SearchStrategy:
        return strategies.dictionaries(keys=self.key.strategy(), values=self.value.strategy()).map(SCMap)

    @classmethod
    def as_var(cls, name: str) -> tuple[KInner, tuple[KInner, ...]]:
        return KApply('SCVal:Map', [KVariable(name, KSort('Map'))]), ()
