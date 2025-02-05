module TEST-SPEC
    imports KASMER

    // Tested lemmas:
    // - bitwise-mk-hostval-then-mask
    claim [test-bitwise-mk-hostval-then-mask]:
        ( (I <<Int 32) |Int 4) &Int 255
          =>
        4
      requires 0 <=Int I

endmodule
