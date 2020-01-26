// triple_element_product.v - Reed Foster
// calculates the product of three serially inputted values

module triple_element_product // 16 clock latency
    ( // ports
        input clock,
        input [31:0] data_in,
        output [95:0] product
    );
    
    wire [31:0] mag1, mag0;
    wire [63:0] mag1_mag2;
    mult_gen_1 mpy_mag1_mag2 ( // 6 clock latency
        .CLK(clock),
        .A(data_in),
        .B(mag1),
        .P(mag1_mag2)
    );
    mult_gen_2 mpy_mag0_mag1_mag2 ( // 10 clock latency
        .CLK(clock),
        .A(mag1_mag2),
        .B(mag0),
        .P(product)
    );
        
    shift_reg #(.DELAY(1), .DATA_WIDTH(32)) mag1_delay (
        .clock(clock), .reset_n(1),
        .shift(1),
        .data_in(data_in),
        .data_out(mag1)
    );
    shift_reg #(.DELAY(8), .DATA_WIDTH(32)) mag0_delay ( // delay of 2 + 6 (z_mpy1)
        .clock(clock), .reset_n(1),
        .shift(1),
        .data_in(data_in),
        .data_out(mag0)
    );

endmodule
