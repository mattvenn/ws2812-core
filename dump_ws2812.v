module dump();
    initial begin
        $dumpfile ("ws2812.vcd");
        $dumpvars (0, ws2812);
        #1;
    end
endmodule
