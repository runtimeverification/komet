# JSON Utilities

This module provides JSON serialization functions for the core WebAssembly semantic sorts.
It is used by the tracing module to serialize the VM state at each traced instruction.
Each function converts a semantic value or operator into a JSON term.

```k
requires "configuration.md"
requires "json.md"

module JSON-UTILS
    imports CONFIG-OPERATIONS
    imports JSON
```

## Value Types

These functions serialize WebAssembly value types and values.
`Val2JSON` converts a Wasm value into a two-element JSON array containing the type and the value.
Reference values can be either an integer (a function index) or `null`.
`undefined` — an auxiliary construct used in `wasm-semantics` to represent the result of partial mathematical functions (e.g. division by zero), is serialized as `null`.

```k
    syntax JSON ::= Val2JSON(Val)                [function, total]
 // ----------------------------------------------------------------------------
    rule Val2JSON(< T:IValType > I)       => [ IValType2JSON(T)   , I ]
    rule Val2JSON(< T:FValType > I)       => [ FValType2JSON(T)   , I ]
    rule Val2JSON(< T:RefValType > I:Int) => [ RefValType2JSON(T) , I ]
    rule Val2JSON(< T:RefValType > null)  => [ RefValType2JSON(T) , null:JSON ]
    rule Val2JSON(undefined)              => null
```

The three `IValType2JSON`, `FValType2JSON`, and `RefValType2JSON` functions handle each subtype of `ValType` separately.
`ValType2JSON` dispatches to the appropriate one via sort inference — each rule's right-hand side constrains `T` to a different subsort of `ValType`.

```k
    syntax JSON ::= ValType2JSON(ValType)        [function, total]
                  | IValType2JSON(IValType)      [function, total]
                  | FValType2JSON(FValType)      [function, total]
                  | RefValType2JSON(RefValType)  [function, total]
 // -----------------------------------------------------------
    rule ValType2JSON(T) => IValType2JSON(T)
    rule ValType2JSON(T) => FValType2JSON(T)
    rule ValType2JSON(T) => RefValType2JSON(T)
    rule IValType2JSON(i32) => "i32"
    rule IValType2JSON(i64) => "i64"
    rule FValType2JSON(f32) => "f32"
    rule FValType2JSON(f64) => "f64"
    rule RefValType2JSON(funcref) => "funcref"
    rule RefValType2JSON(externref) => "externref"

```

## Numeric Operations

These functions serialize the numeric operators used in WebAssembly instructions.
They are used by `Instr2JSON` to serialize the operator component of numeric instructions.

