\ #######   DOUBLE   ##########################################

: 2variable
    create 2 cells allot
;

: 2constant
    create , ,
    does> 2@
;

: dmax
    2over 2over d< if
        2swap
    then
    2drop
;

: dmin
    2over 2over d< invert if
        2swap
    then
    2drop
;

: m+    s>d d+ ;

: m*
    2dup xor >r
    abs swap abs um*
    r> 0< if dnegate then
;

\ From Wil Baden's "FPH Popular Extensions"
\ http://www.wilbaden.com/neil_bawd/fphpop.txt

: tnegate                           ( t . . -- -t . . )
    >r  2dup or dup if drop  dnegate 1  then
    r> +  negate ;

: t*                                ( d . n -- t . . )
                                    ( d0 d1 n)
    2dup xor >r                     ( r: sign)
    >r dabs r> abs
    2>r                             ( d0)( r: sign d1 n)
    r@ um* 0                        ( t0 d1 0)
    2r> um*                         ( t0 d1 0 d1*n .)( r: sign)
    d+                              ( t0 t1 t2)
    r> 0< if tnegate then ;

: t/                                ( t . . u -- d . )
                                    ( t0 t1 t2 u)
    over >r >r                      ( t0 t1 t2)( r: t2 u)
    dup 0< if tnegate then
    r@ um/mod                       ( t0 rem d1)
    rot rot                         ( d1 t0 rem)
    r> um/mod                       ( d1 rem' d0)( r: t2)
    nip swap                        ( d0 d1)
    r> 0< if dnegate then ;

: m*/  ( d . n u -- d . )  >r t*  r> t/ ;

