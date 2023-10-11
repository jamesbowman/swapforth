# ******* project, board and chip name *******
PROJECT ?= project
BOARD ?= board
FPGA_PREFIX ?=
# 12 25 45 85 um-85 um5g-85
FPGA_SIZE ?= 12
FPGA_CHIP ?= lfe5u-$(FPGA_SIZE)f
FPGA_PACKAGE ?= CABGA381
# 2.4 4.8 9.7 19.4 38.8 62.0
FLASH_READ_MHZ ?= 62.0
# fast-read dual-spi qspi
FLASH_READ_MODE ?= fast-read

# ******* design files *******
CONSTRAINTS ?= board_constraints.lpf
TOP_MODULE ?= top
VERILOG_FILES ?= $(TOP_MODULE).v
# implicit list of *.vhd VHDL files to be converted to verilog *.v
# files here are list as *.v but user should
# edit original source which has *.vhd extension (vhdl_blink.vhd)
VHDL_FILES ?=

# ******* tools installation paths *******
# https://github.com/ldoolitt/vhd2vl
#VHDL2VL ?= /mt/scratch/tmp/openfpga/vhd2vl/src/vhd2vl
# https://github.com/YosysHQ/yosys
#YOSYS ?= /mt/scratch/tmp/openfpga/yosys/yosys
# https://github.com/YosysHQ/nextpnr
#NEXTPNR-ECP5 ?= /mt/scratch/tmp/openfpga/nextpnr/nextpnr-ecp5
# https://github.com/SymbiFlow/prjtrellis
#TRELLIS ?= /mt/scratch/tmp/openfpga/prjtrellis

# open source synthesis tools
TRELLISDB ?= $(TRELLIS)/database
LIBTRELLIS ?= $(TRELLIS)/libtrellis
ECPPLL ?= LANG=C ecppll # LANG=C LD_LIBRARY_PATH=$(LIBTRELLIS) $(TRELLIS)/libtrellis/ecppll
ECPPACK ?= LANG=C ecppack # LANG=C LD_LIBRARY_PATH=$(LIBTRELLIS) $(TRELLIS)/libtrellis/ecppack --db $(TRELLISDB)
BIT2SVF ?= $(TRELLIS)/tools/bit_to_svf.py
#BASECFG ?= $(TRELLIS)/misc/basecfgs/empty_$(FPGA_CHIP_EQUIVALENT).config
# yosys options, sometimes those can be used: -noccu2 -nomux -nodram
YOSYS_OPTIONS ?=
# nextpnr options
NEXTPNR_OPTIONS ?=

ifeq ($(FPGA_CHIP), lfe5u-12f)
  CHIP_ID=0x21111043
endif
ifeq ($(FPGA_CHIP), lfe5u-25f)
  CHIP_ID=0x41111043
endif
ifeq ($(FPGA_CHIP), lfe5u-45f)
  CHIP_ID=0x41112043
endif
ifeq ($(FPGA_CHIP), lfe5u-85f)
  CHIP_ID=0x41113043
endif

#ifeq ($(FPGA_SIZE), 12)
#  FPGA_K=$(FPGA_PREFIX)25
#  IDCODE_CHIPID=--idcode $(CHIP_ID)
#else
  FPGA_K=$(FPGA_PREFIX)$(FPGA_SIZE)
  IDCODE_CHIPID=
#endif


FPGA_CHIP_EQUIVALENT ?= lfe5u-$(FPGA_K)f

# clock generator
CLK0_NAME ?= clk0
CLK0_FILE_NAME ?= clocks/$(CLK0_NAME).v
CLK0_OPTIONS ?= --input 25 --output 100 --s1 50 --p1 0 --s2 25 --p2 0 --s3 125 --p3 0
CLK1_NAME ?= clk1
CLK1_FILE_NAME ?= clocks/$(CLK1_NAME).v
CLK1_OPTIONS ?= --input 25 --output 100 --s1 50 --p1 0 --s2 25 --p2 0 --s3 125 --p3 0
CLK2_NAME ?= clk2
CLK2_FILE_NAME ?= clocks/$(CLK2_NAME).v
CLK2_OPTIONS ?= --input 25 --output 100 --s1 50 --p1 0 --s2 25 --p2 0 --s3 125 --p3 0
CLK3_NAME ?= clk3
CLK3_FILE_NAME ?= clocks/$(CLK3_NAME).v
CLK3_OPTIONS ?= --input 25 --output 100 --s1 50 --p1 0 --s2 25 --p2 0 --s3 125 --p3 0

# closed source synthesis tools
#DIAMOND_BASE := /usr/local/diamond
ifneq ($(wildcard $(DIAMOND_BASE)),)
  DIAMOND_BIN :=  $(shell find ${DIAMOND_BASE}/ -maxdepth 2 -name bin | sort -rn | head -1)
  DIAMONDC := $(shell find ${DIAMOND_BIN}/ -name diamondc)
  DDTCMD := $(shell find ${DIAMOND_BIN}/ -name ddtcmd)
