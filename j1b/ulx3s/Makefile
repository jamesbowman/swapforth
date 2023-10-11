# ******* project, board and chip name *******
PROJECT = swapforth
BOARD = ulx3s
# 12 25 45 85
FPGA_SIZE = 85

# ******* design files *******
CONSTRAINTS = ulx3s_v20_segpdi.lpf
TOP_MODULE = ulx3s_top
PREFIX = ../verilog
TOP_MODULE_FILE = $(PREFIX)/$(TOP_MODULE).v

VERILOG_FILES = \
$(TOP_MODULE_FILE) \
$(PREFIX)/j1.v \
$(PREFIX)/ram.v \
$(PREFIX)/uart.v \
$(PREFIX)/stack.v \

# *.vhd those files will be converted to *.v files with vhdl2vl (warning overwriting/deleting)
VHDL_FILES = \

YOSYS_OPTIONS = -abc9
NEXTPNR_OPTIONS = --timing-allow-fail

SCRIPTS = scripts
include $(SCRIPTS)/trellis_path.mk
include $(SCRIPTS)/trellis_main.mk
