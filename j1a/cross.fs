
\   Usage gforth cross.fs <machine.fs> <program.fs>
\
\   Where machine.fs defines the target machine
\   and program.fs is the target program
\

variable lst        \ .lst output file handle

: h#
    base @ >r 16 base !
    0. bl parse >number throw 2drop postpone literal
    r> base ! ; immediate

: tcell     2 ;
: tcells    tcell * ;
: tcell+    tcell + ;

131072 allocate throw constant tflash       \ bytes, target flash
131072 allocate throw constant _tbranches   \ branch targets, cells
tflash      31072 erase
_tbranches  131072 erase
: tbranches cells _tbranches + ;

variable tdp    $1000 tdp !     \ Data pointer
variable tcp    0 tcp !         \ Code pointer
: there     tdp @ ;
: islegal   ;
: tc!       islegal tflash + c! ;
: tc@       islegal tflash + c@ ;
: tw!       islegal tflash + w! ;
: tw@       islegal tflash + w@ ;
: t@        islegal tflash + uw@ ;
: twalign   tdp @ 1+ -2 and tdp ! ;
: tc,       there tc! 1 tdp +! ;
: tw,       there tw! tcell tdp +! ;
: tcode,    tcp @ tw! tcell tcp +! ;
: org       tcp ! ;

wordlist constant target-wordlist
: add-order ( wid -- ) >r get-order r> swap 1+ set-order ;
: :: get-current >r target-wordlist set-current : r> set-current ;

next-arg included       \ include the machine.fs

( Language basics for target                 JCB 19:08 05/02/12)

