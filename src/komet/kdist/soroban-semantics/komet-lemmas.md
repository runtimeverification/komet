```k
requires "wasm-semantics/kwasm-lemmas.md"
requires "data.md"

module KSOROBAN-LEMMAS [symbolic]
  imports KWASM-LEMMAS
  imports SOROBAN

  syntax InternalCmd ::= runLemma(ProofStep) | doneLemma(ProofStep)
  syntax ProofStep ::= HostVal | ScVal | Int | Bool

  rule <k> runLemma(S) => doneLemma(S) ... </k>

  /// Int Helpers

  syntax Bool ::= isPowerOf2(Int)  [function, total]
  rule isPowerOf2(I:Int) => I ==Int 1 <<Int log2Int(I) requires 0 <Int I
  rule isPowerOf2(I:Int) => false                      requires I <=Int 0

  syntax Bool ::= isFullMask(Int)  [function, total]
  rule isFullMask(I:Int) => I ==Int fullMask(log2Int(I) +Int 1) requires 0 <Int I
  rule isFullMask(I:Int) => false                               requires I <=Int 0

  syntax Int ::= fullMask(Int) [function, total]
  rule fullMask(I:Int) => (1 <<Int I) -Int 1 requires 0 <Int I
  rule fullMask(I:Int) => 0                  requires I <=Int 0

  syntax Bool ::= isTag(Int)         [function, total, symbol(isTag)]
                | isHostValInt(Int)  [function, total, symbol(isHostValInt)]
//--------------------------------------------------------------------------
  rule isTag(TAG)   => 0 <=Int TAG andBool TAG <=Int 255
  rule isHostValInt(I) => 0 <=Int I andBool I <=Int maxInt(i64, Unsigned)  [concrete]

  /// Bitwise Lemmas

  rule C |Int S => S |Int C [simplification, concrete(C), symbolic(S)]
  rule X |Int 0 => X        [simplification]

  rule  A &Int  B          =>  B &Int  A          [simplification, concrete(A), symbolic(B)]
  rule (A &Int  B) &Int C  =>  A &Int (B  &Int C) [simplification, concrete(B, C)]
  rule  A &Int (B  &Int C) => (A &Int  B) &Int C  [simplification, symbolic(A, B)]

  rule [modInt-to-bit-mask]:
      I modInt M => I &Int (M -Int 1) requires isPowerOf2(M)
    [simplification, concrete(M)]

  rule X &Int MASK => X
    requires isFullMask(MASK)
     andBool 0 <=Int X
     andBool X <=Int MASK
    [simplification]

  /// Integer Lemmas
  
  // From Wasm Semantics
  // rule #signed(ITYPE, N) => N                  requires 0            <=Int N andBool N <Int #pow1(ITYPE)
  // rule #signed(ITYPE, N) => N -Int #pow(ITYPE) requires #pow1(ITYPE) <=Int N andBool N <Int #pow (ITYPE)

  // rule #unsigned( ITYPE, N) => N +Int #pow(ITYPE) requires N  <Int 0
  // rule #unsigned(_ITYPE, N) => N                  requires 0 <=Int N

  // #unsigned(T, A) is always nonnegative once definedUnsigned(T, A) holds
  // (A may exceed T's signed max -- definedUnsigned allows up to T's unsigned max).
  //   - definedUnsigned(T, A): -#pow1(T) <= A < #pow(T)
  //   - 0 <= A:
  //       1) 0 <= A                                            -- branch condition
  //       2) #unsigned(T, A) == A                              -- #unsigned's definition when 0 <= A
  //       3) 0 <= #unsigned(T, A)                              -- substitute 2) into 1)
  //   - A <  0:
  //       1) -#pow1(T)              <= A                       -- definedUnsigned(T,A)
  //       2) -#pow1(T) +Int #pow(T) <= A +Int #pow(T)          -- add #pow(T) to both sides of 1)
  //       3) #pow1(T)               <= A +Int #pow(T)          -- #pow(T) == 2 *Int #pow1(T)
  //       4) #pow1(T)               <= #unsigned(T, A)         -- A +Int #pow(T) == #unsigned(T, A) since A < 0
  //       5) 0 <= #pow1(T)          <= #unsigned(T, A)         -- #pow1(T) >= 0
  rule [unsigned-is-nonnegative]:
      0 <=Int #unsigned(T, A) => true
    requires definedUnsigned(T, A)
    [simplification]

  // #unsigned(T, A) always stays below #pow(T) once definedUnsigned(T, A) holds.
  //   - definedUnsigned(T, A): -#pow1(T) <= A < #pow(T)
  //   - 0 <= A:
  //       1) A < #pow(T)                                        -- definedUnsigned(T,A)
  //       2) #unsigned(T, A) == A                               -- #unsigned's definition when 0 <= A
  //       3) #unsigned(T, A) < #pow(T)                          -- substitute 2) into 1)
  //   - A <  0:
  //       1) A < 0                                              -- branch condition
  //       2) A +Int #pow(T) < 0 +Int #pow(T)                    -- add #pow(T) to both sides of 1)
  //       3) A +Int #pow(T) < #pow(T)                           -- 0 +Int #pow(T) == #pow(T)
  //       4) #unsigned(T, A) < #pow(T)                          -- A +Int #pow(T) == #unsigned(T, A) since A < 0
  rule [unsigned-upper-bound]:
      #unsigned(T, A) <Int POW_T => true
    requires POW_T ==Int #pow(T)
     andBool definedUnsigned(T, A)
    [simplification]

  // Round-trip identity: #unsigned packs a signed A into T's unsigned range,
  // #signed unpacks it back out. Only recovers A when A was already in T's
  // signed range (-#pow1(T) <= A < #pow1(T), tighter than definedUnsigned):
  //   - 0 <= A (so 0 <= A < #pow1(T) from the requires bounds):
  //       1) 0 <= A < #pow1(T)                                  -- requires bounds, this branch
  //       2) #unsigned(T, A) == A                               -- #unsigned's definition when 0 <= A
  //       3) 0 <= #unsigned(T, A) < #pow1(T)                    -- substitute 2) into 1)
  //       4) #signed(T, #unsigned(T, A)) == #unsigned(T, A)     -- #signed's definition when 0 <= N < #pow1(T), via 3)
  //       5) #signed(T, #unsigned(T, A)) == A                   -- substitute 2) into 4)
  //   - A <  0 (so -#pow1(T) <= A < 0 from the requires bounds):
  //       1) -#pow1(T) <= A < 0                                                -- requires bounds, this branch
  //       2) #unsigned(T, A) == A +Int #pow(T)                                 -- #unsigned's definition when A < 0
  //       3) -#pow1(T) +Int #pow(T) <= A +Int #pow(T) < 0 +Int #pow(T)         -- add #pow(T) to all sides of 1)
  //       4) #pow1(T) <= A +Int #pow(T) < #pow(T)                              -- #pow(T) == 2 *Int #pow1(T)
  //       5) #pow1(T) <= #unsigned(T, A) < #pow(T)                             -- substitute 2) into 4)
  //       6) #signed(T, #unsigned(T, A)) == #unsigned(T, A) -Int #pow(T)       -- #signed's definition when #pow1(T) <= N < #pow(T), via 5)
  //       7) #signed(T, #unsigned(T, A)) == A +Int #pow(T) -Int #pow(T)        -- substitute 2) into 6)
  //       8) #signed(T, #unsigned(T, A)) == A                                  -- simplify 7)
  rule [signed-of-unsigned]:
      #signed( T , #unsigned( T , A ) ) => A
    requires 0 -Int #pow1(T) <=Int A
     andBool A <Int #pow1(T)
    [simplification]


  /// HostVal Lemmas

  rule [getBody-of-fromBodyAndTag]:
      getBody(fromBodyAndTag(BODY, _TAG)) => BODY
    [simplification]

  rule [getTag-of-fromBodyAndTag]:
      getTag(fromBodyAndTag(_BODY, TAG)) => TAG
    [simplification]

  rule [getMajor-of-fromMajorMinorAndTag]:
      getMajor(fromMajorMinorAndTag(MAJ, _MIN, _TAG)) => MAJ
    [simplification]

  rule [getMinor-of-fromMajorMinorAndTag]:
      getMinor(fromMajorMinorAndTag(_MAJ, MIN, _TAG)) => MIN
    [simplification]

  rule [getTag-of-fromMajorMinorAndTag]:
      getTag(fromMajorMinorAndTag(_MAJ, _MIN, TAG)) => TAG
    [simplification]


  rule [bitwise-to-getTag]:
      unwrap( HV:HostVal ) &Int 255 => getTag( HV ) 
    [simplification]

  rule I &Int 18446744073709551615 => I
      requires isHostValInt(I)
    [simplification]

  rule isHostValInt( unwrap(_:HostVal) ) => true     [simplification]

  rule [shrs-to-getBody]:
      i64 . shr_s unwrap(HV:HostVal) 8 => #extends(i64, i56, getBody(HV))
    [simplification]

  rule [shrs-skip-tag]:
      i64 . shr_s unwrap(HV:HostVal) W => #applyIBinOpToVal(
                                            i64 , shr_s,
                                            i64 . shr_s unwrap(HV) 8,
                                            <i64> (W -Int 8)
                                          )
    requires 8 <Int W
    [simplification]

  syntax Val ::= #applyIBinOpToVal(IValType, IBinOp, Val, Val)   [function, total]
  rule #applyIBinOpToVal(T, OP, X1, X2) => T . OP #get(X1) #get(X2)
  rule #applyIBinOpToVal(_,  _,  _,  _) => undefined                  [owise]

endmodule
```
