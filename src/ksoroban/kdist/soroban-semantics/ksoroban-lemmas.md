```k
requires "wasm-semantics/kwasm-lemmas.md"
requires "data.md"

module KSOROBAN-LEMMAS [symbolic]
  imports KWASM-LEMMAS
  imports INT-BITWISE-LEMMAS
  imports HOST-OBJECT-LEMMAS
endmodule

module INT-BITWISE-LEMMAS [symbolic]

  rule C |Int S => S |Int C [simplification, concrete(C), symbolic(S)]
  rule X |Int 0 => X        [simplification]

  rule  A &Int  B          =>  B &Int  A          [simplification, concrete(A), symbolic(B)]
  rule (A &Int  B) &Int C  =>  A &Int (B  &Int C) [simplification, concrete(B, C)]
  rule  A &Int (B  &Int C) => (A &Int  B) &Int C  [simplification, symbolic(A, B)]

  syntax Bool ::= isPowerOf2(Int)  [function, total]
  rule isPowerOf2(I:Int) => I ==Int 1 <<Int log2Int(I) requires 0 <Int I
  rule isPowerOf2(I:Int) => false                      requires I <=Int 0

  syntax Bool ::= isFullMask(Int)  [function, total]
  rule isFullMask(I:Int) => I ==Int fullMask(log2Int(I) +Int 1) requires 0 <Int I
  rule isFullMask(I:Int) => false                               requires I <=Int 0

  syntax Int ::= fullMask(Int) [function, total]
  rule fullMask(I:Int) => (1 <<Int I) -Int 1 requires 0 <Int I
  rule fullMask(I:Int) => 0                  requires I <=Int 0

  rule I modInt M => I &Int fullMask(M) requires isPowerOf2(M) [simplification, concrete(M)]

endmodule

module HOST-OBJECT-LEMMAS [symbolic]
  imports HOST-OBJECT
  imports INT-BITWISE-LEMMAS

  rule (_I <<Int SHIFT |Int T) &Int MASK => T &Int MASK
    requires isFullMask(MASK) andBool SHIFT >=Int log2Int(MASK +Int 1)
    [simplification, concrete(SHIFT, MASK)]

endmodule
```
