import sys
import time
import struct
import array

sys.path.append("../shell")
import swapforth

class FT900Bootloader:
    def __init__(self, ser):
        self.ser = ser
        # self.verbose = True
        self.cumcrc = 0

    cellsize = 4

    def rd1(self):
        """ Return the last incoming character, if any """
        n = self.ser.inWaiting()
        if n:
            r = self.ser.read(n)
            return r[-1]
        else:
            return None

    def waitprompt(self):
        # Might already be at the bootloader prompt
        if self.rd1() == '>':
            return

        # Might be at prompt already, or halted. Send ' '
        self.ser.write(' ')
        self.ser.flush()
        time.sleep(0.001)
        if self.rd1() == '>':
            return

        # Is somewhere else, request manual reset
        print "Please press RESET on target board"
        while True:
            s = self.ser.read(1)
            print repr(s)
            if s == ">":
                break
        print "OK, device reset"

    def confirm(self):
        self.ser.write("C")
        return struct.unpack("I", self.ser.read(4))[0]

    def version(self):
        self.ser.write("V")
        return struct.unpack("I", self.ser.read(4))[0]

    def pmcrc32(self, a, sz):
        t0 = time.time()
        self.ser.write("Q" + struct.pack("II", a, sz))
        (r, ) = struct.unpack("I", self.ser.read(4))
        if self.verbose:
            t = time.time() - t0
            self.cumcrc += t
            print 'crc', sz, t, self.cumcrc
        return r

    def flashcrc32(self, a, sz):
        t0 = time.time()
        self.ser.write("G" + struct.pack("II", a, sz))
        (r, ) = struct.unpack("I", self.ser.read(4))
        if self.verbose:
            t = time.time() - t0
            self.cumcrc += t
            print 'crc', sz, t, self.cumcrc
        return r

    def ex(self, ):
        self.ser.write("R")
        self.ser.flush()

    def setspeed(self, s):
        if hasattr(self.ser, 'setBaudrate'):
            self.ser.write("S" + struct.pack("I", s))
            self.ser.flush()
            time.sleep(.001)
            self.ser.setBaudrate(s)
            self.ser.flushInput()
            self.ser.flushOutput()

    def loadprogram(self, program):
        pstr = program.tostring()
        self.ser.write("P" + struct.pack("II", 0, len(pstr)))
        self.ser.write(pstr)

    def flash(self, addr, s):
        self.ser.write('F' + struct.pack("II", addr, len(s)) + s)
        (answer, ) = struct.unpack("I", self.ser.read(4))
        assert answer == 0xf1a54ed

    def hardboot(self, ):
        self.ser.write("H")
        self.ser.flush()

class TetheredFT900(swapforth.TetheredTarget):

    def boot(self, bootfile = None):
        ser = self.ser
        speed = 921600
        bl = FT900Bootloader(ser)
        ser.setDTR(1)
        ser.setRTS(1)
        ser.setDTR(0)
        ser.setRTS(0)
        bl.waitprompt()

        time.sleep(.001)
        ser.flushInput()

        if bl.confirm() != 0xf70a0d13:
            print 'CONFIRM command failed'
            sys.exit(1)
        bl.setspeed(speed)

        if bl.confirm() != 0xf70a0d13:
            print 'High-speed CONFIRM command failed'
            sys.exit(1)
        if bootfile is not None:
            program = array.array('I', open(bootfile).read())
            bl.loadprogram(program)
        bl.ex()

        time.sleep(.05)
        while True:
            n = ser.inWaiting()
            if not n:
                break
            ser.read(n)

        ser.write("true tethered !\r\n")
        while ser.read(1) != chr(30):
            pass

    def interrupt(self):
        self.ser.write(chr(3))
        self.ser.flush()
        while self.ser.read(1) != chr(30):
            pass

if __name__ == '__main__':
    swapforth.main(TetheredFT900)
