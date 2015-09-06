#!/usr/bin/env python

import sys
from datetime import datetime
import time
import array
import struct
import os

import dpansf


class Bye(Exception):
    pass

def collect_screenshot(dest, ser):
    import Image
    t0 = time.time()
    match = "!screenshot"
    have = "X" * len(match)
    while have != match:
        have = (have + ser.read(1))[-len(match):]
    (w, h) = struct.unpack("II", ser.read(8))
    print '%dx%d image' % (w, h),
    sys.stdout.flush()
    if 0:
        imd = ser.read(4 * w * h)
        im = Image.fromstring("RGBA", (w, h), imd)
    else:
        # print [ord(c) for c in ser.read(20)]
        def getn():
            b = ord(ser.read(1))
            n = b
            while b == 255:
                b = ord(ser.read(1))
                n += b
            # print '  length', n
            return n
                
        imd = ""
        for y in range(h):
            # print 'line', y
            prev = 4 * chr(0)
            d = ""
            while len(d) < 4 * w:
                # print '  have', len(d) / 4
                d += prev * getn()
                d += ser.read(4 * getn())
                prev = d[-4:]
            assert len(d) == 4 * w, 'corrupted screen dump stream'
            imd += d
        im = Image.fromstring("RGBA", (w, h), imd)
    (b,g,r,a) = im.split()
    im = Image.merge("RGBA", (r, g, b, a))
    im.convert("RGB").save(dest)
    took = time.time() - t0
    print 'took %.1fs. Wrote RGB image to %s' % (took, dest)
    ser.write('k')

