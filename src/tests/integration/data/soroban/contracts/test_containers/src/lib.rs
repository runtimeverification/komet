#![no_std]
use soroban_sdk::{contract, contractimpl, Env, Vec};

#[contract]
pub struct ContainersContract;

#[contractimpl]
impl ContainersContract {

    pub fn test_vector(env: Env, n: u32) -> bool {
        let n = n % 100;

        let mut vec: Vec<u32> = Vec::new(&env);
        assert_eq!(vec.len(), 0);

        for i in 0..n {
            vec.push_back(i);
        }

        assert_eq!(vec.len(), n);

        for i in 0..n {
            assert_eq!(vec.get_unchecked(i), i);
        }

        true
    }

}