```k
    syntax JSON ::= IBinOp2JSON(IBinOp)    [function, total]
 // --------------------------------------------------------
    rule IBinOp2JSON( add )   => "add"
    rule IBinOp2JSON( sub )   => "sub"
    rule IBinOp2JSON( mul )   => "mul"
    rule IBinOp2JSON( div_u ) => "div_u"
    rule IBinOp2JSON( rem_u ) => "rem_u"
    rule IBinOp2JSON( div_s ) => "div_s"
    rule IBinOp2JSON( rem_s ) => "rem_s"
    rule IBinOp2JSON( and )   => "and"
    rule IBinOp2JSON( or )    => "or"
    rule IBinOp2JSON( xor )   => "xor"
    rule IBinOp2JSON( shl )   => "shl"
    rule IBinOp2JSON( shr_u ) => "shr_u"
    rule IBinOp2JSON( shr_s ) => "shr_s"
    rule IBinOp2JSON( rotl )  => "rotl"
    rule IBinOp2JSON( rotr )  => "rotr"

    syntax JSON ::= IUnOp2JSON(IUnOp)      [function, total]
 // --------------------------------------------------------
    rule IUnOp2JSON(clz) => "clz"
    rule IUnOp2JSON(ctz) => "ctz"
    rule IUnOp2JSON(popcnt) => "popcnt"

    syntax JSON ::= FBinOp2JSON(FBinOp)    [function, total]
 // --------------------------------------------------------
    rule FBinOp2JSON( add )      => "add"
    rule FBinOp2JSON( sub )      => "sub"
    rule FBinOp2JSON( mul )      => "mul"
    rule FBinOp2JSON( div )      => "div"
    rule FBinOp2JSON( min )      => "min"
    rule FBinOp2JSON( max )      => "max"
    rule FBinOp2JSON( copysign ) => "copysign"

    syntax JSON ::= FUnOp2JSON(FUnOp)   [function, total]
 // ----------------------------------------------------
    rule FUnOp2JSON( abs )     => "abs"
    rule FUnOp2JSON( neg )     => "neg"
    rule FUnOp2JSON( sqrt )    => "sqrt"
    rule FUnOp2JSON( floor )   => "floor"
    rule FUnOp2JSON( ceil )    => "ceil"
    rule FUnOp2JSON( trunc )   => "trunc"
    rule FUnOp2JSON( nearest ) => "nearest"

    syntax JSON ::= IRelOp2JSON(IRelOp)   [function, total]
 // ---------------------------------------------------
    rule IRelOp2JSON( eq )   => "eq"
    rule IRelOp2JSON( ne )   => "ne"
    rule IRelOp2JSON( lt_u ) => "lt_u"
    rule IRelOp2JSON( gt_u ) => "gt_u"
    rule IRelOp2JSON( lt_s ) => "lt_s"
    rule IRelOp2JSON( gt_s ) => "gt_s"
    rule IRelOp2JSON( le_u ) => "le_u"
    rule IRelOp2JSON( ge_u ) => "ge_u"
    rule IRelOp2JSON( le_s ) => "le_s"
    rule IRelOp2JSON( ge_s ) => "ge_s"

    syntax JSON ::= FRelOp2JSON(FRelOp)   [function, total]
 // ---------------------------------------------------
    rule FRelOp2JSON( lt ) => "lt"
    rule FRelOp2JSON( gt ) => "gt"
    rule FRelOp2JSON( le ) => "le"
    rule FRelOp2JSON( ge ) => "ge"
    rule FRelOp2JSON( eq ) => "eq"
    rule FRelOp2JSON( ne ) => "ne"

    syntax JSON ::= TestOp2JSON(TestOp)   [function, total]
 // -------------------------------------------------------
    rule TestOp2JSON( eqz ) => "eqz"

    syntax JSON ::= CvtOp2JSON(CvtOp)   [function, total]
 // -----------------------------------------------------
    rule CvtOp2JSON( extend_i32_u ) => "extend_i32_u"
    rule CvtOp2JSON( extend_i32_s ) => "extend_i32_s"
    rule CvtOp2JSON( convert_i32_s ) => "convert_i32_s"
    rule CvtOp2JSON( convert_i32_u ) => "convert_i32_u"

    rule CvtOp2JSON( wrap_i64 ) => "wrap_i64"
    rule CvtOp2JSON( convert_i64_s ) => "convert_i64_s"
    rule CvtOp2JSON( convert_i64_u ) => "convert_i64_u"

    rule CvtOp2JSON( promote_f32 ) => "promote_f32"
    rule CvtOp2JSON( trunc_f32_s ) => "trunc_f32_s"
    rule CvtOp2JSON( trunc_f32_u ) => "trunc_f32_u"

    rule CvtOp2JSON( demote_f64 ) => "demote_f64"
    rule CvtOp2JSON( trunc_f64_s ) => "trunc_f64_s"
    rule CvtOp2JSON( trunc_f64_u ) => "trunc_f64_u"

```

## Memory Operations

These functions serialize the memory access operators used in `load` and `store` instructions.
They are used by `Instr2JSON` to serialize the operator component of memory instructions.

```k
    syntax JSON ::= StoreOp2JSON(StoreOp) [function]
 // ------------------------------------------------
    rule StoreOp2JSON(store)   => "store"
    rule StoreOp2JSON(store8)  => "store8"
    rule StoreOp2JSON(store16) => "store16"
    rule StoreOp2JSON(store32) => "store32"

    syntax JSON ::= LoadOp2JSON(LoadOp) [function]
 // ------------------------------------------------
    rule LoadOp2JSON(load)     => "load"
    rule LoadOp2JSON(load8_u)  => "load8_u"
    rule LoadOp2JSON(load16_u) => "load16_u"
    rule LoadOp2JSON(load32_u) => "load32_u"
    rule LoadOp2JSON(load8_s)  => "load8_s"
    rule LoadOp2JSON(load16_s) => "load16_s"
    rule LoadOp2JSON(load32_s) => "load32_s"
```

## Instructions

`Instr2JSON` serializes a WebAssembly instruction into a JSON array.
The first element is always the instruction name as a string.
Additional elements carry the instruction's operands — types, operator names (delegated to the numeric and memory operation functions above), indices, and offsets as needed.

