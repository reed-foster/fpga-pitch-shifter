// pitch_detector.v - Reed Foster
// pitch detection module, takes data from FFT module and produces
// a scale_factor that will produce an "in-key" DFT

module pitch_detector
    ( // ports
        input clock, reset_n,
        input [79:0] fft_data,
        input fft_last, fft_valid,
        input [15:0] fft_user,
        output [23:0] scale_factor, // arbitrary choice of precision
        output scale_factor_valid
    );
    // architecture
    
    harmonic_product_spectrum #(.K_WIDTH(), .X_WIDTH()) hps
    (
        .fft_data_re(),
        .fft_data_im(),
        .fft_user(),
        .fft_last(),
        .fft_valid(),
        .k_max(),
        .k_max_valid()
    );

    phase_calculation phase_0
    (
        .fft_data(),
        .fft_user(),
        .fft_last(),
        .fft_valid(),
        .phase(),
        .phase_last(),
        .output_valid()
    );


endmodule
