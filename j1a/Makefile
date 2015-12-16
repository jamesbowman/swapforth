build/ram.v: build/nuc.hex mkrom.py
	python mkrom.py

build/nuc.hex: cross.fs basewords.fs nuc.fs
	gforth cross.fs basewords.fs nuc.fs

bootstrap: build/nuc.hex mkrom.py verilator/bootstrap
	make -C verilator
	(cd ./verilator/; ./bootstrap)
	python mkrom.py


connect: /dev/ttyUSB1
	sudo python shell.py -h /dev/ttyUSB1 -p ../common/

clean:
	rm -f build/nuc.hex
	make -C icestorm clean
	make -C verilator clean

j4a:
	make -C icestorm j4a

j1a8k:
	make -C icestorm j1a8k

j1a:
	make -C icestorm j1a


