#![no_std]
use soroban_sdk::{contract, contractimpl, Env};

#[contract]
pub struct TestContract;

#[contractimpl]
impl TestContract {

    pub fn test_true(env: Env) -> bool {
        true
    }
}

mod test;
