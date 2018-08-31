module test;

  reg clk = 0;
  reg reset = 1;

  initial begin
     $dumpfile("test.vcd");
     $dumpvars(0,test);
     # 20
     reset <= 0;
     wait(ws2812_inst.led_counter == 0);
     
     wait(ws2812_inst.state == 1);

     wait(ws2812_inst.led_counter == 0);
     $finish;
  end

  ws2812 #(.leds(2))  ws2812_inst(.clk(clk), .reset(reset), .red(8'd100), .green(8'd0), .blue(8'd255));
  /* Make a regular pulsing clock. */
  always #1 clk = !clk;

endmodule // test

