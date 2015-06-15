\ To test the ANS File Access word set and extension words

\ This program was written by Gerry Jackson in 2006, with contributions from
\ others where indicated, and is in the public domain - it can be distributed
\ and/or modified in any way but please retain this notice.

\ This program is distributed in the hope that it will be useful,
\ but WITHOUT ANY WARRANTY; without even the implied warranty of
\ MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

\ The tests are not claimed to be comprehensive or correct 

\ ------------------------------------------------------------------------------
\ Version 0.11 25 April 2015 S\" in interpretation mode test added
\              REQUIRED REQUIRE INCLUDE tests added
\              Two S" and/or S\" buffers availability tested
\         0.5  1 April 2012  Tests placed in the public domain.
\         0.4  22 March 2009 { and } replaced with T{ and }T
\         0.3  20 April 2007  ANS Forth words changed to upper case.
\              Removed directory test from the filenames.
\         0.2  30 Oct 2006 updated following GForth tests to remove
\              system dependency on file size, to allow for file
\              buffering and to allow for PAD moving around.
\         0.1  Oct 2006 First version released.

\ ------------------------------------------------------------------------------
\ The tests are based on John Hayes test program for the core word set
\ and requires those files to have been loaded

\ Words tested in this file are:
\     ( BIN CLOSE-FILE CREATE-FILE DELETE-FILE FILE-POSITION FILE-SIZE
\     OPEN-FILE R/O R/W READ-FILE READ-LINE REPOSITION-FILE RESIZE-FILE 
\     S" SOURCE-ID W/O WRITE-FILE WRITE-LINE 
\     FILE-STATUS FLUSH-FILE RENAME-FILE 

\ Words not tested:
\     REFILL INCLUDED INCLUDE-FILE (as these will likely have been
\     tested in the execution of the test files)
\ ------------------------------------------------------------------------------
\ Assumptions, dependencies and notes:
\     - tester.fr or ttester.fs has been loaded prior to this file
\     - These tests create files in the current directory, if all goes
\       well these will be deleted. If something fails they may not be
\       deleted. If this is a problem ensure you set a suitable 
\       directory before running this test. There is no ANS standard
\       way of doing this. Also be aware of the file names used below
\       which are:  fatest1.txt, fatest2.txt and fatest3.txt
\     - TRUE and FALSE are present from the Core extension word set 
\ ------------------------------------------------------------------------------

TESTING File Access word set

DECIMAL

\ ------------------------------------------------------------------------------
TESTING CREATE-FILE CLOSE-FILE

: FN1 S" fatest1.txt" ;
VARIABLE FID1

T{ FN1 R/W CREATE-FILE SWAP FID1 ! -> 0 }T
T{ FID1 @ CLOSE-FILE -> 0 }T

\ ------------------------------------------------------------------------------
TESTING OPEN-FILE W/O WRITE-LINE

: LINE1 S" Line 1" ;

T{ FN1 W/O OPEN-FILE SWAP FID1 ! -> 0 }T
T{ LINE1 FID1 @ WRITE-LINE -> 0 }T
T{ FID1 @ CLOSE-FILE -> 0 }T

\ ------------------------------------------------------------------------------
TESTING R/O FILE-POSITION (simple)  READ-LINE 

200 CONSTANT BSIZE
CREATE BUF BSIZE ALLOT
VARIABLE #CHARS

T{ FN1 R/O OPEN-FILE SWAP FID1 ! -> 0 }T
T{ FID1 @ FILE-POSITION -> 0. 0 }T
T{ BUF 100 FID1 @ READ-LINE ROT DUP #CHARS ! -> TRUE 0 LINE1 SWAP DROP }T
T{ BUF #CHARS @ LINE1 COMPARE -> 0 }T
T{ FID1 @ CLOSE-FILE -> 0 }T

\ ------------------------------------------------------------------------------
TESTING R/W WRITE-FILE REPOSITION-FILE READ-FILE FILE-POSITION S"

: LINE2 S" Line 2 blah blah blah" ;
: RL1 BUF 100 FID1 @ READ-LINE ;
2VARIABLE FP

T{ FN1 R/W OPEN-FILE SWAP FID1 ! -> 0 }T
T{ FID1 @ FILE-SIZE DROP FID1 @ REPOSITION-FILE -> 0 }T
T{ FID1 @ FILE-SIZE -> FID1 @ FILE-POSITION }T
T{ LINE2 FID1 @ WRITE-FILE -> 0 }T
T{ 10. FID1 @ REPOSITION-FILE -> 0 }T
T{ FID1 @ FILE-POSITION -> 10. 0 }T
T{ 0. FID1 @ REPOSITION-FILE -> 0 }T
T{ RL1 -> LINE1 SWAP DROP TRUE 0 }T
T{ RL1 ROT DUP #CHARS ! -> TRUE 0 LINE2 SWAP DROP }T
T{ BUF #CHARS @ LINE2 COMPARE -> 0 }T
T{ RL1 -> 0 FALSE 0 }T
T{ FID1 @ FILE-POSITION ROT ROT FP 2! -> 0 }T
T{ FP 2@ FID1 @ FILE-SIZE DROP D= -> TRUE }T
T{ S" " FID1 @ WRITE-LINE -> 0 }T
T{ S" " FID1 @ WRITE-LINE -> 0 }T
T{ FP 2@ FID1 @ REPOSITION-FILE -> 0 }T
T{ RL1 -> 0 TRUE 0 }T
T{ RL1 -> 0 TRUE 0 }T
T{ RL1 -> 0 FALSE 0 }T
T{ FID1 @ CLOSE-FILE -> 0 }T

\ ------------------------------------------------------------------------------
TESTING BIN READ-FILE FILE-SIZE

: CBUF BUF BSIZE 0 FILL ;
: FN2 S" FATEST2.TXT" ;
VARIABLE FID2
: SETPAD PAD 50 0 DO I OVER C! CHAR+ LOOP DROP ;

SETPAD   \ If anything else is defined setpad must be called again
         \ as pad may move

T{ FN2 R/W BIN CREATE-FILE SWAP FID2 ! -> 0 }T
T{ PAD 50 FID2 @ WRITE-FILE FID2 @ FLUSH-FILE -> 0 0 }T
T{ FID2 @ FILE-SIZE -> 50. 0 }T
T{ 0. FID2 @ REPOSITION-FILE -> 0 }T
T{ CBUF BUF 29 FID2 @ READ-FILE -> 29 0 }T
T{ PAD 29 BUF 29 COMPARE -> 0 }T
T{ PAD 30 BUF 30 COMPARE -> 1 }T
T{ CBUF BUF 29 FID2 @ READ-FILE -> 21 0 }T
T{ PAD 29 + 21 BUF 21 COMPARE -> 0 }T
T{ FID2 @ FILE-SIZE DROP FID2 @ FILE-POSITION DROP D= -> TRUE }T
T{ BUF 10 FID2 @ READ-FILE -> 0 0 }T
T{ FID2 @ CLOSE-FILE -> 0 }T

\ ------------------------------------------------------------------------------
TESTING RESIZE-FILE

T{ FN2 R/W BIN OPEN-FILE SWAP FID2 ! -> 0 }T
T{ 37. FID2 @ RESIZE-FILE -> 0 }T
T{ FID2 @ FILE-SIZE -> 37. 0 }T
T{ 0. FID2 @ REPOSITION-FILE -> 0 }T
T{ CBUF BUF 100 FID2 @ READ-FILE -> 37 0 }T
T{ PAD 37 BUF 37 COMPARE -> 0 }T
T{ PAD 38 BUF 38 COMPARE -> 1 }T
T{ 500. FID2 @ RESIZE-FILE -> 0 }T
T{ FID2 @ FILE-SIZE -> 500. 0 }T
T{ 0. FID2 @ REPOSITION-FILE -> 0 }T
T{ CBUF BUF 100 FID2 @ READ-FILE -> 100 0 }T
T{ PAD 37 BUF 37 COMPARE -> 0 }T
T{ FID2 @ CLOSE-FILE -> 0 }T

\ ------------------------------------------------------------------------------
TESTING DELETE-FILE

T{ FN2 DELETE-FILE -> 0 }T
T{ FN2 R/W BIN OPEN-FILE SWAP DROP 0= -> FALSE }T
T{ FN2 DELETE-FILE 0= -> FALSE }T

\ ------------------------------------------------------------------------------
TESTING multi-line ( comments

T{ ( 1 2 3
4 5 6
7 8 9 ) 11 22 33 -> 11 22 33 }T

\ ------------------------------------------------------------------------------
TESTING SOURCE-ID (can only test it does not return 0 or -1)

T{ SOURCE-ID DUP -1 = SWAP 0= OR -> FALSE }T

\ ------------------------------------------------------------------------------
TESTING RENAME-FILE FILE-STATUS FLUSH-FILE

: FN3 S" fatest3.txt" ;
: >END FID1 @ FILE-SIZE DROP FID1 @ REPOSITION-FILE ;


T{ FN3 DELETE-FILE DROP -> }T
T{ FN1 FN3 RENAME-FILE 0= -> TRUE }T
T{ FN1 FILE-STATUS SWAP DROP 0= -> FALSE }T
T{ FN3 FILE-STATUS SWAP DROP 0= -> TRUE }T  \ Return value is undefined
T{ FN3 R/W OPEN-FILE SWAP FID1 ! -> 0 }T
T{ >END -> 0 }T
T{ S" Final line" fid1 @ WRITE-LINE -> 0 }T
T{ FID1 @ FLUSH-FILE -> 0 }T		\ Can only test FLUSH-FILE doesn't fail
T{ FID1 @ CLOSE-FILE -> 0 }T

\ Tidy the test folder
T{ fn3 DELETE-FILE DROP -> }T

\ ------------------------------------------------------------------------------
TESTING REQUIRED REQUIRE INCLUDED
\ Tests taken from Forth 2012 RfD

T{ 0
  S" required-helper1.fth" REQUIRED
  REQUIRE required-helper1.fth
  INCLUDE required-helper1.fth
  -> 2 }T

T{ 0
  INCLUDE required-helper2.fth
  S" required-helper2.fth" REQUIRED
  REQUIRE required-helper2.fth
  S" required-helper2.fth" INCLUDED
  -> 2 }T
  
\ ------------------------------------------------------------------------------
TESTING S\" (Forth 2012 interpretation mode)

\ S\" in compilation mode already tested in Core Extension tests
T{ : SSQ10 S\" \a\b\e\f\l\m\q\r\t\v\x0F0\x1Fa\xaBx\z\"\\" ; -> }T
T{ S\" \a\b\e\f\l\m\q\r\t\v\x0F0\x1Fa\xaBx\z\"\\" SSQ10  COMPARE -> 0 }T

\ ------------------------------------------------------------------------------
TESTING two buffers available for S" and/or S\"

: SSQ11 S" abcd" ;   : SSQ12 S" 1234" ;
T{ S" abcd"  S" 1234" SSQ12  COMPARE ROT ROT SSQ11 COMPARE -> 0 0 }T
T{ S\" abcd" S\" 1234" SSQ12 COMPARE ROT ROT SSQ11 COMPARE -> 0 0 }T
T{ S" abcd"  S\" 1234" SSQ12 COMPARE ROT ROT SSQ11 COMPARE -> 0 0 }T
T{ S\" abcd" S" 1234" SSQ12  COMPARE ROT ROT SSQ11 COMPARE -> 0 0 }T


\ ------------------------------------------------------------------------------

FILE-ERRORS SET-ERROR-COUNT

CR .( End of File-Access word set tests) CR
