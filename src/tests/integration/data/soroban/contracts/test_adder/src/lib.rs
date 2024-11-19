#![no_std]
use soroban_sdk::{contract, contractimpl, Env};

#[contract]
pub struct AdderContract;

#[contractimpl]
impl AdderContract {
    pub fn add(env: Env, first: u32, second: u32) -> u64 {
       first as u64 + second as u64
    }


    pub fn add_i64(env: Env, first: i64, second: i64) -> i128 {
        first as i128 + second as i128
    }

    pub fn increment_i128(env: Env, x: i128) -> i128 {
        x + 1
    }

    /////////////////////////////////////////////////////////////////////
    /// Properties
    /// 

    pub fn test_add(env: Env, num: u32) -> bool {
        let sum = Self::add(env, num, 5);
        sum == num as u64 + 5
    }


    pub fn test_add_i64_comm(env: Env, first: i64, second: i64) -> bool {
        let a = Self::add_i64(env.clone(), first, second);
        let b = Self::add_i64(env, second, first);

        a == b
    }

    pub fn test_increment_i128(env: Env, x: i128) -> bool {
        x == i128::MAX || x == Self::increment_i128(env, x) - 1
    }

}

mod test;
