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

import swapforth as sf

class TetheredJ1b(sf.TetheredFT900):
    def __init__(self, port):
        ser = serial.Serial(port, 921600, timeout=None, rtscts=0)
        self.ser = ser
        self.searchpath = ['.']
        self.log = open("log", "w")

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

if __name__ == '__main__':
    port = '/dev/ttyUSB0'
    image = None

    r = None
    searchpath = []

    args = sys.argv[1:]
    while args:
        a = args[0]
        if a.startswith('-i'):
            image = args[1]
            args = args[2:]
        elif a.startswith('-h'):
            port = args[1]
            args = args[2:]
        elif a.startswith('-p'):
            searchpath.append(args[1])
            args = args[2:]
        else:
            if not r:
                r = TetheredJ1b(port)
                r.boot(image)
                r.searchpath += searchpath
            if a.startswith('-e'):
                print r.shellcmd(args[1])
                args = args[2:]
            else:
                try:
                    r.include(a)
                except sf.Bye:
                    pass
                args = args[1:]
    if not r:
        r = TetheredJ1b(port)
        r.boot(image)
        r.searchpath += searchpath

    # print repr(r.ser.read(1))
    # r.interactive_command(None)
    # r.listen()
    r.shell()
