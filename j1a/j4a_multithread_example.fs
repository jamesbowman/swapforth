\ Examples for the j4a's multitasking capabilities.

: assign1 ( xt -- ) $100 io! ;
: assign2 ( xt -- ) $200 io! ;
: assign3 ( xt -- ) $400 io! ;
: kill1 2 $4000 io! ;
: kill2 4 $4000 io! ;
: kill3 8 $4000 io! ;

\ note killx will only work from slot0, if called by numbered slots, they will only kill themselves.


variable display
variable delay

0 display !
42 delay !

: update display @ 1 + display ! ;
: show display @ leds ;
' show assign1 \ assigns show to slot 1. note no loop.

: t2 update delay @ ms ;
' t2 $200 assign2 \ assigns a timed update to slot 2, also no loop.

\ leds will count upward, but quit will still run.
\ try:
\ 10 delay !

: slowcount 0 0 do i leds 42 ms loop ;
' slowcount assign3 \ conflicts with the show thread, but both keep running anyway. Note that it has a loop. Will take ~3 hours to finish.



0 assign3 \ asks nicely, but does not stop slot 3, because it's paying no attention. (giving a good example of a locked thread).

kill3 \ selectively resets just the third slot, which does stop it.

0 assign1 0 assign2 \ ask the other two nicely to stop

: offleds 0 leds ;
' offleds 1 or assign1 \ Run a word just once, not continously. Good for initialisation and cleanup after changing tasks.
\ Valid XT's are always even, the lsb is used to autoclear the taskexec register after it has been read once by the slot running it.
