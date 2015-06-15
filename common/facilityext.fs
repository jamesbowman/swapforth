\ #######   FACILITY EXT   ####################################

: csi \ Control Sequence Introducer
    27 emit '[' emit
;

: at-xy ( u1 u2 ) \ cursor to column u1, row u2
    csi
    1+ 0 u.r
    ';' emit
    1+ 0 u.r
    'H' emit
;

: page
    0 0 at-xy
    csi 'J' emit
;
