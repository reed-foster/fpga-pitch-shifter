`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/26/2020 01:49:29 PM
// Design Name: 
// Module Name: fifo_tb
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
module phase_vocoder_tb;

logic reset = 1'b0, clk = 1'b0;
logic [23:0] phase = 24'b0;
logic [23:0] last_phase = 24'b0;
logic phases_valid = 1'b0;
        
logic [23:0] k_max = 1'b0;
logic k_max_valid = 1'b0;

phase_vocoder#() dut( // ports
        .clock(clk), .reset_n(~reset),

        .phase(phase),
        .last_phase(last_phase),
        .phases_valid(phases_valid),
        
        .k_max(k_max),
        .k_max_valid(k_max_valid),
        .fundamental(),
        .fundamental_valid());

initial begin
    reset = 1'b1;
    #10;
    reset = 1'b0;
    phases_valid = 1'b1;
    phase = 3'b101 << 19;
    last_phase = 1'b1 << 22;    
    k_max = 24'd20;
    k_max_valid = 1;
    #10;
    phases_valid = 1'b0;
    k_max_valid = 1'b0;
end

always #5 clk = ~clk;

endmodule