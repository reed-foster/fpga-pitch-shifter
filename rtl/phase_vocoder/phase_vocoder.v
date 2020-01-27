// phase_vocoder.v - Reed Foster
// uses change in DFT phase between windows to estimate frequency

module phase_vocoder
    #( // parameters
        parameter PHASE_WIDTH = 24,
        parameter PHASE_FRAC = 21, // must always be PHASE_WIDTH-3
        parameter K_WIDTH = 11, // 2048 point DFT
        parameter INV_T = 11'h562, // fixed point value determined by step_size/f_s
        parameter INV_T_INT = 6,
        parameter INV_T_FRAC = 5
    )( // ports
        input clock, reset_n,

        input [PHASE_WIDTH-1:0] phase,
        input [PHASE_WIDTH-1:0] last_phase,
        input phases_valid,
        
        input [K_WIDTH-1:0] k_max,
        input k_max_valid,
        output [K_WIDTH+PHASE_FRAC+INV_T_INT-1:0] fundamental,
        output fundamental_valid
    );
    
    localparam MODULE_LATENCY = 14; // total latency = 4 + 2 + 2 + 2 + 4
    localparam INV_2PI = 21'h517cc; // 21 bit fixed point for 1/(2pi)

    wire [PHASE_FRAC-1:0] phase_frac_0 = 0;
    wire [K_WIDTH+PHASE_FRAC-1:0] k_max_full_width = {k_max, phase_frac_0};
    // right shift to divide by oversample factor of 2
    wire [K_WIDTH+PHASE_FRAC-1:0] k_max_shifted = {k_max_full_width[K_WIDTH+PHASE_FRAC-1], k_max_full_width[K_WIDTH+PHASE_FRAC-1:1]};
    
    wire [PHASE_WIDTH-1:0] phase_2pi;
    mult_gen_0 phase_2pi_div ( // shifts output right by 21 to keep 21 bit fraction
        .CLK(clock),
        .A(phase),
        .B(INV_2PI),
        .P(phase_2pi)
    );
    wire [PHASE_WIDTH-1:0] last_phase_2pi;
    mult_gen_0 last_phase_2pi_div ( // 4 cycle latency
        .CLK(clock),
        .A(last_phase),
        .B(INV_2PI),
        .P(last_phase_2pi)
    );
    
    wire [PHASE_WIDTH-1:0] delta_phase;
    c_addsub_0 sub_last_phase_phase ( // 2 cycle latency
        .CLK(clock),
        .A(last_phase_2pi),
        .B(phase_2pi),
        .S(delta_phase)
    );
    
    wire [K_WIDTH+PHASE_FRAC-1:0] n_opt_unrounded;
    c_addsub_1 add_k_delta_phase ( // 2 cycle latency
        .CLK(clock),
        .A(k_max_shifted),
        .B(delta_phase),
        .S(n_opt_unrounded)
    );

    wire [K_WIDTH+PHASE_FRAC-1:0] n_opt;
    round #(.INT_WIDTH(K_WIDTH), .FRAC_WIDTH(PHASE_FRAC)) round_n (
        .fixed_in(n_opt_unrounded),
        .fixed_out(n_opt)
    );
    
    wire [K_WIDTH+PHASE_WIDTH-1:0] fundamental_fs;
    c_addsub_2 sub_n_opt_delta_phase ( // 2 cycle latency
        .CLK(clock),
        .A(n_opt),
        .B(delta_phase),
        .S(fundamental_fs)
    );
    
    mult_gen_1 fundamental_fs_fs_div ( // 4 cycle latency
        .CLK(clock),
        .A(fundamental_fs),
        .B(INV_T),
        .P(fundamental)
    );
    

    shift_reg #(.DELAY(MODULE_LATENCY), .DATA_WIDTH(1)) valid_delay (
        .clock(clock), .reset_n(reset_n),
        .shift(1),
        .data_in(phases_valid & k_max_valid),
        .data_out(fundamental_valid)
    );

    
endmodule
