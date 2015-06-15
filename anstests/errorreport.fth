\ To collect and report on the number of errors resulting from running the 
\ ANS Forth and Forth 2012 test programs

\ This program was written by Gerry Jackson in 2015, and is in the public
\ domain - it can be distributed and/or modified in any way but please
\ retain this notice.

\ This program is distributed in the hope that it will be useful,
\ but WITHOUT ANY WARRANTY; without even the implied warranty of
\ MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

\ ------------------------------------------------------------------------------
\ This file is INCLUDED after Core tests are complete and only uses Core words
\ already tested. The purpose of this file is to count errors in test results
\ and present them as a summary at the end of the tests.

DECIMAL

VARIABLE CORE-ERRORS        VARIABLE CORE-EXT-ERRORS
VARIABLE DOUBLE-ERRORS      VARIABLE EXCEPTION-ERRORS
VARIABLE FACILITY-ERRORS    VARIABLE FILE-ERRORS
VARIABLE LOCALS-ERRORS      VARIABLE MEMORY-ERRORS
VARIABLE SEARCHORDER-ERRORS VARIABLE STRING-ERRORS
VARIABLE TOOLS-ERRORS       VARIABLE PREV-ERRORS

: INIT-ERRORS  ( -- )
   #ERRORS @
   DUP CORE-ERRORS ! PREV-ERRORS !    \ #ERRORS is in file tester.fr
   0 CORE-EXT-ERRORS !   0 DOUBLE-ERRORS !       0 EXCEPTION-ERRORS !
   0 FACILITY-ERRORS !   0 FILE-ERRORS !         0 LOCALS-ERRORS !
   0 MEMORY-ERRORS !     0 SEARCHORDER-ERRORS !  0 STRING-ERRORS !
   0 TOOLS-ERRORS !
;

INIT-ERRORS

\ SET-ERROR-COUNT called at the end of each test file with address of its
\ own error variable
: SET-ERROR-COUNT  ( ad -- )
   #ERRORS @ PREV-ERRORS @ - SWAP !
   #ERRORS @ PREV-ERRORS !
;

\ Report summary of errors

25 CONSTANT MARGIN

: SHOW-ERROR-COUNT  ( ad caddr u -- )
   CR SWAP OVER TYPE MARGIN - ABS
   >R @ ?DUP IF R> .R ELSE R> 1- SPACES [CHAR] - EMIT THEN
;

: HLINE  ( -- )  CR ." ---------------------------"  ;

: REPORT-ERRORS
   HLINE
   CR 8 SPACES ." Error Report"
   CR ." Word Set" 13 SPACES ." Errors"
   HLINE
   CORE-ERRORS S" Core" SHOW-ERROR-COUNT
   CORE-EXT-ERRORS S" Core extension" SHOW-ERROR-COUNT
   DOUBLE-ERRORS S" Double number" SHOW-ERROR-COUNT
   EXCEPTION-ERRORS S" Exception" SHOW-ERROR-COUNT
   FACILITY-ERRORS S" Facility" SHOW-ERROR-COUNT
   FILE-ERRORS S" File-access" SHOW-ERROR-COUNT
   LOCALS-ERRORS S" Locals"    SHOW-ERROR-COUNT
   MEMORY-ERRORS S" Memory-allocation" SHOW-ERROR-COUNT
   TOOLS-ERRORS S" Programming-tools" SHOW-ERROR-COUNT
   SEARCHORDER-ERRORS S" Search-order" SHOW-ERROR-COUNT
   STRING-ERRORS S" String" SHOW-ERROR-COUNT
   HLINE
   #ERRORS S" Total" SHOW-ERROR-COUNT
   HLINE CR CR
;