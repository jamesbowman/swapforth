def flash(s, dest):
    d = [int(x, 36) for x in s.split()]
    print "Image: ", (len(d)), " words"
    open(dest, "w").write("".join(["%04x\n" % (x & 0xffff) for x in d]))

with open ("newmem.dat", "r") as myfile:
    data=myfile.readlines()[0]
    flash(data, "../build/nuc.hex")

