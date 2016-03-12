\ ANS Forth tests - run all tests

\ Adjust the file paths as appropriate to your system
\ Select the appropriate test harness, either the simple tester.fr
\ or the more complex ttester.fs 

CR .( Running ANS Forth and Forth 2012 test programs, version 0.11) CR

include tester.fr
include core.fr

include coreplustest.fth
include errorreport.fth
include coreexttest.fth
include doubletest.fth
include ../localtests/div.fs
include facilitytest.fth
include toolstest.fth
include stringtest.fth
REPORT-ERRORS
#bye
\ include exceptiontest.fth
\ \ include filetest.fth
\ \ include localstest.fth
\ include memorytest.fth
\ \ include searchordertest.fth

CR CR .( Forth tests completed ) CR CR



