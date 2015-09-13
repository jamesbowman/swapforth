build/nuc.hex: cross.fs basewords.fs nuc.fs
	gforth cross.fs basewords.fs nuc.fs

bootstrap: build/nuc.hex verilator/bootstrap
	make -C verilator
	(cd ./verilator/; ./bootstrap)

clean:
	rm -f build/nuc.hex
	make -C xilinx clean
	make -C verilator clean