endif

# programming tools
UJPROG ?= fujprog
OPENFPGALOADER ?= openFPGALoader
OPENFPGALOADER_OPTIONS ?= --board ulx3s
FLEAFPGA_JTAG ?= FleaFPGA-JTAG 
OPENOCD ?= openocd
OPENOCD_INTERFACE ?= $(SCRIPTS)/ft231x.ocd
DFU_UTIL ?= dfu-util
TINYFPGASP ?= tinyfpgasp

# helper scripts directory
SCRIPTS ?= scripts

# rest of the include makefile
FPGA_CHIP_UPPERCASE := $(shell echo $(FPGA_CHIP) | tr '[:lower:]' '[:upper:]')


#all: $(BOARD)_$(FPGA_SIZE)f_$(PROJECT).bit $(BOARD)_$(FPGA_SIZE)f_$(PROJECT).vme $(BOARD)_$(FPGA_SIZE)f_$(PROJECT).svf
all: $(BOARD)_$(FPGA_SIZE)f_$(PROJECT).bit $(BOARD)_$(FPGA_SIZE)f_$(PROJECT).svf

# VHDL to VERILOG conversion
# convert all *.vhd filenames to .v extension
VHDL_TO_VERILOG_FILES = $(VHDL_FILES:.vhd=.v)
# implicit conversion rule
%.v: %.vhd
	$(VHDL2VL) $< $@

#*.v: *.vhdl
#	$(VHDL2VL) $< $@

#$(PROJECT).ys: makefile
#	$(SCRIPTS)/ysgen.sh $(VERILOG_FILES) $(VHDL_TO_VERILOG_FILES) > $@
#	echo "hierarchy -top ${TOP_MODULE}" >> $@
#	echo "synth_ecp5 -noccu2 -nomux -nodram -json ${PROJECT}.json" >> $@

#$(PROJECT).json: $(PROJECT).ys $(VERILOG_FILES) $(VHDL_TO_VERILOG_FILES)
#	$(YOSYS) $(PROJECT).ys

$(PROJECT).json: $(VERILOG_FILES) $(VHDL_TO_VERILOG_FILES)
	$(YOSYS) \
	-p "read -sv $(VERILOG_FILES) $(VHDL_TO_VERILOG_FILES)" \
	-p "hierarchy -top ${TOP_MODULE}" \
	-p "synth_ecp5 ${YOSYS_OPTIONS} -json ${PROJECT}.json"

$(BOARD)_$(FPGA_SIZE)f_$(PROJECT).config: $(PROJECT).json $(BASECFG)
	$(NEXTPNR-ECP5) $(NEXTPNR_OPTIONS) --$(FPGA_K)k --package $(FPGA_PACKAGE) --json $(PROJECT).json --lpf $(CONSTRAINTS) --textcfg $@

$(BOARD)_$(FPGA_SIZE)f_$(PROJECT).bit: $(BOARD)_$(FPGA_SIZE)f_$(PROJECT).config
	$(ECPPACK) $(IDCODE_CHIPID) --compress --freq $(FLASH_READ_MHZ) --input $< --bit $@
#	$(ECPPACK) $(IDCODE_CHIPID) --compress --freq $(FLASH_READ_MHZ) --spimode $(FLASH_READ_MODE) --input $< --bit $@

$(CLK0_FILE_NAME):
	$(ECPPLL) $(CLK0_OPTIONS) --file $@

$(CLK1_FILE_NAME):
	$(ECPPLL) $(CLK1_OPTIONS) --file $@

$(CLK2_FILE_NAME):
	$(ECPPLL) $(CLK2_OPTIONS) --file $@

$(CLK3_FILE_NAME):
	$(ECPPLL) $(CLK3_OPTIONS) --file $@

# generate XCF programming file for DDTCMD
$(BOARD)_$(FPGA_SIZE)f.xcf: $(BOARD)_$(FPGA_SIZE)f_$(PROJECT).bit $(SCRIPTS)/$(BOARD)_sram.xcf $(SCRIPTS)/xcf.xsl $(DTD_FILE)
	xsltproc \
	  --stringparam FPGA_CHIP $(FPGA_CHIP_UPPERCASE) \
	  --stringparam CHIP_ID $(CHIP_ID) \
	  --stringparam BITSTREAM_FILE $(BOARD)_$(FPGA_SIZE)f_$(PROJECT).bit \
	  $(SCRIPTS)/xcf.xsl $(SCRIPTS)/$(BOARD)_sram.xcf > $@

