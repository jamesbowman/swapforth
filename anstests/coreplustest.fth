\ Additional tests on the the ANS Forth Core word set

\ This program was written by Gerry Jackson in 2007, with contributions from
\ others where indicated, and is in the public domain - it can be distributed
\ and/or modified in any way but please retain this notice.

\ This program is distributed in the hope that it will be useful,
\ but WITHOUT ANY WARRANTY; without even the implied warranty of
\ MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

\ The tests are not claimed to be comprehensive or correct 

\ ------------------------------------------------------------------------------
\ Version 0.11 25 April 2015 Number prefixes # $ % and 'c' character input tested
\         0.10 3 August 2014 Test IMMEDIATE doesn't toggle an immediate flag
\         0.3  1 April 2012 Tests placed in the public domain.
\              Testing multiple ELSE's.
\              Further tests on DO +LOOPs.
\              Ackermann function added to test RECURSE.
\              >IN manipulation in interpreter mode
\              Immediate CONSTANTs, VARIABLEs and CREATEd words tests.
\              :NONAME with RECURSE moved to core extension tests.
\              Parsing behaviour of S" ." and ( tested
\         0.2  6 March 2009 { and } replaced with T{ and }T
\              Added extra RECURSE tests
\         0.1  20 April 2007 Created
\ ------------------------------------------------------------------------------
\ The tests are based on John Hayes test program for the core word set
\
\ This file provides some more tests on Core words where the original Hayes
\ tests are thought to be incomplete
\
\ Words tested in this file are:
\     DO +LOOP RECURSE ELSE >IN IMMEDIATE
\ ------------------------------------------------------------------------------
\ Assumptions and dependencies:
\     - tester.fr or ttester.fs has been loaded prior to this file
\     - core.fr has been loaded so that constants MAX-INT, MIN-INT and
\       MAX-UINT are defined
\ ------------------------------------------------------------------------------

DECIMAL

TESTING DO +LOOP with run-time increment, negative increment, infinite loop
\ Contributed by Reinhold Straub

VARIABLE ITERATIONS
VARIABLE INCREMENT
: GD7 ( LIMIT START INCREMENT -- )
   INCREMENT !
   0 ITERATIONS !
   DO
      1 ITERATIONS +!
      I
      ITERATIONS @  6 = IF LEAVE THEN
      INCREMENT @
   +LOOP ITERATIONS @
;

T{  4  4 -1 GD7 -> 4 1 }T
T{  1  4 -1 GD7 -> 4 3 2 1 4 }T
T{  4  1 -1 GD7 -> 1 0 -1 -2 -3 -4 6 }T
T{  4  1  0 GD7 -> 1 1 1 1 1 1 6 }T
T{  0  0  0 GD7 -> 0 0 0 0 0 0 6 }T
T{  1  4  0 GD7 -> 4 4 4 4 4 4 6 }T
T{  1  4  1 GD7 -> 4 5 6 7 8 9 6 }T
T{  4  1  1 GD7 -> 1 2 3 3 }T
T{  4  4  1 GD7 -> 4 5 6 7 8 9 6 }T
T{  2 -1 -1 GD7 -> -1 -2 -3 -4 -5 -6 6 }T
T{ -1  2 -1 GD7 -> 2 1 0 -1 4 }T
T{  2 -1  0 GD7 -> -1 -1 -1 -1 -1 -1 6 }T
T{ -1  2  0 GD7 -> 2 2 2 2 2 2 6 }T
T{ -1  2  1 GD7 -> 2 3 4 5 6 7 6 }T
T{  2 -1  1 GD7 -> -1 0 1 3 }T
T{ -20 30 -10 GD7 -> 30 20 10 0 -10 -20 6 }T
T{ -20 31 -10 GD7 -> 31 21 11 1 -9 -19 6 }T
T{ -20 29 -10 GD7 -> 29 19 9 -1 -11 5 }T

\ ------------------------------------------------------------------------------
TESTING DO +LOOP with large and small increments

\ Contributed by Andrew Haley

MAX-UINT 8 RSHIFT 1+ CONSTANT USTEP
USTEP NEGATE CONSTANT -USTEP
MAX-INT 7 RSHIFT 1+ CONSTANT STEP
STEP NEGATE CONSTANT -STEP

VARIABLE BUMP

T{ : GD8 BUMP ! DO 1+ BUMP @ +LOOP ; -> }T

T{ 0 MAX-UINT 0 USTEP GD8 -> 256 }T
T{ 0 0 MAX-UINT -USTEP GD8 -> 256 }T

T{ 0 MAX-INT MIN-INT STEP GD8 -> 256 }T
T{ 0 MIN-INT MAX-INT -STEP GD8 -> 256 }T

\ Two's complement arithmetic, wraps around modulo wordsize
\ Only tested if the Forth system does wrap around, use of conditional
\ compilation deliberately avoided

MAX-INT 1+ MIN-INT = CONSTANT +WRAP?
MIN-INT 1- MAX-INT = CONSTANT -WRAP?
MAX-UINT 1+ 0=       CONSTANT +UWRAP?
0 1- MAX-UINT =      CONSTANT -UWRAP?

: GD9  ( n limit start step f result -- )
   >R IF GD8 ELSE 2DROP 2DROP R@ THEN -> R> }T
