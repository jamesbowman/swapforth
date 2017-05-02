build/ram.v: build/nuc.hex mkrom.py
	python mkrom.py

build/nuc.hex: cross.fs basewords.fs nuc.fs
	gforth cross.fs basewords.fs nuc.fs

bootstrap: build/nuc.hex mkrom.py verilator/bootstrap
	make -C verilator
	(cd ./verilator/; ./bootstrap)
	python mkrom.py

clean:
	rm -f build/nuc.hex
	make -C icestorm clean
	make -C verilator clean

UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Linux)

connect: /dev/ttyUSB1
	sudo python shell.py -h /dev/ttyUSB1 -p ../common/

j4a:
	make -C icestorm j4a

j1a8k:
	make -C icestorm j1a8k

j1a:
	make -C icestorm j1a

endif

ifeq ($(UNAME_S),Darwin)

/dev/tty.usbserial-*B: mackextload

connect: /dev/tty.usbserial-*B
	sudo python shell.py -h /dev/tty.usbserial-*B -p ../common/

j4a: mackextunload
	make -C icestorm j4a

j1a8k: mackextunload
	make -C icestorm j1a8k

j1a: mackextunload
	make -C icestorm j1a

mackextunload:
	sudo kextunload -bundle-id com.apple.driver.AppleUSBFTDI

mackextload:
	sudo kextload -bundle-id com.apple.driver.AppleUSBFTDI

endif

pcon:
	$(info Use C-a C-t to toggle reset line as necessary)
	$(info Use C-a C-x to exit. No shell.py features are available)
	picocom -b 921600 /dev/ttyUSB1 --imap lfcrlf,crcrlf --omap delbs,crlf --send-cmd "ascii-xfr -s -l 30 -n"


.PHONY: connect sim_connect j4a_sim_connect clean bootstrap mackextload mackextunload macconnect linmodload pcon
