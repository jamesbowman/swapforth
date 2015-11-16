( FAT32                                      JCB 16:54 03/19/15)

\ This is an implementation of the File Access words based on
\ a FAT32 filesystem.
\ The 'dev' is the device that the filesystem is based on.
\ See sddev in ft900/sdhost for an example of a suitable device.

\ FAT32 scheme: http://www.pjrc.com/tech/8051/ide/fat.html

localwords  \ {

: ok    0 ;         \ file words give 0 for success

                    \ need an unsigned version of min
: umin  2dup u< if drop else nip then ;

shared class
    1 cells var     dev
    method          fs-open
    method          root        \ open the root dir
    1 cells var     csector     \ sector cache for getsector
    512 var         secbuf
    1 cells var     lba
    1 cells var     fat_begin_lba
    1 cells var     cluster_begin_lba
    1 cells var     sectors_per_cluster
    1 cells var     root_dir_first_cluster
    1 cells var     cshift      \ bit-shifts to get cluster
end-class fat

32              constant SZ
16              constant NHANDLES
SZ NHANDLES *   constant TABSZ
create filetab TABSZ allot
filetab TABSZ erase

: fileid    ( file-type -- fileid ) \ assign the next available fileid
    filetab TABSZ bounds do
        i @ 0= if
            i !
            i unloop exit
        then
    SZ +loop
    ." out of file handles"
    abort
;

: tosector ( pos cluster o -- sector )    \ sector address of (cluster, pos)
    >r
    2 - r@ sectors_per_cluster @ *
    r@ cluster_begin_lba @ +
    swap
    9 rshift r> sectors_per_cluster @ 1- and
    +
;

: getsector ( sector o -- )
    2dup csector @ = if
        2drop
    else
        \ cr ." [MISS]" over .
        >r
        dup r@ csector !
        r@ secbuf 1 rot r> dev @ blk-rd
    then
;

: getpoint ( pos cluster fat -- )
    >r
    r@ tosector
    r> getsector
;

: secread ( dst u pos cluster fat -- )
    >r
    r@ tosector         ( dst u sec# )
    r> dev @ blk-rd
;

set-current \ }{

: files?
    NHANDLES 0 do
        cr 
        filetab i SZ * + dup .
        dup @ if
            ??
        else
            drop
        then
    loop
;

shared class
    method      read-file
    method      read-line
    method      file-position
    method      close-file
    method      file-size
    method      reposition-file
    method      resize-file
    method      write-file
    method      write-line
    method      file-status
    method      flush-file
end-class file

\ #######   fat-file: FAT32-backed file   #####################

file class
    1 cells var file-fs
    1 cells var position        \ position in file
    1 cells var size            \ size of file in bytes
    1 cells var f32-start       \ start cluster
    1 cells var f32-cur         \ current cluster
end-class fat-file

:noname ( fileid -- )
    position @ 0
    ok
; fat-file defines file-position

:noname     ( fileid -- ior )
    0 swap !
    ok
; fat-file defines close-file

:noname  ( fileid -- ud ior )
    size @ 0
    ok
; fat-file defines file-size

: atbyte  ( fileid -- u ) \ offset within current sector, 0 to 511
    position @ 511 and
;

: sec  ( fileid -- a ) \ pointer to the 512-byte sector storage
    file-fs @ secbuf
;

: secload  ( fileid -- ) \ load the current sector into sec
    >r
    r@ position @ r@ f32-cur @       \ read into secbuf
    r> file-fs @ getpoint
;

: grog  ( dst u fileid -- ) \ load u sectors to dst
    >r
    r@ position @ r@ f32-cur @       \ read into secbuf
    r> file-fs @ secread
;

: thispoint  ( fileid -- a ) \ read current sector into secbuf, return offset
    >r
    r@ secload
    r@ atbyte r> sec + \ offset into secbuf
;

: fastcase ( u fileid -- f ) \ for a read of size u, can use fast path?
    >r
    dup 512 =
    over 1024 = or
    over 2048 = or
    over 4096 = or
    over 8192 = or
    over 16384 = or
    over 32768 = or
    swap 1-
    r> position @ and 0=
    and
;

:noname  ( c-addr u fileid -- u2 ior )
    >r
    over swap                           ( dst dst rem ) \ save dst
    r@ size @ r@ position @ - umin      \ prevent read past end
    dup r@ fastcase if
        2dup                            ( dst u dst u )

        9 rshift r@ grog

        dup r@ position @ + 0 r@ reposition-file throw
        + 0
    else
        begin
            dup
        while
            2dup                            ( dst rem dst rem )
            512 r@ atbyte -                 \ how many bytes in sector
            min tuck                        ( dst rem u' dst u' )
            r@ thispoint
            -rot                            ( dst rem u' src dst u' )
            move                            ( dst rem u' )
            dup r@ position @ + 0 r@ reposition-file throw
            /string
        repeat
    then
                                        ( dst dst' 0 )
    drop swap - ok                      ( cnt 0 )
    r> drop
; fat-file defines read-file

: get1  ( fileid -- c )
    >r
    r@ atbyte dup r@ sec + c@
    swap 511 < if
        1 r> position +!
    else
        r@ position @ 1+ 0 r@ reposition-file throw
        r> secload
    then
;

\ before /pack           |-------------------------------------|
\ after                  c|------------------------------------|

: /pack  ( c-addr u c -- c-addr' u' ) \ prepend c to string
    rot tuck        ( u c-addr c c-addr )
    c!
    swap 1 /string  ( c-addr u )
;

:noname  ( c-addr u fileid -- u2 flag ior )
    >r
    r@ size @ r@ position @ = if
        2drop 0 false
    else
        over swap                           ( dst dst rem ) \ save dst
        r@ secload
        begin
            dup
        while
            r@ get1
            dup 10 = if
                2drop 0
            else dup 13 = if
                drop
            else
                /pack
            then then
        repeat
                                            ( dst dst' 0 )
        drop swap - true                    ( cnt true )
    then
    r> drop
    ok
; fat-file defines read-line

:noname
    cr
    ." fat: "
    ." sectors_per_cluster=" dup sectors_per_cluster @ u.
    ." cshift=" dup cshift @ u.
    ." root_dir_first_cluster=" root_dir_first_cluster @ u.
; fat defines ??
hex
: BPB_SecPerClus secbuf 0d + c@ ;
: BPB_RsvdSecCnt secbuf 0e + uw@ ;
: BPB_FATSz32   secbuf  024 + ul@ ;
: BPB_RootClus  secbuf  02c + ul@ ;
decimal

: log2  ( u -- u )
    0
    begin
        2dup 1 swap lshift u>
    while
        1+
    repeat
    nip
;

:noname ( dev -- )
    >r

    r@ dev !
    r@ csector on

    0 r@ getsector
    r@ secbuf 446 + 8 + r@ lba 4 move

    r@ lba @ r@ getsector

    r@ lba @ r@ BPB_RsvdSecCnt +               r@ fat_begin_lba !
    r@ lba @ r@ BPB_RsvdSecCnt + r@ BPB_FATSz32 2* + r@ cluster_begin_lba !
    r@ BPB_RootClus                            r@ root_dir_first_cluster !
    r@ BPB_SecPerClus dup                      r@ sectors_per_cluster !
    log2 9 +                                   r@ cshift !
    r> drop
; fat defines init

\ LOCALWORDS      \ {

: cluster.
    ." cluster " u.
;

:noname
    ." fat-file: "
    ." size=" dup size @ u.
    ." start=" dup f32-start @ cluster.
    ." cur=" dup f32-cur @ cluster.
    ." pos=" position @ u.
; fat-file defines ??

create _d 32 allot
: _atend    _d c@ 0= ;

hex

: d.filesize
    [ _d 01c + ] literal ul@
;

: d.cluster
    [ _d 01a + ] literal uw@ [ _d 014 + ] literal uw@ 10 lshift or
;

: d.attrib
    [ _d 00b + ] literal c@
;

decimal

( Directory traversal and LFN                JCB 19:30 03/12/15)

0 value dirid

: dirent \ read the current directory entry
    _d 32 dirid read-file 2drop
;

create lfn  \ offsets of the 13 characters in a dir entry
    $01 c, $03 c, $05 c, $07 c, $09 c, $0e c,
    $10 c, $12 c, $14 c, $16 c, $18 c, $1c c,
    $1e c,

: ucs2 ( n -- u16 ) \ Read UCS-2 character n from _d
    lfn + c@
    _d +
    dup 1+ c@ 8 lshift
    swap c@ or
;

: adjust ( n -- ) \ move the dirid file pointer n bytes
    s>d
    dirid file-position throw
    d+
    dirid reposition-file throw
;

: seq ( -- u ) \ return the sequence number of the current entry, 1-20
    _d c@ $40 invert and
;

: xfill ( c-addr1 u1 ch -- c-addr2 u2 )
    over if
        /pack
    else
        drop            \ no room, discard
    then
;

: lfn ( c-addr1 u1 -- c-addr2 u2 ) \ read the LFN into (c-addr, u1)
    -64 adjust dirent
    d.attrib $0f = seq 1 = and if
        21 1 do
            \ _d 32 dump
            seq i <> abort" LFN mismatch"
            13 0 do
                i ucs2
                ?dup 0= if
                    \ found 0000, so normal exit
                    j 32 * adjust
                    unloop unloop
                    exit
                then
                ( c-addr1 u1 ch )
                xfill
            loop
            \ Filenames that are multiples of 13 characters
            \ just stop. There is no 0000.
            _d c@ $40 and if
                seq 32 * adjust
                unloop
                exit
            then
            -64 adjust
            dirent
        loop
    then
;

\ Extracting 8.3 filenames

\ 8.3 filenames appear in the directry like this:
\
\ 0  1  2  3  4  5  6  7  .  8  9  10
\ x  x  x  x  x  x  x  x  .  x  x  x
\
\ Byte 12 bit 4: make extension lower-case
\         bit 3: make basename lower-case

variable fold

: ?lower ( c1 -- c2 ) \ lowercase c2 if c1 is upper and fold is true
    dup [char] A [char] Z 1+ within
    fold @ and
    32 and +
;

\ Copy a filename part. r0 and r1 is the range of bytes
: part ( c-addr1 u1 r1 r0 -- c-addr2 u2 )
    do
        _d i + c@
        dup bl = if
            drop leave
        then
        ?lower
        xfill
    loop
;

: canlower   ( u -- ) \ fold is true if byte 12 bit is set
    _d 12 + c@ and 0<> fold !
;

: do8.3 ( c-addr1 u1 -- c-addr2 u2 )
    dirent
    $08 canlower            \ bit 3: make basename lower-case
    8 0 part                \ basename
    _d 8 + c@ bl <> if
        $10 canlower        \ bit 4: make extension lower-case
        [char] . xfill
        11 8 part           \ extension
    then
;

: (read-dir) ( c-addr u1 dirid -- u2 )
    to dirid
    over >r     \ save starting c-addr
    begin
        dirent
        \ _d 32 dump
        d.attrib 0<>
    while
        _d c@ $e5 <>
        d.attrib $20 = and if
            lfn ( c-addr u1 )
            drop
            r> 2dup = if
                12 do8.3 drop
                swap
            then
            -
            exit
        then
    repeat
    r> drop

    2drop 0
;

create filename 256 allot

: searchdir ( c-addr u dirid -- 0 | 1 )
    >r
    begin
        2dup
        filename 256 r@ ['] (read-dir) catch throw
        ?dup
    while
        filename swap   ( c-addr u1 filename u2 )
        icompare
        0= if
            2drop
            -32 adjust dirent
            r> close-file throw
            1
            exit
        then
    repeat
    2drop 2drop
    r> close-file throw
    0
;

: setfile ( cluster size fs fileid -- ) \ set up a fileid
    >r
    r@ file-fs !
    r@ size !
    dup r@ f32-start !
    r@ f32-cur !
    0 r> position !
;

:noname ( c-addr u fam fat -- fileid ior )
    >r
    drop    \ xxx fam
    r@ root searchdir
    if
        d.cluster d.filesize r@         ( cluster size fs )
        fat-file fileid >r
        r@ setfile
        r> 0
    else
        1   \ error, open failed
    then
    r> drop
; fat defines fs-open

: clusterpart ( pos file -- cp )    \ cp is the cluster part of the pos
    file-fs @ cshift @ rshift
;

: nextcluster ( c fat -- c' ) \ follow cluster chain one step
    >r
    dup 127 and 2 lshift swap
    7 rshift                        ( offset block )
    r@ fat_begin_lba @ +            ( offset lba )
    r@ getsector
    r@ secbuf + ul@                 ( cluster' )
    r> drop
;

:noname  ( ud. fileid -- ior )
    >r
    drop
    dup                                 \ {
    r@ clusterpart                      ( seek' )
    r@ position @ r@ clusterpart        ( seek' cur' )
    2dup < if
        drop 0
        r@ f32-start @ r@ f32-cur !
    then
    begin
        2dup <>
    while
        \ advance to next cluster
        r@ f32-cur @                    ( cluster )
        r@ file-fs @ nextcluster
        r@ f32-cur !
        1+
    repeat
    2drop

    r@ position !                        \ }
    ok
    r> drop
; fat-file defines reposition-file

:noname ( fat -- fileid )
    >r
    r@ root_dir_first_cluster @     ( cluster )
    true                            ( cluster size )
    r>                              ( cluster size fs )
    fat-file
    fileid
    >r
    r@ setfile
    r>
; fat defines root


\ PUBLICWORDS     \ }{

sddev anew constant sd
fat anew constant c:

: bin   ;
: r/o   0 ;
: r/w   1 ;

: open-file  ( c-addr u fam -- fileid ior )
    c: fs-open
;

: cold
    cold
    sd init
    sd c: init
;

: cwd
    c: root
;

: cat
    bl parse
    r/o open-file throw >r
    begin
        pad 512 r@ read-file throw
        ?dup
    while
        pad swap type
    repeat
    r> drop
;

: open-dir
    2drop cwd 0
;

: read-dir ( c-addr u1 dirid -- u2 ior )
    ['] (read-dir) catch
;

: close-dir
    close-file
;

: ls
    root >r
    begin
        pad 256 r@ read-dir throw
        ?dup
    while
        cr
        pad swap
        2dup r/o open-file throw
        dup file-size throw
        10 d.r space
        close-file throw
        type
    repeat
    r> close-dir throw
;

\ DONEWORDS       \ }

previous    \ }
