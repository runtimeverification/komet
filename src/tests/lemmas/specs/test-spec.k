module TEST-SPEC
    imports KASMER

    // Tested lemmas:
    // - bitwise-mk-hostval-then-mask
    claim [test-bitwise-mk-hostval-then-mask]:
        <program> .Steps </program>
        <instrs> .K </instrs>
        <k>
            runLemma( ( (I <<Int 32) |Int 4) &Int 255 )
          =>
            doneLemma( 4 )
        </k>
      requires 0 <=Int I

endmodule
