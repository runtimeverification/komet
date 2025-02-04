module INT-BITWISE-SPEC
    imports KASMER

    // Tested lemmas:
    // - modInt-to-bit-mask
    claim [test-modInt-to-andInt]:
        <program> .Steps </program>
        <instrs> .K </instrs>
        <k>
            runLemma( ( (I <<Int 32) |Int 4) modInt 256 )
          =>
            doneLemma( ( (I <<Int 32) |Int 4) &Int 255 )
        </k>
      requires 0 <=Int I

endmodule
