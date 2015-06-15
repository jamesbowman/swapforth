\ To test some of the ANS Forth Programming Tools and extension wordset

\ This program was written by Gerry Jackson in 2006, with contributions from
\ others where indicated, and is in the public domain - it can be distributed
\ and/or modified in any way but please retain this notice.

\ This program is distributed in the hope that it will be useful,
\ but WITHOUT ANY WARRANTY; without even the implied warranty of
\ MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

\ The tests are not claimed to be comprehensive or correct 

\ ------------------------------------------------------------------------------
\ Version 0.11 25 April Added tests for N>R NR> SYNONYM TRAVERSE-WORDLIST
\              NAME>COMPILE NAME>INTERPRET NAME>STRING
\         0.6  1 April 2012 Tests placed in the public domain.
\              Further tests on [IF] [ELSE] [THEN]
\         0.5  30 November 2009 <true> and <false> replaced with TRUE and FALSE
\         0.4  6 March 2009 ENDIF changed to THEN. {...} changed to T{...}T
\         0.3  20 April 2007 ANS Forth words changed to upper case
\         0.2  30 Oct 2006 updated following GForth test to avoid
\              changing stack depth during a colon definition
\         0.1  Oct 2006 First version released

\ ------------------------------------------------------------------------------
\ The tests are based on John Hayes test program

\ Words tested in this file are:
\     AHEAD [IF] [ELSE] [THEN] CS-PICK CS-ROLL [DEFINED] [UNDEFINED]
\     N>R NR> SYNONYM TRAVERSE-WORDLIST NAME>COMPILE NAME>INTERPRET
\     NAME>STRING
\     

\ Words not tested:
\     .S ? DUMP SEE WORDS
\     ;CODE ASSEMBLER BYE CODE EDITOR FORGET STATE 
\ ------------------------------------------------------------------------------
\ Assumptions and dependencies:
\     - tester.fr or ttester.fs has been loaded prior to this file
\     - testing TRAVERSE-WORDLIST uses WORDLIST SEARCH-WORDLIST GET-CURRENT
\       SET-CURRENT and FORTH-WORDLIST from the Search-order word set
\ ------------------------------------------------------------------------------

DECIMAL

\ ------------------------------------------------------------------------------
TESTING AHEAD

T{ : PT1 AHEAD 1111 2222 THEN 3333 ; -> }T
T{ PT1 -> 3333 }T

\ ------------------------------------------------------------------------------
TESTING [IF] [ELSE] [THEN]

T{ TRUE  [IF] 111 [ELSE] 222 [THEN] -> 111 }T
T{ FALSE [IF] 111 [ELSE] 222 [THEN] -> 222 }T

T{ TRUE  [IF] 1     \ Code spread over more than 1 line
             2
          [ELSE]
             3
             4
          [THEN] -> 1 2 }T
T{ FALSE [IF]
             1 2
          [ELSE]
             3 4
          [THEN] -> 3 4 }T

T{ TRUE  [IF] 1 TRUE  [IF] 2 [ELSE] 3 [THEN] [ELSE] 4 [THEN] -> 1 2 }T
T{ FALSE [IF] 1 TRUE  [IF] 2 [ELSE] 3 [THEN] [ELSE] 4 [THEN] -> 4 }T
T{ TRUE  [IF] 1 FALSE [IF] 2 [ELSE] 3 [THEN] [ELSE] 4 [THEN] -> 1 3 }T
T{ FALSE [IF] 1 FALSE [IF] 2 [ELSE] 3 [THEN] [ELSE] 4 [THEN] -> 4 }T

\ ------------------------------------------------------------------------------
TESTING immediacy of [IF] [ELSE] [THEN]

T{ : PT2 [  0 ] [IF] 1111 [ELSE] 2222 [THEN]  ; PT2 -> 2222 }T
T{ : PT3 [ -1 ] [IF] 3333 [ELSE] 4444 [THEN]  ; PT3 -> 3333 }T
: PT9 BL WORD FIND ;
T{ PT9 [IF]   NIP -> 1 }T
T{ PT9 [ELSE] NIP -> 1 }T
T{ PT9 [THEN] NIP -> 1 }T

\ -----------------------------------------------------------------------------
TESTING [IF] and [ELSE] carry out a text scan by parsing and discarding words
\ so that an [ELSE] or [THEN] in a comment or string is recognised

: PT10 REFILL DROP REFILL DROP ;

T{ 0  [IF]            \ WORDS IGNORED UP TO [ELSE] 2
      [THEN] -> 2 }T
T{ -1 [IF] 2 [ELSE] 3 S" [THEN] 4 PT10 IGNORED TO END OF LINE"
      [THEN]          \ PRECAUTION IN CASE [THEN] IN STRING ISN'T RECOGNISED
   -> 2 4 }T

\ ------------------------------------------------------------------------------
TESTING CS-PICK and CS-ROLL

\ Test pt5 based on example in ANS document p 176.

: ?REPEAT
   0 CS-PICK POSTPONE UNTIL
; IMMEDIATE

VARIABLE PT4