```k
    syntax JSON ::= Instr2JSON(Instr)     [function]
 // ------------------------------------------------
    rule Instr2JSON(hostCall(MOD, FUNC, _)) => ["hostCall", MOD, FUNC]
    rule Instr2JSON(#call(IDX))             => ["call", IDX]
    rule Instr2JSON(#br(I))                 => ["br", I]
    rule Instr2JSON( T:IValType . const I )       => ["const", IValType2JSON(T), I]
    rule Instr2JSON( T:FValType . const I:Int )   => ["const", FValType2JSON(T), I]
    rule Instr2JSON( T:FValType . const I:Float ) => ["const", FValType2JSON(T), I]
    
    rule Instr2JSON( T:IValType . OP:IBinOp ) => [IBinOp2JSON(OP), IValType2JSON(T)]
    rule Instr2JSON( T:IValType . OP:IUnOp )  => [IUnOp2JSON(OP),  IValType2JSON(T)]
    rule Instr2JSON( T:IValType . OP:IRelOp ) => [IRelOp2JSON(OP), IValType2JSON(T)]
    rule Instr2JSON( T:IValType . OP:TestOp ) => [TestOp2JSON(OP), IValType2JSON(T)]
    
    rule Instr2JSON( T:FValType . OP:FBinOp ) => [FBinOp2JSON(OP), FValType2JSON(T)]
    rule Instr2JSON( T:FValType . OP:FUnOp )  => [FUnOp2JSON(OP),  FValType2JSON(T)]
    rule Instr2JSON( T:FValType . OP:FRelOp ) => [FRelOp2JSON(OP), FValType2JSON(T)]
    
    rule Instr2JSON( T:ValType  . OP:CvtOp )  => [CvtOp2JSON(OP), ValType2JSON(T)]

    rule Instr2JSON(drop)        => [ "drop" ]
    rule Instr2JSON(select)      => [ "select" ]
    rule Instr2JSON(nop)         => [ "nop" ]
    rule Instr2JSON(unreachable) => [ "unreachable" ]
    rule Instr2JSON(return)      => [ "return" ]
    rule Instr2JSON(#block(_, _, _)) => [ "block" ]
    rule Instr2JSON(#loop(_,_,_))    => [ "loop"]
    rule Instr2JSON(#br_if(I))       => ["br_if", I ]
    rule Instr2JSON(#br_table(INTS)) => ["br_table", [ Ints2JSONs(INTS) ] ]
    

    rule Instr2JSON(#global.get(I)) => ["global.get", I]
    rule Instr2JSON(#global.set(I)) => ["global.set", I]
    rule Instr2JSON(#local.get(I))  => ["local.get",  I]
    rule Instr2JSON(#local.set(I))  => ["local.set",  I]
    rule Instr2JSON(#local.tee(I))  => ["local.tee",  I]

    rule Instr2JSON(#load(T,  OP, OFFSET))  => ["load",  ValType2JSON(T), LoadOp2JSON(OP),  OFFSET]
    rule Instr2JSON(#store(T, OP, OFFSET))  => ["store", ValType2JSON(T), StoreOp2JSON(OP), OFFSET]

    rule Instr2JSON(#table.get(I))     => ["table.get",  I]
    rule Instr2JSON(#table.set(I))     => ["table.set",  I]
    rule Instr2JSON(#table.size(I))    => ["table.size", I]
    rule Instr2JSON(#table.grow(I))    => ["table.grow", I]
    rule Instr2JSON(#table.fill(I))    => ["table.fill", I]
    rule Instr2JSON(#table.copy(I, J)) => ["table.copy", I, J]
    rule Instr2JSON(#table.init(I, J)) => ["table.init", I, J]
    rule Instr2JSON(#elem.drop(I))     => ["elem.drop",  I]

```

`Ints2JSONs` converts a list of integers into a sequence of JSON values, used by `Instr2JSON` to serialize the branch target list of `br_table`.

```k
    syntax JSONs ::= Ints2JSONs(Ints) [function]
 // --------------------------------------------
    rule Ints2JSONs(.Ints) => .JSONs
    rule Ints2JSONs(I IS)  => I , Ints2JSONs(IS)

```

## Runtime Structures

These functions serialize the runtime state captured at each trace point.

`Locals2JSON` serializes the local variable map as a JSON object, with local indices as string keys and their values serialized with `Val2JSON`.

`ValStack2JSON` serializes the value stack as a JSON array, preserving the stack order from top to bottom.

```k
    syntax JSON  ::= Locals2JSON(Map)    [function]
    syntax JSONs ::= Locals2JSONs(Map)   [function]
 // --------------------------------------------------
    rule Locals2JSON( M:Map ) => { Locals2JSONs(M) }
    rule Locals2JSONs( .Map) => .JSONs
    rule Locals2JSONs( (I:Int |-> V:Val) REST:Map ) => Int2String(I) : Val2JSON(V), Locals2JSONs( REST )

    syntax JSON  ::= ValStack2JSON(ValStack)    [function, total]
    syntax JSONs ::= ValStack2JSONs(ValStack)   [function, total]
 // -------------------------------------------------------------
    rule ValStack2JSON(VS)         => [ ValStack2JSONs(VS) ]
    rule ValStack2JSONs(.ValStack) => .JSONs
    rule ValStack2JSONs(V : Vs)    => Val2JSON(V) , ValStack2JSONs(Vs)

endmodule