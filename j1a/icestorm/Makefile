VERILOGS = j1a.v uart.v ../verilog/j1.v ../verilog/stack2.v
SUBDIRS = ..

all: $(SUBDIRS) j1a.bin

j1a.bin: $(VERILOGS) j1a.pcf Makefile ../build/ram.v
	yosys  -q -p "synth_ice40 -top top -blif j1a.blif" $(VERILOGS)
	arachne-pnr -p j1a.pcf j1a.blif -o j1a.txt
	icebox_explain j1a.txt > j1a.ex
	icepack j1a.txt j1a0.bin
	icemulti -p0 j1a0.bin > j1a.bin

$(SUBDIRS):
	$(MAKE) -C $@

clean:
	rm -f j1a.blif j1a.txt j1a.ex j1a.bin

.PHONY: subdirs
.PHONY: subdirs $(SUBDIRS)
.PHONY: clean
