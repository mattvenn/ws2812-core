PACKAGE = ct256
DEVICE = hx8k
PROJ = ws2812
PIN_DEF = 8k.pcf
SEED = 10
SHELL := /bin/bash # Use bash syntax
BUILD_DIR = ./build
SRC_DIR = ./
TEST_DIR = ./

all: $(BUILD_DIR)/$(PROJ).bin $(BUILD_DIR)/$(PROJ).rpt formal

MODULES = ws2812.v
VERILOG = top.v $(MODULES)
SRC = $(foreach ii,$(VERILOG),$(addprefix $(SRC_DIR)/, $(ii)))

export COCOTB_REDUCED_LOG_FMT=1
export LIBPYTHON_LOC=$(shell cocotb-config --libpython)

# $@ The file name of the target of the rule.rule
# $< first pre requisite
# $^ names of all preerquisites

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

# rules for building the blif file
$(BUILD_DIR)/%.json: $(SRC)
	pru-yosys -l $(BUILD_DIR)/build.log -p 'synth_ice40 -top top -json $(BUILD_DIR)/$(PROJ).json' $(SRC)

# asc
$(BUILD_DIR)/%.asc: $(BUILD_DIR)/%.json $(PIN_DEF) 
	pru-nextpnr-ice40 -l $(BUILD_DIR)/nextpnr.log --seed $(SEED) --freq 20 --package $(PACKAGE) --$(DEVICE) --asc $@ --pcf $(PIN_DEF) --json $<

# bin, for programming
$(BUILD_DIR)/%.bin: $(BUILD_DIR)/%.asc
	icepack $< $@

# timing
$(BUILD_DIR)/%.rpt: $(BUILD_DIR)/%.asc
	icetime -d $(DEVICE) -mtr $@ $<

debug:
	iverilog -o ws2812.out ws2812.v ws2812_tb.v
	vvp ws2812.out -fst
	gtkwave test.vcd gtk-ws2812.gtkw

test:
	rm -rf sim_build/
	rm -f results.xml
	mkdir sim_build/
	iverilog -o sim_build/sim.vvp -s ws2812 -s dump -g2012 ws2812.v dump_ws2812.v
	MODULE=test_ws2812 vvp -M $$(cocotb-config --prefix)/cocotb/libs -m libcocotbvpi_icarus sim_build/sim.vvp
	! grep failure results.xml

view:
	gtkwave ws2812.vcd ws2812.gtkw

prog: $(BUILD_DIR)/$(PROJ).bin
	iceprog $<

formal:
	sby -f $(PROJ).sby || gtkwave $(PROJ)/engine_0/*vcd ws2812_formal.gtkw 

clean:
	rm -f $(BUILD_DIR)/*

#secondary needed or make will remove useful intermediate files
.SECONDARY:
.PHONY: all prog clean formal debug

