#![no_std]
use soroban_sdk::{contract, contractimpl, Env, FromVal, Val};

#[contract]
pub struct TtlContract;

extern "C" {

    fn kasmer_set_ledger_sequence(x : u64);

    fn kasmer_set_ledger_timestamp(x : u64);

}

fn set_ledger_sequence(x: u32) {
    unsafe {
        kasmer_set_ledger_sequence(Val::from_u32(x).to_val().get_payload());
    }
}

fn set_ledger_timestamp(env: &Env, x: u64) {
    unsafe {
        kasmer_set_ledger_timestamp(Val::from_val(env, &x).get_payload());
    }
}

const MAX_ENTRY_TTL: u32 = 6312000;

#[contractimpl]
impl TtlContract {

    pub fn test_ttl(
        env: Env,
        ttl: u32,
        seq: u32,
        threshold: u32,
        extend_to: u32
    ) -> bool {
        
        // Validate the input
        if threshold > ttl || threshold > extend_to || ttl == 0 || extend_to == 0 {
            return true;
        }

        // Set the initial TTL and ledger sequence number
        env.storage().instance().extend_ttl(threshold, ttl);
        let init_ttl = u32::min(ttl, MAX_ENTRY_TTL);
        let init_seq = env.ledger().sequence();
        let init_live_until = init_seq.checked_add(init_ttl - 1); // the sequence number at the beginning is 0
        
        set_ledger_sequence(seq);
        
        if let Some(live_until) = init_live_until {
            // If the contract is still alive extend the instance ttl
            if seq <= live_until {
                env.storage().instance().extend_ttl(threshold, extend_to);
            }
        }

        // Since there is no getter function for the TTL value, we cannot verify 
        // if `extend_ttl` works as expected.
        // Currently, we only check if the function runs without errors.
        // Consider adding a custom hook to retrieve the TTL value for more thorough testing.
        true
    }

    pub fn test_timestamp(env: Env, t: u64) -> bool {
        set_ledger_timestamp(&env, t);
        env.ledger().timestamp() == t
    }

}
