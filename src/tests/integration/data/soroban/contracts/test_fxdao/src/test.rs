#![cfg(test)]

use super::*;
use soroban_sdk::Env;

#[test]
fn test() {
    let env = Env::default();
    let contract_id = env.register_contract(None, TestFxDAOContract);
    let client = TestFxDAOContractClient::new(&env, &contract_id);

    let vaults_hash = env.deployer().upload_contract_wasm(VaultsContract::WASM);
    
    client.init(&Bytes::from(&vaults_hash));
    
    assert!(client.test_deposit_ratio(&25, &30, &123));
}
