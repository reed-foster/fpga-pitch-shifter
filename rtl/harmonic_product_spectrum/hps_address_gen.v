// hps_address_gen.v - Reed Foster
// takes the element-wise product of the original DFT, every other sample of
// the original DFT, and every 3rd sample of the original DFT
// this is equivalent to the product of the original and two rescaled DFTs
// using zero-order hold interpolation

module hps_address_gen
    #( // parameters
        parameter K_WIDTH = 11 // 2048 samples
    )( // ports
        input clock, reset_n,
        
        input done_storing_mag, // goes high as soon as tlast is received, goes low when new tvalid received
        
        output [K_WIDTH-2:0] k,
        output [K_WIDTH-2:0] ram_addr, // read address
        output ram_enable, // read enable
        output done, // asserted when k == 2**(K_WIDTH-1)-1
        
        output triple_complete // used for data_valid after multiply stage
    );
    // architecture
    
    reg [1:0] clock_divide = 0;

    always @(posedge clock)
    begin
        if (reset_n == 0)
            clock_divide <= 0;
        else
        begin
            if (done_storing_mag)
            begin
                if (clock_divide == 2'b10)
                    clock_divide <= 0;
                else
                    clock_divide <= clock_divide + 1;
            end
        end
    end
    
    wire count_enable = clock_divide == 2'b10;
    reg [K_WIDTH-2:0] div1 = 0, div2 = 0, div3 = 0;
    always @(posedge clock)
    begin
        if (reset_n == 0)
        begin
            div1 <= 0;
            div2 <= 0;
            div3 <= 0;
        end
        else if (count_enable)
        begin
            div1 <= div1 + 1;
            div2 <= div2 + 2;
            div3 <= div3 + 3;
        end
    end
    
    assign done = (div1 == (1 << (K_WIDTH-1)) - 1);
    assign ram_addr = (clock_divide == 2'b0) ? div1 : ((clock_divide == 2'b1) ? div2 : ((clock_divide == 2'b10) ? div3 : 0));
    assign k = div1;
    assign ram_enable = 1;
    assign triple_complete = count_enable;

endmodule