;

T{ 0 0 0  USTEP +UWRAP? 256 GD9
T{ 0 0 0 -USTEP -UWRAP?   1 GD9
T{ 0 MIN-INT MAX-INT  STEP +WRAP? 1 GD9
T{ 0 MAX-INT MIN-INT -STEP -WRAP? 1 GD9

\ ------------------------------------------------------------------------------
TESTING DO +LOOP with maximum and minimum increments

: (-MI) MAX-INT DUP NEGATE + 0= IF MAX-INT NEGATE ELSE -32767 THEN ;
(-MI) CONSTANT -MAX-INT

T{ 0 1 0 MAX-INT GD8  -> 1 }T
T{ 0 -MAX-INT NEGATE -MAX-INT OVER GD8  -> 2 }T

T{ 0 MAX-INT  0 MAX-INT GD8  -> 1 }T
T{ 0 MAX-INT  1 MAX-INT GD8  -> 1 }T
T{ 0 MAX-INT -1 MAX-INT GD8  -> 2 }T
T{ 0 MAX-INT DUP 1- MAX-INT GD8  -> 1 }T

T{ 0 MIN-INT 1+   0 MIN-INT GD8  -> 1 }T
T{ 0 MIN-INT 1+  -1 MIN-INT GD8  -> 1 }T
T{ 0 MIN-INT 1+   1 MIN-INT GD8  -> 2 }T
T{ 0 MIN-INT 1+ DUP MIN-INT GD8  -> 1 }T

\ ------------------------------------------------------------------------------
TESTING multiple RECURSEs in one colon definition

: ACK ( m n -- u )    \ Ackermann function, from Rosetta Code
   OVER 0= IF  NIP 1+ EXIT  THEN       \ ack(0, n) = n+1
   SWAP 1- SWAP                        ( -- m-1 n )
   DUP  0= IF  1+  RECURSE EXIT  THEN  \ ack(m, 0) = ack(m-1, 1)
   1- OVER 1+ SWAP RECURSE RECURSE     \ ack(m, n) = ack(m-1, ack(m,n-1))
;

T{ 0 0 ACK ->  1 }T
T{ 3 0 ACK ->  5 }T
T{ 2 4 ACK -> 11 }T

\ ------------------------------------------------------------------------------
TESTING multiple ELSE's in an IF statement
\ Discussed on comp.lang.forth and accepted as valid ANS Forth

: MELSE IF 1 ELSE 2 ELSE 3 ELSE 4 ELSE 5 THEN ;
T{ 0 MELSE -> 2 4 }T
T{ -1 MELSE -> 1 3 5 }T

\ ------------------------------------------------------------------------------
TESTING manipulation of >IN in interpreter mode

.( Start ) cr
T{ 12345 DEPTH OVER 9 < 34 AND + 3 + >IN ! -> 12345 2345 345 45 5 }T
T{ 14145 8115 ?DUP 0= 34 AND >IN +! TUCK MOD 14 >IN ! GCD CALCULATION -> 15 }T

\ ------------------------------------------------------------------------------
TESTING IMMEDIATE with CONSTANT  VARIABLE and CREATE [ ... DOES> ]

T{ 123 CONSTANT IW1 IMMEDIATE IW1 -> 123 }T
T{ : IW2 IW1 LITERAL ; IW2 -> 123 }T
T{ VARIABLE IW3 IMMEDIATE 234 IW3 ! IW3 @ -> 234 }T
T{ : IW4 IW3 [ @ ] LITERAL ; IW4 -> 234 }T
T{ :NONAME [ 345 ] IW3 [ ! ] ; DROP IW3 @ -> 345 }T
T{ CREATE IW5 456 , IMMEDIATE -> }T
T{ :NONAME IW5 [ @ IW3 ! ] ; DROP IW3 @ -> 456 }T
T{ : IW6 CREATE , IMMEDIATE DOES> @ 1+ ; -> }T
T{ 111 IW6 IW7 IW7 -> 112 }T
T{ : IW8 IW7 LITERAL 1+ ; IW8 -> 113 }T
T{ : IW9 CREATE , DOES> @ 2 + IMMEDIATE ; -> }T
: FIND-IW BL WORD FIND NIP ;  ( -- 0 | 1 | -1 )
T{ 222 IW9 IW10 FIND-IW IW10 -> -1 }T   \ IW10 is not immediate
T{ IW10 FIND-IW IW10 -> 224 1 }T        \ IW10 becomes immediate

\ ------------------------------------------------------------------------------
TESTING that IMMEDIATE doesn't toggle a flag

VARIABLE IT1 0 IT1 !
: IT2 1234 IT1 ! ; IMMEDIATE IMMEDIATE
T{ : IT3 IT2 ; IT1 @ -> 1234 }T

\ ------------------------------------------------------------------------------
TESTING parsing behaviour of S" ." and (
\ which should parse to just beyond the terminating character no space needed

T{ : GC5 S" A string"2DROP ; GC5 -> }T
T{ ( A comment)1234 -> 1234 }T
T{ : PB1 CR ." You should see 2345: "." 2345"( A comment) CR ; PB1 -> }T
 
\ ------------------------------------------------------------------------------
TESTING number prefixes # $ % and 'c' character input
\ Adapted from the Forth 200X Draft 14.5 document

VARIABLE OLD-BASE
DECIMAL BASE @ OLD-BASE !
T{ #1289 -> 1289 }T
T{ #12346789. -> 12346789. }T
T{ #-1289 -> -1289 }T
T{ #-12346789. -> -12346789. }T
T{ $12eF -> 4847 }T
T{ $12aBcDeF. -> 313249263. }T
T{ $-12eF -> -4847 }T
T{ $-12AbCdEf. -> -313249263. }T
T{ %10010110 -> 150 }T
T{ %10010110. -> 150. }T
T{ %-10010110 -> -150 }T
T{ %-10010110. -> -150. }T
T{ 'z' -> 122 }T
\ Check BASE is unchanged
T{ BASE @ OLD-BASE @ = -> TRUE }T

\ Repeat in Hex mode
16 OLD-BASE ! 16 BASE !
T{ #1289 -> 509 }T                  \ 2
T{ #12346789. -> BC65A5. }T         \ 2
T{ #-1289 -> -509 }T                \ 2
T{ #-12346789. -> -BC65A5. }T       \ 2
T{ $12eF -> 12EF }T                 \ 2
T{ $12aBcDeF. -> 12AbCdeF. }T       \ 2
T{ $-12eF -> -12EF }T               \ 2
T{ $-12AbCdEf. -> -12ABCDef. }T     \ 2
T{ %10010110 -> 96 }T               \ 2
T{ %10010110. -> 96. }T             \ 2
T{ %-10010110 -> -96 }T             \ 2
T{ %-10010110. -> -96. }T           \ 2
T{ 'z' -> 7a }T                     \ 2
\ Check BASE is unchanged
T{ BASE @ OLD-BASE @ = -> TRUE }T   \ 2

DECIMAL
\ Check number prefixes in compile mode
T{ : nmp  #8327. $-2cbe %011010111 ''' ; nmp -> 8327. -11454 215 39 }T


\ ------------------------------------------------------------------------------

CR .( End of additional Core tests) CR
