module INT-BITWISE-SPEC
    imports KASMER

    // Tested lemmas:
    // - modInt-to-bit-mask
    claim [test-modInt-to-andInt]:
        ( (I <<Int 32) |Int 4) modInt 256
          =>
        ( (I <<Int 32) |Int 4) &Int 255 
      requires 0 <=Int I

endmodule
