`default_nettype none

module top (
	input  clk,
    output [7:0] LED,
    output ws_data
);

    reg reset = 1;
    always @(posedge clk)
        reset <= 0;

    reg [23:0] count = 0;
    always @(posedge clk)
        count <= count + 1;

    reg [23:0] led_rgb_data = 24'h00_00_10;
    reg [7:0] led_num = 0;
    wire led_write = &count;

    ws2812 #(.NUM_LEDS(4)) ws2812_inst(.data(ws_data), .clk(clk), .reset(reset), .rgb_data(led_rgb_data), .led_num(led_num), .write(led_write));

endmodule
