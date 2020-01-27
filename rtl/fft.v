// fft.v - Reed Foster
// parameterizable wrapper for XFFT IP

module fft
    #( // parameters
        parameter INVERSE = 0
    )( // ports
        input aclk,

        input [47:0] s_axis_data_tdata, // 24-bit fixed point
        input s_axis_data_tlast,
        output s_axis_data_tready,
        input s_axis_data_tvalid,

        output [47:0] m_axis_data_tdata,
        output m_axis_data_tlast,
        output [15:0] m_axis_data_tuser,
        output m_axis_data_tvalid,
        input m_axis_data_tready
    );
    // architecture

endmodule
