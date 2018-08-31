`default_nettype none
module ws2812 (
    input [7:0] red,
    input [7:0] green,
    input [7:0] blue,
    input reset,
    input clk,  //12MHz

    output reg data
);
    parameter leds = 8;

    /*
    great information here:

    * https://cpldcpu.wordpress.com/2014/01/14/light_ws2812-library-v2-0-part-i-understanding-the-ws2812/
    * https://github.com/japaric/ws2812b/blob/master/firmware/README.md

    period 1200ns:
        * t on  800ns
        * t off 400ns

    end of frame/reset is 50us

    clock period at 12MHz = 83ns:
        * t on  counter = 10, makes t_on  = 833ns
        * t off counter = 5,  makes t_off = 416ns
        * reset is 600 counts

    */
    parameter t_on = 10;
    parameter t_off = 5;
    parameter t_reset = 600;
    localparam t_period = t_on + t_off;

    initial data = 0;


    reg [23:0] rgb;

    reg [3:0] led_counter = 0;
    reg [9:0] bit_counter = 0;
    reg [4:0] rgb_counter = 0;

    localparam STATE_DATA  = 0;
    localparam STATE_RESET = 1;

    reg [1:0] state = STATE_RESET;

    always @(posedge clk)
        if(reset) begin
            state <= STATE_RESET;
            bit_counter <= t_reset;
            rgb_counter <= 23;
            led_counter <= leds;
            rgb <= {red, green, blue};
            data <= 0;
        end else case(state)

            STATE_RESET: begin
                // register the input values
                rgb <= {red, green, blue};
                rgb_counter <= 5'd23;
                led_counter <= leds;
                data <= 0;

                bit_counter <= bit_counter - 1;

                if(bit_counter == 0) begin
                    state <= STATE_DATA;
                    bit_counter <= t_period;
                end
            end

            STATE_DATA: begin
                // output the data
                if(rgb[rgb_counter])
                    data <= bit_counter > (t_period - t_on);
                else
                    data <= bit_counter > (t_period - t_off);

                // count the period
                bit_counter <= bit_counter - 1;

                // after each bit, increment rgb counter
                if(bit_counter == 0) begin
                    bit_counter <= t_on + t_off;
                    rgb_counter <= rgb_counter - 1;

                    if(rgb_counter == 0) begin
                        led_counter <= led_counter - 1;
                        bit_counter <= t_period;
                        rgb_counter <= 23;

                        if(led_counter == 0) begin
                            state <= STATE_RESET;
                            led_counter <= leds;
                            bit_counter <= t_reset;
                        end
                    end
                end 
            end

        endcase

    `ifdef FORMAL
        // start in reset
        initial restrict(reset);

        // past valid signal
        reg f_past_valid = 0;
        always @(posedge clk)
            f_past_valid <= 1'b1;

        // check everything is zeroed on the reset signal
        always @(posedge clk)
            if (f_past_valid)
                if ($past(reset)) begin
                    assert(bit_counter == t_reset);
                    assert(rgb_counter == 23);
                end

        always @(posedge clk) begin
            assert(bit_counter <= t_reset);
            assert(rgb_counter <= 23);
            assert(led_counter <= leds);

            if(state == STATE_DATA)
                assert(bit_counter <= t_period);

            if(state == STATE_RESET)
                assert(data == 0);
        end
            
    `endif
    
endmodule