class TetheredTarget:
    verbose = True
    cellsize = 4

    def __init__(self, port):
        self.open_ser(port, 115200)
        self.searchpath = ['.']
        self.log = open("log", "w")
        self.interpreting = True

    def open_ser(self, port, speed):
        try:
            import serial
        except:
            print "This tool needs PySerial, but it was not found"
            sys.exit(1)
        self.ser = serial.Serial(port, speed, timeout=None, rtscts=0)

    def custom(self):
        self.tex = open("log.tex", "wt")
        self.texlog(r"\begin{framed}" + '\n')
        self.texlog(r"\begin{Verbatim}[commandchars=\\\{\}]" + '\n')
        self.verbose = True

    def texlog(self, s):
        self.tex.write(s.replace('\r', '\n'))

    def listen(self):
        print 'listen'
        while 1:
            c = self.ser.read(1)
            print repr(c)

    def command_response(self, cmd):
        ser = self.ser
        # print
        # print 'cmd', repr(cmd)
        ser.write(cmd + '\r')
        r = []
        while True:
            c = ser.read(max(1, ser.inWaiting()))
            # print 'got', repr(c)
            r.append(c.replace(chr(30), ''))
            if chr(30) in c:
                # print 'full reponse', repr("".join(r))
                return "".join(r)

    def interactive_command(self, cmd = None):
        ser = self.ser
        if cmd is not None:
            ser.write(cmd + '\r')
        r = []
        while True:
            if ser.inWaiting() == 0:
                sys.stdout.flush()
            c = ser.read(max(1, ser.inWaiting()))
            clean = c.replace(chr(30), '')
            sys.stdout.write(clean)
            r.append(clean)
            if chr(30) in c:
                r = "".join(r)
                self.log.write(r)
                self.texlog(r)
                self.interpreting = r.endswith(' ok\r\n')
                return r

    def include(self, filename, write = sys.stdout.write):

        for p in self.searchpath:
            try:
                incf = open(p + "/" + filename, "rt")
            except IOError:
                continue
            for l in incf:
                # time.sleep(.001)
                # sys.stdout.write(l)
                while l.endswith('\n') or l.endswith('\r'):
                    l = l[:-1]
                if self.verbose:
                    print repr(l)
                if l == "#bye":
                    raise Bye
                l = l.expandtabs(4)
                rs = l.split()
                if rs and rs[0] == 'include':
                    self.include(rs[1])
                elif l.startswith('#'):
                    self.shellcmd(l)
                else:
                    r = self.command_response(l)
                    if r.startswith(' '):
                        r = r[1:]
                    if r.endswith(' ok\r\n'):
                        r = r[:-5]
                    if 'error: ' in r:
                        print '--- ERROR ---'
                        sys.stdout.write(l + '\n')
                        sys.stdout.write(r)
                        raise Bye
                    else:
                        write(r)
                        # print repr(r)
                        self.log.write(r)
            return
        print "Cannot find file %s in %r" % (filename, self.searchpath)
        raise Bye

    def serialize(self):
        l = self.command_response('serialize')
        return [int(x, 36) for x in l.split()[:-1]]

    def shellcmd(self, cmd):
        ser = self.ser
        if cmd.startswith('#noverbose'):
            self.verbose = False
        elif cmd.startswith('#include'):
            cmd = cmd.split()
            if len(cmd) != 2:
                print 'Usage: #include <source-file>'
            else:
                try:
                    self.include(cmd[1])
                except Bye:
                    pass
        elif cmd.startswith('#flash'):
            cmd = cmd.split()
            if len(cmd) != 2:
                print 'Usage: #flash <dest-file>'
                ser.write('\r')
            else:
                print 'please wait...'
                dest = cmd[1]
                d = self.serialize()
                print 'Image is', self.cellsize*len(d), 'bytes'
                if self.cellsize == 4:
                    if dest.endswith('.hex'):
                        open(dest, "w").write("".join(["%08x\n" % (x & 0xffffffff) for x in d]))
                    else:
                        open(dest, "wb").write(array.array("i", d).tostring())
                else:
                    if dest.endswith('.hex'):
                        open(dest, "w").write("".join(["%04x\n" % (x & 0xffff) for x in d]))
                    else:
                        open(dest, "wb").write(array.array("h", d).tostring())
        elif cmd.startswith('#setclock'):
            n = datetime.utcnow()
            cmd = "decimal %d %d %d %d %d %d >time&date" % (n.second, n.minute, n.hour, n.day, n.month, n.year)
            ser.write(cmd + "\r\n")
            ser.readline()
        elif cmd.startswith('#bye'):
            sys.exit(0)
        elif cmd.startswith('#invent'):
            def pp(s):
                return " ".join(sorted(s))
            words = sorted((self.command_response('words')).upper().split()[:-1])
            print 'duplicates:', pp(set([w for w in words if words.count(w) > 1]))
            print 'have CORE words: ', pp(set(dpansf.words['CORE']) & set(words))
            print 'missing CORE words: ', pp(set(dpansf.words['CORE']) - set(words))
            print
            print pp(words)
            allwords = {}
            for ws in dpansf.words.values():
                allwords.update(ws)
            print 'unknown: ', pp(set(words) - set(allwords))
            print 'extra:', pp(set(allwords) & (set(words) - set(dpansf.words['CORE'])))
            extra = (set(allwords) & (set(words) - set(dpansf.words['CORE'])))
            if 0:
                for w in sorted(extra):
                    ref = allwords[w]
                    part = ref[:ref.index('.')]
                    print '\href{http://forth.sourceforge.net/std/dpans/dpans%s.htm#%s}{\wordidx{%s}}' % (part, ref, w.lower())
        elif cmd.startswith('#time '):
            t0 = time.time()
            r = self.shellcmd(cmd[6:])
            t1 = time.time()
            print r
            print 'Took %.6f seconds' % (t1 - t0)
        elif cmd.startswith('#measure'):
            ser = self.ser
            # measure the board's clock
            cmd = ":noname begin $21 emit 100000000 0 do loop again ; execute\r\n"
            time.time() # warmup
            ser.write(cmd)
            while ser.read(1) != '!':
                pass
            t0 = time.time()
            n = 0
            while True:
                ser.read(1)
                t = time.time()
                n += 1
                print "%.6f MHz" % ((2 * 100.000000 * n) / (t - t0))
        elif cmd.startswith('#screenshot'):
            cmd = cmd.split()
            if len(cmd) != 2:
                print 'Usage: #screenshot <dest-image-file>'
                ser.write('\r')
            else:
                dest = cmd[1]
                ser.write('GD.screenshot\r\n')
                collect_screenshot(dest, ser)
                ser.write('\r\n')
        elif cmd.startswith('#movie'):
            cmd = cmd.split()
            if len(cmd) != 2:
                print 'Usage: #movie <command>'
                ser.write('\r')
            else:
                dest = cmd[1]
                ser.write('%s\r' % cmd[1])
                for i in xrange(10000):
                    collect_screenshot("%04d.png" % i, ser)
                ser.write('\r\n')
        else:
            self.texlog(r"\underline{\textbf{%s}}" % cmd)
            self.texlog('\n')
            self.interactive_command(cmd)

    def texlog(self, s):
        pass

    def shell(self, autocomplete = True):
        import readline
        import os
        histfile = os.path.join(os.path.expanduser("~"), ".swapforthhist")
        try:
            readline.read_history_file(histfile)
        except IOError:
            pass
        import atexit
        atexit.register(readline.write_history_file, histfile)

        if autocomplete:
            words = sorted((self.command_response('words')).split())
            print 'Loaded', len(words), 'words'
            def completer(text, state):
                text = text.lower()
                candidates = [w for w in words if w.startswith(text)]
                if state < len(candidates):
                    return candidates[state]
                else:
                    return None
            if 'libedit' in readline.__doc__:
                readline.parse_and_bind("bind ^I rl_complete")
            else:
                readline.parse_and_bind("tab: complete")
            readline.set_completer(completer)
            readline.set_completer_delims(' ')

        ser = self.ser
        while True:
            try:
                if self.interpreting:
                    prompt = '>'
                else:
                    prompt = '+'
                cmd = raw_input(prompt).strip()
                self.shellcmd(cmd)
            except KeyboardInterrupt:
                print
                self.interrupt()
            except EOFError:
                self.texlog(r"\end{Verbatim}" + '\n')
                self.texlog(r"\end{framed}" + '\n')
                break

def main(Tethered):
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
                r = Tethered(port)
                r.boot(image)
                r.searchpath += searchpath
            if a.startswith('-e'):
                r.shellcmd(args[1])
                args = args[2:]
            else:
                try:
                    r.include(a)
                except Bye:
                    pass
                args = args[1:]
    if not r:
        r = Tethered(port)
        r.boot(image)
        r.searchpath += searchpath
    r.shell()
