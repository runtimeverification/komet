#![no_std]
use soroban_sdk::{contract, contractimpl, Env, Map, Vec};

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

    pub fn test_map_iterate(env: Env, n: u32) -> bool {
        let n = n % 100;

        let mut map: Map<u32, i32> = Map::new(&env);
        assert_eq!(map.len(), 0);

        for i in (0..n).rev() {
            map.set(i, -(i as i32));
        }
        assert_eq!(map.len(), n);

        // Iterate through the key-value pairs in the map, ensuring:
        let mut cur = 0;
        for (i, x) in map {
            // Keys are strictly increasing
            assert_eq!(cur, i);
            assert_eq!(x, -(i as i32));
            
            cur += 1;
        }

        true
    }
}
