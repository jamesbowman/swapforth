                                              \  Wil Baden  1998-08-26

\  *******************************************************************
\  *     FPH Popular Extensions                                      *
\  *******************************************************************

\  <A HREF="http://www.forth.com/Content/Handbook/Handbook.html">
\         Forth Programmer's Handbook, Conklin and Rather
\  </A>

\  With _Forth Programmer's Handbook_, ISBN 0-9662156-0-5, as an 
\  authoritative work about contemporary Forth, for portability 
\  today's Forth implementations and tutorials should agree with it 
\  when possible. 

\
\  Here are words that are in FPH but not in Standard Forth.
\
\  GLOSSARY
\
\     .'          CURRENT     INCLUDE     M/          WH
\     2+          CVARIABLE   IS          NOT         WHERE
\     2-          DASM        L           T*          [DEFINED]
\     C+!         DEFER       LOCATE      T/          [UNDEFINED]
\     CONTEXT     EMPTY       M-          VOCABULARY
\
\  /GLOSSARY
\
\  These words are in common usage. Some of them are implementation 
\  dependent. Others have simple definitions in Standard Forth. 
\  Potential definitions for those which can be defined in Standard 
\  Forth are given here for systems that are missing them. 
\
\  Comment out definitions that you already have or are
\  improving.
\
\  Definitions in Standard Forth by Wil Baden.  Any similarity
\  with anyone else's code is coincidental, historical, or
\  inevitable.

\  2+                           ( n -- n+2 )
\     Add 2 to the top of stack.

\  2-                           ( n -- n-2 )
\     Subtract 2 from the top of stack.

\  C+!                          ( n addr -- )
\     Add the low-order byte of _n_ to the byte at _addr_,
\     removing both from the stack.

\  DEFER                        ( "name" -- )
\     Define _name_ as an execution vector. When _name_ is
\     executed, the execution token stored in _name_'s data area
\     will be retrieved and its behavior performed. An abort
\     will occur if _name_ is executed before it has been
\     initialized.

\  EMPTY                        ( -- )
\     Reset the dictionary to a predefined golden state,
\     discarding all definitions and releasing all allocated
\     data space beyond that state.

\  INCLUDE                      ( "filename" -- )
\     Include the named file.

\  IS                           ( xt "name" -- )
\     Store _xt_ in _name_, where _name_ is a word defined by
\     `DEFER`.

\  M*/                          ( d . n u -- d . )
\     Multiply _d._ by _n_ to triple result; divide by _u_ to double
\     result.  [Double]

\  M-                           ( d . n --  d . )
\     Subtract single number _n_ from double number _d._.

\  M/                           ( d . n -- q )
\     Divide double number _d._ by single number _n_.

\  NOT                          ( x -- flag )
\     Identical to `0=`, used for program clarity to reverse the
\     result of a previous test.

\  T*                           ( d . n -- t . . )
\     Multiply a double number by a single number to get a triple number.

\  T/                           ( t . . u -- d . )
\     Divide a triple number by an unsigned number to get a double
\     answer.

\  [DEFINED]                    ( "name" -- flag )
\     Search the dictionary for _name_. If _name_ is found,
\     return TRUE; otherwise return FALSE. Immediate for use in
\     definitions.

\  [UNDEFINED]                  ( "name" -- flag )
\     Search the dictionary for _name_. If _name_ is found,
\     return FALSE; otherwise return TRUE. Immediate for use in
\     definitions.

\  VOCABULARY                   ( "name" -- )
\     Create a word list _name_. Subsequent execution of _name_
\     replaces the first word list in the search order with
\     _name_. When _name_ is made the compilation word list, new
\     definitions will be added to _name_'s list.

: 2+  ( n -- n+2 )  2 + ;

: 2-  ( n -- n-2 )  2 - ;

: C+! ( n addr -- ) dup >R C@ + R> C! ;

: M-  ( d . n -- d . )  NEGATE M+ ;

: M/  ( d . n -- q )  SM/REM NIP ;

: NOT ( n -- flag ) S" 0= " EVALUATE ; IMMEDIATE

: [DEFINED]                       ( "name" -- flag )
    BL WORD FIND NIP 0<> ; IMMEDIATE

: [UNDEFINED]                     ( "name" -- flag )
    BL WORD FIND NIP 0= ; IMMEDIATE

[DEFINED] WORDLIST [IF]

    \  From Standard Forth Rationale A.16.6.2.0715.

    : Do-Vocabulary                   ( -- )
        DOES>  @ >R                     ( )( R: widnew)
            GET-ORDER  NIP              ( wid_n ... wid_2 n)
        R> SWAP SET-ORDER ;

: VOCABULARY                      ( "name" -- )
    WORDLIST CREATE ,  Do-Vocabulary ;
[THEN]
