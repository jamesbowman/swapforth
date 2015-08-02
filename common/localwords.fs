\ Start a local word definition region
\ These words will not be globally visible.
\ Usage:
\
\       localwords  \ {
\           ... define local words ...
\       publicwords \ }{
\           ... define public words ...
\       donewords   \ }
\

: LOCALWORDS
    get-current
    get-order wordlist swap 1+ set-order definitions
;

: PUBLICWORDS
    set-current
;

: DONEWORDS
    previous
;

marker testing-localwords
    : k0 100 ;
    t{ k0 -> 100 }t
    localwords
        : k0 200 ;
        : k1 300 ;
    publicwords
        t{ k0 k1 -> 200 300 }t
        : k01 k0 k1 ;
    donewords
    t{ k0 -> 100 }t
    t{ k01 -> 200 300 }t
    t{ bl word k1 find nip -> 0 }t
testing-localwords
