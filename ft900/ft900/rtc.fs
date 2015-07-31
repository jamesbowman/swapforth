localwords  \ {

\ http://www.ftdichip.com/Support/Documents/AppNotes/AN_324_FT900_User_Manual.pdf

$10280
io-32   ccvr    \ Current Counter Value Register
io-32   cmr     \ Counter Match Register
io-32   clr     \ Counter Load Register
io-32   ccr     \ Counter Control Register (WEN EN MASK IEN)
io-32   stat    \ 1 means interrupt
cell+
io-32   eoi     \ End of Interrupt Register - read clears interrupt

drop

set-current \ }{

: rtc@
    ccvr @
;

previous    \ }

