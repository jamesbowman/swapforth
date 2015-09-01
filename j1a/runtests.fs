#noverbose
\ ANS Forth tests - run all tests

\ Adjust the file paths as appropriate to your system
\ Select the appropriate test harness, either the simple tester.fr
\ or the more complex ttester.fs 

CR .( Running ANS Forth and Forth 2012 test programs, version 0.11) CR

new

\ From: John Hayes S1I
\ Subject: tester.fr
\ Date: Mon, 27 Nov 95 13:10:09 PST  

\ (C) 1995 JOHNS HOPKINS UNIVERSITY / APPLIED PHYSICS LABORATORY
\ MAY BE DISTRIBUTED FREELY AS LONG AS THIS COPYRIGHT NOTICE REMAINS.
\ VERSION 1.2

\ 31/3/2015 Variable #ERRORS added and incremented for each error reported.
\ 22/1/09 The words { and } have been changed to T{ and }T respectively to
\ agree with the Forth 200X file ttester.fs. This avoids clashes with
\ locals using { ... } and the FSL use of } 

HEX

: ERROR         \ ( C-ADDR U -- ) DISPLAY AN ERROR MESSAGE FOLLOWED BY
                \ THE LINE THAT HAD THE ERROR.
   CR TYPE SOURCE TYPE          \ DISPLAY LINE CORRESPONDING TO ERROR
   begin again
;

VARIABLE ACTUAL-DEPTH                   \ STACK RECORD
CREATE ACTUAL-RESULTS 20 CELLS ALLOT

: T{            \ ( -- ) SYNTACTIC SUGAR.
   ;

: ->            \ ( ... -- ) RECORD DEPTH AND CONTENT OF STACK.
   DEPTH DUP ACTUAL-DEPTH !             \ RECORD DEPTH
   ?DUP IF                              \ IF THERE IS SOMETHING ON STACK
      0 DO ACTUAL-RESULTS I CELLS + ! LOOP \ SAVE THEM
   THEN ;

: }T            \ ( ... -- ) COMPARE STACK (EXPECTED) CONTENTS WITH SAVED
      \ (ACTUAL) CONTENTS.
   DEPTH ACTUAL-DEPTH @ = IF            \ IF DEPTHS MATCH
      DEPTH ?DUP IF                     \ IF THERE IS SOMETHING ON THE STACK
         0  DO                          \ FOR EACH STACK ITEM
                ACTUAL-RESULTS I CELLS + @      \ COMPARE ACTUAL WITH EXPECTED
                <> IF S" bad: " ERROR BEGIN AGAIN THEN
         LOOP
      THEN
   ELSE                                 \ DEPTH MISMATCH
      S" WRONG NUMBER OF RESULTS: " ERROR
   THEN ;

: TESTING       \ ( -- ) TALKING COMMENT.
  SOURCE 
   >IN ! DROP [CHAR] * EMIT
;

marker TST1
include core.fr
decimal
cr .( At end of core    : ) unused 4 u.r .(  bytes free) cr
TST1
\ Hack. These were defined in core.fr, but MARKER loses them
0 INVERT                        CONSTANT MAX-UINT
0 INVERT 1 RSHIFT               CONSTANT MAX-INT
0 INVERT 1 RSHIFT INVERT        CONSTANT MIN-INT
0 INVERT 1 RSHIFT               CONSTANT MID-UINT
0 INVERT 1 RSHIFT INVERT        CONSTANT MID-UINT+1

include coreplustest.fth
cr .( At end of coreplus: ) unused 4 u.r .(  bytes free) cr

\ include coreexttest.fth
\ include errorreport.fth
\ include coreexttest.fth
\ include doubletest.fth
\ include exceptiontest.fth
\ include facilitytest.fth
\ include filetest.fth
\ include localstest.fth
\ include memorytest.fth
\ include toolstest.fth
\ include searchordertest.fth
\ include stringtest.fth
\ REPORT-ERRORS

CR CR .( Forth tests completed ) CR CR

new
cr .( Base system:        ) unused 4 u.r .(  bytes free)
cr cr
