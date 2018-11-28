PACKAGE = ct256
DEVICE = hx8k
PROJ = ws2812
PIN_DEF = 8k.pcf
SHELL := /bin/bash # Use bash syntax
BUILD_DIR = ./build
SRC_DIR = ./
TEST_DIR = ./

all: $(BUILD_DIR)/$(PROJ).bin $(BUILD_DIR)/$(PROJ).rpt formal

MODULES = ws2812.v
VERILOG = top.v $(MODULES)
SRC = $(foreach ii,$(VERILOG),$(addprefix $(SRC_DIR)/, $(ii)))

# $@ The file name of the target of the rule.rule
# $< first pre requisite
# $^ names of all preerquisites

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

# rules for building the blif file
$(BUILD_DIR)/%.blif: $(SRC) | $(BUILD_DIR)
	yosys -p "synth_ice40 -top top -blif $@" $^ | tee $(BUILD_DIR)/build.log

# asc
$(BUILD_DIR)/%.asc: $(PIN_DEF) $(BUILD_DIR)/%.blif
	arachne-pnr --device 8k --package $(PACKAGE) -p $^ -o $@
	#arachne-pnr -d $(subst hx,,$(subst lp,,$(DEVICE))) -o $@ -p $^

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

prog: $(BUILD_DIR)/$(PROJ).bin
	iceprog $<

formal:
	sby -f $(PROJ).sby || gtkwave $(PROJ)/engine_0/*vcd ws2812_formal.gtkw 

clean:
	rm -f $(BUILD_DIR)/*

#secondary needed or make will remove useful intermediate files
.SECONDARY:
.PHONY: all prog clean formal debug

