The ULX3S board is based upon the Lattice ECP5 FPGA. It's a it's a prototype
board with lots of features in a small form factor. For more info, see
https://ulx3s.github.io.

Currently the only tested toolchain is Trellis (or rather the tools associated
with Trellis).

As with the other supported platforms, have the Trellis tools installed, and run
make in this directory to create a bitstream. Run fujprog to install it over
USB:

  fujprog ulx3s_85f_swapforth.bit

Now you can use `shell.py` in the parent directory to attach to the Forth
process over UART. The Verilator bootstrap process will also work for ULX3S.

Currently only J1b itself and UART are supported. Support for low-hanging fruit
like GPIOs, buttons and LEDs should follow shortly.
