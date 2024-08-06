```k
requires "wasm-semantics/kwasm-lemmas.md"
requires "data.md"

module KSOROBAN-LEMMAS [symbolic]
  imports KWASM-LEMMAS
  imports HOST-OBJECT-LEMMAS
endmodule
```

```k
module HOST-OBJECT-LEMMAS [symbolic]
  imports HOST-OBJECT

  rule (_I <<Int 8 |Int T) &Int 255 => T &Int 255 [simplification]

  rule X |Int 0 => X [simplification]

  rule (_X <<Int S) &Int 255 => 0 requires S >=Int 8 [simplification]
endmodule
```
