\ Examples for the j4a's multitasking capabilities.

: assign1 ( xt -- ) $100 io! ;
: assign2 ( xt -- ) $200 io! ;
: assign3 ( xt -- ) $400 io! ;
: kill1 2 $4000 io! ;
: kill2 4 $4000 io! ;
: kill3 8 $4000 io! ;
: slotid $8000 io@ ;
: once 1+ ;

\ there is no operating system here - just four lots of cpu contexts (PCs, stacks) which always round-robin (fine threading)
\ as well as an IO device used to hold execution tokens (XT's) in a special register (the taskselect register, $4000),
\ which delivers a different XT depending upon which context did the read.

\ Note, It always reads as zero for slot zero, the 'programmers' UI thread.

\ It is read by code in swapforth which runs just before init does normally, you normally don't need to read it.
\ this splits the contexts apart and also implements a rudimentory task scheduler. (that code checks for zero before jumping into it)

\ It will re-run that word until something sets it to zero, so the 'begin again' part is taken care of for you.

\ And if one is added to the XT written there, it will be cleared when accessed the first time.
\ This alows for running a word to initialise or alter the stack of a non-zero context.


\ note killx will work from any slot, but the nonzero slots cannot reset slot zero, only slot zero can.


variable display
variable delay

0 display !
42 delay !

: update display @ 1 + display ! ;
: show display @ leds ;
' show assign1 \ assigns show to slot 1. note no loop.

: t2 update delay @ ms ;
' t2 assign2 \ assigns a timed update to slot 2, also no loop.

\ leds will count upward, but quit will still run.
\ try:
\ 10 delay !

: slowcount 0 0 do i leds 42 ms loop ;
' slowcount assign3 \ conflicts with the show thread, but both keep running anyway. Note that it has a loop. Will take ~3 hours to finish.



0 assign3 \ asks nicely, but does not stop slot 3, because it's paying no attention. (giving a good example of a locked thread).

kill3 \ selectively resets just the third slot, which does stop it.

0 assign1 0 assign2 \ ask the other two nicely to stop

: offleds 0 leds ;
' offleds once assign1 \ Run a word just once, not repeatedly. Good for initialisation and cleanup after changing tasks.
\ Valid XT's are always even, the lsb is used to autoclear the taskexec register after it has been read once by the slot running it.
