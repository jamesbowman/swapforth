\ Comus explains some common Forth words that aren't in the ANS Forth Standard. The name Comus was suggested by Neil Bawd.
\ 
\ http://www.murphywong.net/hello/comus.htm

: noop      ;
: off       false swap ! ;
: on        true swap ! ;

\ #######   RANDOM   ##########################################

\ setseed   sets the random number seed
\ random    returns a random 32-bit number
\
\ based on "Xorshift RNGs" by George Marsaglia
\ http://www.jstatsoft.org/v08/i14/paper

variable seed
$7a92764b seed !

: setseed   ( u -- )
    dup 0= or       \ map 0 to -1
    seed !
;

: random    ( -- u )
    seed @
    dup 13 lshift xor
    dup 17 rshift xor
    dup 5  lshift xor
    dup seed !
;

: randrange  ( u0 -- u1 ) \ u1 is a random number less than u0
    random um* nip
;
