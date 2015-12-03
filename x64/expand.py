import sys

def expand(filename):
    for dir in ('.', '../common', '../anstests/'):
        try:
            f = open(dir + "/" + filename)
        except IOError:
            continue
        for line in f:
            line = line.replace('\r', '')
            if line.strip().startswith('#bye'):
                sys.exit(0)
            if line.strip().startswith('include '):
                expand(line.split()[1])
            else:
                sys.stdout.write(line)
        print
        return
    assert 0, filename + 'not found'

if __name__ == '__main__':
    for a in sys.argv[1:]:
        expand(a)
