#![cfg(test)]

use crate::{contract_a, contract_b, TestCrossContract, TestCrossContractClient};
use soroban_sdk::Env;


#[test]
fn test() {
    let env = Env::default();

    let hash_a = env.deployer().upload_contract_wasm(contract_a::WASM).into();
    let hash_b = env.deployer().upload_contract_wasm(contract_b::WASM).into();

    let test_address = env.register(TestCrossContract, ());
    
    let client = TestCrossContractClient::new(&env, &test_address);
    client.init(&hash_a, &hash_b);


    // should succeed
    assert!(client.test_try_add(&1000, &2000));
    
    // should overflow
    assert!(client.test_try_add(&u32::MAX, &1));

}
