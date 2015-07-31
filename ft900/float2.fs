3.141592653e    fconstant PI

LOCALWORDS      \ {

PI 2.e f*       fconstant PI2*
PI .5e f*       fconstant PI2/
PI .25e f*      fconstant PI4/
pi 6.e f/   fconstant   pi6/
0.26794919e fconstant   pi12/tan    \ pi 12e f/ ftan
0.57735026e fconstant   pi6/tan     \ pi 6e f/ ftan

: squared
    fdup f*
;

 0.9999932946e  fconstant cc1
-0.4999124376e  fconstant cc2
 0.0414877472e  fconstant cc3
-0.0012712095e  fconstant cc4

: fcos52 ( F: x -- r )
    fdup f*
    fdup cc4 f* cc3 f+
    fover f* cc2 f+
    f* cc1 f+
;

1.6867629106e fconstant ac1
0.4378497304e fconstant ac2
1.6867633134e fconstant ac3

: atan_66s
    fdup squared
    fdup ac2 f* ac1 f+
    fswap ac3 f+
    f/
    f*
;

: newton ( F: xhalf y -- xhalf y' )
    fover fover                 ( xhalf y xhalf y )
    fdup f* f* 1.5e fswap f- f* ( xhalf y' )
;

PUBLICWORDS     \ }{

: fcos ( F: r -- r )
    fabs PI2* fmod

    fdup PI f< 0= if
        PI2* fswap f-
    then

    fdup PI2/ f< if
        fcos52
    else
        PI fswap f- fcos52 fnegate
    then

\     fdup PI2/ f/ f>s case
\     0   of fcos52                       endof
\     1   of PI fswap f- fcos52 fnegate   endof
\     2   of PI f- fcos52 fnegate         endof
\     3   of PI2* fswap f- fcos52          endof
\     endcase
;

: fsin
    PI2/ fswap f- fcos
;

: fsincos
    fdup fsin fswap fcos
;

: degrees ( F: r0 -- r1 ) \ r0 is in degrees, r1 in radians
    [ pi2* 360.e f/ ] fliteral f*
;

: radians ( F: r0 -- r1 ) \ r0 is in radians r1 in degrees
    [ 360.e pi2* f/ ] fliteral f*
;

: fatan
    fdup f0< if
        fnegate recurse fnegate
    else
        1.0e fover f< if
            1.0e fswap f/
            recurse
            pi2/ fswap f-
        else
            pi12/tan fover f< if
                fdup pi6/tan f- fswap
                pi6/tan f* 1.0e f+
                f/
                recurse
                pi6/ f+
            else
                atan_66s
            then
        then
    then
;

: finvsqrt
    fabs
    fdup 0.5e f* fswap
    $5f3759df f> 2/ - >f
    newton
    newton
    newton
    fswap fdrop
;

: fsqrt
    fdup f0= invert if
        fabs fdup finvsqrt f*
    then
;

: fasin
    fdup squared 1.0e fswap f- fsqrt f/
    fatan
;

: facos
    fasin
    PI2/ fswap f-
;

DONEWORDS       \ }

marker testing-float2

    : close ( F: r0 r1 -- ) ( -- f )
        fover f- fabs fswap f/
        10000e f* f>d
        d0=
    ;

    T{ 22222e 22223e close -> true }T
    T{ 22222e 22232e close -> false }T

    : 0close ( F: r -- ) ( -- f )
        fabs 0.00001e f<
    ;

    T{ 0e fsqrt 0close -> true }T
    T{ 0e fasin 0close -> true }T
    T{ 0e fsin 0close -> true }T
    T{ 0e fcos 1.0e close -> true }T

    T{ 121e fsqrt 11e close -> true }T
    T{ -121e fsqrt 11e close -> true }T
    T{ 79218e fdup fsqrt fdup f* close -> true }T
    T{ 79218e fdup fsqrt fdup f* close -> true }T

    T{ 0.5e fdup fasin fsin close -> true }T
    T{ -0.5e fdup fasin fsin close -> true }T

    T{ 0.5e fdup facos fcos close -> true }T
    T{ 0.5e fcos -0.5e fcos close -> true }T

testing-float2
