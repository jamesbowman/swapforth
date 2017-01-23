\ Examples for the j4a's multitasking capabilities.
#include j4a_utils.fs
\ adds these words: on1 on2 on3 once kill1 kill2 kill3 stopall  killall  coreId

\ there is no operating system here - just four lots of cpu contexts (PC + stacks, sometimes called 'slots' or 'cores') which always round-robin (fine threading), each getting 1/4 of the processing power at all times

\ An IO device used to hold execution tokens (XT's) in a special IO register (the taskselect register, $4000),
\ which delivers a different XT depending upon which context did the read.

\ Note, It always reads as zero for slot zero, the 'programmers' UI thread.
\ If you want to use slot zero as well, do so as you would a j1a, with init.
\ You must use slot zero initially to assign XT's to the other cores, the XT's will reset to zero on boot.

\ It is read by code in swapforth which runs just before init does normally, you normally don't need to read it.
\ this splits the contexts apart and also implements a rudimentory task scheduler. (that code checks for zero before jumping into it)

\ It will re-run that word until something sets it to zero, so the 'begin again' part is taken care of for you.
\ Consider such a word to be the 'main' loop, running by itself repeatedly on it's own CPU.

\ And if 1 is added to the XT written there, it will be cleared when accessed the first time without changing which word is accessed
\ This alows for running a word just 'once' to initialise or alter the stack of a non-zero context.


\ note kill<x> will work from any slot, but the nonzero slots cannot reset slot zero, only slot zero can.
\ This is so you can't accidentally lock yourself out of the system by leaving a thread running, resetting slot0.


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

\ leds will count upward, but core0 of the j4a is still waiting to serve you. that was nice and easy, wasn't it?

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

' offleds once on1 \ Run a word just once, not repeatedly. Good for initialisation and cleanup after changing tasks.

\ Valid XT's are always even, the lsb is used to autoclear the taskexec register after it has been read once by the slot running it.
\ Note that it is not safe to write XT's one after the other to the same core - it takes several cycles for it to poll for the XT even if it's stopped. so a program with sequential writes *won't* result in each task running one after the next. Just use a new word if you want to do something like that.

\ one need not name one's code:
:noname -1 leds ; once \ :noname leaves it's XT on the stack.
  :noname 0 leds ; once swap on2 42 ms on3 \ one core turns leds on, the next will turn them off.
\ note that without 'once' these will 'fight', resulting in the LEDS's flashing at high speed.


\ initialise a core, run for a while, then nicely interrupt that core and clean up before stopping:
:noname 0 ; once on1 \ initialise a counter on core 1's stack
1 ms \ wait a little while, so core 1 does definitely get a chance to run.
:noname delay @ ms 1+ dup leds ; on1 \ uses just the stack to count on the leds
10000 ms
:noname drop 0 leds ; once on1 \ stops and cleans up the stack, also turns the leds off .
