
[Documentation - Host Value Type](https://github.com/stellar/stellar-protocol/blob/master/core/cap-0046-01.md#host-value-type)

```k
module HOST-OBJECT-SYNTAX
    imports BOOL-SYNTAX
    imports INT-SYNTAX
    imports BYTES-SYNTAX
    imports STRING-SYNTAX
    imports LIST
    imports MAP
```

## ScVal

[Documentation: ScVal](https://github.com/stellar/stellar-protocol/blob/master/core/cap-0046-01.md#scval)

`ScVal` is a union of various datatypes used in the context of smart contracts for passing values to and from contracts and
storing data on the host side. 


```k
    syntax ScVal 
     ::= SCBool(Bool)                              [symbol(SCVal:Bool)]
        | "Void"                                   [symbol(SCVal:Void)]
        | U32(Int)                                 [symbol(SCVal:U32)]
        | I32(Int)                                 [symbol(SCVal:I32)]
        | U64(Int)                                 [symbol(SCVal:U64)]
        | I64(Int)                                 [symbol(SCVal:I64)]
        | U128(Int)                                [symbol(SCVal:U128)]
        | ScVec(List)                              [symbol(SCVal:Vec)]
        | ScMap(Map)                               [symbol(SCVal:Map)]
        | ScAddress(Address)                       [symbol(SCVal:Address)]
        | Symbol(String)                           [symbol(SCVal:Symbol)]

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
                 | getTag(HostVal)          [function, total, symbol(getTag)]
                 | getBody(HostVal)         [function, total, symbol(getBody)]
 // -----------------------------------------------------------------------
    rule getMajor(HostVal(I)) => I >>Int 32
    rule getTag(HostVal(I))   => I &Int 255
    rule getBody(HostVal(I))  => I >>Int 8

    syntax Bool ::= isObject(HostVal)                   [function, total, symbol(isObject)]
                  | isObjectTag(Int)                [function, total, symbol(isObjectTag)]
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
    rule getTag(SCBool(true))  => 0
    rule getTag(SCBool(false)) => 1
    rule getTag(Void)          => 2
    rule getTag(U32(_))        => 4 
    rule getTag(I32(_))        => 5
    rule getTag(U64(I))        => 6     requires          I <=Int #maxU64small
    rule getTag(U64(I))        => 64    requires notBool( I <=Int #maxU64small )
    rule getTag(I64(_))        => 65    // I64small is not implemented
    rule getTag(U128(I))       => 10    requires          I <=Int #maxU64small
    rule getTag(U128(I))       => 68    requires notBool( I <=Int #maxU64small ) // U64small and U128small have the same width
    rule getTag(ScVec(_))      => 75
    rule getTag(ScMap(_))      => 76
    rule getTag(ScAddress(_))  => 77
    rule getTag(Symbol(BS))    => 14    requires lengthString(BS) <=Int 9
    rule getTag(Symbol(BS))    => 74    requires lengthString(BS) >Int  9


    // 64-bit integers that fit in 56 bits
    syntax Int ::= "#maxU64small"     [macro]
                 | "#maxI64small"     [macro]
                 | "#minI64small"     [macro]
 // -----------------------------------------
    rule #maxU64small => 72057594037927935
    rule #maxI64small => 36028797018963967
    rule #minI64small => -36028797018963968

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
    rule OBJS {{ I }} orDefault (D:ScVal) => ScValOrDefault(OBJS [ I ], D)
      requires 0 <=Int I andBool I <Int size(OBJS)

    rule _OBJS {{ _I }} orDefault (D:ScVal) => D
      [owise]

    syntax HostVal ::= List "{{" Int "}}" "orDefault" HostVal     
        [function, total, symbol(HostVal:getOrDefault)]
 // ---------------------------------------------------------
    rule OBJS {{ I }} orDefault (D:HostVal) => HostValOrDefault(OBJS [ I ], D)
      requires 0 <=Int I andBool I <Int size(OBJS)

    rule _OBJS {{ _I }} orDefault (D:HostVal) => D
      [owise]

```

## Conversion between `HostVal` and `ScVal`


```k
    syntax ScVal ::= fromSmall(HostVal)      [function, total, symbol(fromSmall)]
 // -----------------------------------------------------------------------------------
    rule fromSmall(VAL) => SCBool(false)           requires getTag(VAL) ==Int 0

    rule fromSmall(VAL) => SCBool(true)            requires getTag(VAL) ==Int 1

    rule fromSmall(VAL) => Void                    requires getTag(VAL) ==Int 2

    rule fromSmall(VAL) => U32(getMajor(VAL))      requires getTag(VAL) ==Int 4

    rule fromSmall(VAL) => I32(#signed(i32, getMajor(VAL)))
      requires getTag(VAL) ==Int 5
       andBool definedSigned(i32, getMajor(VAL))
      [preserves-definedness]

    rule fromSmall(VAL) => U64(getBody(VAL))       requires getTag(VAL) ==Int 6

    rule fromSmall(VAL) => U128(getBody(VAL))      requires getTag(VAL) ==Int 10

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
    rule toSmall(U32(I))        => fromMajorMinorAndTag(I, 0, 4)
    rule toSmall(I32(I))        => fromMajorMinorAndTag(#unsigned(i32, I), 0, 5)
      requires definedUnsigned(i32, I)
    rule toSmall(U64(I))        => fromBodyAndTag(I, 6)               requires I <=Int #maxU64small
    rule toSmall(U128(I))       => fromBodyAndTag(I, 10)              requires I <=Int #maxU64small
    rule toSmall(Symbol(S))     => fromBodyAndTag(encode6bit(S), 14)  requires lengthString(S) <=Int 9
    rule toSmall(_)             => HostVal(-1)                        [owise]

    syntax Bool ::= toSmallValid(ScVal)
        [function, total, symbol(toSmallValid)]
 // ---------------------------------------------------------------------------------
    rule toSmallValid(VAL) => toSmall(VAL) =/=K HostVal(-1)


    syntax String ::= decode6bit(Int)       [function, total, symbol(decode6bit)]
 // --------------------------------------------------------------------------------
    rule decode6bit(I) => decode6bit(I >>Int 6) +String decode6bitChar(I &Int 63)   requires 0 <Int I
    rule decode6bit(_) => ""                                                        [owise] 

    syntax String ::= "sixBitStringTable" [macro]
 // -------------------------------------------------------------------------------------------
    rule sixBitStringTable => "_0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefgyahijklmnopqrstuvwxyz"

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
    
endmodule
```
