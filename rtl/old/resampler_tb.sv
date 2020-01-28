`timescale 1ps / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/24/2020 03:22:33 PM
// Design Name: 
// Module Name: resampler_tb
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


module resampler_tb;

logic [79:0] fft_data_out; // Sim data
logic [10:0] fft_user_out; // Sim addr
logic fft_valid;
logic fft_last;
logic [23:0] scale_factor = 24'h100000; 
logic scale_factor_valid = 1'b1; // Will change
logic output_ready = 1'b1; // Will change
logic reset = 1'b0, clk = 1'b0;

// Output of dut
logic [79:0] data_out;
logic output_valid;
logic output_last;
logic [10:0] output_k;

logic [11:0] dut_data_out_16;

resampler dut(.clk(clk), .rst(reset), .fft_data(fft_data_out),
              .fft_user(fft_user_out), .fft_valid(fft_valid), .fft_last(fft_last),
              .scale_factor(scale_factor), .scale_factor_valid(scale_factor_valid),
              .data_out(data_out), .output_valid(output_valid), .output_last(output_last), .output_ready(output_ready), .output_k(output_k)
              );
             
             
assign fft_data_out = 2 * fft_user_out;             
assign dut_data_out_16 = data_out;
assign fft_last = (fft_user_out == 11'd2047);

initial begin
    reset = 1'b1;
    fft_valid = 1'b0;
    #10000;
    reset = 1'b0;
    fft_user_out = 12'b0;
    #5000;
    fft_valid = 1'b1;
end

always @(posedge clk) begin
    fft_user_out <= fft_user_out + 1;
    if (fft_user_out == 11'd2047) begin
        fft_user_out <= 0;
        fft_valid <= 0;
    end
end

always #5000 clk = ~clk;

endmodule