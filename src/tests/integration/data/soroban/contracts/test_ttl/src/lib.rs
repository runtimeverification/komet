#![no_std]
use soroban_sdk::{contract, contractimpl, Env, FromVal, Val};

#[contract]
pub struct TtlContract;

#[link(wasm_import_module = "env")]
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
// A freshly deployed contract instance (and its code) is a persistent entry, so
// it already carries the minimum persistent TTL before anything extends it.
const MIN_PERSISTENT_ENTRY_TTL: u32 = 4096;

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

        // Track where the entry's live-until bound stands, mirroring the host:
        // it starts at the minimum persistent TTL, and an extension applies only
        // while the remaining TTL is at or below the threshold, never reaching
        // past the maximum entry TTL.
        let init_seq = env.ledger().sequence();
        let mut live_until = init_seq.saturating_add(MIN_PERSISTENT_ENTRY_TTL - 1);
        let requested = init_seq.saturating_add(ttl);
        if live_until - init_seq <= threshold && live_until < requested {
            live_until = u32::min(requested, init_seq.saturating_add(MAX_ENTRY_TTL - 1));
        }
        env.storage().instance().extend_ttl(threshold, ttl);

        set_ledger_sequence(seq);

        // Extending an entry that has already expired is an error, so only
        // extend while the contract is still alive.
        if seq <= live_until {
            env.storage().instance().extend_ttl(threshold, extend_to);
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
