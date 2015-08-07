build/ram.v: build/nuc.hex mkrom.py
	python mkrom.py

build/nuc.hex: cross.fs basewords.fs nuc.fs
	gforth cross.fs basewords.fs nuc.fs

bootstrap: build/nuc.hex mkrom.py verilator/mk
	make -C verilator
	(cd ./verilator/; ./bootstrap)
	python mkrom.py

clean:
	rm -f build/nuc.hex
	make -C icestorm clean
	make -C verilator clean

