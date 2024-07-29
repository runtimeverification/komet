#![no_std]
use soroban_sdk::{contract, contractimpl, Env, I256, Map, Symbol, U256, Vec};
#[contract]
pub struct TypesContract;

#[contractimpl]
impl TypesContract {
    pub fn bool_type(_env: Env, b: bool) -> bool { b }

    pub fn signed_types(_env: Env, _i_32: i32, _i_64: i64, _i_128: i128, _i_256: I256) {}

    pub fn unsigned_types(_env: Env, _u_32: u32, _u_64: u64, _u_128: u128, _u_256: U256) {}

    pub fn symbol_type(_env: Env, symbol: Symbol) -> Symbol { symbol }

    pub fn vec_type(_env: Env, vec: Vec<u32>) -> Vec<u32> { vec }

    pub fn nested_vec_type(_env: Env, nested_vec: Vec<Vec<u32>>) -> Vec<Vec<u32>> { nested_vec }

    pub fn map_type(_env: Env, map: Map<u32, u32>) -> Map<u32, u32> { map }

    pub fn nested_map_type(_env: Env, map: Map<u32, Map<u32, u32>>) -> Map<u32, Map<u32, u32>> { map }

    pub fn deeply_nested_type(_env: Env, nested: Vec<Map<u32, Vec<Map<u32, u32>>>>) -> Vec<Map<u32, Vec<Map<u32, u32>>>> { nested }
}
