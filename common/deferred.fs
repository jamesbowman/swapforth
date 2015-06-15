: defer ( "name" -- )
  create ['] abort ,
does> ( ... -- ... )
  @ execute ;

: defer@ ( xt1 -- xt2 )
  >body @ ;

: defer! ( xt2 xt1 -- )
  >body ! ;

: is
  state @ if
    POSTPONE ['] POSTPONE defer!
  else
    ' defer!
  then ; immediate

: action-of
 state @ if
   POSTPONE ['] POSTPONE defer@
 else
   ' defer@
then ; immediate
