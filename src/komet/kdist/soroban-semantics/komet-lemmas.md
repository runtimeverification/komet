```k
requires "wasm-semantics/kwasm-lemmas.md"
requires "data.md"

module KSOROBAN-LEMMAS [symbolic]
  imports KWASM-LEMMAS
  imports INT-BITWISE-LEMMAS
  imports HOST-OBJECT-LEMMAS
  imports SOROBAN
  imports MAP-SYMBOLIC

  syntax InternalCmd ::= runLemma(ProofStep) | doneLemma(ProofStep)
  syntax ProofStep ::= HostVal | ScVal | Int | Bool | Val

  rule <k> runLemma(S) => doneLemma(S) ... </k>

endmodule

module INT-BITWISE-LEMMAS [symbolic]
  imports INT
  imports BOOL

  rule C |Int S => S |Int C [simplification, concrete(C), symbolic(S)]
  rule X |Int 0 => X        [simplification]

  rule  A &Int  B          =>  B &Int  A          [simplification, concrete(A), symbolic(B)]
  rule (A &Int  B) &Int C  =>  A &Int (B  &Int C) [simplification, concrete(B, C)]
  rule  A &Int (B  &Int C) => (A &Int  B) &Int C  [simplification, symbolic(A, B)]

  syntax Bool ::= isPowerOf2(Int)  [function, total, symbol(isPowerOf2)]
  rule isPowerOf2(I:Int) => I ==Int 1 <<Int log2Int(I) requires 0 <Int I
  rule isPowerOf2(I:Int) => false                      requires I <=Int 0

  syntax Bool ::= isFullMask(Int)  [function, total, symbol(isFullMask)]
  rule isFullMask(I:Int) => I ==Int fullMask(log2Int(I) +Int 1) requires 0 <Int I
  rule isFullMask(I:Int) => false                               requires I <=Int 0

  syntax Int ::= fullMask(Int) [function, total, symbol(fullMask)]
  rule fullMask(I:Int) => (1 <<Int I) -Int 1 requires 0 <Int I
  rule fullMask(I:Int) => 0                  requires I <=Int 0

  rule [modInt-to-bit-mask]:
      I modInt M => I &Int (M -Int 1) requires isPowerOf2(M) andBool 0 <=Int I
    [simplification, concrete(M), preserves-definedness]

endmodule

module HOST-OBJECT-LEMMA-HELPERS [symbolic]
  imports HOST-OBJECT
  imports INT-BITWISE-LEMMAS

  syntax Bool ::= isTag(Int)      [function, total, symbol(isTag)]
                | isPayload(Int)  [function, total, symbol(isPayload)]
//-----------------------------------------------------------------
  rule isTag(TAG)   => 0 <=Int TAG andBool TAG <=Int 255
  // A payload is a 64-bit unsigned integer
  rule isPayload(P) => 0 <=Int P   andBool P <Int #pow(i64)     [concrete]

endmodule

module HOST-OBJECT-LEMMAS [symbolic]
  imports HOST-OBJECT-LEMMA-HELPERS

  rule [bitwise-mk-hostval-then-mask]:
      (_I <<Int SHIFT |Int T) &Int MASK => T &Int MASK
    requires isFullMask(MASK) andBool SHIFT >=Int log2Int(MASK +Int 1)
    [simplification, concrete(SHIFT, MASK)]

  rule [64bit-fullmask-of-payload]:
      X &Int 18446744073709551615 => X
    requires isPayload(X)
    [simplification]


  rule #getRange(#setRange(_BM, ADDR, VAL,  WIDTH), ADDR', WIDTH') => #wrap(WIDTH', VAL)
    requires 0 <=Int ADDR
     andBool 0  <Int WIDTH
     andBool 0 <=Int VAL andBool VAL <Int 2 ^Int (8 *Int WIDTH)
     andBool ADDR'  ==Int ADDR
     andBool WIDTH' <=Int WIDTH
    [simplification]

  rule [shrs-to-getBody]:
      i64 . shr_s unwrap(HV:HostVal) 8 => <i64> getBody(HV)
    [simplification]

  rule [shift-to-getBody]:
      unwrap(HV) >>Int 8 => getBody(HV)
      [simplification]

  rule [defined-unsigned-is-non-negative]:
        0 <=Int #unsigned(T, I) => true
    requires definedUnsigned(T, I)
    [simplification, preserves-definedness]

  rule [and-255-of-unwrap]:
    unwrap(HV:HostVal) &Int 255 => getTag(HV)    [simplification]

  rule [getTag-of-fromMajorMinorAndTag]:
      getTag(fromMajorMinorAndTag(MAJ, MIN, TAG)) => TAG
    requires 0 <=Int MAJ
     andBool 0 <=Int MIN
     andBool isTag(TAG)
    [simplification]

  rule [getBody-of-fromBodyAndTag]:
      getBody(fromBodyAndTag(BODY, TAG)) => BODY
    requires 0 <=Int BODY
     andBool isTag(TAG)
      [simplification]

  rule [getTag-of-fromBodyAndTag]:
      getTag(fromBodyAndTag(BODY, TAG)) => TAG
    requires 0 <=Int BODY
     andBool isTag(TAG)
      [simplification]

  rule [unwrap-is-payload]:
      isPayload(unwrap(_:HostVal)) => true
    [simplification]

  rule [unwrap-is-non-negative]:
      0 <=Int unwrap(_:HostVal) => true
    [simplification]

  // #getRange(_,_,8)'s result always fits in 64-bit
  rule [getRange-8-is-payload]: 
      isPayload(#getRange(_, _, 8)) => true
    [simplification]


  rule [getBody-of-unwrapped-small-i64]:
      #signed(
        i64,
        unwrap(
          fromBodyAndTag( #unsigned ( i56 , I:Int ) , 7 )
        )
      ) >>Int 8
      => I
    requires isSmallInt(Signed, I)
    [simplification]

  rule [shift-of-nonneg-is-nonneg]:
      0 <=Int I <<Int S => true
    requires 0 <=Int I andBool 0 <=Int S
    [simplification]

  rule [or-of-nonnegs-is-nonneg]:
      0 <=Int X |Int Y => true
    requires 0 <=Int X andBool 0 <=Int Y
    [simplification]

endmodule
```
