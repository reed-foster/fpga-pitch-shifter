// complex_mag.v - Reed Foster
// calculates the magnitude of a complex number

module complex_mag // 6 clock latency
    ( // ports
        input clock,
        input [47:0] complex,
        output [31:0] magnitude
    );
    
    wire [47:0] real_2, imag_2;
    mult_gen_0 real_mpy ( // 4 clock latency
        .CLK(clock),
        .A(complex[23:0]),
        .B(complex[23:0]),
        .P(real_2)
    );
    mult_gen_0 imag_mpy (
        .CLK(clock),
        .A(complex[47:24]),
        .B(complex[47:24]),
        .P(imag_2)
    );
    
    wire [31:0] real_rescaled, imag_rescaled;

    assign real_rescaled = real_2[38:7]; // arbitrary decision; TODO check output of FFT with real data
    assign imag_rescaled = imag_2[38:7];

    c_addsub_0 sum ( // 2 clock latency
        .CLK(clock),
        .A(real_rescaled),
        .B(imag_rescaled),
        .S(magnitude)
    );

endmodule
