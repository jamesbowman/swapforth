\ These definitions for Forth2012 taken from the standard
\ http://www.forth200x.org/documents/html/core.html

: HOLDS ( addr u -- ) 
   BEGIN DUP WHILE 1- 2DUP + C@ HOLD REPEAT 2DROP
;

: BUFFER: ( u "<name>" -- ; -- addr ) 
   CREATE ALLOT
;