T{ : PT5  ( N1 -- )
      PT4 !
      BEGIN
         -1 PT4 +!
         PT4 @ 4 > 0= ?REPEAT \ BACK TO BEGIN IF FALSE
         111
         PT4 @ 3 > 0= ?REPEAT
         222
         PT4 @ 2 > 0= ?REPEAT
         333
         PT4 @ 1 =
      UNTIL
; -> }T

T{ 6 PT5 -> 111 111 222 111 222 333 111 222 333 }T


T{ : ?DONE POSTPONE IF 1 CS-ROLL ; IMMEDIATE -> }T  \ Same as WHILE
T{ : PT6
      >R
      BEGIN
         R@
      ?DONE
         R@
         R> 1- >R
      REPEAT
      R> DROP
   ; -> }T

T{ 5 PT6 -> 5 4 3 2 1 }T

: MIX_UP 2 CS-ROLL ; IMMEDIATE  \ CS-ROT

: PT7    ( f3 f2 f1 -- ? )
   IF 1111 ROT ROT         ( -- 1111 f3 f2 )     ( cs: -- orig1 )
      IF 2222 SWAP         ( -- 1111 2222 f3 )   ( cs: -- orig1 orig2 )
         IF                                      ( cs: -- orig1 orig2 orig3 )
            3333 MIX_UP    ( -- 1111 2222 3333 ) ( cs: -- orig2 orig3 orig1 )
         THEN                                    ( cs: -- orig2 orig3 )
         4444        \ Hence failure of first IF comes here and falls through
      THEN                                      ( cs: -- orig2 )
      5555           \ Failure of 3rd IF comes here
   THEN                                         ( cs: -- )
   6666              \ Failure of 2nd IF comes here
;

T{ -1 -1 -1 PT7 -> 1111 2222 3333 4444 5555 6666 }T
T{  0 -1 -1 PT7 -> 1111 2222 5555 6666 }T
T{  0  0 -1 PT7 -> 1111 0    6666 }T
T{  0  0  0 PT7 -> 0    0    4444 5555 6666 }T

: [1CS-ROLL] 1 CS-ROLL ; IMMEDIATE

T{ : PT8
      >R
      AHEAD 111
      BEGIN 222 
         [1CS-ROLL]
         THEN
         333
         R> 1- >R
         R@ 0<
      UNTIL
      R> DROP
   ; -> }T

T{ 1 PT8 -> 333 222 333 }T

\ ------------------------------------------------------------------------------
TESTING [DEFINED] [UNDEFINED]

CREATE DEF1

T{ [DEFINED]   DEF1 -> TRUE  }T
T{ [UNDEFINED] DEF1 -> FALSE }T
T{ [DEFINED]   12345678901234567890 -> FALSE }T
T{ [UNDEFINED] 12345678901234567890 -> TRUE  }T
T{ : DEF2 [DEFINED]   DEF1 [IF] 1 [ELSE] 2 [THEN] ; -> }T
T{ : DEF3 [UNDEFINED] DEF1 [IF] 3 [ELSE] 4 [THEN] ; -> }T
T{ DEF2 -> 1 }T
T{ DEF3 -> 4 }T

