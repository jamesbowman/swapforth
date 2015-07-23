\  Date of Easter According to Knuth

\  Donald E. Knuth, _The Art of Computer Programming_, 1.3.2 Exercise
\  14-15.

\  [Commentary by Knuth, Forth by Wil Baden. This is not well-suited
\  for Forth, but there's no advantage in purifying it.]

\  The following algorithm, due to the Neapolitan astronomer Aloysius
\  Lilius and the German Jesuit mathematician Christopher Clavius in
\  the late 16th century, is used by most Western churches to
\  determine the date of Easter Sunday for any year after 1582.

: ANDIF   S" DUP IF DROP " EVALUATE ; IMMEDIATE

: ORIF   S" DUP 0= IF DROP " EVALUATE ; IMMEDIATE


\          Counters.

\  Y
\     Year.

\  G
\     Golden number.

\  C
\     Century.

\  X
\     Century leap year adjustment.

\  Z
\     Moon's orbit adjustment.

\  D
\     Sunday date.

\  E
\     Epact.

\  N
\     Day of month.

VARIABLE Y  \  Year
VARIABLE G  \  Golden number
VARIABLE C  \  Century
VARIABLE X  \  Century leap year adjustment
VARIABLE Z  \  Moon's orbit adjustment
VARIABLE D  \  Sunday date
VARIABLE E  \  Epact
VARIABLE N  \  Day of month

\  EASTER            ( yyyyy -- dd mm yyyyy )
\     Compute date of Easter for year _yyyyy_.

: EASTER            ( yyyyy -- dd mm yyyyy )

    Y !                      ( )

    \  E1. Golden number.
    \  _G_ is the so-called "golden number" of the year in the 
    \  19-year Metonic cycle. 

    Y @  19 MOD  1+  G !

    \  E2. Century.
    \  When _Y_ is not a multiple of 100, _C_ is the century number; 
    \  for example, 1984 is in the twentieth century. 

    Y @  100 /  1+  C !

    \  E3. Corrections.
    \  Here _X_ is the number of years, such as 1900, in which leap 
    \  year was dropped in order to keep in step with the sun; _Z_ is 
    \  a special correction designed to synchronize Easter with the 
    \  moon's orbit. 

    C @  3 4 */  12 -  X !
    C @  8 *  5 +  25 /  5 -  Z !

    \  E4. Find Sunday.
    \  March ((-_D_) mod 7) actually will be a Sunday.

    Y @  5 4 */  X @ -  10 -  D !

    \  E5. Epact.
    \  This number _E_ is the _epact_, which specifies when a full
    \  moon occurs.

    G @  11 *  20 +  Z @ +  X @ -  30 MOD
        dup 0< IF  30 +  THEN
        E !
    E @  25 =  ANDIF  G @  11 >  THEN
    ORIF  E @ 24 =  THEN
        IF  1 E +!  THEN

    \  E6. Find full moon.
    \  Easter is supposedly the first Sunday following the first full 
    \  moon that occurs on or after March 21.  Actually perturbations 
    \  in the moon's orbit do not make this strictly true, but we are 
    \  concerned here with the "calendar moon" rather than the actual 
    \  moon.  The _N_th of March is a calendar full moon. 

    44  E @ -  N !
    N @  21 < IF  30 N +!  THEN

    \  E7. Advance to Sunday.

    N @  7 +
    D @  N @ +  7 MOD  -
    N !

    \  E8.  Get month.

    N @  31 > IF
        N @  31 -  4  Y @
    ELSE
        N @  3  Y @
    THEN ;

\  .EASTER             ( yyyyy -- )
\     Display date of Easter for year _yyyyy_.

: .EASTER      ( yyyyy -- )
    EASTER  .  4 = IF  ." April "  ELSE  ." March " THEN . ;

