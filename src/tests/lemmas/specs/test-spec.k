module TEST-SPEC
    imports KASMER


    // Tested lemmas:
    // - and-255-of-unwrap
    claim [test-bitwise-gettag-of-u32]:
          unwrap(toSmall(U32(I))) &Int 255 => 4
      requires 0 <=Int I

    // Tested lemmas:
    // - getTag-of-fromMajorMinorAndTag
    claim [test-getTag-of-u32]:
          getTag(toSmall(U32(I))) => 4
      requires 0 <=Int I

    // Tested lemmas:
    // - getTag-of-fromBodyAndTag
    // - defined-unsigned-is-non-negative
    claim [getTag-of-small-i64]:
      <program> .Steps </program>
      <instrs> .K </instrs>
      <k>
        runLemma( getTag(toSmall(I64(I))) )
      =>
        doneLemma( 7 )
      </k>
      requires isSmallInt(Signed, I)


    // Tested lemmas:
    // - modInt-to-bit-mask-64
    // - unwrap-fits-in-64-bits
    claim [modInt-of-unwrap-unsigned]:
      <program> .Steps </program>
      <instrs> .K </instrs>
      <k>
        runLemma( unwrap ( fromBodyAndTag ( #unsigned ( i56 , I ) , 7 )) modInt 18446744073709551616 )
      =>
        doneLemma( unwrap ( fromBodyAndTag ( #unsigned ( i56 , I ) , 7 )) )
      </k>
      requires isSmallInt(Signed, I)

    // Tested lemmas:
    // - modInt-to-bit-mask-64
    // - unwrap-fits-in-64-bits
    // - shrs-to-getBody
    // - getBody-of-fromBodyAndTag
    claim [shrs-of-unwrap-unsigned]:
      <program> .Steps </program>
      <instrs> .K </instrs>
      <k>
        runLemma( i64 . shr_s unwrap ( fromBodyAndTag ( #unsigned ( i56 , I ) , 7 )) modInt 18446744073709551616 8 )
      =>
        doneLemma( <i64> #unsigned ( i64 , I ) )
      </k>
      requires isSmallInt(Signed, I)

endmodule
