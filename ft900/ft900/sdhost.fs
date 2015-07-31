LOCALWORDS  \ {

$00010000 constant SYS_CARD_INSERT
$00000800 constant BUFFER_READ_ENABLE
$00000002 constant CMD_INHIBIT_D
$00000001 constant CMD_INHIBIT_C

\ Clock control register
$00000001 constant INTER_CLK_EN
$00000002 constant INTER_CLK_STABLE
$00000004 constant SD_CLK_EN

\ Command register
$0020 constant DATA_PRES_SEL
$0010 constant CMD_IDX_CHECK_EN
$0008 constant CMD_CRC_CHECK_EN

$10400
cell+
io-32 BLK_CS                \ BLK_SIZE  BLK_COUNT
io-32 arg1reg	
io-32 tmr_cmdr
io-32 response0
io-32 response1
cell+ \ io-32 response2
cell+ \ io-32 response3	
io-32 bufferdport	
io-32 presentstate	
io-32 hostcontrol1
io-32 clockcontrol
io-32 normintstatus_err
io-32 normintstatus_en_err
cell+ \ io-32 normintsig_en
io-32 autocmd12
io-32 capreg0		
io-32 capreg1		
cell+ \ io-32 maxcurrentcap0	
cell+ \ io-32 maxcurrentcap1	
cell+ \ io-32 forceeventcmd12
cell+ \ io-32 admaerrorstatus	
cell+ \ io-32 admasysaddr0	
cell+ \ io-32 admasysaddr1	
cell+ \ io-32 presetvalue0	
cell+ \ io-32 presetvalue1	
cell+ \ io-32 presetvalue2	
cell+ \ io-32 presetvalue3	
drop

$104fc
io-32 specversion	
io-32 vendor1		
drop

: vendor ( u -- a ) \ vendor register u
    cells vendor1 +
;

: setclock ( u -- )
    8 lshift 
    clockcontrol @
    $ffff invert and    dup clockcontrol !  \ disable internal & SD
    or                  dup clockcontrol !  \ write new divider
    1 or                dup clockcontrol !  \ enable internal clock

    \ Wait until clock is stable
    begin
        clockcontrol @ INTER_CLK_STABLE and
    until

    \ Enable SD output
    4 or clockcontrol !
;

: sdhost-init
    12 clockon if
        \ 27 19 do
        \     $48 i pads
        \ loop

        $40 19 pads     \ CLK
        $48 20 pads     \ CMD
        $40 21 pads     \ DATA3
        $40 22 pads     \ DATA2
        $40 23 pads     \ DATA1
        $48 24 pads     \ DATA0
        $40 25 pads     \ CD
        $40 26 pads     \ WP

        $01 clockcontrol 3 + c! \ soft-reset

        8 2 or 16 lshift
        autocmd12 or!

        $02000101 0 vendor ! \ pulse latch offset
        $0000000b 5 vendor ! \ Debounce to maximum

        normintstatus_en_err on  \ Enable all error and interrupt bits

        \ INTER_CLK_EN $ffc0 or clockcontrol or!
        $80 setclock
    then
;

: wait_ready_command
    begin
        presentstate @ CMD_INHIBIT_C and 0=
    until
    begin
        presentstate @ CMD_INHIBIT_D and 0=
    until
;

: wait_int_response
    begin
        normintstatus_err @ 1 and
    until
    1 normintstatus_err !
;

\ Command register
$0020 constant DATA_PRES_SEL
$0010 constant CMD_IDX_CHECK_EN
$0008 constant CMD_CRC_CHECK_EN

\ See table 4-10
0                                               constant R_
CMD_CRC_CHECK_EN 1 or                           constant R2
2                                               constant R3
2                                               constant R4
CMD_CRC_CHECK_EN CMD_IDX_CHECK_EN or 2 or       constant R1
CMD_CRC_CHECK_EN CMD_IDX_CHECK_EN or 2 or       constant R5
CMD_CRC_CHECK_EN CMD_IDX_CHECK_EN or 2 or       constant R6
CMD_CRC_CHECK_EN CMD_IDX_CHECK_EN or 2 or       constant R7
CMD_CRC_CHECK_EN CMD_IDX_CHECK_EN or 3 or       constant R1b5b

\ READ-1 is the 32-bit command to read 1 sector
\ READ-N is the same, but for multiple sectors

18 8 lshift
R1 or
1 5 lshift or
16 lshift
16 or       \ TRAN_DIR_SEL=1
$22 or      \ BLK_CNT_EN=1
1 2 lshift or   \ Auto cmd12 enable
constant READ-N

17 8 lshift
R1 or
1 5 lshift or
16 lshift
16 or       \ TRAN_DIR_SEL=1
constant READ-1

: command   ( arg resp c -- response )
    wait_ready_command
    8 lshift or
    swap arg1reg !
    16 lshift tmr_cmdr !
    wait_int_response
    response0 @
;

: rdsec ( caddr -- ) \ wait for ready, then read a sector
    begin
        presentstate @ BUFFER_READ_ENABLE and
    until
    bufferdport 512 streamin
;

\ -------------------------------------------------------------
PUBLICWORDS \ }{

object class
    method      ??          \ every object has ?? for debug
    method      init        \ and initialize
end-class shared

shared class
    method      blk-rd
    method      blk-wr
end-class blkdev

blkdev class
  1 cells var   rca
  1 cells var   capacity    \ capacity in Kbytes
end-class sddev

:noname
    cr ." sddev:"
    ." rca=" dup rca @ u.
    ." capacity=" capacity @ 1024 um* <# #s #> type
; sddev defines ??

:noname ( o -- )
    sdhost-init
    >r
    0 R_ 0 command drop
    $1aa R1 $08 command $1aa =  ( F8 )

    begin
        0 R1 55 command drop
        dup $40000000 and $FF8000 or R3 41 command
        $80000000 and 0=
    while
        10 ms
    repeat
    drop

    \ CMD2: switch from ready state to ident.
    0 R2 2 command drop

    \ CMD3: get RCA
    0 R6 3 command
    $ffff0000 and r@ rca !

    \ CSD register
    r@ rca @ R2 9 command drop

    response1 @ 8 rshift 512 *
    r@ capacity !

    \ Put card in transfer state
    r@ rca @ R1b5b 7 command $700 <> throw

    \ SET_BLOCKLEN
    512 R1 16 command drop

    \ 4-bit mode; high-speed mode
    r@ rca @ R1 55 command drop
    2 R1 6 command drop
    6 hostcontrol1 or!

    $10200 BLK_CS !
    2 normintstatus_err !

    \ Set the SDhost clock to 50MHz
    $01 setclock

    r> drop
; sddev defines init

:noname ( dst u sector o -- )
    drop
    wait_ready_command
    arg1reg !      \ sector
    dup 16 lshift 512 or BLK_CS !

    dup 1 = if
        drop
        READ-1 tmr_cmdr !
        wait_int_response
        rdsec
    else
        READ-N tmr_cmdr !
        wait_int_response
        0 do
            dup rdsec
            512 +
        loop
        drop
    then
; sddev defines blk-rd

DONEWORDS    \ }
