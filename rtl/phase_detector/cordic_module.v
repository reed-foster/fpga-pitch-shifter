// cordic_module.v - Reed Foster
// generates enable and address signals synchronized with CORDIC IP output

module cordic_module
    #( // parameters
        ADDR_WIDTH = 11, // 2048 point DFT (need to regenerate Block RAM IP when changing this)
        PHASE_WIDTH = 24
    )( // ports
        input clock, reset_n,

        input [47:0] fft_tdata,
        input fft_tvalid,
        input [15:0] fft_tuser,
        output cordic_tready,
        
        output [PHASE_WIDTH-1:0] phase,
        output [ADDR_WIDTH-2:0] phase_addr,
        output phase_valid
    );
    
    localparam CORDIC_LATENCY = 28;

    wire cordic_phase_valid;
    wire [ADDR_WIDTH-1:0] phase_addr_t;

    assign phase_addr = phase_addr_t[ADDR_WIDTH-2:0];
    assign phase_valid = cordic_phase_valid & ~(phase_addr_t[ADDR_WIDTH-1]);

    // CORDIC IP
    // 24-bit in/out CORDIC module configured to compute arctan
    // coarse rotation enabled, blocking enabled
    // input is 1QN (N = 22 bit fractional part)
    // output is 2QN (N = 21 bit fractional part)
    // 28 clock cycle latency
    cordic_0 atan2 (
        .aclk(clock),
        .s_axis_cartesian_tvalid(fft_tvalid),
        .s_axis_cartesian_tdata(fft_tdata),
        .s_axis_cartesian_tready(cordic_tready),
        .m_axis_dout_tvalid(cordic_phase_valid),
        .m_axis_dout_tdata(phase)
    );
    
    // Synchronize arrival of CORDIC IP output with corresponding indices (from fft_tuser)
    shift_reg #(.DELAY(CORDIC_LATENCY), .DATA_WIDTH(ADDR_WIDTH)) phase_write_addr_delay (
        .clock(clock), .reset_n(reset_n),
        .shift(cordic_tready),
        .data_in(fft_tuser[ADDR_WIDTH-1:0]),
        .data_out(phase_addr_t)
    );
    
endmodule
