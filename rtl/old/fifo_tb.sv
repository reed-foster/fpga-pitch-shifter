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
module fifo_tb;

logic reset = 1'b0, clk = 1'b0;
logic [11:0]counter = 12'b0;

logic dequeue = 1'b0;
logic enqueue = 1'b0;

fifo#() dut(.clock(clk), 
        .reset(reset),
        .dequeue(dequeue),
        .enqueue(enqueue),
        .data_in(counter),
        .data_out(),
        .data_valid(),
        .full(),
        .empty());

initial begin
    reset = 1'b1;
    #10;
    reset = 1'b0;
    enqueue = 1'b1;
    counter <= 0;
    #5;
    for (int i = 0; i < 2048; i++) begin
        counter <= counter + 1;
        if (counter == 50)
            dequeue = 1'b1;
        if (counter == 100)
            dequeue = 1'b0;
        if (counter == 150)
            dequeue = 1'b1;
        #10;
    end    
end

always #5 clk = ~clk;

endmodule