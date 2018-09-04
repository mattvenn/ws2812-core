module test;

  reg clk = 0;
  reg reset = 1;
  reg [7:0] led_num = 0;
  reg write = 0;
  reg [23:0] rgb_data = 0;

  initial begin
     $dumpfile("test.vcd");
     $dumpvars(0,test);
     $dumpvars(1,ws2812_inst.led_reg[1]);
     # 20
     reset <= 0;
     # 10
     led_num <= 1;
     rgb_data <= 24'hAABBCC;
     write <= 1;
     # 2;
     write <= 0;

     wait(ws2812_inst.led_counter == 0);
     
     wait(ws2812_inst.state == 1);

     wait(ws2812_inst.led_counter == 0);
     $finish;
  end

  ws2812 #(.leds(2))  ws2812_inst(.clk(clk), .reset(reset), .rgb_data(rgb_data), .led_num(led_num), .write(write));
  /* Make a regular pulsing clock. */
  always #1 clk = !clk;

endmodule // test

