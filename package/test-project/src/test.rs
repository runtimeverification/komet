#![cfg(test)]

use super::*;
use soroban_sdk::Env;

#[test]
fn test() {
    let env = Env::default();
    let contract_id = env.register_contract(None, TestContract);
    let client = TestContractClient::new(&env, &contract_id);

    assert!(true);
}
