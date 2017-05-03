VERILOGS = j1a.v async_in_filter.v uart.v ../verilog/j1.v ../verilog/stack2.v

VERILOGS8k = j1a8k.v uart.v async_in_filter.v ../verilog/j1.v ../verilog/stack2.v

VERILOGS8k4 = j4a.v uart.v async_in_filter.v ../verilog/*.v

SUBDIRS = ..

all: $(SUBDIRS) j1a.bin

j1a.bin: $(VERILOGS) j1a.pcf Makefile ../build/ram.v
	yosys  -q -p "synth_ice40 -top top -abc2 -blif j1a.blif" $(VERILOGS)
	arachne-pnr -p j1a.pcf j1a.blif -o j1a.txt
	#skipped:# icebox_explain j1a.txt > j1a.ex
	icepack j1a.txt j1a0.bin
	icemulti -p0 j1a0.bin > j1a.bin && rm j1a0.bin

j1a8k.bin: $(VERILOGS8k) j1a8k.pcf Makefile ../build/ram.v
	yosys  -q -p "synth_ice40 -top top -abc2 -blif j1a8k.blif" $(VERILOGS8k)
	arachne-pnr -d 8k -p j1a8k.pcf j1a8k.blif -o j1a8k.txt
	#skipped:# icebox_explain j1a8k.txt > j1a8k.ex
	icepack j1a8k.txt j1a8k0.bin
	icemulti -p0 j1a8k0.bin > j1a8k.bin && rm j1a8k0.bin

j4a.bin: $(VERILOGS8k4) j1a8k.pcf Makefile ../build/ram.v
	yosys  -q -p "synth_ice40 -top top -abc2 -blif j4a.blif" $(VERILOGS8k4)
	arachne-pnr -d 8k -p j1a8k.pcf j4a.blif -o j4a.txt
	#skipped:# icebox_explain j4a.txt > j4a.ex
	icepack j4a.txt j4a0.bin
	icemulti -p0 j4a0.bin > j4a.bin && rm j4a0.bin
	
j1a8k: j1a8k.bin
	sudo iceprog j1a8k.bin

j1a: j1a.bin
	sudo iceprog j1a.bin

j4a: j4a.bin
	sudo iceprog j4a.bin


$(SUBDIRS):
	$(MAKE) -C $@

clean:
	rm -f j1a.blif j1a.txt j1a.bin
	rm -f j1a8k.blif j1a8k.txt j1a8k.bin
	rm -f j1a.blif j4a.txt j4a.bin

.PHONY: subdirs
.PHONY: subdirs $(SUBDIRS)
.PHONY: clean
.PHONY: j1a8k
.PHONY: j1a
.PHONY: j4a

