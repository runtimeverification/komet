#![no_std]
use soroban_sdk::{contract, contractimpl, symbol_short, Address, Bytes, BytesN, Env, Symbol, Val, Vec};

#[contract]
pub struct TestFxDAOContract;

mod VaultsContract {
    soroban_sdk::contractimport!(
        file = "wasm/vaults.wasm"
    );
}

const SALT: &[u8; 32] = b"fxdao___________________________";
const FXDAO_KEY: Symbol = symbol_short!("fxdao");

#[contractimpl]
impl TestFxDAOContract {
    pub fn init(env: Env, hash: Bytes, fee: u128) {
        let addr = env.deployer().with_current_contract(*SALT).deploy(BytesN::try_from(hash).unwrap());
        let self_addr = env.current_contract_address();
        
        let client = VaultsContract::Client::new(&env, &addr);

        client.init(&self_addr, &self_addr, &self_addr, &self_addr, &self_addr, &fee, &self_addr);

        env.storage().instance().set(&FXDAO_KEY, &addr);
    }

    pub fn test_deposit_ratio(env: Env, currency_rate: u128, collateral: u128, debt: u128) -> bool {
        let fxdao_addr: Address = env.storage().instance().get(&FXDAO_KEY).unwrap();
        let client = VaultsContract::Client::new(&env, &fxdao_addr);

        let res = client.calculate_deposit_ratio(&currency_rate, &collateral, &debt);
        
        true
    }

}

mod test;
