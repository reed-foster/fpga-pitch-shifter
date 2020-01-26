// round.v - Reed Foster
// rounds a fixed point number to nearest integer

module round
    #( // parameters
        parameter INT_WIDTH = 11,
        parameter FRAC_WIDTH = 21
    )( // ports
        input [INT_WIDTH+FRAC_WIDTH-1:0] fixed_in,
        output [INT_WIDTH+FRAC_WIDTH-1:0] fixed_out
    );

    wire [INT_WIDTH-1:0] rounded_integer;
    wire [INT_WIDTH-1:0] integer_part = fixed_in[INT_WIDTH+FRAC_WIDTH-1:FRAC_WIDTH];
    assign rounded_integer = fixed_in[FRAC_WIDTH-1] ? integer_part + 1 : integer_part;
    
    wire [FRAC_WIDTH-1:0] fraction_part = 0;
    assign fixed_out = {rounded_integer, fraction_part};

endmodule
