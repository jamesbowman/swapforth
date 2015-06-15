: begin-structure       \ -- addr 0 ; -- size
\ *G Begin definition of a new structure. Use in the form
\ ** *\fo{BEGIN-STRUCTURE }. At run time *\fo{}
\ ** returns the size of the structure.
  create
    here 0  0 ,                         \ mark stack, lay dummy
  does> @  ;                            \ -- rec-len

: end-structure         \ addr n --
\ *G Terminate definition of a structure.
  swap !  ;                             \ set len

: +FIELD                 \ n <"name"> -- ; Exec: addr -- 'addr
\ *G Create a new field within a structure definition of size n bytes.
  create
    over , +
  does>
    @ +
;

: cfield:       \ n1 <"name"> -- n2 ; Exec: addr -- 'addr
\ *G Create a new field within a structure definition of size 1 CHARS.
  1 chars +FIELD
;

: field:        \ n1 <"name"> -- n2 ; Exec: addr -- 'addr
\ *G Create a new field within a structure definition of size 1 CELLS.
\ ** The field is ALIGNED.
  aligned  1 cells +FIELD
;

: ffield:       \ n1 <"name"> -- n2 ; Exec: addr -- 'addr
\ *G Create a new field within a structure definition of size 1 FLOATS.
\ ** The field is FALIGNED.
  faligned  1 floats +FIELD
;
