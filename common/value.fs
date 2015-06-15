\ Portable implementation of VALUE, etc
\ The first cell of a VALUE is the XT of the "TO" word.
\ Subsequent cells are the value itself.
\
\ For example, "3 VALUE FOO" makes
\
\   FOO:    +---------+
\           |    !    |
\           +---------+
\           |    3    |
\           +---------+
\
\ and "100 200 2VALUE BAR" makes
\
\   BAR:    +---------+
\           |    2!   |
\           +---------+
\           |   200   |
\           +---------+
\           |   100   |
\           +---------+
\

: value
    create ['] ! , ,
    does> cell+ @
;

: 2value
    create ['] 2! , , ,
    does> cell+ 2@
;

: to
    ' >body
    dup cell+
    state @ if
        postpone literal
        @ compile,
    else
        swap @ execute
    then
; immediate
