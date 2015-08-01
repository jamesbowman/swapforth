\ #######   TOOLS   ###########################################

: ?
    @ .
;

: hex2. ( u -- )
    base @ swap
    hex
    s>d <# # # #> type space
    base !
;

: dump
    ?dup
    if
        base @ >r hex
        1- 4 rshift 1+
        0 do
            cr dup dup 8 u.r space space
            16 0 do
                dup c@ hex2. 1+
            loop
            space swap
            16 0 do
                dup c@ 127 and
                dup 0 bl within over 127 = or
                if drop [char] . then
                emit 1+
            loop
            drop
        loop
        r> base !
    then
    drop
;

: (.s)
    depth if
        >r recurse r>
        dup .
    then
;

: .s
    [char] < emit depth 0 .r [char] > emit space
    (.s)
;

\ #######   TOOLS EXT   #######################################

\ From ANS specification A.15.6.2.2533

: [ELSE]  ( -- )
    1 begin                               \ level
      begin
        bl word count dup  while          \ level adr len
        2dup  s" [IF]"  compare 0=
        if                                \ level adr len
          2drop 1+                        \ level'
        else                              \ level adr len
          2dup  s" [ELSE]"
          compare 0= if                   \ level adr len
             2drop 1- dup if 1+ then      \ level'
          else                            \ level adr len
            s" [THEN]"  compare 0= if     \ level
              1-                          \ level'
            then
          then
        then ?dup 0=  if exit then        \ level'
      repeat  2drop                       \ level
    refill 0= until                       \ level
    drop
;  immediate

: [IF]  ( flag -- )
0= if postpone [ELSE] then ;  immediate

: [THEN]  ( -- )  ;  immediate

: cs-pick   pick ;
: cs-roll   roll ;

: [defined] bl word find nip 0<> ; immediate
: [undefined] postpone [defined] 0= ; immediate
