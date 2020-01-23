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

endmodule
