// harmonic_product_spectrum.v - Reed Foster
// takes in complex-valued DFT coefficients from FFT module
// calculates magnitudes and generates a harmonic product spectrum

module harmonic_product_spectrum
    #( // parameters
        parameter K_WIDTH = 12 // 4096 samples
        parameter X_WIDTH = 21 // input to FFT is 21-bit fixed point
    )( // ports
        input clock, reset_n,
        // FFT module produces XN_WIDTH+K_WIDTH+1 wide outputs when configured with no scaling fixed point
        input [X_WIDTH+K_WIDTH:0] fft_data_re,
        input [X_WIDTH+K_WIDTH:0] fft_data_im,
        input [15:0] fft_user,
        input fft_last,
        input fft_valid,
        output [K_WIDTH-1:0] k_max,
        output k_max_valid
    );

    localparam MAG_WIDTH = 6*(X_WIDTH+K_WIDTH+1) // (x^2)^3 = x^6
    
    ///////////////////////////////
    // Calculate Magnitude
    ///////////////////////////////
    // div squared re,im by 64 then clip
    wire [31:0] re_2;
    wire [31:0] im_2;
    assign re_2 = ((fft_data_re*fft_data_re) >>> 6)[31:0];
    assign im_2 = ((fft_data_im*fft_data_im) >>> 6)[31:0];
    // sum re,im
    wire [31:0] mag_in;
    assign mag_in = (re_2 + im_2)[31:0];
    

    /////////////////////////////
    // Magnitude RAM
    /////////////////////////////
    // generate RAM address
    wire [K_WIDTH-2:0] ram_address;
    wire [K_WIDTH-1:0] k_in;
    assign k_in = fft_user[K_WIDTH-1:0];
    reg done_writing = 0;
    // hps_complete_t goes high when final address group is generated,
    // delayed by 3 cycles to allow for all addresses to be read out
    wire hps_complete, hps_complete_t; 
    always @(posedge clock)
    begin
        if (fft_last)
            done_writing <= 1;
        else if (hps_complete) // reset when a new fft_stream starts coming in
            done_writing <= 0;
    end

    assign ram_address = done_writing ? generated_address : k_in;
    // RAM
    reg [31:0] mag_ram [1<<(K_WIDTH-1):0]; // store first half of DFT magnitudes
    reg [31:0] mag_out = 0;
    wire ram_read;

    always @(posedge clock)
    begin
        if (fft_valid)
            mag_ram[ram_address] <= mag_in;
        else if (ram_read)
            mag_out <= mag_ram[ram_address];
    end

    wire [31:0] mag_0, mag_1, mag_2;


    hps_xk_gen #(.K_WIDTH(K_WIDTH-1)) address_gen
    (
        .clock(clock), .reset_n(reset_n),
        .fft_last(),
        .k(),
        .ram_addr(),
        .ram_enable(ram_read),
        .triple_complete(),
        .k_last(hps_complete_t)
    );

    shift_reg #(.DELAY(3), .DATAWIDTH(1))
    (
        .clock(clock), .reset_n(reset_n),
        .shift(1),
        .data_in(hps_complete_t),
        .data_out(hps_complete)
    );

    maximum_stream #(.MAG_WIDTH(MAG_WIDTH), .K_WIDTH(K_WIDTH)) max_k_detect
    (
        .clock(clock), .reset_n(reset_n),
        .data_valid(),
        .data_in(),
        .k_in(),
        .max_k(k_max),
        .max_k_valid(k_max_valid)
    );

endmodule