# run DDTCMD to generate VME file
$(BOARD)_$(FPGA_SIZE)f_$(PROJECT).vme: $(BOARD)_$(FPGA_SIZE)f.xcf $(BOARD)_$(FPGA_SIZE)f_$(PROJECT).bit
	LANG=C ${DDTCMD} -oft -fullvme -if $(BOARD)_$(FPGA_SIZE)f.xcf -nocompress -noheader -of $@

# run DDTCMD to generate SVF file
#$(BOARD)_$(FPGA_SIZE)f_$(PROJECT).svf: $(BOARD)_$(FPGA_SIZE)f.xcf $(BOARD)_$(FPGA_SIZE)f_$(PROJECT).bit
#	LANG=C ${DDTCMD} -oft -svfsingle -revd -maxdata 8 -if $(BOARD)_$(FPGA_SIZE)f.xcf -of $@

# generate SVF file by prjtrellis python script
#$(BOARD)_$(FPGA_SIZE)f_$(PROJECT).svf: $(BOARD)_$(FPGA_SIZE)f_$(PROJECT).bit
#	$(BIT2SVF) $< $@

$(BOARD)_$(FPGA_SIZE)f_$(PROJECT).svf: $(BOARD)_$(FPGA_SIZE)f_$(PROJECT).config
	$(ECPPACK) $(IDCODE_CHIPID) $< --compress --freq $(FLASH_READ_MHZ) --svf-rowsize 800000 --svf $@
#	$(ECPPACK) $(IDCODE_CHIPID) $< --compress --freq $(FLASH_READ_MHZ) --spimode $(FLASH_READ_MODE) --svf-rowsize 800000 --svf $@

# program SRAM  with ujrprog (temporary)
prog: program
program: $(BOARD)_$(FPGA_SIZE)f_$(PROJECT).bit
	$(UJPROG) $<

# program SRAM with OPENFPGALOADER
prog_ofl: program_ofl
program_ofl: $(BOARD)_$(FPGA_SIZE)f_$(PROJECT).bit
	$(OPENFPGALOADER) $(OPENFPGALOADER_OPTIONS) $<

# program SRAM  with FleaFPGA-JTAG (temporary)
program_flea: $(BOARD)_$(FPGA_SIZE)f_$(PROJECT).vme
	$(FLEAFPGA_JTAG) $<

# program FLASH over US1 port with ujprog (permanently)
flash: $(BOARD)_$(FPGA_SIZE)f_$(PROJECT).bit
	$(UJPROG) -j flash $<

# program FLASH over US1 port with openFPGALoader (permanently)
flash_ofl: $(BOARD)_$(FPGA_SIZE)f_$(PROJECT).bit
	$(OPENFPGALOADER) $(OPENFPGALOADER_OPTIONS) -f $<

# program FLASH over US2 port with DFU bootloader (permanently)
flash_dfu: $(BOARD)_$(FPGA_SIZE)f_$(PROJECT).bit
	$(DFU_UTIL) -a 0 -D $<
	$(DFU_UTIL) -a 0 -e

# program FLASH over US2 port with tinyfpgasp bootloader (permanently)
flash_tiny: $(BOARD)_$(FPGA_SIZE)f_$(PROJECT).bit
	$(TINYFPGASP) -w $<

# generate chip-specific openocd programming file
$(BOARD)_$(FPGA_SIZE)f.ocd: $(SCRIPTS)/ecp5-ocd.sh
	$(SCRIPTS)/ecp5-ocd.sh $(CHIP_ID) $(BOARD)_$(FPGA_SIZE)f_$(PROJECT).svf > $@

# program SRAM with OPENOCD
prog_ocd: program_ocd
program_ocd: $(BOARD)_$(FPGA_SIZE)f_$(PROJECT).svf $(BOARD)_$(FPGA_SIZE)f.ocd
	$(OPENOCD) --file=$(OPENOCD_INTERFACE) --file=$(BOARD)_$(FPGA_SIZE)f.ocd

JUNK = *~
#JUNK += $(PROJECT).ys
JUNK += $(PROJECT).json
JUNK += $(VHDL_TO_VERILOG_FILES)
JUNK += $(BOARD)_$(FPGA_SIZE)f_$(PROJECT).config
JUNK += $(BOARD)_$(FPGA_SIZE)f_$(PROJECT).bit
JUNK += $(BOARD)_$(FPGA_SIZE)f_$(PROJECT).vme
JUNK += $(BOARD)_$(FPGA_SIZE)f_$(PROJECT).svf
JUNK += $(BOARD)_$(FPGA_SIZE)f.xcf
JUNK += $(BOARD)_$(FPGA_SIZE)f.ocd
JUNK += $(CLK0_FILE_NAME) $(CLK1_FILE_NAME) $(CLK2_FILE_NAME) $(CLK3_FILE_NAME)

clean:
	rm -f $(JUNK)
