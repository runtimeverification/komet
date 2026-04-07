
```k
requires "configuration.md"
requires "fs.md"

module TRACING
    imports CONFIG-OPERATIONS
    imports FILE-SYSTEM

    syntax TraceItem ::= Instr
    
 
    syntax InternalInstr ::= "#beforeTrace"             [symbol("#beforeTrace")]
                           | #afterTrace(TraceItem)     [symbol("#afterTrace")]
 // ---------------------------------------------------------------------------
    rule [skip-tracedInstr]:
        <instrs> #afterTrace(_) => .K ... </instrs> // generalize this in the middle of the sequence

    syntax Bool ::= alreadyTraced(K)          [function, total]
 // -------------------------------------------------------
    rule alreadyTraced(I ~> #afterTrace(I) ~> _) => true
    rule alreadyTraced(_)                        => false   [owise]

    rule [insert-beforeTrace]:
      <instrs> I:TraceItem ~> REST 
            => #beforeTrace
            ~> I
            ~> #afterTrace(I)
            ~> REST
      </instrs>
      <ioDir> PATH </ioDir>
      requires shouldTrace(I)
       andBool notBool alreadyTraced(I ~> REST)
       andBool PATH =/=String ""
      [priority(10)]

    rule [trace-instr]:
      <instrs> #beforeTrace
            ~> H 
            => #let TRACE_DATA = generateTrace(H) #in
               #if TRACE_DATA =/=String ""
               #then #appendFile(PATH, TRACE_DATA +String "\n")
               #else .K
               #fi
            ~> H
               ...
      </instrs>
      <ioDir> PATH </ioDir>


    rule [trace-skip-unhandled]:
      <instrs> (#beforeTrace => .K) ~> _:TraceItem ... </instrs>
      [owise]


    syntax Bool ::= shouldTrace(TraceItem)      [function, total]
 // -------------------------------------------------------------
    rule shouldTrace(hostCall(_, _, _)) => true
    rule shouldTrace(#call(_))          => true
    rule shouldTrace(_)                 => false  [owise]

    syntax String ::= generateTrace(Instr)   [function, total]
 // ---------------------------------------------------------
    rule generateTrace(hostCall(MOD, FUNC, _)) => "hostCall " +String MOD +String " " +String FUNC
    rule generateTrace(#call(IDX))             => "call " +String Int2String(IDX)
    rule generateTrace(_)                      => ""      [owise]

    rule [trap-skip-afterTrace]: <instrs> trap ~> (#afterTrace(_) => .K) ... </instrs>

endmodule
```