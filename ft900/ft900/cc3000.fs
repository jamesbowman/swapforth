
\
\ GND       
\ 3V3
\ VIN
\ CLK       
\ MISO
\ MOSI
\ CS        28
\ VBEN      31
\ IRQ       33

31 constant VBEN    \ aka SPIM IO2
33 constant IRQpin  \ aka SPIM SS1

: sel       0 28 digitalWrite ;
: unsel     1 28 digitalWrite ;

: IRQ   IRQpin digitalRead ;

: ??
    IRQ .
;


variable verbose verbose off
: >spi
    verbose @ if
        cr dup hex2.
    then
    >spi
;

: s>spi
    bounds ?do
        i c@ >spi
    loop
;

: HCI ( caddr u code -- )
    >r
    sel
    $01 >spi                    \ WRITE
    dup 5 +                     \ Payload length, big-endian!
    dup 8 rshift >spi >spi      
    0 >spi 0 >spi               \ Busy, Busy
    $01 >spi                    \ HCI_TYPE_CMND
    r> dup >spi 8 rshift >spi   \ Command operation code
    tuck
    dup >spi                    \ Arguments length
    s>spi
    1 and 0= if 0 >spi then     \ optional padding
    unsel
;

variable pkt
: <pkt ( -- )
    pad pkt !
;

: pkt, ( x -- )
    pkt @ !
    4 pkt +!
;

: pkts, ( string -- )
    tuck
    pkt @ swap move
    pkt +!
;

: pkt> ( -- caddr u )
    pad
    pkt @ over -
;

: connect ( key security ssid -- )
    <pkt
        28          pkt,    \ ?
        dup         pkt,    \ SSID length
        rot         pkt,    \ WLAN security type 0,1,2,3
        dup 16 +    pkt,    \ SSID length + 16
        2swap dup   pkt,    \ Key length
        0           pkt,    \ ? and BSSID
        0           pkt,
        2swap       pkts,   \ SSID
                    pkts,   \ Key
    pkt>
    $0001 HCI
;

: gethostbyname ( name -- )
    <pkt
        8           pkt,
        dup         pkt,
                    pkts,
    pkt>
    $1010 HCI
;

( Handling events from CC3000                JCB 16:43 06/13/15)

256 buffer: event

\ Event argument parsing words

: status ( args -- args )
    over c@ 0<> 512 and throw
    1 /string
;

: e8
    over >r
    1 /string
    r> c@
;

: e16
    over >r
    2 /string
    r> pad 2 move
    pad uw@
;

: e32
    over >r
    4 /string
    r> pad 4 move
    pad @
;

: //ends
    nip 0<> 513 and throw
;

: .ip   ( x -- )
    <#
        3 0 do
            dup $ff and s>d #s 2drop 8 rshift
            [char] . hold
        loop
        s>d #s
    #> type
;

: dhcp ( args )
    status
    cr e32 ." address  " .ip
    cr e32 ." subnet   " .ip
    cr e32 ." gateway  " .ip
    cr e32 ." server   " .ip
    cr e32 ." DNS      " .ip
    //ends
;

: dns ( args )
    cr ." DNS response: "
    status
    e32 .
    e32 .ip
    //ends
;

: xdump ( addr -- )
    base @ swap hex
    6 0 do
        i if [char] : emit then
        dup i + c@
        s>d <# # # #> type
    loop
    drop
    base !
;

: .sec ( u -- ) \ print meaning of security field 0-3
    4 *
    s" noneWEP WPA WPA2" drop +
    4 type space
;

: scanresult ( args )
    \ cr 2dup dump cr
    status
    e32 ?dup if
        cr ." scanresult: "
        .
        e32 drop            \ scan status
        e8 2/ 4 .r space    \ RSSI
        e8                  \ SSID.name.length, security
        dup 3 and .sec     
        2 rshift >r       
        e16 6 .r space      \ entry time
        over r> type
        32 /string          \ SSID
        6 /string           \ BSSID
        2 /string           \ ??
        //ends

        <pkt
            0       pkt,
        pkt>
        $0007 HCI
    else
        2drop
    then
;

: gotevent ( args code -- ) \ handle event code with args
    case
    $0007 of scanresult   endof
    $8010 of dhcp   endof
    $1010 of dns    endof
        cr .x space
        bounds ?do 
            i c@ hex2.
        loop
        0
    endcase
;

: READ
    begin IRQ 0= until
    sel
    $03 >spi
    $00 >spi
    $00 >spi
    spi> 8 lshift spi> or

    event swap bounds ?do
        spi> i c!
    loop
    unsel

    event c@ $04 = if
        event 3 + count
        event 1+ dup c@ swap 1+ c@ 8 lshift or
        gotevent
    then

;

: wait-response
    begin IRQ until
    READ
;

create shedkey
    $EC c, $D6 c, $05 c, $A5 c, $6D c,

: scan
    <pkt
        36      pkt,
        4000    pkt,
        20      pkt,
        100     pkt,
        2       pkt,
        $07ff   pkt,
        -120    pkt,
        0       pkt,
        205     pkt,
        16 0 do
            2000    pkt,
        loop
    pkt>
    $0003 HCI

    wait-response

    2000 ms

    <pkt
        0       pkt,
    pkt>
    $0007 HCI

    begin
        wait-response
    again
;

: x
    500 ms

    OUTPUT 28 pinMode
    unsel
    INPUT IRQpin pinMode
    $08 IRQpin setpad \ pullup

    1 ms
    IRQ 0= abort" IRQ should be high"

    spi-init
    $102A0 @ $04 or $102A0 !    \ mode 1
    8 spi-speed

    OUTPUT VBEN pinMode
    1 VBEN digitalWrite

    cr ." Waiting for CC3000 to boot"

    begin
        IRQ 0=
    until
    cr ??
    cr

    sel
    50 us
    $01 >spi $00 >spi $05 >spi $00 >spi
    50 us
    $00 >spi $01 >spi $00 >spi $40 >spi $01 >spi $00 >spi
    unsel

    \ cr 100 0 do ?? 10 ms loop

    wait-response

    0 0 $400b HCI

    wait-response

    \ scan exit

    shedkey 5 1 s" bowmanvilleShed" connect

    wait-response

    100 ms

    READ

    READ

    s" yahoo.com" gethostbyname READ
    s" excamera.com" gethostbyname READ
;
