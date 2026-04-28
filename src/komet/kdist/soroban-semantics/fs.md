
```k
module FILE-SYSTEM
    imports STRING
    imports INT
    imports K-IO

    
    // When this number is too big the llvm-backend gets stuck
    // Not sure what's the biggest number accepted by the backend
    // but for the purpose of the kontrol-node 100mb should be
    // sufficient.
    syntax Int ::= "MAX_READ" [alias]
    // ------------------------------

    rule MAX_READ => 104857600 // 100mb

    syntax IOString ::= #readFile( String ) [function, impure, symbol(readFile)]
    // -----------------------------------------------------------------------------------

    syntax K ::= #writeFile( String, String ) [function, impure, symbol(writeFile)]
               | #appendFile( String, String) [function, impure, symbol(appendFile)]
               | #appendFileToFile( String, String ) [function, impure, symbol(appendFileToFile)]
    // --------------------------------------------------------------------------------------------------

    rule #readFile( FILE )
          => #let HANDLE:IOInt = #open( FILE, "r" ) #in
             #let RESULT = #read({HANDLE}:>Int, MAX_READ) #in
             #let _ = #close({HANDLE}:>Int) #in
             RESULT

    rule #writeFile( FILE, CONTENTS )
          => #let HANDLE:IOInt = #open( FILE, "w") #in
             #let RESULT = #write({HANDLE}:>Int, CONTENTS) #in
             #let _ = #close({HANDLE}:>Int) #in
             RESULT

    rule #appendFile( FILE, CONTENTS )
          => #let HANDLE:IOInt = #open( FILE, "a" ) #in
             #let RESULT = #write({HANDLE}:>Int, CONTENTS) #in
             #let _ = #close({HANDLE}:>Int) #in
             RESULT

    rule #appendFileToFile( DEST, SOURCE )
          => #system( "dd if=" +String SOURCE +String " of=" +String DEST +String " bs=1M oflag=append conv=notrunc" )

    rule #systemResult( _, _, _ ) => .K [owise]

endmodule
```
