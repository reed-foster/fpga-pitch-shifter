// hps_xk_gen.v - Reed Foster
// address generator for HPS
// this HPS implementation takes the element-wise product of three DFTS:
//      the original DFT scaled by 1, 1/2 and 1/3
//
// intended to be used in conjunction with a RAM to store X[k] magnitudes

module hps_xk_gen
    #( // parameters
        parameter K_WIDTH = 12 // 4096 samples
    )( // ports
        input clock, reset_n,

        input fft_last, // goes high when the last coefficient is received from the FFT IP
        
        output [K_WIDTH-1:0] k,
        output [K_WIDTH-1:0] ram_addr, // read address
        output ram_enable, // read enable

        // pulses high for one clock after all three addresses have been read
        // used as data_valid for combined product of all 3 DFT points
        output triple_complete,
        output k_last // goes high when k reaches K_MAX
    );
    // architecture

    localparam K_MAX = 1 << K_WIDTH - 1;
    assign k_last = (orig_counter == K_MAX);
    
    // goes high when DFT magnitudes finish storing to RAM
    // should be reset when FFT IP starts outputting new data
    reg data_received = 0;

    // divide clock by 3 to get allow for reading out element by element
    // i.e. every 3rd clock, calculate new k's for each scale factor
    // and over the course of the 3 clocks, get the magnitude of each X[k]
    reg [1:0] clock_divide = 0; // prescale counter
    reg counter_increment; // goes high for one clock to update counters

    reg [K_WIDTH-1:0] orig_counter = 0; // counter for X[k]
    wire [K_WIDTH-1:0] div2_counter = 0; // counter for X[k//2]
    reg [K_WIDTH-1:0] div3_counter = 0; // counter for X[k//3]
    reg [1:0] div_three_prescale = 0; // clock divider for calculating k//3 from k

    assign div2_counter = orig_counter >> 2;
    assign k = orig_counter;

    always @(posedge clock)
    begin
        if (reset_n == 0)
        begin
            data_received <= 0;
            orig_counter <= 0;
            div_three_prescale <= 0;
        end
        else
        begin
            if (fft_last)
                data_received <= 1;

            if (data_received)
            begin
                if (clock_divide == 2'b10)
                begin
                    clock_divide <= 0;
                    counter_increment <= 1;
                end
                else
                begin
                    clock_divide <= clock_divide + 1;
                    counter_increment <= 0;
                end

                if (counter_increment)
                begin
                    orig_counter <= orig_counter + 1;
                    if (div_three_prescale == 2'b10)
                    begin
                        div_three_prescale <= 0;
                        div3_counter <= div3_counter + 1;
                    end
                    else
                        div_three_prescale <= div_three_prescale + 1;
                end
            end
        end
    end
    
    assign ram_addr = (clock_divide == 2'b0) ? orig_counter : ((clock_divide == 2'b1) ? div2_counter : ((clock_divide == 2'b10) ? div3_counter : 0));
    assign triple_complete = counter_increment;

endmodule
