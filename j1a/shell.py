#!/usr/bin/env python

import sys
from datetime import datetime
import time
import array
import struct
import os

try:
    import serial
except:
    print "This tool needs PySerial, but it was not found"
    sys.exit(1)

sys.path.append("../shell")
import swapforth

class TetheredJ1a(swapforth.TetheredTarget):
    cellsize = 2

    def reset(self):
        ser = self.ser
        ser.setDTR(1)
        ser.setDTR(0)

        for c in ' 1 tth !\r':
            ser.write(c)
            ser.flush()
            ser.flushInput()
            # print repr(ser.read(ser.inWaiting()))

        sys.stdout.flush()
        while 1:
            c = ser.read(1)
            # print repr(c)
            if c == chr(30):
                break

    def boot(self, bootfile = None):
        sys.stdout.write('Contacting... ')
        self.reset()
        print 'established'

    def interrupt(self):
        self.reset()
        
if __name__ == '__main__':
    port = '/dev/ttyUSB0'

    r = None
    searchpath = []

    args = sys.argv[1:]
    while args:
        a = args[0]
        if a.startswith('-h'):
            port = args[1]
            args = args[2:]
        elif a.startswith('-p'):
            searchpath.append(args[1])
            args = args[2:]
        else:
            if not r:
                r = TetheredJ1a(port)
                r.boot()
                r.searchpath += searchpath
            if a.startswith('-e'):
                print r.shellcmd(args[1])
                args = args[2:]
            else:
                try:
                    r.include(a)
                except swapforth.Bye:
                    pass
                args = args[1:]
    if not r:
        r = TetheredJ1a(port)
        r.boot()
        r.searchpath += searchpath

    r.shell()
