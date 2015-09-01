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

class TetheredJ1b(swapforth.TetheredTarget):
    def __init__(self, port):
        ser = serial.Serial(port, 921600, timeout=None, rtscts=0)
        self.ser = ser
        self.searchpath = ['.']
        self.log = open("log", "w")
        self.interpreting = True
        self.verbose = False

    def boot(self, bootfile = None):
        ser = self.ser
        ser.setDTR(1)
        ser.setDTR(0)

        def trim(L):
            while L[-1] == 0:
                L = L[:-1]
            return L.tostring()

        if bootfile is not None:
            boot = array.array('I', [int(l, 16) for l in open(bootfile)])

            code = trim(boot[:0x3f80 / 4])    # remove bootloader itself (top 128 bytes)

            data = trim(boot[0x4000 / 4:])

            print 'sizes:', len(code), len(data)

            ser.write(chr(27))
            print 'wrote 27'
            # print repr(ser.read(1))

            ser.write(struct.pack('II', len(code), 0))
            ser.write(code)
            ser.write(struct.pack('II', len(data) + 0x4000, 0x4000))
            ser.write(data)
            print 'completed load of %d+%d bytes' % (len(code), len(data))
        while 1:
            c = ser.read(1)
            print  repr(c)
            if c == chr(30):
                break
        if 0:
            ser.write('115200 $1008 io!\r')
            self.ser.flush()
            time.sleep(.010)
            # self.ser.setBaudrate(921600)
            # self.ser.flushInput()
            # self.ser.flushOutput()
            print 'all set'
            print repr(self.ser.read(1))
            while 1:
                c = ser.read(1)
                print  repr(c)
                if c == chr(30):
                    break

    def reset(self):
        ser = self.ser
        ser.setDTR(1)
        ser.setDTR(0)
        time.sleep(0.01)

        while 1:
            c = ser.read(1)
            print repr(c)
            if c == chr(30):
                break

    def interrupt(self):
        self.reset()

if __name__ == '__main__':
    swapforth.main(TetheredJ1b)
