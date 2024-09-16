#![no_std]
use soroban_sdk::{contract, contractimpl, symbol_short, Address, Bytes, Env, FromVal, Symbol, Val};

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
pub struct TestFxDAOContract;

mod VaultsContract {
    soroban_sdk::contractimport!(
        file = "wasm/vaults.wasm"
    );
}

const ADDR: &[u8; 32] = b"fxdao_ctr_______________________";
const FXDAO_KEY: Symbol = symbol_short!("fxdao");
const FEE: u128 = 100;

#[contractimpl]
impl TestFxDAOContract {
    pub fn init(env: Env, hash: Bytes) {
        let addr = create_contract(&env, &Bytes::from_array(&env, ADDR), &hash);
        let self_addr = env.current_contract_address();
        let client = VaultsContract::Client::new(&env, &addr);

        client.init(&self_addr, &self_addr, &self_addr, &self_addr, &self_addr, &FEE, &self_addr);

        env.storage().instance().set(&FXDAO_KEY, &addr);
    }

    pub fn test_deposit_ratio(env: Env, currency_rate: u128, collateral: u128, debt: u128) -> bool {
        if debt == 0                      // division by 0
        || currency_rate > 1_000_000_000  // avoid overflow
        || collateral > 1_000_000_000 {
            return true
        }

        let fxdao_addr: Address = env.storage().instance().get(&FXDAO_KEY).unwrap();
        let client = VaultsContract::Client::new(&env, &fxdao_addr);

        client.calculate_deposit_ratio(&currency_rate, &collateral, &debt);

        true
    }

    pub fn test_get_core_state(env: Env) -> bool {
        let self_addr = env.current_contract_address();
        let fxdao_addr: Address = env.storage().instance().get(&FXDAO_KEY).unwrap();
        let client = VaultsContract::Client::new(&env, &fxdao_addr);

        let core_state = client.get_core_state();

        assert_eq!(&core_state.col_token, &self_addr);
        assert_eq!(&core_state.oracle, &self_addr);
        assert_eq!(&core_state.protocol_manager, &self_addr);
        assert_eq!(&core_state.admin, &self_addr);
        assert_eq!(&core_state.stable_issuer, &self_addr);
        assert_eq!(&core_state.panic_mode, &false);
        assert_eq!(&core_state.fee, &FEE);

        true
    }

    pub fn test_set_admin(env: Env, addr: Address) -> bool {
        let fxdao_addr: Address = env.storage().instance().get(&FXDAO_KEY).unwrap();
        let client = VaultsContract::Client::new(&env, &fxdao_addr);

        client.set_admin(&addr);

        let core_state = client.get_core_state();
        core_state.admin == addr
    }
}

mod test;
