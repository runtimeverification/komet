#![no_std]
use soroban_sdk::{contract, contractimpl, xdr::{int128_helpers::{i128_from_pieces, i128_hi, i128_lo}, FromXdr, ScVal}, Env, Val};

#[contract]
pub struct TestIntegersContract;

#[contractimpl]
impl TestIntegersContract {

    pub fn i128_hi(_env: Env, x: i128) -> i64 {
        i128_hi(x)
    }

    pub fn i128_lo(_env: Env, x: i128) -> u64 {
        i128_lo(x)
    }

    pub fn i128_from_pieces(_env: Env, hi: i64, lo: u64) -> i128 {
        i128_from_pieces(hi, lo)
    }

    /////////////////////////////////////////////////////////////////////
    /// Properties
    /// 

    pub fn test_i128_roundtrip(env: Env, x: i128) -> bool {
        let hi = Self::i128_hi(env.clone(), x);
        let lo = Self::i128_lo(env.clone(), x);
        let y = Self::i128_from_pieces(env, hi, lo);

        x == y
    }

    pub fn test_i128_roundtrip_2(env: Env, hi: i64, lo: u64) -> bool {
        let x = Self::i128_from_pieces(env.clone(), hi, lo);
        let hi2 = Self::i128_hi(env.clone(), x);
        let lo2 = Self::i128_lo(env, x);
        
        hi == hi2 && lo == lo2
    }

    // hi < 0 iff x < 0
    pub fn test_i128_hi_negativity(env: Env, x: i128) -> bool {
        let hi = Self::i128_hi(env, x);
        (x < 0) == (hi < 0)
    }

    // hi < 0 iff x < 0
    pub fn test_i128_hi_negativity_2(env: Env, hi: i64, lo: u64) -> bool {
        let x = Self::i128_from_pieces(env, hi, lo);
        (x < 0) == (hi < 0)
    } 
}
