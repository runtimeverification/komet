# Errors


```k
module ERRORS
    imports BOOL
    imports INT

    syntax ErrorType ::= "ErrContract"             [symbol(ErrorType:Contract)]
                         | "ErrWasmVm"               [symbol(ErrorType:WasmVm)]
                         | "ErrContext"              [symbol(ErrorType:Context)]
                         | "ErrStorage"              [symbol(ErrorType:Storage)] 
                         | "ErrObject"               [symbol(ErrorType:Object)]
                         | "ErrCrypto"               [symbol(ErrorType:Crypto)]
                         | "ErrEvents"               [symbol(ErrorType:Events)]
                         | "ErrBudget"               [symbol(ErrorType:Budget)]
                         | "ErrValue"                [symbol(ErrorType:Value)]
                         | "ErrAuth"                 [symbol(ErrorType:Auth)]

    syntax Int ::= ErrorType2Int(ErrorType)      [function, total, symbol(ErrorType2Int)]
 // -------------------------------------------------------------------------------------
    rule ErrorType2Int(ErrContract)  => 0
    rule ErrorType2Int(ErrWasmVm)   => 1
    rule ErrorType2Int(ErrContext)  => 2
    rule ErrorType2Int(ErrStorage)  => 3
    rule ErrorType2Int(ErrObject)   => 4
    rule ErrorType2Int(ErrCrypto)   => 5
    rule ErrorType2Int(ErrEvents)   => 6
    rule ErrorType2Int(ErrBudget)   => 7
    rule ErrorType2Int(ErrValue)    => 8
    rule ErrorType2Int(ErrAuth)     => 9

    syntax ErrorType ::= Int2ErrorType(Int)   [function, total, symbol(Int2ErrorType)]
 // ----------------------------------------------------------------------------------
    rule Int2ErrorType(1) => ErrWasmVm
    rule Int2ErrorType(2) => ErrContext
    rule Int2ErrorType(3) => ErrStorage
    rule Int2ErrorType(4) => ErrObject
    rule Int2ErrorType(5) => ErrCrypto
    rule Int2ErrorType(6) => ErrEvents
    rule Int2ErrorType(7) => ErrBudget
    rule Int2ErrorType(8) => ErrValue
    rule Int2ErrorType(9) => ErrAuth
    rule Int2ErrorType(_) => ErrContract   [owise]

    syntax Bool ::= Int2ErrorTypeValid(Int)   [function, total, symbol(Int2ErrorTypeValid)]
 // ---------------------------------------------------------------------------------------
    rule Int2ErrorTypeValid(I) => 0 <=Int I andBool I <=Int 9

    syntax Int ::= "ArithDomain"         [macro]
                 | "IndexBounds"         [macro]
                 | "InvalidInput"        [macro]
                 | "MissingValue"        [macro]
                 | "ExistingValue"       [macro]
                 | "ExceededLimit"       [macro]
                 | "InvalidAction"       [macro]
                 | "InternalError"       [macro]
                 | "UnexpectedType"      [macro]
                 | "UnexpectedSize"      [macro]
 // --------------------------------------------
    rule ArithDomain => 0
    rule IndexBounds => 1
    rule InvalidInput => 2
    rule MissingValue => 3
    rule ExistingValue => 4
    rule ExceededLimit => 5
    rule InvalidAction => 6
    rule InternalError => 7
    rule UnexpectedType => 8
    rule UnexpectedSize => 9

endmodule
```