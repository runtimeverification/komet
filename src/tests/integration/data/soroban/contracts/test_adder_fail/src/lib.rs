#![no_std]
use soroban_sdk::{contract, contractimpl, Env};

#[contract]
pub struct AdderContract;

#[contractimpl]
impl AdderContract {
    pub fn add(env: Env, first: u32, second: u32) -> u32 {
       first + second
    }

    pub fn test_add_fail(env: Env, num: u32) -> bool {
        let sum = Self::add(env, num, 4294967295);
        sum == num + 4294967295 // overflow!
    }
}
