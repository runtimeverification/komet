use soroban_sdk::{Address, Bytes, Env};

#[cfg(not(test))]
use soroban_sdk::{FromVal, Val};

#[cfg(not(test))]
extern "C" {
    fn kasmer_create_contract(addr_val: u64, hash_val: u64) -> u64;
}

#[cfg(not(test))]
pub fn create_contract(env: &Env, addr: Bytes, hash: Bytes) -> Address {
    unsafe {
        let res = kasmer_create_contract(addr.as_val().get_payload(), hash.as_val().get_payload());
        Address::from_val(env, &Val::from_payload(res))
    }
}


#[cfg(test)]
pub fn create_contract(env: &Env, addr: Bytes, hash: Bytes) -> Address {
    use soroban_sdk::BytesN;

    let addr: BytesN<32> = addr.try_into().unwrap();
    let hash: BytesN<32> = hash.try_into().unwrap();
    env.deployer()
        .with_current_contract(addr)
        .deploy_v2(hash, ())
}
