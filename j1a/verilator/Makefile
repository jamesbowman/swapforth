SUBDIRS=..

all: obj_dir/Vj1a ../build/nuc.hex

VERILOGS=j1a.v ../verilog/*.v

obj_dir/Vj1a: $(VERILOGS) sim_main.cpp Makefile
	verilator -Wall --cc --trace $(VERILOGS) --top-module j1a --exe sim_main.cpp
	$(MAKE) -C obj_dir OPT_FAST="-O2" -f Vj1a.mk Vj1a

../build/nuc.hex:
	$(MAKE) -C ..

.PHONY: all
