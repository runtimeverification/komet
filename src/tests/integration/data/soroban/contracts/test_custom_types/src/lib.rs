#![no_std]
use soroban_sdk::{contract, contractimpl, contracttype, symbol_short, Address, Bytes, Env, FromVal, Symbol, TryFromVal, TryIntoVal, Val, Vec, EnvBase};

#[contract]
pub struct TestCustomTypesContract;

#[contracttype]
#[derive(PartialEq)]
pub enum MyBool {
    True,
    False
}

fn to_bool(p: &MyBool) -> bool {
    match p {
        MyBool::True => true,
        MyBool::False => false
    }
}

fn from_bool(p: bool) -> MyBool {
    if p {
        MyBool::True
    } else {
        MyBool::False
    }
}


#[contractimpl]
impl TestCustomTypesContract {

    pub fn test_my_bool_roundtrip(env: Env, p: bool) -> bool {
        
        // mp:MyBool lives in the Wasm memory
        let mp = from_bool(p);
        
        // convert MyBool to a host object
        let v: Val = mp.try_into_val(&env).unwrap();

        // convert v:Val to MyBool, load it to the Wasm memory
        // (using the 'symbol_index_in_linear_memory' host function under the hood)
        let mp2: MyBool = MyBool::try_from_val(&env, &v).unwrap();
        
        let p2 = to_bool(&mp2);
        
        mp == mp2 && p == p2
    }

}
