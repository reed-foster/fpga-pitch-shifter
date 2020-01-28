// scale_factor_tb.v - Reed Foster
// testbench for scale_factor module

module scale_factor_tb;

logic clock, reset_n;
logic [37:0] fundamental;
logic fundamental_valid;
logic [1:0] key_select;
logic [23:0] factor;
logic factor_valid;

scale_factor uut (.*);

initial begin
    reset_n = 0;
    clock = 0;
    fundamental = 0;
    fundamental_valid = 0;
    key_select = 0;
    #10;
    reset_n = 1;
    fundamental = 524288000; // 250 Hz
    fundamental_valid = 1;
    #1000;
    fundamental_valid = 0;
end

always #5 clock = ~clock;

endmodule
