# WS2812 core

very simple single LED driver. Demonstrates timing is working.

Parameter leds can set the number of LEDs in the chain. All LEDs
receive the same data.

# Makefile

    make debug

Use iverilog to run the testbench and show the results

    make formal

Use symbiyosys to formally prove certain aspects of the core

    make prog

Synthesise and program bitstream to 8k dev board.
