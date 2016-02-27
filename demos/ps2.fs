here cp @
5 constant CLK                  4 constant DAT
: CLK@   CLK io@ ;              : DAT@  DAT io@ ;

: fall              begin CLK@ until begin CLK@ 0= until ;
: getbit ( -- u )   fall DAT@ ;
: kb?               CLK@ DAT@ + 0= ;
: rx ( -- code )
    begin kb? until
    0
    8 0 do getbit i lshift + loop
    getbit getbit 2drop ;

: low ( pin )       0 over io! OUTPUT swap pinMode ;
: release ( pin )   INPUT swap pinMode ;
: tx1               1 and if 4 release else 4 low then fall ;
: tx ( code -- )
    CLK low 1 ms DAT low CLK release fall
    0 8 0 do
        over i rshift dup tx1
        +                           \ accumulate parity
    loop
    1+ tx1 drop                     \ send odd parity
    DAT release
    fall begin CLK@ DAT@ and until ;
: leds ( x -- )     $ed tx rx drop tx rx drop ;

variable make       \ is this a key-make event?
variable mods       \ Modifiers. Mask bits are:
                    \   1       2       4       8
                    \   shift   caps    ctrl 

: ismake ( code -- code|0 ) make @ and make on ;
: ?m ( msk -- f )   mods @ and 0<> ;
: mx ( mask -- 0 )  ismake mods @ xor mods ! 0 ;
: m! ( msk -- 0 )   dup invert mods @ and mods ! mx ;

: alpha ( u -- )
    1 ?m 2 ?m xor $20 and -     \ upper/lower case
    4 ?m if $1f and then        \ control key
    ismake ;
: shift
    1 ?m if nip else drop then
    ismake ;

create _ $80 cells allot : dx cells _ + ;
: ;op postpone ; swap dx ! ; immediate

$00 :noname 0 ;op
$12 :noname 1 m! ;op    ( LEFT SHIFT )
$12 dx @ $59 dx !       ( RIGHT SHIFT )
$58 :noname 2 mx ;op    ( CAPS )
$14 :noname 4 m! ;op    ( CONTROL )

$0d :noname $09 ismake ;op  ( TAB )
$29 :noname $20 ismake ;op  ( SPACE )
$5a :noname $0a ismake ;op  ( ENTER )
$66 :noname $08 ismake ;op  ( BKSP )
$7c :noname '*' ismake ;op  ( ASTERISK )
$7b :noname '-' ismake ;op  ( MINUS )
$79 :noname '+' ismake ;op  ( PLUS )

$15 :noname 'q' alpha ;op       $31 :noname 'n' alpha ;op
$1a :noname 'z' alpha ;op       $32 :noname 'b' alpha ;op
$1b :noname 's' alpha ;op       $33 :noname 'h' alpha ;op
$1c :noname 'a' alpha ;op       $34 :noname 'g' alpha ;op
$1d :noname 'w' alpha ;op       $35 :noname 'y' alpha ;op
$21 :noname 'c' alpha ;op       $3a :noname 'm' alpha ;op
$22 :noname 'x' alpha ;op       $3b :noname 'j' alpha ;op
$23 :noname 'd' alpha ;op       $3c :noname 'u' alpha ;op
$24 :noname 'e' alpha ;op       $42 :noname 'k' alpha ;op
$2a :noname 'v' alpha ;op       $43 :noname 'i' alpha ;op
$2b :noname 'f' alpha ;op       $44 :noname 'o' alpha ;op
$2c :noname 't' alpha ;op       $4b :noname 'l' alpha ;op
$2d :noname 'r' alpha ;op       $4d :noname 'p' alpha ;op

$0e :noname '`' '~' shift ;op   $46 :noname '9' '(' shift ;op
$16 :noname '1' '!' shift ;op   $49 :noname '.' '>' shift ;op
$1e :noname '2' '@' shift ;op   $4a :noname '/' '?' shift ;op
$25 :noname '4' '$' shift ;op   $4c :noname ';' ':' shift ;op
$26 :noname '3' '#' shift ;op   $4e :noname '-' '_' shift ;op
$2e :noname '5' '%' shift ;op   $52 :noname ''' '"' shift ;op
$36 :noname '6' '^' shift ;op   $54 :noname '[' '{' shift ;op
$3d :noname '7' '&' shift ;op   $55 :noname '=' '+' shift ;op
$3e :noname '8' '*' shift ;op   $5b :noname ']' '}' shift ;op
$41 :noname ',' '<' shift ;op   $5d :noname '\' '|' shift ;op
$45 :noname '0' ')' shift ;op

: graw
    rx
    $f0 over = if drop 0 make off then
    $e0 over = if drop 0 then
    dx @ execute ;

: /kb mods off make on ;

: debug begin rx hex2. again ;

: x
    /kb
    begin graw .x depth throw cr again ;

: q /kb begin graw ?dup if emit then again ;

cp @ swap - . cr
here swap - . cr

: x 8 0 do i leds 100 ms loop ;

: soak
    0
    begin
        dup .
        dup 7 and leds
        1+
    again ;
