\ Mini-OOF                                                 12apr98py
: method ( m v "name" -- m' v ) Create  over , swap cell+ swap
  DOES> ( ... o -- ... ) @ over @ + @ execute ;
: var ( m v size "name" -- m v' ) Create  over , +
  DOES> ( o -- addr ) @ + ;
: class ( class -- class methods vars ) dup 2@ ;
: end-class  ( class methods vars "name" -- )
  Create  here >r , dup , 2 cells ?DO ['] noop , 1 cells +LOOP
  cell+ dup cell+ r> rot @ 2 cells /string move ;
: >vt ( class "name" -- addr )  ' >body @ + ;
: bind ( class "name" -- xt )    >vt @ ;
: defines ( xt class "name" -- ) >vt ! ;
\ : new ( class -- o )  align here over @ allot tuck ! ;
: :: ( class "name" -- ) bind compile, ;
Create object  1 cells , 2 cells ,
