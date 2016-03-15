\ Examples for the j4a's multitasking capabilities.
\ You probably don't want to #include this

: on1 ( xt -- ) $100 io! ;
: on2 ( xt -- ) $200 io! ;
: on3 ( xt -- ) $400 io! ;
: once ( standard/looping xt -- runonce xt ) 1 or ;
: kill1 0 on1 2 $4000 io! ;
: kill2 0 on2 4 $4000 io! ;
: kill3 0 on3 8 $4000 io! ;
: stopall 0 on1 0 on2 0 on3 ;
: killall kill1 kill2 kill3 ;
\ note killx will only work from slot0, if called by numbered slots, they will only kill themselves.

\ and now for very simple "model-view-controller" app
\ this exploitsthe j4's architecture to break the system design into separate, simple pieces

variable display
variable delay

0 display !
42 delay !


: show display @ leds ; \ this is the "view" in a MVC. You might have a more complicated "display" function.

' show on1 \ assigns show to slot 1. note no loop.

: update display @ 1 + display ! ; \ this is the "model" in a MVC pattern

: t2 update delay @ ms ;
' t2 on2 \ assigns a timed update to slot 2, also no loop.

\ leds will count upward, but quit will still run. that was nice and easy, wasn't it?


\ try:
\ 10 delay !
\ here, user interaction via quit is the "controller" in the MVC pattern, but we could just as well have a small loop polling some switches, running on3

\ now let's sabotage our system:
: slowcount 0 0 do i leds 10 ms loop ;
' slowcount on3 \ conflicts with the show thread, but both keep running anyway.
\ Note that it has a loop. this will take ~3 hours to finish, then will run repeatedly since we forgot to mark it to run just once.


0 on3 \ asks nicely, but does not stop slot 3, because it's paying no attention. (giving a good example of a locked thread).
\ 0 is treated as a special case, it causes the core to just sit and poll again, effectively "stopping" it.

kill3 \ selectively resets just the third slot, which does do a nondiscretionary interrupt. Also resets its stacks.
\ note that CTRL-C in the python shell will reset all cores, clearing the stacks, but won't clear the XT's.

0 on1 0 on2 \ ask the other two nicely to stop, in between iterations. A "cooperative" interrupt if you will
0 leds \ the led's would be left in whatever state, so we have to clean up ourselves.

: offleds 0 leds ;
' offleds once on1 \ Run a word just once, not continously. Good for initialisation and cleanup after changing tasks.
\ Valid XT's are always even, the lsb is used to autoclear the taskexec register after it has been read once by the slot running it.
\ Note that it is not safe to write XT's one after the other to the same core - it takes several cycles for it to poll for the XT even if it's stopped. so a program with sequential writes *won't* result in each task running one after the next.

\ one need not name one's code:
:noname -1 leds ; once
  :noname 0 leds ; once swap on2 on3 \ one core turns leds on, the next will turn them off.
\ note that without 'once' these will 'fight', resulting in the LEDS's flashing at high speed.


\ initialise a core, run for a while, then nicely interrupt that core and clean up before stopping
:noname 0 ; on1 \ initialise a counter on core 1's stack
1 ms \ wait a little while, so core 1 does definitely get a chance to run.
:noname delay @ ms 1+ dup leds ; on1 \ uses just the stack to count on the leds
10000 ms
:noname drop 0 leds ; once on1 \ stops and cleans up the stack, also turns the leds off .
