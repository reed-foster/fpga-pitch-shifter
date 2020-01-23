// resampler.v - Reed Foster
// uses zero-order hold interpolation to generate

module resampler
    #( // parameters
        parameter SCALE_FACTOR_INTEGER_WIDTH = 4,
        parameter SCALE_FACTOR_FRACTION_WIDTH = 5,
        parameter N_WIDTH = 12 // 4096 samples
    )( // ports
        input clock, reset_n,

        input [SCALE_FACTOR_INTEGER_WIDTH+SCALE_FACTOR_FRACTION_WIDTH-1:0] scale_factor,
        input scale_factor_valid,

        input fft_last,
        
        input downstream_ready, 
        output downstream_valid, // index is valid
        output [XK_WIDTH+SCALE_FACTOR_INTEGER_WIDTH-1:0] downstream_data, // rescaled X_k index

        output [XK_WIDTH-1:0] ram_addr, // read address
        output ram_enable // read enable
    );
    // architecture
    
    localparam XK_MAX = 2 ** XK_WIDTH - 1;
    wire xk_postscale_max;

    reg [XK_WIDTH+SCALE_FACTOR_INTEGER_WIDTH-1:0] xk = 0;
    wire [XK_WIDTH+SCALE_FACTOR_INTEGER_WIDTH+SCALE_FACTOR_FRACTION_WIDTH-1:0] xk_postscale;
    assign xk_postscale = product >>> SCALE_FACTOR_FRACTION_WIDTH;

    // replace these multiplications with multiplier IP
    assign product = xk * scale_factor;
    assign xk_postscale_max = XK_MAX * scale_factor;
    
    reg fft_frame_complete = 0;
    reg count_enable = 0;

    shift_reg #(.DELAY(4), .DATA_WIDTH(1)) downstream_valid_delay
    (
        .clock(clock),
        .reset_n(reset_n),
        .shift(downstream_ready),
        .data_in(count_enable),
        .data_out(downstream_valid)
    )

    shift_reg #(.DELAY(4), .DATA_WIDTH(XK_WIDTH+SCALE_FACTOR_INTEGER_WIDTH-1)) downstream_data_delay
    (
        .clock(clock),
        .reset_n(reset_n),
        .shift(downstream_ready),
        .data_in(xk),
        .data_out(downstream_data)
    )

    always @(posedge clock)
    begin
        if (reset_n == 0)
        begin
            xk <= 0;
            fft_frame_complete <= 0;
            count_enable <= 0;
        end
        else
        begin
            if (fft_last)
                fft_frame_complete <= 1;

            if (fft_frame_complete && scale_factor_valid)
                count_enable <= 1;

            if (count_enable && downstream_ready)
                xk <= xk + 1;
        end
    end

    endmodule
