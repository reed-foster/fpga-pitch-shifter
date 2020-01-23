`timescale 1 ns/10 ps

module autotune_tb;

localparam N = 12; // Size of input and output audio samples
localparam M = 132000; // Number of samples in the test input
// 132000 for queen.dat
// 48000 for sample_input.txt
logic clk = 1'b0;
logic [N-1:0] sample_input [0:M-1];
logic [N-1:0] adc_input;
logic [N-1:0] autotune_output;
logic reset;

logic [15:0] cycle; // Counter for the address of sample

// autotune #(.clk(clk), .input(adc_input), .output(autotune_output), .reset(reset));

initial begin
    reset = 1'b1;
    cycle = 16'b0;
    $readmemh("/home/tim/Downloads/fpga-pitch-shifter/project_1/project_1.srcs/sources_1/imports/fpga-pitch-shifter/queen.dat", sample_input);
    #20;
    reset = 1'b0;
end

always @(posedge clk)
begin
    if (cycle == M)
    begin
        $stop;
    end
    cycle = cycle + 1;
end

always @(posedge clk) begin
    adc_input = sample_input[cycle];
end

always #5 clk = ~clk;

endmodule