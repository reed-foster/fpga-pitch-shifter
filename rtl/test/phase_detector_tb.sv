// phase_detector_tb.sv - Reed Foster
// testbench for phase_detector (tracks delta phase between sample frames)

module phase_detector_tb;

localparam K_WIDTH = 11;
localparam M = 16536;
logic [$clog2(M)-1:0] cycle;

logic clock = 0;
logic reset_n;
logic [47:0] fft_tdata;
logic fft_tvalid = 0, fft_tlast = 0;
logic [15:0] fft_tuser;
logic cordic_tready;
logic [K_WIDTH-1:0] k_max;
logic k_max_valid = 0;
logic [23:0] phase;
logic [23:0] phase_last;
logic phases_valid;

phase_detector #(.ADDR_WIDTH(K_WIDTH), .PHASE_WIDTH(24)) uut (.*);

logic [23:0] re, im;
assign re = cycle*cycle;
assign im = cycle+5;

assign k_max = 25;
assign fft_tuser = cycle[K_WIDTH-1:0];
assign fft_tdata = {im,re};

initial begin
    fft_tvalid <= 0;
    reset_n <= 0;
    cycle <= 0;
    #20;
    reset_n <= 1;
    fft_tvalid <= 1;
end

always @(posedge clock)
begin
    if (cycle == (1 << K_WIDTH) - 2)
        fft_tlast <= 1;
    if (cycle == (1 << K_WIDTH) - 1)
    begin
        fft_tlast <= 0;
        fft_tvalid <= 0;
    end
    if (cycle == 400)
        k_max_valid <= 1;
    if (cordic_tready & reset_n)
        cycle <= cycle + 1;
    if (cycle == 15000)
    begin
        fft_tvalid <= 1;
        cycle <= 0;
    end
end

always #5 clock = ~clock;

endmodule
