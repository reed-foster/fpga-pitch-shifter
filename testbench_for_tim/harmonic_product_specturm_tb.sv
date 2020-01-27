// harmonic_product_spectrum_tb.sv - Reed Foster
// testbench for harmonic_product_spectrum.v

module harmonic_product_specturm_tb;

localparam M = 8192;
logic [$clog2(M)-1:0] cycle; // Counter for the address of sample
logic [11:0] sample_input [0:M-1];

logic clock = 1'b0;
logic reset_n;
logic ram_tready;
logic [47:0] fft_tdata;
logic fft_tvalid, fft_tlast;
logic [15:0] fft_tuser;
logic cordic_tready = 1;
logic [10:0] k_max;
logic k_max_valid;

harmonic_product_spectrum uut (.*);

logic [11:0] sample_data;

logic event_frame_started;
logic event_tlast_unexpected, event_tlast_missing;
logic event_status_channel_halt, event_data_in_channel_halt, event_data_out_channel_halt;

xfft_0 fft (
    .aclk(clock),
    .s_axis_config_tdata(8'b00001011),
    .s_axis_config_tvalid(1'b1),
    .s_axis_config_tready(),
    .s_axis_data_tdata({20'b0, sample_data}),
    //.s_axis_data_tdata(32'hfff),
    .s_axis_data_tvalid(1),
    .s_axis_data_tready(ram_tready),
    .s_axis_data_tlast(1'b0),
    .m_axis_data_tdata(fft_tdata),
    .m_axis_data_tvalid(fft_tvalid),
    .m_axis_data_tready(cordic_tready),
    .m_axis_data_tuser(fft_tuser),
    .m_axis_data_tlast(fft_tlast),
    .event_frame_started(event_frame_started),
    .event_tlast_unexpected(event_tlast_unexpected),
    .event_tlast_missing(event_tlast_missing),
    .event_status_channel_halt(event_status_channel_halt),
    .event_data_in_channel_halt(event_data_in_channel_halt),
    .event_data_out_channel_halt(event_data_out_channel_halt)
);

blk_mem_gen_1 signal_mem (
    .clka(clock),
    .ena(1),
    .wea(0),
    .addra(cycle),
    .dina(12'b0),
    .douta(sample_data)
);

initial begin
    reset_n = 1'b0;
    cycle = 16'b0;
    #20;
    reset_n = 1'b1;
end

always @(posedge clock)
begin
    if (cycle == M)
    begin
        $stop;
    end
    if (ram_tready)
        cycle <= cycle + 1;
end

always #5 clock = ~clock;


endmodule