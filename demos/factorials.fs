\ Large factorials
\
\ Original Jupiter Ace version by J Yale.
\ "Practical Computing" September 1982, page 151.
\
\ http://www.jupiter-ace.co.uk/Forth_general_PC8209p151.html
\
\ Slightly modified for ANS Forth compliance, James Bowman
\
\ This is an ANS Forth program:
\   Requiring the Core Extensions word set
\

\ :  BYTE-ARRAY
\    CREATE ALLOT
\    DOES> +
\ ;

1000 CONSTANT MAX-DIGITS

\ MAX-DIGITS BYTE-ARRAY F-BUFF
: F-BUFF pad + ;

VARIABLE LAST 0 LAST ! ( Last buff element )

: *BUFF ( Multiplier )
 0                  ( Carry )
 LAST @ 1+ 0
 DO
  OVER I F-BUFF C@
  * + 10 /MOD
  SWAP I F-BUFF C!
 LOOP
 BEGIN ( Extend buffer to accept final carry )
  ?DUP
 WHILE
  10 /MOD SWAP
  1 LAST +!
  LAST @ DUP 1+
  MAX-DIGITS >
   IF
    ." Out of buffer" abort
   THEN
  F-BUFF C!
 REPEAT
 DROP ;

: SETUP
 1 0 F-BUFF C! ( Start buff=1 )
 0 LAST ! ;

: .FAC
 LAST @ 1+ 0
 DO
  LAST @ I -
  DUP 1+ 3 MOD
  0= I 0= 0= AND
  IF
   [CHAR] , EMIT
  THEN
  F-BUFF C@ [CHAR] 0 + EMIT
 LOOP ;

: FAC
 SETUP 1+ 1
 DO
  I *BUFF
 LOOP ;

: FACS
 SETUP 1+ 1
 DO
  I *BUFF ." Factorial"
  I 3 U.R
  ."  = " .FAC CR
 LOOP ;

.( "20 FACS" gives:) cr
\ 20 FACS

.( and "100 FAC .FAC" gives:) cr
\ 100 FAC .FAC
