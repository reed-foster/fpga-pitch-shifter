// harmonic_product_spectrum.v - Reed Foster
// takes the element-wise product of the original DFT, every other sample of
// the original DFT, and every 3rd sample of the original DFT
// this is equivalent to the product of the original and two rescaled DFTs
// using zero-order hold interpolation

module harmonic_product_spectrum
    #( // parameters
        parameter K_WIDTH = 12, // 4096 samples
        parameter DATA_WIDTH = 34, // 34-bit fixed point
        parameter SCALE_FACTOR = 2 // 2 or 3
    )( // ports
        input clock, reset_n,

        input fft_last, // goes high when the last coefficient is received from the FFT IP
        
        output [K_WIDTH-1:0] k,
        output [K_WIDTH-1:0] ram_addr, // read address
        output ram_enable // read enable
    );
    // architecture
    
    reg data_received = 0;

    // divide clock by 3 to get allow for reading out element by element
    // i.e. every 3rd clock, calculate new k's for each scale factor
    // and over the course of the 3 clocks, get the magnitude of each X[k]
    reg [1:0] clock_divide = 0;
    reg counter_increment;

    reg [K_WIDTH-1:0] orig_counter = 0;
    wire [K_WIDTH-1:0] div2_counter = 0;
    reg [K_WIDTH-1:0] div3_counter = 0;
    reg [1:0] div_three_prescale = 0;

    assign div2_counter = orig_counter >> 2;
    assign k = orig_counter;

    always @(posedge clock)
    begin
        if (reset_n == 0)
        begin
            data_received <= 0;
            orig_counter <= 0;
            div_three <= 0;
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
    
    assign ram_addr <= (clock_divide == 0) ? orig_counter : (clock_divide == 1) ? div2_counter : (clock_divide == 2) ? div3_counter : 0;

endmodule
