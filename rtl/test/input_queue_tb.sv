// input_queue_tb.sv - Tim Magoun
// testbench for input_queue/top.v

`timescale 1 ns/10 ps

module autotune_tb;

localparam M = 132000; // Number of samples in the test input
// 132000 for queen.dat and sine440.dat
// 48000 for sample_input.txt
logic clk = 1'b0;
logic [11:0] sample_input [0:M-1];
logic reset_n;

logic [15:0] cycle; // Counter for the address of sample

logic last, ready = 1, sampled_adc_valid;
logic [11:0] sampled_adc_in;
logic [11:0] data;

assign sampled_adc_valid = 1;

input_queue uut
   (.clock(clk), .reset_n(reset_n),
    .adc_sample(sampled_adc_in),
    .adc_valid(sampled_adc_valid),
    .data(data),
    .valid(valid),
    .ready(ready),
    .last(last));

initial begin
    reset_n = 1'b0;
    cycle = 16'b0;
    $readmemh("queen.dat", sample_input);
    #20;
    reset_n = 1'b1;
end

always @(posedge clk)
begin
    if (cycle == M)
    begin
        $stop;
    end
    cycle <= cycle + 1;
end

always @(posedge clk) begin
    sampled_adc_in <= sample_input[cycle];
end

always #5 clk = ~clk;

initial begin
    ready = 1;
    #500
    ready = 0;
    #200
    ready = 1;
    #10000
    ready = 0;
    #200
    ready = 1;
end

endmodule
