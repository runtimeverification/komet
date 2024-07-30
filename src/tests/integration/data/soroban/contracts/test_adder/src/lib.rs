#![no_std]
use soroban_sdk::{contract, contractimpl, Env};

#[contract]
pub struct AdderContract;

#[contractimpl]
impl AdderContract {
    pub fn add(env: Env, first: u32, second: u32) -> u64 {
       first as u64 + second as u64
    }

    pub fn test_add(env: Env, num: u32) -> bool {
        let sum = Self::add(env, num, 5);
        sum == num as u64 + 5
    }
}

mod test;
