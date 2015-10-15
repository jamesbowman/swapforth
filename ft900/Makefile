all: nuc.bin nuc.sim

test: nuc.sim
	python expand.py swapforth.fs runtests.fs | ft32-elf-run nuc.sim | grep '^Forth tests completed'
	
nuc.bin: nuc.s Makefile
	ft32-elf-as --defsym SIMULATOR=0 -a=lst -o nuc.o nuc.s
	ft32-elf-ld --oformat binary -o nuc.bin nuc.o

nuc.sim: nuc.s Makefile
	ft32-elf-as --defsym SIMULATOR=1 -a=lst -o nuc.o nuc.s
	ft32-elf-gcc -nostartfiles -o nuc.sim -msim nuc.o

clean:
	rm -f nuc.bin nuc.sim nuc.o
