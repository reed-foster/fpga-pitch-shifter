`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/26/2020 03:01:13 PM
// Design Name: 
// Module Name: frame_overlap_gen_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module frame_overlap_gen_tb;

logic clk = 1'b0;
logic rst = 1'b0;
logic [35:0] test_ifft_data_in;
logic [11:0] test_ifft_addr_in;
logic test_valid;

frame_overlap_gen dut(
    .clk(clk), .rst(rst),
    .ifft_data(test_ifft_data_in),
    .ifft_user(test_ifft_addr_in),
    .ifft_valid(test_valid),
    .ifft_ready(),
    .output_data(),
    .output_valid());

initial begin

rst = 1'b1;
# 10;
rst = 1'b0;
#10;


for (int i = 0; i < 10000; i++) begin
    if (i > 0 && i % 4096 == 0) begin
        test_valid = 1'b0;
        i = 0;
        #46400000 // Simulate ifft processing
        test_valid = 1'b0;
    end

    test_ifft_data_in = 2 * i << 18;
    test_ifft_addr_in = i;
    test_valid = 1'b1;
    #10;
end

test_valid = 1'b0;

end

always #5 clk = ~clk;

endmodule
