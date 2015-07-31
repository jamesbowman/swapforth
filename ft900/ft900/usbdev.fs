$1000c constant PMCFG

$10180

$00 over + constant INTSTATUS       \ Interrupt Status
$04 over + constant EPINTSTATUS     \ Endpoints Interrupt Status
$08 over + constant INTENABLE       \ Interrupt Enable
$0C over + constant EPINTENABLE     \ Endpoints Interrupt Enable
$10 over + constant MODE            \ Mode
$14 over + constant FRAMENUMBER     \ Frame Number
$18 over + constant ADDRESSENABLE   \ Address
$1c over + constant EP0             \ Endpoint 0

drop

: EP ( n -- a ) \ address of endpoint n
    4 lshift EP0 +
;

: EP-CONTROL           ;            \ Endpoint Control Register
: EP-STATUS       $4 + ;            \ Endpoint Status Register
: EP-BUFFERLENGTH $8 + ;            \ Endpoint Buffer Length Register
: EP-BUFFER       $c + ;            \ Endpoint Buffer Register

: usbdev-init
    14 clockon drop
    PMCFG @ 10 bit or PMCFG !       \ Enable USB Device PHY
    1 MODE c!
;

8 buffer: request
: bmRequestType request c@ ;
: bRequest      request 1 + c@ ;
: wValue        request 2 + uw@ ;
: wIndex        request 4 + uw@ ;
: wLength       request 6 + uw@ ;

: w,
    dup c, 8 rshift c,
;

create desc-device
    (  0 ) $12     c, \ bLength            Size of this descriptor, in bytes.
    (  1 ) $01     c, \ bDescriptorType    DEVICE descriptor type.
    (  2 ) $0100   w, \ bcdUSB             USB specification release number in binary coded decimal.
    (  4 ) 0       c, \ bDeviceClass       See interface.
    (  5 ) 0       c, \ bDeviceSubClass    See interface.
    (  6 ) 0       c, \ bDeviceProtocol    See interface.
    (  7 ) 64      c, \ bMaxPacketSize0    Maximum packet size for endpoint 
    (  8 ) $0403   w, \ idVendor           Vendor ID. Assigned by the USB-IF.
    ( 10 ) $0947   w, \ idProduct          Product ID. Assigned by manufacturer.
    ( 12 ) $1234   w, \ bcdDevice          Device release number in binary coded decimal.
    ( 14 ) 0       c, \ iManufacturer      Index of string descriptor.
    ( 15 ) 0       c, \ iProduct           Index of string descriptor.
    ( 16 ) 0       c, \ iSerialNumber      Index of string descriptor.
    ( 17 ) 1       c, \ bNumConfigurations One configuration only for DFU.

create desc-config
    (  0 ) 9       c, \ bLength            Size of this descriptor, in bytes.
    (  1 ) $02     c, \ bDescriptorType    DEVICE descriptor type.
    (  2 ) 27      w, \ wTotalLength       
    (  4 ) 1       c, \ bNumInterfaces
    (  5 ) 0       c, \ bConfigurationValue
    (  6 ) 0       c, \ iConfiguration
    (  7 ) $80     c, \ bmAttributes
    (  8 ) 50      c, \ bMaxPower

    (  0 ) $09     c, \ bLength            Size of this descriptor, in bytes.
    (  1 ) $04     c, \ bDescriptorType    INTERFACE descriptor type.
    (  2 ) $00     c, \ bInterfaceNumber   Number of this interface. 
    (  3 ) 0       c, \ bAlternateSetting  Alternate setting. *
    (  4 ) $00     c, \ bNumEndpoints      Only the control pipe is used.
    (  5 ) $FE     c, \ bInterfaceClass    Application Specific Class Code
    (  6 ) $01     c, \ bInterfaceSubClass Device Firmware Upgrade Code
    (  7 ) $02     c, \ bInterfaceProtocol DFU mode protocol.
    (  8 ) 0       c, \ iInterface         Index of string descriptor for this interface.

    (  0 ) $09     c, \ bLength            Size of this descriptor, in bytes.
    (  1 ) $21     c, \ bDescriptorType    DFU FUNCTIONAL descriptor type.
    (  2 ) 7       c, \ bmAttributes       mask DFU attributes
    (  3 ) 30000   w, \ wDetachTimeOut     Time, in milliseconds, that the device
    (  5 ) 4096    w, \ wTransferSize      Maximum number of bytes that the device can accept per control-write transaction. 
    (  7 ) $100    w, \ bcdDFUVersion      Numeric expression identifying the version of the DFU Specification release. 

