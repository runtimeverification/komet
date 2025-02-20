#![no_std]
use soroban_sdk::{contract, contractimpl, symbol_short, Address, Bytes, Env, Symbol};

mod komet;


#[contract]
pub struct TestCrossContract;


mod contract_a {
    soroban_sdk::contractimport!(
        file = "../../../../../../../deps/soroban-examples/cross_contract/contract_a/target/wasm32-unknown-unknown/release/soroban_cross_contract_a_contract.wasm"
    );
}

mod contract_b {
    soroban_sdk::contractimport!(
        file = "../../../../../../../deps/soroban-examples/cross_contract/contract_b/target/wasm32-unknown-unknown/release/soroban_cross_contract_b_contract.wasm"
    );
}

const ADDR_A: &[u8; 32] = b"contract_a______________________";
const ADDR_A_KEY: Symbol = symbol_short!("ctr_a");
const ADDR_B: &[u8; 32] = b"contract_b______________________";
const ADDR_B_KEY: Symbol = symbol_short!("ctr_b");

#[contractimpl]
impl TestCrossContract {
    pub fn init(env: Env, hash_a: Bytes, hash_b: Bytes) {
        let address_a = komet::create_contract(&env, Bytes::from_array(&env, ADDR_A), hash_a);
        let address_b = komet::create_contract(&env, Bytes::from_array(&env, ADDR_B), hash_b);

        env.storage().instance().set(&ADDR_A_KEY, &address_a);
        env.storage().instance().set(&ADDR_B_KEY, &address_b);
    }

    pub fn test_add_with(env: Env, x: u32, y: u32) -> bool {
        if x > 100 || y > 100 {
            return true;
        }

        let address_a : Address = env.storage().instance().get(&ADDR_A_KEY).unwrap();
        let address_b : Address = env.storage().instance().get(&ADDR_B_KEY).unwrap();
        
        let client = contract_b::Client::new(&env, &address_b);
        x + y == client.add_with(&address_a, &x, &y)
    }

    pub fn test_try_add(env: Env, x: u32, y: u32) -> bool {
        let address_a : Address = env.storage().instance().get(&ADDR_A_KEY).unwrap();
        
        let expected_result = x.checked_add(y);
        let client = contract_a::Client::new(&env, &address_a);
        let call_result = client.try_add(&x, &y); 
        
        match (expected_result, call_result) {
            (Some(expected), Ok(Ok(res))) => expected==res,
            (None, Err(_)) => true, // overflow
            (_, _) => false,
        }
    }

}

mod test;