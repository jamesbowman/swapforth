( Floating-Point                             JCB 22:38 03/22/15)

\ The following words are already defined:
\
\ fdup
\ fdrop
\ fswap
\ f0<
\ fabs
\ f<
\ fliteral
\ f+
\ f-
\ f*
\ f/
\ f>  move from float-stack to the data-stack
\ >f  move from data-stack to the float-stack

: fconstant  : postpone fliteral postpone ; ;

: fover     f> f> tuck >f >f >f ;
: f0=       f> 0= ;
: f=        f- f0= ;
: f!        f> swap ! ;
: f@        @ >f ;
: frot      f> f> f> -rot >f >f >f ;
: falign    align ;
: faligned  aligned ;
: float+    cell+ ;
: floats    cells ;
: fvariable variable ;
: fmax      fover fover f< if fswap then fdrop ;
: fmin      fover fover f< invert if fswap then fdrop ;

: f>s
    f>d d>s
;

: d>f
    dup 0< if
        dnegate recurse fnegate
    else
        us>f [ 65536 s>f fdup f* ] fliteral f*
        us>f f+
    then
;

marker testing-float1
    $feed55000000. 2constant big1

    T{ 79218.   d>f f>d -> 79218.   }T
    T{ 0 79218  d>f f>d -> 0 79218  }T
    T{ -1.      d>f f>d -> -1.      }T
    T{ big1     d>f f>d -> big1     }T

testing-float1

LOCALWORDS      \ {

1 s>f               fconstant FLT_1
0 s>f               fconstant FLT_0
10 s>f              fconstant FLT_10
FLT_1 FLT_10 f/     fconstant FLT_.1

: exponent
    23 rshift $ff and
;

: isat ( caddr u c -- caddr u 0 | caddr' u' 1 )
    over 0= if
        drop dup    ( caddr 0 0 )
    else
        >r
        over c@ r> = negate
        dup >r
        /string
        r>
    then
;

: >+-number ( ud1 c-addr1 u1 -- ud2 c-addr2 u2 ) \ signed version of >number
    [char] - isat if
        >number
        2swap dnegate 2swap
    else
        [char] + isat drop
        >number
    then
;

: tuck0. ( caddr u - 0. caddr u ) \ tuck0. 0. under the string, prepare for >number
    0. 2swap
;

: pow10 ( n -- 10**n)
    dup 0< if
        FLT_1
        negate recurse 
        f/
    else
        FLT_1
        0 ?do
            FLT_10 f*
        loop
    then
;

: isdigit
    [char] 0 [char] 9 1+ within
;

\ consume the decimal digits, accumulating a floating fraction
: >frac ( c-addr u -- c-addr' u' ) ( F: 0 -- r )
    FLT_.1 fswap
    begin
        over c@ isdigit
        over 0<> and
    while
        over c@ [char] 0 - 
        fover s>f f* f+
        fswap FLT_.1 f* fswap
        1 /string
    repeat
    fswap fdrop
;

: notafloat
    fdrop 2drop 2drop 2drop false
;

: finput ( c-addr u -- true | false ) ( F: -- r |  )
    [char] - isat >r
    [char] + isat drop

    tuck0.
    >number           ( int. caddr u )

    FLT_0
    [char] . isat if
        >frac
    then                ( int. caddr u ) ( F: frac )

    tuck0.              ( int. exp. caddr u ) ( F: frac )
    [char] e isat >r
    [char] E isat r> or if
        >+-number
        0= if
            drop
            d>s >r      \ save exponent
            d>f f+      \ sum int. and fraction
            r> pow10 f* \ exponentiate
            r@ if       \ apply sign
                fnegate
            then
            true
        else
            notafloat
        then
    else
        notafloat
    then
    r> drop \ sign
;

:noname
    >inwas @ >in !
    parse-name
    finput if
        state @ if
            postpone fliteral
        then
    else
        -13 throw
    then
; is hook-number

PUBLICWORDS     \ }{

: floor
    f>
    $007fffff over exponent \ 127=no shift, 128==shift 1, etc
    127 - dup 0< if
        drop 2drop 0
    else
        23 min
        rshift invert and
    then
    >f
;

\ This is rubbish. Should use:
\ "How to Print Floating-Point Numbers Accurately" Steele & White
\ https://lists.nongnu.org/archive/html/gcl-devel/2012-10/pdfkieTlklRzN.pdf
\ http://hub.darcs.net/pointfree/cranberry-net/browse/code/wetland-mcu-nodes/blocks/float.frt

: f.
    fdup f0< if
        fnegate [char] - emit
    then
    fdup f>d 0 d.r
    [char] . emit
    fdup floor f- 10000000e0 f* f>d
    <# # # # # # # # #> type
    space
;

: .f
    fdepth >r
    [char] < emit
    r@ 0 .r
    [char] > emit
    space
    r@ 0 ?do
        f>
    loop
    r> 0 ?do
        >f fdup f.
    loop
;

: frac ( F: r0 -- r1 )
    fdup floor f-
;

: fmod ( F: r0 r1 -- r2 )
    fswap fover     ( r1 r0 r1 )
    f/ frac f*
;

: fround
    fdup f0< if
        fnegate recurse fnegate
    else
        fdup floor fswap frac       ( F: integer-part fraction-part )
        fdup 0.5e f= if
            fdrop                   \ round to nearest even
            0.5e f* 0.5e f+ floor 2.0e f*
        else
            0.5e f< invert if
                FLT_1 f+
            then
        then
    then
;

DONEWORDS       \ }

marker testing-float1

    T{ 0.0e fround f0= -> true }T
    T{ 0.0E fround f0= -> true }T
    T{ 7.499e fround 7.0e f= -> true }T
    T{ 7.501e fround 8.0e f= -> true }T
    T{ 0.500e fround 0.0e f= -> true }T
    T{ 1.500e fround 2.0e f= -> true }T
    T{ 2.500e fround 2.0e f= -> true }T
    T{ 3.500e fround 4.0e f= -> true }T

    T{ 0e f>d -> 0. }T
    T{ 79218e f>d -> 79218. }T
    T{ -79218e f>d -> -79218. }T

testing-float1
