import sys

def expand(filename):
    for line in open(filename):
        if line.strip().startswith('include '):
            expand("../../common/" + line.split()[1])
        else:
            sys.stdout.write(line)

if __name__ == '__main__':
    for a in sys.argv[1:]:
        expand(a)
