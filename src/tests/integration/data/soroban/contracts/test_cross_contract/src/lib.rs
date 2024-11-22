#![no_std]
use soroban_sdk::{contract, contractclient, contractimpl, symbol_short, Address, Bytes, Env, FromVal, Symbol, Val};

extern "C" {
    fn kasmer_create_contract(addr_val: u64, hash_val: u64) -> u64;
}

fn create_contract(env: &Env, addr: &Bytes, hash: &Bytes) -> Address {
    unsafe {
        let res = kasmer_create_contract(addr.as_val().get_payload(), hash.as_val().get_payload());
        Address::from_val(env, &Val::from_payload(res))
    }
}

#[contract]
pub struct TestCrossContract;

#[contractclient(name = "ContractBClient")]
trait ContractB {
    fn add_with(e: Env, address: Address, x: u32, y: u32) -> u32;
}

const ADDR_A: &[u8; 32] = b"contract_a______________________";
const ADDR_A_KEY: Symbol = symbol_short!("ctr_a");
const ADDR_B: &[u8; 32] = b"contract_b______________________";
const ADDR_B_KEY: Symbol = symbol_short!("ctr_b");

#[contractimpl]
impl TestCrossContract {
    pub fn init(env: Env, hash_a: Bytes, hash_b: Bytes) {
        let address_a = create_contract(&env, &Bytes::from_array(&env, ADDR_A), &hash_a);
        let address_b = create_contract(&env, &Bytes::from_array(&env, ADDR_B), &hash_b);

        env.storage().instance().set(&ADDR_A_KEY, &address_a);
        env.storage().instance().set(&ADDR_B_KEY, &address_b);
    }

    pub fn test_add_with(env: Env, x: u32, y: u32) -> bool {
        if x > 100 || y > 100 {
            return true;
        }

        let address_a : Address = env.storage().instance().get(&ADDR_A_KEY).unwrap();
        let address_b : Address = env.storage().instance().get(&ADDR_B_KEY).unwrap();
        
        let client = ContractBClient::new(&env, &address_b);
        x + y == client.add_with(&address_a, &x, &y)
    }

}
