# WS2812 core

very simple single LED driver. Demonstrates timing is working.

* Parameter NUM_LEDS sets the number of LEDs in the chain (up to 255)
* Data for each LED is loaded with the write signal
* Data is RGB format, 24 bits.
* expects clock to be 12 MHz

# Makefile

    make debug

Use iverilog to run the testbench and show the results

    make formal

Use symbiyosys to formally prove certain aspects of the core

    make prog

Synthesise and program bitstream to 8k dev board.