0 [IF] \ {  xxx not yet in swapforth
\ ------------------------------------------------------------------------------
TESTING N>R NR>

T{ : NTR  N>R -1 NR> ; -> }T
T{ 1 2 3 4 5 6 7 4 NTR -> 1 2 3 -1 4 5 6 7 4 }T
T{ 1 0 NTR -> 1 -1 0 }T
T{ : NTR2 N>R N>R -1 NR> -2 NR> ;
T{ 1 2 2 3 4 5 3 NTR2 -> -1 1 2 2 -2 3 4 5 3 }T
T{ 1 0 0 NTR2 -> 1 -1 0 -2 0 }T

\ ------------------------------------------------------------------------------
TESTING SYNONYM

: SYN1 1234 ;
T{ SYNONYM NEW-SYN1 SYN1 -> }T
T{ NEW-SYN1 -> 1234 }T
: SYN2 2345 ; IMMEDIATE
T{ SYNONYM NEW-SYN2 SYN2 -> }T
T{ NEW-SYN2 -> 2345 }T
T{ : SYN3 SYN2 LITERAL ; SYN3 -> 2345 }T

\ ------------------------------------------------------------------------------
TESTING TRAVERSE-WORDLIST NAME>COMPILE NAME>INTERPRET NAME>STRING

GET-CURRENT CONSTANT CURR-WL
WORDLIST CONSTANT TRAV-WL
: WDCT ( n nt -- n+1 f ) DROP 1+ TRUE ;
T{ 0 ' WDCT TRAV-WL TRAVERSE-WORDLIST -> 0 }T

TRAV-WL SET-CURRENT
: TRAV1 1 ;
T{ 0 ' WDCT TRAV-WL TRAVERSE-WORDLIST -> 1 }T
: TRAV2 2 ; : TRAV3 3 ; : TRAV4 4 ; : TRAV5 5 ; : TRAV6 6 ; IMMEDIATE
CURR-WL SET-CURRENT
T{ 0 ' WDCT TRAV-WL TRAVERSE-WORDLIST -> 6 }T  \ Traverse whole wordlist

\ Terminate TRAVERSE-WORDLIST after n words & check it compiles
: (PART-OF-WL)  ( ct n nt -- ct+1 n-1 )  DROP DUP IF SWAP 1+ SWAP 1- THEN DUP ;
: PART-OF-WL  ( n -- ct 0 | ct+1 n-1)
   0 SWAP ['] (PART-OF-WL) TRAV-WL TRAVERSE-WORDLIST DROP
;
T{ 0 PART-OF-WL -> 0 }T
T{ 1 PART-OF-WL -> 1 }T
T{ 4 PART-OF-WL -> 4 }T
T{ 9 PART-OF-WL -> 6 }T  \ Traverse whole wordlist

\ Testing NAME>.. words require a name token. It will be easier to test them
\ if there is a way of obtaining the name token of a given word. To get this we
\ need a definition to compare a given name with the result of NAME>STRING.
\ The output from NAME>STRING has to be copied into a buffer and converted to a
\ known case as a given Forth system may store names as lower, upper or mixed case.

CREATE UCBUF 32 CHARS ALLOT    \ The buffer

\ Convert string to upper case and save in the buffer.

: >UPPERCASE  ( caddr u  -- caddr2 u2 )
   32 MIN DUP >R UCBUF ROT ROT
   OVER + SWAP
   DO
      I C@ DUP [CHAR] a [CHAR] z 1+ WITHIN IF 32 INVERT AND THEN
      OVER C! CHAR+
   LOOP DROP
   UCBUF R>
;

\ Compare string (caddr u) with name associated with nt, f=0 if the same
: NAME?  ( caddr u nt -- caddr u f )   \ f = true for name = (caddr u) string
   NAME>STRING >UPPERCASE 2OVER COMPARE 0=
;

\ The word to be executed by TRAVERSE-WORDLIST
: GET-NT  ( caddr u 0 nt -- caddr u nt false | caddr u 0 nt ) \ nt <> 0
   2>R R@ NAME? IF R> R> ELSE 2R> THEN
;

\ Get name token of (caddr u) in wordlist wid, return 0 if not present
: GET-NAME-TOKEN  ( caddr u wid -- nt | 0 )
   0 ['] GET-NT ROT TRAVERSE-WORDLIST >R 2DROP R>
;

\ Test NAME>STRING via TRAVERSE-WORDLIST
T{ S" ABCDE" TRAV-WL GET-NAME-TOKEN 0= -> TRUE  }T \ Not in wordlist
T{ S" TRAV4" TRAV-WL GET-NAME-TOKEN 0= -> FALSE }T

\ Test NAME>INTERPRET on a word with interpretation semantics
T{ S" TRAV3" TRAV-WL GET-NAME-TOKEN NAME>INTERPRET EXECUTE -> 3 }T

\ Test NAME>INTERPRET on a word without interpretation semantics. It is
\ difficult to choose a suitable word because:
\    - a user cannot define one in a standard system
\    - a Forth system may choose to define interpretation semantics for a word
\      despite the standard stating they are undefined.
\ Standard words that are not likely to have interpretation semantics defined
\ could be: ; EXIT ['] [CHAR] RECURSE
\ ['] will be used since it has an equivalent in interpretation mode, if that
\ doesn't work in a given system choose another word for that system.
\ FORTH-WORDLIST is needed

T{ S" [']" FORTH-WORDLIST GET-NAME-TOKEN NAME>INTERPRET -> 0 }T

\ Test NAME>COMPILE
: N>C  ( caddr u -- )  TRAV-WL GET-NAME-TOKEN NAME>COMPILE EXECUTE ; IMMEDIATE
T{ : N>C1  ( -- n )  [ S" TRAV2" ] N>C ; N>C1 -> 2 }T          \ Not immediate
T{ : N>C2  ( -- n )  [ S" TRAV6" ] N>C LITERAL ; N>C2 -> 6 }T  \ Immediate word
T{ S" TRAV6" TRAV-WL GET-NAME-TOKEN NAME>COMPILE EXECUTE -> 6 }T

\ Test the order of finding words with the same name
TRAV-WL SET-CURRENT
: TRAV3 33 ; : TRAV3 333 ; : TRAV7 7 ; : TRAV3 3333 ;
CURR-WL SET-CURRENT

: GET-ALL  ( caddr u nt -- [n] caddr u true )
   DUP >R NAME? IF R@ NAME>INTERPRET EXECUTE ROT ROT THEN
   R> DROP TRUE
; 

: GET-ALL  ( caddr u -- i*x )
   ['] GET-ALL TRAV-WL TRAVERSE-WORDLIST 2DROP
;

T{ S" TRAV3" GET-ALL -> 3333 333 33 3 }T

\ ------------------------------------------------------------------------------
[THEN]  \ }

TOOLS-ERRORS SET-ERROR-COUNT

CR .( End of Programming Tools word tests) CR
