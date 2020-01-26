// top.v - Reed Foster
// toplevel module

module top
    ( // ports
        input clock, reset_n,
        input vauxp3, vauxn3,
        input [15:0] sw,
        output aud_pwm,
        output aud_sd
    );
    // architecture
    
    wire [11:0] adc_data;
    wire adc_valid;

    adc adc_0
    (
        .clock(clock),
        .reset_n(reset_n),
        .vauxn3(vauxn3), .vausxp3(vauxp3),
        .sampled_data(adc_data),
        .data_valid(adc_valid)
    );

    input_queue input_queue_0
    (
        .clock(clock),
        .reset_n(reset_n),
        .input_valid(adc_valid),
        .data_in(adc_data),
        .data_out(),
        .output_valid(),
        .output_last()
    );

    fft #(.INVERSE(0)) fft_0
    (
        .aclk(clock),
        .s_axis_data_tdata(),
        .s_axis_data_tlast(),
        .s_axis_data_tready(),
        .s_axis_data_tvalid(),
        .m_axis_data_tdata(),
        .m_axis_data_tlast(),
        .m_axis_data_tuser(),
        .m_axis_data_tvalid(),
        .m_axis_data_tready()
    );

    pitch_detector pitch_detector_0
    (
        .clock(clock),
        .reset_n(reset_n),
        .fft_data(),
        .fft_last(),
        .fft_user(),
        .fft_valid(),
        .scale_factor(),
        .scale_factor_valid()
    );

    resample dft_resample
    (
        .clock(clock),
        .reset_n(reset_n),
        .fft_data(),
        .fft_user(),
        .fft_valid(),
        .fft_last(),
        .scale_factor(),
        .scale_factor_valid(),
        .data_out(),
        .output_valid(),
        .output_last()
    );

    fft #(.INVERSE(1)) fft_1
    (
        .aclk(clock),
        .s_axis_data_tdata(),
        .s_axis_data_tlast(),
        .s_axis_data_tready(),
        .m_axis_data_tdata(),
        .m_axis_data_tlast(),
        .m_axis_data_tuser(),
        .m_axis_data_tvalid(),
        .m_axis_data_tready()
    );

endmodule