warnings off
:: ( postpone ( ;
:: \ postpone \ ;

:: org          org ;
:: include      include ;
:: included     included ;
:: marker       marker ;
:: [if]         postpone [if] ;
:: [else]       postpone [else] ;
:: [then]       postpone [then] ;

: literal
    \ dup $f rshift over $e rshift xor 1 and throw
    dup h# 8000 and if
        h# ffff xor recurse
        ~T alu
    else
        h# 8000 or tcode,
    then
;

: literal
    dup $8000 and if
        invert recurse
        ~T alu
    else
        $8000 or tcode,
    then
;

( Defining words for target                  JCB 19:04 05/02/12)

: codeptr   tcp @ 2/ ;  \ target data pointer as a jump address

: wordstr ( "name" -- c-addr u )
    >in @ >r bl word count r> >in !
;

variable link 0 link !

:: header
    twalign there
    \ cr ." link is " link @ .
    link @ tw,
    link !
    bl parse
    \ cr ." at " there . 2dup type tcp @ .
    dup tc,
    bounds do
        i c@ tc,
    loop
    twalign
    tcp @ tw,
;

:: header-imm
    twalign there
    link @ 1+ tw,
    link !
    bl parse
    dup tc,
    bounds do
        i c@ tc,
    loop
    twalign
    tcp @ tw,
;

variable wordstart

:: :
    hex
    there s>d
    <# bl hold # # # # #>
    lst @ write-file throw
    wordstr lst @ write-line throw

    there wordstart !
    create  codeptr ,
    does>   @ scall

;

:: :noname
;

:: ,
    twalign
    tw,
;

:: allot
    0 ?do
        0 tc,
    loop
;

: shortcut ( orig -- f ) \ insn @orig precedes ;. Shortcut it.
    \ call becomes jump
    dup t@ h# e000 and h# 4000 = if
        dup t@ h# 1fff and over tw!
        true
    else
        dup t@ h# e00c and h# 6000 = if
            dup t@ h# 0080 or r-1 over tw!
            true
        else
            false
        then
    then
    nip
;

:: ;
    tcp @ wordstart @ = if
        s" exit" evaluate
    else
        tcp @ 2 - shortcut \ true if shortcut applied
        tcp @ 0 do
            i tbranches @ tcp @ = if
                i tbranches @ shortcut and
            then
        loop
        0= if   \ not all shortcuts worked
            s" exit" evaluate
        then
    then
;

:: ;fallthru ;

:: jmp
    ' >body @ ubranch
;

:: constant
    create  ,
    does>   @ literal
;

:: create
    twalign
    create there ,
    does>   @ literal
;

:: inline:
    parse-name evaluate
    \ tcp @ tw! tcell tcp +! ;
    tcp @ 2 - >r
    r@ tw@ $8000 or r> tw!
    s" code," evaluate
;

( Switching between target and meta          JCB 19:08 05/02/12)

: target    only target-wordlist add-order definitions ;
: ]         target ;
:: meta     forth definitions ;
:: [        forth definitions ;

: t'        bl parse target-wordlist search-wordlist 0= throw >body @ ;

( eforth's way of handling constants         JCB 13:12 09/03/10)

: sign>number   ( c-addr1 u1 -- ud2 c-addr2 u2 )
    0. 2swap
    over c@ [char] - = if
        1 /string
        >number
        2swap dnegate 2swap
    else
        >number
    then
;

: base>number   ( caddr u base -- )
    base @ >r base !
    sign>number
    r> base !
    dup 0= if
        2drop drop literal
    else
        1 = swap c@ [char] . = and if
            drop dup literal 32 rshift literal
        else
            -1 abort" bad number"
        then
    then ;
warnings on

:: d# bl parse 10 base>number ;
:: h# bl parse 16 base>number ;
:: ['] ' >body @ 2* literal ;
:: [char] char literal ;

:: asm-0branch
    ' >body @
    0branch
;

( Conditionals                               JCB 13:12 09/03/10)

: resolve ( orig -- )
    tcp @ over tbranches ! \ forward reference from orig to this loc
    dup t@ tcp @ 2/ or swap tw!
;

:: if
    tcp @
    0 0branch
;

:: DOUBLE
    tcp @ 2/ 1+ scall
;

:: then
    resolve
;

:: else
    tcp @
    0 ubranch 
    swap resolve
;

:: begin tcp @ ;

:: again ( dest -- )
    2/ ubranch
;
:: until
    2/ 0branch
;
:: while
    tcp @
    0 0branch
;
:: repeat
    swap 2/ ubranch
    resolve
;

2 org
: .trim ( a-addr u ) \ shorten string until it ends with '.'
    begin
        2dup + 1- c@ [char] . <>
    while
        1-
    repeat
;

( Strings                                    JCB 11:57 05/18/12)

: >str ( c-addr u -- str ) \ a new u char string from c-addr
    dup cell+ allocate throw dup >r
    2dup ! cell+    \ write size into first cell
                    ( c-addr u saddr )
    swap cmove r>
;
: str@  dup cell+ swap @ ;
: str! ( str c-addr -- c-addr' ) \ copy str to c-addr
    >r str@ r>
    2dup + >r swap
    cmove r>
;
: +str ( str2 str1 -- str3 )
    over @ over @ + cell+ allocate throw >r
    over @ over @ + r@ !
    r@ cell+ str! str! drop r>
;

: example
    s"  sailor" >str
    s" hello" >str
    +str str@ type
;

next-arg 2dup .trim >str constant prefix.
: .suffix  ( c-addr u -- c-addr u ) \ e.g. "bar" -> "foo.bar"
    >str prefix. +str str@
;
: create-output-file w/o create-file throw ;
: out-suffix ( s -- h ) \ Create an output file h with suffix s
    >str
    prefix. +str
    s" build/" >str +str str@
    create-output-file
;
:noname
    s" lst" out-suffix lst !
; execute


target included                         \ include the program.fs

[ tcp @ 0 org ] main [ org ]
meta

decimal
0 value file
: dumpall.16
    s" hex" out-suffix to file

    hex
    4096 0 do
        tflash i 2* + w@
        s>d <# # # # # #> file write-line throw
    loop
    file close-file
;
: dumpall.32
    s" hex" out-suffix to file

    hex
    8192 0 do
        tflash i 4 * + @
        s>d <# # # # # # # # # #> file write-line throw
    loop
    file close-file
;

dumpall.16
." tdp " tdp @ .
." tcp " tcp @ .

bye
