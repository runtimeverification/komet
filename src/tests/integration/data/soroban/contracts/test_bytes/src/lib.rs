#![no_std]
use soroban_sdk::{contract, contractimpl, Env, Bytes};

#[contract]
pub struct BytesContract;

#[contractimpl]
impl BytesContract {

    pub fn test_put_get(_env: Env, mut bs: Bytes, i: u32, v: u32) -> bool {
        if bs.len() < 1 || i >= bs.len() || v > 255 {
            return true;
        }

        let v = v as u8;
    
        bs.set(i, v);

        bs.get_unchecked(i) == v
    }

    pub fn test_push_and_pop(_env: Env, mut bs: Bytes, v: u32) -> bool {
        if v > 255 {
            return true;
        }
        
        let init_len = bs.len();
        let v = v as u8;
        
        bs.push_back(v);
        
        assert_eq!(init_len + 1, bs.len());
        assert_eq!(v, bs.last_unchecked());
        assert_eq!(v, bs.get_unchecked(bs.len()-1));

        let v_popped = bs.pop_back_unchecked();

        assert_eq!(init_len, bs.len());
        assert_eq!(v, v_popped);

        true
    }

    pub fn test_insert_is_append_slices(_env: Env, mut bs: Bytes, i: u32, v: u32) -> bool {
        if i >= bs.len() || v > 255 {
            return true;
        }
        let v = v as u8;

        let mut res = bs.slice(0..i);
        res.push_back(v);
        res.append(&bs.slice(i..));

        bs.insert(i, v);
        
        res == bs && res.get_unchecked(i) == v
    }

    pub fn test_insert_delete_is_id(_env: Env, mut bs: Bytes, i: u32, v: u32) -> bool {
        if i >= bs.len() || v > 255 {
            return true;
        }
        let v = v as u8;
        let bs_init = bs.clone();
 
        bs.insert(i, v);

        assert_eq!(bs.get_unchecked(i), v);

        bs.remove_unchecked(i);        

        bs_init == bs
    }

    pub fn test_front_and_back(_env: Env, bs: Bytes) -> bool {
        if bs.len() < 1 {
            return true;
        }

        bs.get_unchecked(0) == bs.first_unchecked()
        && bs.get_unchecked(bs.len()-1) == bs.last_unchecked()
    }
}

mod test;
