#!/usr/bin/env python
from __future__ import print_function

import sys
import time
import array
import os

sys.path.append("../shell")
import swapforth

class TetheredJ1a(swapforth.TetheredTarget):
    cellsize = 2

    def open_ser(self, port, speed):
        try:
            import serial
        except:
            print("This tool needs PySerial, but it was not found")
            sys.exit(1)
        self.ser = serial.Serial(port, 4 * 115200, timeout=None, rtscts=0)

    def reset(self, fullreset = True):
        ser = self.ser
        ser.setDTR(1)
        if fullreset:
            ser.setRTS(1)
            ser.setRTS(0)
        ser.setDTR(0)
        
        def waitcr():
            while ser.read(1) != chr(10):
                pass

        waitcr()
        ser.write(b'\r')
        waitcr()

        for c in ' 1 tth !':
            ser.write(c.encode('utf-8'))
            ser.flush()
            time.sleep(0.001)
            ser.flushInput()
            # print(repr(ser.read(ser.inWaiting())))
        ser.write(b'\r')

        while 1:
            c = ser.read(1)
            # print(repr(c))
            if c == b'\x1e':
                break

    def boot(self, bootfile = None):
        sys.stdout.write('Contacting... ')
        self.reset()
        print('established')

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
