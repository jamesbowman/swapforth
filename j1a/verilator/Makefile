SUBDIRS=..

all: obj_dir/Vj1a ../build/nuc.hex build/lib/python/vsimj1a.so

VERILOGS=j1a.v ../verilog/*.v

obj_dir/Vj1a obj_dir/Vj1a__ALL.a: $(VERILOGS) sim_main.cpp Makefile
	verilator -Wall --cc $(VERILOGS) --top-module j1a --exe sim_main.cpp
	$(MAKE) -C obj_dir CXXFLAGS="-fPIC" OPT_FAST="-O2" -f Vj1a.mk Vj1a

../build/nuc.hex:
	$(MAKE) -C ..

build/lib/python/vsimj1a.so: setup.py obj_dir/Vj1a__ALL.a vsim.cpp
	python setup.py install --home build

clean:
	rm -rf obj_dir
	rm -f newmem.dat

.PHONY: all
