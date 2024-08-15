#![no_std]
use soroban_sdk::{contract, contractimpl, Env, Val};

#[contract]
pub struct TtlContract;

extern "C" {
    fn kasmer_set_ledger_sequence(x : u64);
}

fn set_ledger_sequence(x: u32) {
    unsafe {
        kasmer_set_ledger_sequence(Val::from_u32(x).to_val().get_payload());
    }
}

#[contractimpl]
impl TtlContract {

    pub fn test_ttl(
        env: Env,
        init_live_until: u32,
        seq: u32,
        threshold: u32,
        extend_to: u32
    ) -> bool {
        
        // Given:
        //   contract is still alive and extend_ttl inputs are valid
        if seq <= init_live_until && threshold <= extend_to {
            env.storage().instance().extend_ttl(0, init_live_until);
            set_ledger_sequence(seq);
        
        // When:
            env.storage().instance().extend_ttl(threshold, extend_to);
        }

        // Since there is no getter function for the TTL value, we cannot verify 
        // if `extend_ttl` works as expected.
        // Currently, we only check if the function runs without errors.
        // Consider adding a custom hook to retrieve the TTL value for more thorough testing.
        true
    }
}
