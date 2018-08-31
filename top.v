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

    ws2812 #(.leds(7)) ws2812_inst(.data(ws_data), .clk(clk), .reset(reset), .red(count[23:16]), .green(8'd0), .blue(255 - count[23:16]));

endmodule
