#![cfg(test)]

use super::*;
use soroban_sdk::Env;

#[test]
fn test() {
    let env = Env::default();
    let contract_id = env.register_contract(None, AdderContract);
    let client = AdderContractClient::new(&env, &contract_id);

    let sum = client.add(&25, &30);
    assert_eq!(
        sum,
        55
    );
}
