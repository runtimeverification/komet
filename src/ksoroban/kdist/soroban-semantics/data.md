
[Documentation - Host Value Type](https://github.com/stellar/stellar-protocol/blob/master/core/cap-0046-01.md#host-value-type)

```k
module HOST-OBJECT-SYNTAX
    imports BOOL-SYNTAX
    imports INT-SYNTAX
    imports BYTES-SYNTAX
    imports STRING-SYNTAX
    imports LIST
    imports MAP

    syntax ScVal 
     ::= SCBool(Bool)                              [symbol(SCVal:Bool)]
        | "Void"                                   [symbol(SCVal:Void)]
        | U32(Int)                                 [symbol(SCVal:U32)]
        | I32(Int)                                 [symbol(SCVal:I32)]
        | U64(Int)                                 [symbol(SCVal:U64)]
        | I64(Int)                                 [symbol(SCVal:I64)]
        | ScVec(List)                              [symbol(SCVal:Vec)]
        | ScMap(Map)                               [symbol(SCVal:Map)]
        | ScAddress(Address)                       [symbol(SCVal:Address)]

    syntax HostVal ::= HostVal(Int)     [symbol(HostVal)]

    syntax Address ::= AccountId | ContractId
    syntax AccountId  ::= Account(Bytes)          [symbol(AccountId)]
    syntax ContractId ::= Contract(Bytes)         [symbol(ContractId)]

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
 // --------------------------------------------------------------------------------
    rule fromHandleAndTag(H, T) => fromMajorMinorAndTag(H, 0, T)
    rule fromMajorMinorAndTag(MAJ, MIN, TAG) => HostVal((((MAJ <<Int 24) |Int MIN) <<Int 8) |Int TAG)

    syntax WasmStringToken ::= #unparseWasmString ( String )         [function, total, hook(STRING.string2token)]
                             | #quoteUnparseWasmString ( String )   [function, total]
    rule #quoteUnparseWasmString(S) => #unparseWasmString("\"" +String S +String "\"")

    syntax Int ::= getTag(ScVal)   [function, total]
 // -----------------------------------------------------
    rule getTag(SCBool(true))  => 0
    rule getTag(SCBool(false)) => 1
    rule getTag(Void)          => 2
    rule getTag(U32(_))        => 4 
    rule getTag(I32(_))        => 5
    rule getTag(U64(_))        => 64
    rule getTag(I64(_))        => 65
    rule getTag(ScVec(_))      => 75
    rule getTag(ScMap(_))      => 76
    rule getTag(ScAddress(_))  => 77

    syntax ScVal ::= ScValOrDefault(KItem, ScVal)   [function, total, symbol(ScValOrDefault)]
 // ---------------------------------------------------------
    rule ScValOrDefault(X:ScVal, _:ScVal) => X
    rule ScValOrDefault(_,       D:ScVal) => D    [owise]

    syntax Int ::= IntOrDefault(KItem, Int)   [function, total, symbol(IntOrDefault)]
 // ---------------------------------------------------------
    rule IntOrDefault(X:Int, _:Int) => X
    rule IntOrDefault(_,     D:Int) => D    [owise]

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


    syntax ScVal ::= convertSmall(HostVal)      [function, total, symbol(convertSmall)]
 // -----------------------------------------------------------------------------------
    rule convertSmall(VAL) => SCBool(false)
      requires getTag(VAL) ==Int 0

    rule convertSmall(VAL) => SCBool(true)
      requires getTag(VAL) ==Int 1

    rule convertSmall(VAL) => Void
      requires getTag(VAL) ==Int 2

    rule convertSmall(VAL) => U32(getMajor(VAL))
      requires getTag(VAL) ==Int 4

    rule convertSmall(VAL) => I32(#signed(i32, getMajor(VAL)))
      requires getTag(VAL) ==Int 5
       andBool definedSigned(i32, getMajor(VAL))
      [preserves-definedness]

    rule convertSmall(VAL) => U64(getBody(VAL))
      requires getTag(VAL) ==Int 6

    rule convertSmall(_) => Void    [owise]

    syntax Bool ::= convertSmallImplemented(HostVal)    [function, total, symbol(convertSmallImplemented)]
 // ------------------------------------------------------------------------------------------------------
    rule convertSmallImplemented(VAL) => 0 <=Int getTag(VAL) andBool getTag(VAL) <=Int 6

endmodule
```