#![no_std]
use soroban_sdk::{contract, contractimpl, Bytes, Env};

#[contract]
pub struct TestHostfunsContract;

const ARR_LENGTH: usize = 512;

#[contractimpl]
impl TestHostfunsContract {

    // Validate the roundtrip conversion of a `Bytes` value into a slice. 
    // Tests the 'bytes_copy_to_linear_memory' and
    // 'bytes_new_from_linear_memory' host functions
    pub fn test_bytes_slice_roundtrip(env: Env, a: Bytes) -> bool {
        let mut arr_a = [0 as u8; ARR_LENGTH];
        
        if a.len() as usize > ARR_LENGTH {
            return true;
        }
        
        let mut slc_a = &mut arr_a[0..a.len() as usize];
        // bytes_copy_to_linear_memory
        a.copy_into_slice(&mut slc_a);

        // bytes_new_from_linear_memory
        let a2 = Bytes::from_slice(&env, slc_a);
       
        a == a2
    }
}
