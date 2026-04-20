from __future__ import annotations

from typing import TYPE_CHECKING

import pytest

from komet.scval import (
    SCBoolType,
    SCI32Type,
    SCI64Type,
    SCI128Type,
    SCI256Type,
    SCMapType,
    SCSymbolType,
    SCType,
    SCU32Type,
    SCU64Type,
    SCU128Type,
    SCU256Type,
    SCVecType,
)

if TYPE_CHECKING:
    from typing import Any

SCTYPE_XDR_DATA = TEST_CASES = [
    # --- primitives ---
    ('bool', SCBoolType()),
    ('symbol', SCSymbolType()),
    ('i32', SCI32Type()),
    ('i64', SCI64Type()),
    ('i128', SCI128Type()),
    ('i256', SCI256Type()),
    ('u32', SCU32Type()),
    ('u64', SCU64Type()),
    ('u128', SCU128Type()),
    ('u256', SCU256Type()),
    # --- vec ---
    (
        {'vec': {'element_type': 'u32'}},
        SCVecType(SCU32Type()),
    ),
    (
        {'vec': {'element_type': {'vec': {'element_type': 'u32'}}}},
        SCVecType(SCVecType(SCU32Type())),
    ),
    # --- map ---
    (
        {'map': {'key_type': 'u32', 'value_type': 'u32'}},
        SCMapType(key=SCU32Type(), value=SCU32Type()),
    ),
    (
        {
            'map': {
                'key_type': 'u32',
                'value_type': {'map': {'key_type': 'u32', 'value_type': 'u32'}},
            }
        },
        SCMapType(SCU32Type(), SCMapType(SCU32Type(), SCU32Type())),
    ),
    # --- deeply nested ---
    (
        {
            'vec': {
                'element_type': {
                    'map': {
                        'key_type': 'u32',
                        'value_type': {
                            'vec': {
                                'element_type': {
                                    'map': {
                                        'key_type': 'u32',
                                        'value_type': 'u32',
                                    }
                                }
                            }
                        },
                    }
                }
            }
        },
        SCVecType(SCMapType(SCU32Type(), SCVecType(SCMapType(SCU32Type(), SCU32Type())))),
    ),
]


@pytest.mark.parametrize('xdr_json, expected_type', SCTYPE_XDR_DATA)
def test_from_json(xdr_json: Any, expected_type: SCType) -> None:
    ty = SCType.from_xdr_json(xdr_json)
    assert ty == expected_type
