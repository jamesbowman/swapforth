SUBDIRS=..

all: obj_dir/Vj1b ../build/nuc.hex build/lib/python/vsimj1b.so

VERILOGS=j1b.v ../verilog/j1.v ../verilog/stack.v

obj_dir/Vj1b obj_dir/Vj1b__ALL.a: $(VERILOGS) sim_main.cpp Makefile
	verilator --l2-name v -Wall -I../verilog/ --cc $(VERILOGS) --top-module j1b --exe sim_main.cpp
	$(MAKE) -C obj_dir CXXFLAGS="-fPIC" OPT_FAST="-O2" -f Vj1b.mk Vj1b

../build/nuc.hex:
	$(MAKE) -C ..

build/lib/python/vsimj1b.so: setup.py obj_dir/Vj1b__ALL.a vsim.cpp
	python setup.py install --home build

clean:
	rm -rf build
	rm -rf obj_dir
	rm -f newmem.dat


.PHONY: all
