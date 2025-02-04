#![cfg(test)]

use super::*;
use soroban_sdk::Env;

#[test]
fn test() {
    let env = Env::default();
    let contract_id = env.register_contract(None, BytesContract);
    let client = BytesContractClient::new(&env, &contract_id);

    let bss = [
        Bytes::from_array(&env, b"asd"),
        Bytes::from_array(&env, b"asdqwezzzzzzzzzzzzzzzzzzzxxxxxxxxxxxxxxxxxccccccccccccccc"),
        Bytes::from_array(&env, b"")
    ];

    for bs in &bss {
        assert!(
            client.test_push_and_pop(bs, &0)
        );
    }

    for bs in &bss {
        for i in 0..bs.len() {
            assert!(
                client.test_insert_is_append_slices(bs, &i, &0)
            );
        }
    }

}
