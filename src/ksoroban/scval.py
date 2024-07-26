from __future__ import annotations

from abc import ABC, abstractmethod
from dataclasses import dataclass
from typing import TYPE_CHECKING

from .utils import KSorobanError

if TYPE_CHECKING:
    from typing import Any, Final, TypeVar

    SCT = TypeVar('SCT', bound='SCType')


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


@dataclass
class SCMonomorphicType(SCType):
    @classmethod
    def _from_dict(cls: type[SCT], d: dict[str, Any]) -> SCT:
        return cls()


@dataclass
class SCBoolType(SCMonomorphicType): ...


@dataclass
class SCI32Type(SCMonomorphicType): ...


@dataclass
class SCI64Type(SCMonomorphicType): ...


@dataclass
class SCI128Type(SCMonomorphicType): ...


@dataclass
class SCI256Type(SCMonomorphicType): ...


@dataclass
class SCU32Type(SCMonomorphicType): ...


@dataclass
class SCU64Type(SCMonomorphicType): ...


@dataclass
class SCU128Type(SCMonomorphicType): ...


@dataclass
class SCU256Type(SCMonomorphicType): ...


@dataclass
class SCSymbolType(SCMonomorphicType): ...


@dataclass
class SCVecType(SCType):
    element: SCType

    def __init__(self, element: SCType) -> None:
        self.element = element

    @classmethod
    def _from_dict(cls: type[SCVecType], d: dict[str, Any]) -> SCVecType:
        return SCVecType(SCType.from_dict(d['element']))


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
