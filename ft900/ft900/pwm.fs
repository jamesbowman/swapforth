localwords  \ {

\ http://www.ftdichip.com/Support/Documents/AppNotes/AN_324_FT900_User_Manual.pdf
\ http://www.ftdichip.com/Support/Documents/AppNotes/AN_140_Vinculum-II_PWM_Example.pdf

$103c0
io-8    ctrl0
io-8    ctrl1
io-8    prescaler
io-16   cnt
16 io-n cmp             \ 8 16-bit words
8 io-n  toggle          \ 8 bytes
io-8    clr_en
io-8    cmp8
io-8    init
drop

: uw! ( u a -- ) \ misaligned 16-bit store
    over 8 rshift over 1+ c! c!
;

\ PAD   CHANNEL
\ 52    4
\ 53    5
\ 54    6
\ 55    7
\ 56    0
\ 57    1
\ 58    2

: channel  ( pad -- chan ) \ from pad number 52-58 to channel 0-7
    7 and
;

set-current \ }{

: pwm-count  ( u -- ) \ set the 16-bit PWM limit register
    cnt uw!
;

: pwm-prescale  ( u -- ) \ set the 8-bit PWM prescaler
    prescaler c!
;

: pwm-en  ( pad -- ) \ enable PWM output on a pad
    $40 swap setpad
;

: pwm!  ( u pad -- ) \ Set PWM comparator for pad
    channel 2* cmp + uw!
;
    
: pwm-init
    2 clockon drop
    $01 ctrl1 c!

    0 pwm-prescale
    $ffff pwm-count

    $ff clr_en c!
    $ff init c!

    8 0 do
        i bit toggle i + c!
    loop
;

previous    \ }