\ http://www.usb.org/developers/docs/devclass_docs/DFU_1.1.pdf
\ Table 3.1 and 3.2

\ http://www.usbmadesimple.co.uk/ums_4.htm
\ http://lists.openmoko.org/pipermail/devel/2014-August/007298.html

: EP0STAT EP0 EP-STATUS ;

: tx
    EP0STAT c!
    begin
        EP0STAT c@
        $02 and 0=
    until
;

: 0xmit 
    \ 2dup dump
    EP0 EP-BUFFER -rot streamout.b
    $12 tx
;

: 0recv  ( c-addr -- u ) \ write incoming packet to c-addr, u is the length
    begin
        EP0STAT c@ 1 and
    until

    EP0 EP-BUFFER
    EP0 EP-BUFFERLENGTH c@ dup >r
    streamin.b
    r>
;

: %
    postpone cr postpone ." postpone space
    \ postpone \
; immediate

create dfu-status
    0 c,                \ bStatus
    0 c, 0 c, 0 c,      \ bwPollTimeout
    2 c,                \ bState
    0 c,                \ iString

: sector
    wValue 12 lshift
;

: handle-dfu
    bRequest case
    0 of    % DFU_DETACH
    endof
    1 of    % DFU_DNLOAD
        wLength if
            wLength 0 do
                pad i + 0recv
                $1 EP0STAT c!
            +loop
            wValue 63 < if
                \ pad sector 4096 flash!
            then
            5 \ dfuDNLOAD-SYNC 
        else
            8 \ dfuMANIFEST-WAIT-RESET
        then
        dfu-status 4 + c!
        $12 tx
    endof
    2 of    % DFU_UPLOAD
        wValue 63 < if
            sector pad wLength flash@
            wLength 0 do
                i 0<> i 63 and 0= and if
                    $02 tx
                then
                pad i + c@ EP0 EP-BUFFER c!
            loop
        then
        $12 tx

    endof
    3 of    % DFU_GETSTATUS
        dfu-status 6 0xmit
    endof
    4 of    % DFU_CLRSTATUS
    endof
    5 of    % DFU_GETSTATE
    endof
    6 of    % DFU_ABORT 
    endof
    endcase
;

: dfudev
    EP0STAT c@ 0= if exit then
    \ cr
    \ ." status: " EP0STAT c@ hex2.
    \ ." length: " EP0 EP-BUFFERLENGTH c@ hex2.

    EP0STAT c@ 4 and if
        request EP0 EP-BUFFER 8 streamin.b
        4 EP0STAT c!

        \ request 8 dump
        cr bmRequestType hex2. bRequest hex2. wValue . wIndex . wLength .
        
        bmRequestType 126 and case
        0 of
            bRequest case
            5 of    \ SET_ADDRESS
                wValue ADDRESSENABLE c!
                $12 tx
            endof
            6 of    \ GET_DESCRIPTOR
                $6 EP0 EP-CONTROL c!
                wValue 8 rshift case
                1 of desc-device 18 0xmit endof
                2 of desc-config 27 wLength min 0xmit endof
                endcase
            endof
            9 of    \ SET_CONFIGURATION
                $12 tx
            endof
            11 of   \ SET_INTERFACE
                $12 tx
            endof
            endcase
        endof
        32 of
            handle-dfu
        endof
        endcase

    then
;

: x
    usbdev-init
    begin
        dfudev
        \ 30 ms
    again
;
