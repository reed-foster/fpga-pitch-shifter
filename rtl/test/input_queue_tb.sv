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
logic [11:0] counter;
logic last, ready = 1, sampled_adc_valid;
logic [11:0] sampled_adc_in;
logic OUTPUT_RATE = 12'd2267; // Clock cycles per output
assign sampled_adc_valid = 1;

initial begin
    reset_n = 1'b0;
    cycle = 16'b0;
    counter = 12'b0;
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
    if (counter == OUTPUT_RATE) begin
        cycle <= cycle + 1;
        counter <= 0;
    end
    else begin
        counter <= counter + 1;
    end
end

always @(posedge clk) begin
    sampled_adc_in <= sample_input[cycle];
end

always #5 clk = ~clk;

endmodule
