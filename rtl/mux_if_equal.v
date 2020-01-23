// mux_if_equal.v - Reed Foster
// muxes two inputs depending on whether the controlling input is equal to
// a constant


module mux_if_equal
    #( // parameters
        parameter CONSTANT = 0,
        parameter CONTROL_WIDTH = 12,
        parameter DATA_WIDTH = 32
    )( // ports
        input [CONTROL_WIDTH-1:0] control,
        input [DATA_WIDTH-1:0] data_in_0, // default output
        input [DATA_WIDTH-1:0] data_in_1, // this is outputted if control == CONSTANT
        output [DATA_WIDTH-1:0] data_out
    );

    wire select;
    assign select = (control == CONSTANT);

    assign data_out = select ? data_in_1 : data_in_0;
endmodule
