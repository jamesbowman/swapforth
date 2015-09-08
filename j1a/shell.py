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

    def reset(self, fullreset = True):
        print 'reset'
        ser = self.ser
        ser.setDTR(1)
        if fullreset:
            ser.setRTS(1)
            ser.setRTS(0)
        ser.setDTR(0)
        if fullreset:
            time.sleep(0.1)

        for c in ' 1 tth !':
            ser.write(c)
            ser.flush()
            time.sleep(0.001)
            ser.flushInput()
            # print repr(ser.read(ser.inWaiting()))
        ser.write('\r')

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
        self.reset(False)

    def serialize(self):
        l = self.command_response('0 here dump')
        lines = l.strip().replace('\r', '').split('\n')
        s = []
        for l in lines:
            l = l.split()
            s += [int(b, 16) for b in l[1:17]]
        s = array.array('B', s).tostring().ljust(8192, chr(0xff))
        return array.array('H', s)

if __name__ == '__main__':
    swapforth.main(TetheredJ1a)
