( J1 base words implemented in assembler     JCB 17:27 12/31/11)

: T         h# 0000 ;
: N         h# 0100 ;
: T+N       h# 0200 ;
: T&N       h# 0300 ;
: T|N       h# 0400 ;
: T^N       h# 0500 ;
: ~T        h# 0600 ;
: N==T      h# 0700 ;
: N<T       h# 0800 ;
: T2/       h# 0900 ;
: T2*       h# 0a00 ;
: rT        h# 0b00 ;
: [T]       h# 0c00 ;
: io[T]     h# 0d00 ;
: status    h# 0e00 ;
: Nu<T      h# 0f00 ;

: T->N      h# 0010 or ;
: T->R      h# 0020 or ;
: N->[T]    h# 0030 or ;
: N->io[T]  h# 0040 or ;
: _IORD_    h# 0050 or ;
: RET       h# 0080 or ;

: d-1       h# 0003 or ;
: d+1       h# 0001 or ;
: r-1       h# 000c or ;
: r-2       h# 0008 or ;
: r+1       h# 0004 or ;

: imm       h# 8000 or tcode, ;
: alu       h# 6000 or tcode, ;
: ubranch   h# 0000 or tcode, ;
: 0branch   h# 2000 or tcode, ;
: scall     h# 4000 or tcode, ;


:: noop      T                       alu ;
:: +         T+N                 d-1 alu ;
:: xor       T^N                 d-1 alu ;
:: and       T&N                 d-1 alu ;
:: or        T|N                 d-1 alu ;
:: invert    ~T                      alu ;
:: =         N==T                d-1 alu ;
:: <         N<T                 d-1 alu ;
:: u<        Nu<T                d-1 alu ;
:: swap      N     T->N              alu ;
:: dup       T     T->N          d+1 alu ;
:: drop      N                   d-1 alu ;
:: over      N     T->N          d+1 alu ;
:: nip       T                   d-1 alu ;
:: >r        N     T->R      r+1 d-1 alu ;
:: r>        rT    T->N      r-1 d+1 alu ;
:: r@        rT    T->N          d+1 alu ;
:: @         T                       alu
             [T]                     alu ;
:: io@       T     _IORD_            alu
             io[T]                   alu ;
:: !         
             T     N->[T]        d-1 alu
             N                   d-1 alu ;
:: io!       
             T     N->io[T]      d-1 alu
             N                   d-1 alu ;
:: 2/        T2/                     alu ;
:: 2*        T2*                     alu ;
:: depth     status T->N         d+1 alu ;
:: exit      T  RET              r-1 alu ;
:: hack      T      N->io[T]         alu ;

\ Elided words
\ These words are supported by the hardware but are not
\ part of ANS Forth.  They are named after the word-pair
\ that matches their effect  
\ Using these elided words instead of
\ the pair saves one cycle and one instruction.

:: 2dupand   T&N   T->N          d+1 alu ;
:: 2dup<     N<T   T->N          d+1 alu ;
:: 2dup=     N==T  T->N          d+1 alu ;
:: 2dupor    T|N   T->N          d+1 alu ;
:: 2dup+     T+N   T->N          d+1 alu ;
:: 2dupu<    Nu<T  T->N          d+1 alu ;
:: 2dupxor   T^N   T->N          d+1 alu ;
:: dup>r     T     T->R      r+1     alu ;
:: dup@      [T]   T->N          d+1 alu ;
:: overand   T&N                     alu ;
:: over>     N<T                     alu ;
:: over=     N==T                    alu ;
:: overor    T|N                     alu ;
:: over+     T+N                     alu ;
:: overu>    Nu<T                    alu ;
:: overxor   T^N                     alu ;
:: rdrop     T                   r-1 alu ;
:: tuck!     T     N->[T]        d-1 alu ;
