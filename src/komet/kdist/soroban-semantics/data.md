# Host Data Types

[Documentation - Host Value Type](https://github.com/stellar/stellar-protocol/blob/master/core/cap-0046-01.md#host-value-type)

```k
requires "errors.md"

module HOST-OBJECT-SYNTAX
    imports BOOL-SYNTAX
    imports INT-SYNTAX
    imports BYTES-SYNTAX
    imports STRING-SYNTAX
    imports LIST
    imports MAP
    imports ERRORS
```

## ScVal

[Documentation: ScVal](https://github.com/stellar/stellar-protocol/blob/master/core/cap-0046-01.md#scval)

`ScVal` is a union of various datatypes used in the context of smart contracts for passing values to and from contracts
and storing data on the host side.
It combines elements from Stellar XDR’s `ScVal` and the Soroban Rust environment’s `HostObject` type (_Stellar XDR_ is
the data format storing and communicating blockchain data).

* [Stellar XDR - `ScVal`](https://github.com/stellar/stellar-xdr/blob/78ef9860777bd53e75a8ce8b978131cade26b321/Stellar-contract.x#L214)
* [Soroban Environment - `HostObject`](https://github.com/stellar/rs-soroban-env/blob/00ddd2714e757d0005bfc98798f05aa209f283bf/soroban-env-host/src/host_object.rs#L22)

There are notable differences between XDR’s `ScVal` and Rust’s `HostObject`:

* Data Representation: XDR `ScVal` and Rust `HostObject` differ in their data representation and storage.
  XDR’s `ScVal` is recursive on container types such as map and vector, meaning it stores `ScVal`s as both keys and
  values within vectors and maps, allowing for nested data structures. In contrast, `HostObject` uses `HostVal` in
  container types, which requires resolving the corresponding host objects when accessing these values. 
* Containers: XDR uses sorted vectors of key-value pairs for maps with binary search for lookups. The Rust environment
  also uses a sorted vector but stores `HostVal` within these containers. Our semantics, however, use `Map` instead for
  efficient lookup and simpler implementation.

In our semantic implementation, `ScVal` is utilized to represent both XDR `ScVal` and Rust `HostObject`, adapting to
various contexts:

* Inside the Host:
  * `ScVec`: Represented as a `List` of `HostVal`
  * `ScMap`: Represented as a `Map` from `ScVal` to `HostVal`.
    Using `ScVal` as keys allows for more efficient lookups because it avoids the additional layer of indirection that
    would be required if `HostVal` were used.
* Outside the Host:
  * `ScVec`: Represented as a `List` of `ScVal`.
  * `ScMap`: Represented as a `Map` from `ScVal` to `ScVal`.

```k
    syntax ScVal
      ::= SCBool(Bool)                             [symbol(SCVal:Bool)]
        | "Void"                                   [symbol(SCVal:Void)]
        | Error(ErrorType, Int)                    [symbol(SCVal:Error)]
        | U32(Int)                                 [symbol(SCVal:U32)]
        | I32(Int)                                 [symbol(SCVal:I32)]
        | U64(Int)                                 [symbol(SCVal:U64)]
        | I64(Int)                                 [symbol(SCVal:I64)]
        | U128(Int)                                [symbol(SCVal:U128)]
        | I128(Int)                                [symbol(SCVal:I128)]
        | U256(Int)                                [symbol(SCVal:U256)]
        | ScVec(List)                              [symbol(SCVal:Vec)]      // List<HostVal> or List<ScVal>
        | ScMap(Map)                               [symbol(SCVal:Map)]      // Map<ScVal, HostVal> or Map<ScVal, ScVal>
        | ScAddress(Address)                       [symbol(SCVal:Address)]
        | Symbol(String)                           [symbol(SCVal:Symbol)]
        | ScBytes(Bytes)                           [symbol(SCVal:Bytes)]
        | ScString(String)                         [symbol(SCVal:String)]

    syntax Address ::= AccountId | ContractId
    syntax AccountId  ::= Account(Bytes)          [symbol(AccountId)]
    syntax ContractId ::= Contract(Bytes)         [symbol(ContractId)]

```

## HostVal

[Documentation: HostVal](https://github.com/stellar/stellar-protocol/blob/master/core/cap-0046-01.md#host-value-type)

`HostVal` is used to pass values to and from Wasm contracts. It is a 64-bit representation of `ScVal`.

Bit-packed Representation:

  * Tag (Low 8 bits): The lower 8 bits make up the tag. The tag value determines how the remaining 56 bits are to be interpreted.
  * Body (High 56 bits): The body can be split into two parts:
    * Minor Component (Low 24 bits): The lower 24 bits of the body.
    * Major Component (High 32 bits): The upper 32 bits of the body.

Some HostVal instances, known as small values, are self-contained and carry all the information necessary to convert them to ScVal. Other HostVal instances contain a handle in their major component to a ScVal stored on the host side.

```k
    syntax HostVal ::= HostVal(Int)     [symbol(HostVal)]

endmodule

module HOST-OBJECT
    imports INT
    imports BOOL
    imports LIST
    imports MAP
    imports STRING
    imports BYTES
    imports HOST-OBJECT-SYNTAX
    imports WASM

    syntax Int ::= getMajor(HostVal)        [function, total, symbol(getMajor)]
                 | getMinor(HostVal)        [function, total, symbol(getMinor)]
                 | getTag(HostVal)          [function, total, symbol(getTag)]
                 | getBody(HostVal)         [function, total, symbol(getBody)]
 // -----------------------------------------------------------------------
    rule getMajor(HostVal(I)) => I >>Int 32
    rule getMinor(HostVal(I)) => (I &Int (#pow(i32) -Int 1)) >>Int 8
    rule getTag(HostVal(I))   => I &Int 255
    rule getBody(HostVal(I))  => I >>Int 8

    syntax Bool ::= isObject(HostVal)                   [function, total, symbol(isObject)]
                  | isObjectTag(Int)                    [function, total, symbol(isObjectTag)]
                  | isRelativeObjectHandle(HostVal)     [function, total, symbol(isRelativeObjectHandle)]
 // --------------------------------------------------------------------------------
    rule isObject(V)               => isObjectTag(getTag(V))
    rule isObjectTag(TAG)          => 64 <=Int TAG andBool TAG <=Int 77
    rule isRelativeObjectHandle(V) => getMajor(V) &Int 1 ==Int 0

    syntax Int ::= indexToHandle(Int, Bool)       [function, total, symbol(indexToHandle)]
 // --------------------------------------------------------------------------------
    rule indexToHandle(I, false) => (I <<Int 1) |Int 1
    rule indexToHandle(I, true)  =>  I <<Int 1

    syntax Int ::= getIndex(HostVal)   [function, total, symbol(getIndex)]
 // ----------------------------------------------------------------------------
    rule getIndex(V) => getMajor(V) >>Int 1

    syntax HostVal ::= fromHandleAndTag(Int, Int)                [function, total, symbol(fromHandleAndTag)]
                     | fromMajorMinorAndTag(Int, Int, Int)       [function, total, symbol(fromMajorMinorAndTag)]
                     | fromBodyAndTag(Int, Int)                  [function, total, symbol(fromBodyAndTag)]
 // --------------------------------------------------------------------------------
    rule fromHandleAndTag(H, T)              => fromMajorMinorAndTag(H, 0, T)
    rule fromMajorMinorAndTag(MAJ, MIN, TAG) => fromBodyAndTag((MAJ <<Int 24) |Int MIN, TAG)
    rule fromBodyAndTag(BODY, TAG)           => HostVal((BODY <<Int 8) |Int TAG)

    syntax WasmStringToken ::= #unparseWasmString ( String )         [function, total, hook(STRING.string2token)]
                             | #quoteUnparseWasmString ( String )   [function, total]
    rule #quoteUnparseWasmString(S) => #unparseWasmString("\"" +String S +String "\"")

  // https://github.com/stellar/stellar-protocol/blob/master/core/cap-0046-01.md#tag-values
    syntax Int ::= getTag(ScVal)   [function, total]
 // -----------------------------------------------------
    rule getTag(SCBool(false)) => 0
    rule getTag(SCBool(true))  => 1
    rule getTag(Void)          => 2
    rule getTag(Error(_,_))    => 3
    rule getTag(U32(_))        => 4
    rule getTag(I32(_))        => 5
    rule getTag(U64(I))        => 6     requires          I <=Int #maxU64small
    rule getTag(U64(I))        => 64    requires notBool( I <=Int #maxU64small )
    rule getTag(I64(I))        => 7     requires          #minI64small <=Int I andBool I <=Int #maxI64small
    rule getTag(I64(I))        => 65    requires notBool( #minI64small <=Int I andBool I <=Int #maxI64small )
    rule getTag(U128(I))       => 10    requires          I <=Int #maxU64small
    rule getTag(U128(I))       => 68    requires notBool( I <=Int #maxU64small ) // U64small and U128small have the same width
    rule getTag(I128(I))       => 11    requires          #minI64small <=Int I andBool I <=Int #maxI64small
    rule getTag(I128(I))       => 69    requires notBool( #minI64small <=Int I andBool I <=Int #maxI64small )
    rule getTag(U256(I))       => 12    requires          I <=Int #maxU64small
    rule getTag(U256(I))       => 70    requires notBool( I <=Int #maxU64small ) // U64small and U128small have the same width
    rule getTag(ScVec(_))      => 75
    rule getTag(ScMap(_))      => 76
    rule getTag(ScAddress(_))  => 77
    rule getTag(Symbol(BS))    => 14    requires lengthString(BS) <=Int 9
    rule getTag(Symbol(BS))    => 74    requires lengthString(BS) >Int  9
    rule getTag(ScBytes(_))    => 72
    rule getTag(ScString(_))   => 73

    syntax Int ::= getTagWithFlag(alwaysAllocate: Bool, ScVal)   [function, total]
 // -------------------------------------------------------------------------------
    rule getTagWithFlag(true, U64(_))    => 64
    rule getTagWithFlag(true, I64(_))    => 65
    rule getTagWithFlag(true, U128(_))   => 68
    rule getTagWithFlag(true, I128(_))   => 69
    rule getTagWithFlag(true, Symbol(_)) => 74
    rule getTagWithFlag(_,    SCV)       => getTag(SCV)      [owise]
   
    // Define the max/min values of small 64-bit integers that fit in 56 bits.
    // These are used to check whether an i64 can be embedded directly as a "small" HostVal
    // based on the small integer definition in [CAP-046-01](https://github.com/stellar/stellar-protocol/blob/master/core/cap-0046-01).md#tag-values)
    syntax Int ::= "#maxU64small"     [macro]  // Maximum unsigned small int: 2^56 - 1
                 | "#maxI64small"     [macro]  // Maximum signed small int: 2^55 - 1
                 | "#minI64small"     [macro]  // Minimum signed small int: -2^55
 // -----------------------------------------------------------------------------------------
    rule #maxU64small => maxInt(i56, Unsigned)
    rule #maxI64small => maxInt(i56, Signed)
    rule #minI64small => minInt(i56, Signed)

    // Helpers for computing max/min values given a bit width and signedness.
    syntax Int ::= maxInt(IWidth, Signedness)      [function, total]
                 | minInt(IWidth, Signedness)      [function, total]
 // ----------------------------------------------------------------
    // For unsigned: max = 2^W - 1, min = 0
    rule maxInt(W, Unsigned) => #pow(W) -Int 1
    rule minInt(_, Unsigned) => 0

    // For signed: max = 2^(W - 1) - 1, min = -2^(W - 1)
    rule maxInt(W, Signed)   => #pow1(W) -Int 1
    rule minInt(W, Signed)   => 0 -Int #pow1(W)

    // refactor small int checks using this
    syntax Bool ::= inRangeInt(IWidth, Signedness, Int)  [function, total, symbol(inRangeInt)]
 // ------------------------------------------------------------------------------------------
    rule inRangeInt(W, SG, I) => minInt(W, SG) <=Int I andBool I <=Int maxInt(W, SG)

    syntax ScVal ::= ScValOrDefault(KItem, ScVal)   [function, total, symbol(ScValOrDefault)]
 // ---------------------------------------------------------
    rule ScValOrDefault(X:ScVal, _:ScVal) => X
    rule ScValOrDefault(_,       D:ScVal) => D    [owise]

    syntax HostVal ::= HostValOrDefault(KItem, HostVal)   [function, total, symbol(HostValOrDefault)]
 // ---------------------------------------------------------
    rule HostValOrDefault(X:HostVal, _:HostVal) => X
    rule HostValOrDefault(_,         D:HostVal) => D    [owise]

    syntax ScVal ::= List "{{" Int "}}" "orDefault" ScVal
        [function, total, symbol(List:getOrDefault)]
 // ---------------------------------------------------------
    rule OBJS:List {{ I }} orDefault (D:ScVal) => ScValOrDefault(OBJS [ I ], D)
      requires 0 <=Int I andBool I <Int size(OBJS)

    rule _OBJS:List {{ _I }} orDefault (D:ScVal) => D
      [owise]

    syntax HostVal ::= List "{{" Int "}}" "orDefault" HostVal
        [function, total, symbol(HostVal:getOrDefault)]
 // ---------------------------------------------------------
    rule OBJS:List {{ I }} orDefault (D:HostVal) => HostValOrDefault(OBJS [ I ], D)
      requires 0 <=Int I andBool I <Int size(OBJS)

    rule _OBJS:List {{ _I }} orDefault (D:HostVal) => D
      [owise]

    // typed version of builtin MAP [ K ] orDefault V
    syntax HostVal ::= Map "{{" KItem "}}" "orDefault" HostVal
        [function, total, symbol(HostVal:lookupOrDefault)]
 // ---------------------------------------------------------
    rule OBJS:Map {{ I }} orDefault (D:HostVal) => HostValOrDefault(OBJS [ I ] orDefault D, D)

    // typed version of builtin MAP [ K ] orDefault V
    syntax ScVal ::= Map "{{" KItem "}}" "orDefault" ScVal
        [function, total, symbol(ScVal:lookupOrDefault)]
 // ---------------------------------------------------------
    rule OBJS:Map {{ I }} orDefault (D:ScVal) => ScValOrDefault(OBJS [ I ] orDefault D, D)
```

## Conversion between `HostVal` and `ScVal`


```k
    syntax ScVal ::= fromSmall(HostVal)      [function, total, symbol(fromSmall)]
 // -----------------------------------------------------------------------------------
    rule fromSmall(VAL) => SCBool(false)           requires getTag(VAL) ==Int 0

    rule fromSmall(VAL) => SCBool(true)            requires getTag(VAL) ==Int 1

    rule fromSmall(VAL) => Void                    requires getTag(VAL) ==Int 2

    rule fromSmall(VAL) => Error(Int2ErrorType(getMinor(VAL)), getMajor(VAL))
                                                   requires getTag(VAL) ==Int 3
                                                    andBool Int2ErrorTypeValid(getMinor(VAL))

    rule fromSmall(VAL) => U32(getMajor(VAL))      requires getTag(VAL) ==Int 4

    rule fromSmall(VAL) => I32(#signed(i32, getMajor(VAL)))
      requires getTag(VAL) ==Int 5
       andBool definedSigned(i32, getMajor(VAL))
      [preserves-definedness]

    rule fromSmall(VAL) => U64(getBody(VAL))       requires getTag(VAL) ==Int 6

    rule fromSmall(VAL) => I64(#signed(i56, getBody(VAL)))
      requires getTag(VAL) ==Int 7
       andBool definedSigned(i56, getBody(VAL))

    rule fromSmall(VAL) => U128(getBody(VAL))      requires getTag(VAL) ==Int 10

    rule fromSmall(VAL) => I128(#signed(i56, getBody(VAL)))
      requires getTag(VAL) ==Int 11
       andBool definedSigned(i56, getBody(VAL))

    rule fromSmall(VAL) => U256(getBody(VAL))      requires getTag(VAL) ==Int 12

    rule fromSmall(VAL) => Symbol(decode6bit(getBody(VAL)))
                                                   requires getTag(VAL) ==Int 14

    // return `Void` for invalid values
    rule fromSmall(_) => Void    [owise]

    syntax Bool ::= fromSmallValid(HostVal)
        [function, total, symbol(fromSmallValid)]
 // ---------------------------------------------------------------------------------
    rule fromSmallValid(VAL) => fromSmall(VAL) =/=K Void orBool getTag(VAL) ==Int 2


    syntax HostVal ::= toSmall(ScVal)      [function, total, symbol(toSmall)]
 // ---------------------------------------------------------------------------------
    rule toSmall(SCBool(false)) => fromMajorMinorAndTag(0, 0, 0)
    rule toSmall(SCBool(true))  => fromMajorMinorAndTag(0, 0, 1)
    rule toSmall(Void)          => fromMajorMinorAndTag(0, 0, 2)
    rule toSmall(Error(TYP, I)) => fromMajorMinorAndTag(I, ErrorType2Int(TYP), 3)
    rule toSmall(U32(I))        => fromMajorMinorAndTag(I, 0, 4)
    rule toSmall(I32(I))        => fromMajorMinorAndTag(#unsigned(i32, I), 0, 5)
      requires definedUnsigned(i32, I)
    rule toSmall(U64(I))        => fromBodyAndTag(I, 6)               requires I <=Int #maxU64small
    rule toSmall(I64(I))        => fromBodyAndTag(#unsigned(i56, I), 7)
      requires #minI64small <=Int I andBool I <=Int #maxI64small
       andBool definedUnsigned(i56, I)
    rule toSmall(U128(I))       => fromBodyAndTag(I, 10)              requires I <=Int #maxU64small
    rule toSmall(I128(I))       => fromBodyAndTag(#unsigned(i56, I), 11)
      requires #minI64small <=Int I andBool I <=Int #maxI64small
       andBool definedUnsigned(i56, I)
    rule toSmall(U256(I))       => fromBodyAndTag(I, 12)              requires I <=Int #maxU64small
    rule toSmall(Symbol(S))     => fromBodyAndTag(encode6bit(S), 14)  requires lengthString(S) <=Int 9
    rule toSmall(_)             => HostVal(-1)                        [owise]

    syntax Bool ::= toSmallValid(ScVal)
        [function, total, symbol(toSmallValid)]
 // ---------------------------------------------------------------------------------
    rule toSmallValid(VAL) => toSmall(VAL) =/=K HostVal(-1)

    syntax Bool ::= alwaysSmall(ScVal)
        [function, total, symbol(alwaysSmall)]
 // ---------------------------------------------------------------------------------
    rule alwaysSmall(SCBool(_))   => true
    rule alwaysSmall(Void)        => true
    rule alwaysSmall(Error(_, _)) => true
    rule alwaysSmall(U32(_))      => true
    rule alwaysSmall(I32(_))      => true
    rule alwaysSmall(_)           => false [owise]

    syntax String ::= decode6bit(Int)       [function, total, symbol(decode6bit)]
 // --------------------------------------------------------------------------------
    rule decode6bit(I) => decode6bit(I >>Int 6) +String decode6bitChar(I &Int 63)   requires 0 <Int I
    rule decode6bit(_) => ""                                                        [owise]

    syntax String ::= "sixBitStringTable" [macro]
 // -------------------------------------------------------------------------------------------
    rule sixBitStringTable => "_0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"

    syntax String ::= decode6bitChar(Int)   [function, total, symbol(decode6bitChar)]
 // ---------------------------------------------------------------------------------
    rule decode6bitChar(I) => substrString(sixBitStringTable, I -Int 1, I)

    syntax Int ::= encode6bit   (     String)           [function, total, symbol(encode6bit)]
                 | encode6bitAux(Int, String)           [function, total, symbol(encode6bitAux)]
 // --------------------------------------------------------------------------------
    rule encode6bit(S) => encode6bitAux(0, S)

    rule encode6bitAux(A, S)
      => encode6bitAux((A <<Int 6) |Int encode6bitChar(head(S)), tail(S))
      requires 0 <Int lengthString(S)
    rule encode6bitAux(A, _) => A
      [owise]

    syntax Int ::= encode6bitChar(String)   [function, total, symbol(encode6bitChar)]
 // ---------------------------------------------------------------------------------
    rule encode6bitChar(I) => findChar(sixBitStringTable, I, 0) +Int 1

    syntax Bool ::= validSymbol(String)          [function, total, symbol(validSymbol)]
                  | validSymbolChar(String)      [function, total, symbol(validSymbolChar)]
 // --------------------------------------------------------------------------------
    rule validSymbol(S) => true
      requires lengthString(S) ==Int 0
    rule validSymbol(S) => validSymbolChar(head(S)) andBool validSymbol(tail(S))
      requires 0 <Int lengthString(S) andBool lengthString(S) <=Int 32
    rule validSymbol(S) => false
      requires 32 <Int lengthString(S)

    rule validSymbolChar(I) => findChar(sixBitStringTable, I, 0) =/=Int -1

    syntax String ::= head(String)    [function, total, symbol(headString)]
                    | tail(String)    [function, total, symbol(tailString)]
 // -----------------------------------------------------------------------
    rule head(S) => ""                                         requires lengthString(S) <=Int 0
    rule head(S) => substrString(S, 0, 1)                      requires lengthString(S) >Int 0
    rule tail(S) => ""                                         requires lengthString(S) <=Int 0
    rule tail(S) => substrString(S, 1, lengthString(S))        requires lengthString(S) >Int 0

    // 56-bit integers for small values
    syntax IWidth ::= "i56"
 // ------------------------------------
    rule #width(i56) => 56
    rule #pow(i56)  => 72057594037927936
    rule #pow1(i56) => 36028797018963968

    syntax IWidth ::= "i128"     [symbol(i128)]
                    | "i256"     [symbol(i256)]
 // -------------------------------------------
    rule #width(i128) => 128
    rule #pow(i128)   => 340282366920938463463374607431768211456
    rule #pow1(i128)  => 170141183460469231731687303715884105728
    rule #width(i256) => 256
    rule #pow(i256)   => 115792089237316195423570985008687907853269984665640564039457584007913129639936
    rule #pow1(i256)  => 57896044618658097711785492504343953926634992332820282019728792003956564819968

```

## Value Comparison

[CAP 46-1: Comparison](https://github.com/stellar/stellar-protocol/blob/master/core/cap-0046-01.md#comparison)

```k
    syntax Ordering ::= "Less"       [symbol(Ordering:Less)]
                      | "Equal"      [symbol(Ordering:Equal)]
                      | "Greater"    [symbol(Ordering:Greater)]

    syntax Int ::= Ordering2Int(Ordering)     [function, total]
 // -----------------------------------------------------------
    rule Ordering2Int(Less)    => -1
    rule Ordering2Int(Equal)   => 0
    rule Ordering2Int(Greater) => 1
```

- `compare(A, B)`: Defines a total order between `ScVal`s.
  

```k
    syntax Ordering ::= compare(ScVal, ScVal)    [function, total, symbol(compare)]
```

If `A` and `B` belong to different variants, their order is determined by the function `ScValTypeOrd(_:ScVal)`.
`ScValTypeOrd` assigns a unique precedence to each variant type.

```k
    rule compare(A, B) => compareInt(ScValTypeOrd(A), ScValTypeOrd(B))
      requires ScValTypeOrd(A) =/=Int ScValTypeOrd(B)
```

If `A` and `B` are of the same variant, they are compared by their underlying values.
For scalar types the comparison is straightforward.

```k
    rule compare(SCBool(A), SCBool(B)) => compareBool(A, B)
    rule compare(Void, Void)           => Equal
    rule compare(Error(ATYP, ACODE), Error(BTYP, BCODE))
      => #if ATYP ==K BTYP
         #then compareInt(ACODE, BCODE)
         #else compareInt(ErrorType2Int(ATYP), ErrorType2Int(BTYP))
         #fi
    rule compare(U32(A),  U32(B))  => compareInt(A, B)
    rule compare(I32(A),  I32(B))  => compareInt(A, B)
    rule compare(U64(A),  U64(B))  => compareInt(A, B)
    rule compare(I64(A),  I64(B))  => compareInt(A, B)
    rule compare(U128(A), U128(B)) => compareInt(A, B)
    rule compare(I128(A), I128(B)) => compareInt(A, B)
    rule compare(U256(A), U256(B)) => compareInt(A, B)
    rule compare(ScAddress(A), ScAddress(B)) => compareAddress(A, B)
    rule compare(Symbol(A), Symbol(B))       => compareString(A, B)
    rule compare(ScBytes(A), ScBytes(B))     => compareBytes(A, B)
    rule compare(ScString(A), ScString(B))   => compareString(A, B)
```

For container types, the comparison is recursive as defined in `compareVec` and `compareMap`.

- Maps are compared key-by-key in sorted or der of keys
- Vectors are compared element-by-element in order

```k
    rule compare(ScVec(A), ScVec(B)) => compareVec(A, B)
    rule compare(ScMap(A), ScMap(B)) => compareMap(A, sortedKeys(A), B, sortedKeys(B))
```

### Comparison of scalars

```k
    syntax Ordering ::= compareBool(Bool, Bool)             [function, total, symbol(compareBool)]
 // ----------------------------------------------------------------------------------------------
    rule compareBool(true, true)  => Equal
    rule compareBool(true, false) => Greater
    rule compareBool(false,true)  => Less
    rule compareBool(false,false) => Equal

    syntax Ordering ::= compareAddress(Address, Address)    [function, total, symbol(compareAddress)]
 // -------------------------------------------------------------------------------------
    rule compareAddress(Account(_),  Contract(_)) => Less
    rule compareAddress(Contract(_), Account(_))  => Greater
    rule compareAddress(Contract(A), Contract(B)) => compareBytes(A, B)
    rule compareAddress(Account(A),  Account(B))  => compareBytes(A, B)

    syntax Ordering ::= compareBytes(Bytes, Bytes)       [function, total, symbol(compareBytes)]
                      | compareString(String, String)    [function, total, symbol(compareString)]
 // ---------------------------------------------------------------------------------------------
    rule compareBytes(A, B) => compareString(Bytes2String(A), Bytes2String(B))
    rule compareString(A, B) => Less    requires A  <String B
    rule compareString(A, B) => Equal   requires A ==String B
    rule compareString(A, B) => Greater requires A  >String B

    syntax Ordering ::= compareInt(Int, Int)   [function, total]
 // ------------------------------------------------------------
    rule compareInt(A, B) => Less    requires A  <Int B
    rule compareInt(A, B) => Equal   requires A ==Int B
    rule compareInt(A, B) => Greater requires A  >Int B

```

### Comparison of vectors (`compareVec`)

The `compareVec` function compares two lists of `ScVal` values element by element, determining their order based on the
first differing element. If one list is shorter, it is considered smaller; if all elements are equal, the lists are equal. 
If a list contains an element that is not an `ScVal`, which should not occur, the function returns a default value of
`Equal` to remain total.

```k
    syntax Ordering ::= compareVec(List, List)    [function, total, symbol(compareVec)]
 // -----------------------------------------------------------------------------
    rule compareVec(.List,                .List              ) => Equal
    rule compareVec(.List,                ListItem(_:ScVal) _) => Less
    rule compareVec(ListItem(_:ScVal) _, .List               ) => Greater
    rule compareVec(ListItem(A) AS, ListItem(B) BS)
      => #let C = compare(A, B) #in
         #if C =/=K Equal
         #then C
         #else compareVec(AS, BS)
         #fi
    // invalid type
    rule compareVec(_, _) => Equal [owise]
```

### Comparison of maps (`compareMap`)

The `compareMap` function compares two maps by iterating through their sorted keys and comparing the keys and
corresponding values.

`compareMap(Map1, Keys1, Map2, Keys2)`:
- `Map1` and `Map2`: Two maps being compared
- `Keys1` and `Keys2`: Sorted lists of keys for the respective maps, the order in which entries are compared.

```k
    syntax Ordering ::= compareMap(map1: Map, keys1: List, map2: Map, keys2: List)
        [function, total, symbol(compareMap)]
 // -----------------------------------------------------------------------------------
    rule compareMap(_M1, .List,               _M2, .List)               => Equal
    rule compareMap(_M1, .List,               _M2, ListItem(_:ScVal) _) => Less
    rule compareMap(_M1, ListItem(_:ScVal) _, _M2, .List)               => Greater
    rule compareMap(M1,  ListItem(A) AS,       M2, ListItem(B) BS)
      => #let C = compareMapItem( A, M1 {{ A }} orDefault Void, B, M2 {{ B }} orDefault Void ) #in
         #if C =/=K Equal
         #then C
         #else compareMap(M1, AS, M2, BS)
         #fi
    // invalid type
    rule compareMap(_, _, _, _) => Equal [owise]


    syntax Ordering ::= compareMapItem(key1: ScVal, val1: ScVal, key2: ScVal, val2: ScVal)    [function, total]
 // -----------------------------------------------------------------------------------------------------------
    rule compareMapItem(AK, AV, BK, BV)
      => #let C = compare(AK, BK) #in
         #if C =/=K Equal
         #then C
         #else compare(AV, BV)
         #fi

    syntax Int ::= ScValTypeOrd(ScVal)    [function, total, symbol(ScValTypeOrd)]
 // -------------------------------------------------------------------------------------------------
    rule ScValTypeOrd(SCBool(_))     => 0
    rule ScValTypeOrd(Void)          => 1
    rule ScValTypeOrd(Error(_,_))    => 2
    rule ScValTypeOrd(U32(_))        => 3
    rule ScValTypeOrd(I32(_))        => 4
    rule ScValTypeOrd(U64(_))        => 5
    rule ScValTypeOrd(I64(_))        => 6
    // Timepoint                     => 7
    // Duration                      => 8
    rule ScValTypeOrd(U128(_))       => 9
    rule ScValTypeOrd(I128(_))       => 10
    rule ScValTypeOrd(U256(_))       => 11
    rule ScValTypeOrd(ScBytes(_))    => 13
    rule ScValTypeOrd(ScString(_))   => 14
    rule ScValTypeOrd(Symbol(_))     => 15
    rule ScValTypeOrd(ScVec(_))      => 16
    rule ScValTypeOrd(ScMap(_))      => 17
    rule ScValTypeOrd(ScAddress(_))  => 18
    // ContractInstance              => 19
    // LedgerKeyContractInstance     => 20
    // LedgerKeyNonce                => 21
```

## Sorted key lists for ScMap

### Insertion

```k
    syntax List ::= insertKey(ScVal, List)   [function, total, symbol(insertKey)]
 // ----------------------------------------------------------------------------------------------
    rule insertKey(KEY, ListItem(X) XS) => ListItem(X) insertKey(KEY, XS) 
      requires Less ==K compare(X, KEY)
    rule insertKey(KEY, ListItem(X) XS) => ListItem(X) XS 
      requires Equal ==K compare(X, KEY)
    rule insertKey(KEY, XS)             => ListItem(KEY) XS
      [owise]
```

### Creation

```k
    syntax List ::= sortedKeys(Map)   [function, total]
 // ---------------------------------------------------
    rule sortedKeys(M) => sortKeys(keys_list(M))

    syntax List ::= sortKeys(List)    [function, total, symbol(sortKeys)]
 // -------------------------------------------------------------------------
    rule sortKeys(ListItem(KEY:ScVal) REST) => insertKey(KEY, sortKeys(REST))
    rule sortKeys(.List)                    => .List
    // sort mismatch
    rule sortKeys(ListItem(_) _REST)        => .List    [owise]

endmodule
```
