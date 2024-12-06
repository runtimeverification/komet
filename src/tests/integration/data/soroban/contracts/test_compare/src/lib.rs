#![no_std]
use core::cmp::Ordering;

use soroban_sdk::{contract, contractimpl, Address, Env, IntoVal, TryFromVal, Val, Vec};

#[contract]
pub struct CompareContract;

// Compares two values of type `T` using host-side comparison semantics.
// The values are placed into vectors to ensure comparison is performed
// via `obj_cmp`, regardless of the type-specific behavior.
fn compare<T>(e: &Env, a: T, b: T) -> Ordering 
  where T: TryFromVal<Env, Val> + IntoVal<Env, Val>
{
  let va = Vec::from_array(&e, [a]);
  let vb = Vec::from_array(&e, [b]);

  va.cmp(&vb)
}

#[contractimpl]
impl CompareContract {
    pub fn test_address(_env: Env, a: Address, b: Address) -> bool {
        let _ = a.cmp(&b);
        true
    }

    pub fn test_address_vec(env: Env, a: Address, b: Address) -> bool {
        compare(&env, a.clone(), b.clone()) == a.cmp(&b)
    }

    /// The `soroban_sdk` implements integer comparison on the Wasm side. This test 
    /// uses the `compare` function to ensure the integers are compared using the 
    /// `obj_cmp` host function. It then verifies that the result matches the 
    /// comparison performed by the SDK's guest-side implementation.
    pub fn test_cmp_i128(env: Env, a: i128, b: i128) -> bool {
        compare(&env, a, b) == a.cmp(&b)
    }

    pub fn test_cmp_i64(env: Env, a: i64, b: i64) -> bool {
        compare(&env, a, b) == a.cmp(&b)
    }

    pub fn test_cmp_i32(env: Env, a: i32, b: i32) -> bool {
        compare(&env, a, b) == a.cmp(&b)
    }

    pub fn test_cmp_u128(env: Env, a: i128, b: i128) -> bool {
        compare(&env, a, b) == a.cmp(&b)
    }

    pub fn test_cmp_u64(env: Env, a: i64, b: i64) -> bool {
        compare(&env, a, b) == a.cmp(&b)
    }

    pub fn test_cmp_u32(env: Env, a: i32, b: i32) -> bool {
        compare(&env, a, b) == a.cmp(&b)
    }

    pub fn test_cmp_bool(env: Env, a: bool, b: bool) -> bool {
        compare(&env, a, b) == a.cmp(&b)
    }

    pub fn test_cmp_void(env: Env) -> bool {
      let a = ();
      let b = ();
      compare(&env, a, b) == a.cmp(&b)
    }
}
