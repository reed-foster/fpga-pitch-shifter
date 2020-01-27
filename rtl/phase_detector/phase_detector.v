// phase_detector.v - Reed Foster
// module for calculating the phase from cartesian DFT coefficients
// outputs the current window phases and the phases from the previous window

module phase_detector
    #( // parameters
        ADDR_WIDTH = 11, // 2048 point DFT (need to regenerate Block RAM IP when changing this)
        PHASE_WIDTH = 24
    )( // ports
        input clock, reset_n,

        input [47:0] fft_tdata,
        input fft_tvalid,
        input fft_tlast,
        input [15:0] fft_tuser,
        output cordic_tready,

        input [ADDR_WIDTH-1:0] k_max,
        input k_max_valid,

        output [PHASE_WIDTH-1:0] phase,
        output [PHASE_WIDTH-1:0] phase_last,
        output phases_valid
    );
    
    // Wait until last DFT coefficient is received before outputting phase at k_max
    reg done_storing_phase = 0;
    
    //////////////////////////////
    // CORDIC -> Phase RAM pipe
    /////////////////////////////

    // CORDIC signals
    localparam CORDIC_LATENCY = 28;
    wire cordic_phase_valid;
        
    // Current Phase Block RAM signals
    wire [ADDR_WIDTH-2:0] phase_write_addr;
    wire [ADDR_WIDTH-2:0] phase_read_addr;
    wire [PHASE_WIDTH-1:0] phase_data_in;
    wire [PHASE_WIDTH-1:0] phase_data_out;
    wire phase_write_enable;

    assign phase_read_addr = (done_storing_phase) ? k_max[ADDR_WIDTH-2:0] : fft_tuser[ADDR_WIDTH-2:0];
    
    cordic_module #(.ADDR_WIDTH(ADDR_WIDTH), .PHASE_WIDTH(PHASE_WIDTH)) cordic_module_0 (
        .clock(clock), .reset_n(reset_n),
        .fft_tdata(fft_tdata),
        .fft_tvalid(fft_tvalid),
        .fft_tuser(fft_tuser),
        .cordic_tready(cordic_tready),
        .phase(phase_data_in),
        .phase_addr(phase_write_addr),
        .phase_valid(phase_write_enable)
    );
    
    // BRAM IP
    // Size: 2**(ADDR_WIDTH-1) x PHASE_WIDTH
    // Read Latency: 2 cycles
    blk_mem_gen_0 phase_ram (
        .clka(clock), .clkb(clock),
        .ena(1), .wea(phase_write_enable),
        .addra(phase_write_addr),
        .dina(phase_data_in), .douta(),
        .enb(1), .web(0),
        .addrb(phase_read_addr),
        .dinb(0), .doutb(phase_data_out)
    );
    
    //////////////////////////////////////
    // done_storing_phase mgmt: wait until
    // final DFT coefficient to arrive
    // before processing data
    //////////////////////////////////////
    wire tvalid_cordic_sync;
    wire tlast_cordic_sync;

    shift_reg #(.DELAY(CORDIC_LATENCY-1), .DATA_WIDTH(2)) tlast_tvalid_cordic_delay (
        .clock(clock), .reset_n(reset_n),
        .shift(cordic_tready),
        .data_in({fft_tlast, fft_tvalid}),
        .data_out({tlast_cordic_sync, tvalid_cordic_sync})
    );

    always @(posedge clock)
    begin
        if (tlast_cordic_sync)
            done_storing_phase <= 1;
        if (tvalid_cordic_sync)
            done_storing_phase <= 0;
    end   
    
    //////////////////////////////
    // Previous Phase Block RAM
    //////////////////////////////
    wire [ADDR_WIDTH-2:0] last_phase_write_addr;
    wire [ADDR_WIDTH-2:0] last_phase_read_addr;
    wire [33:0] last_phase_data_in;
    wire [33:0] last_phase_data_out;
    wire last_phase_write_enable;
    wire last_phase_read_enable;

    blk_mem_gen_0 last_phase_ram (
        .clka(clock), .clkb(clock),
        .ena(1), .wea(last_phase_write_enable),
        .addra(last_phase_write_addr),
        .dina(phase_data_out), .douta(),
        .enb(done_storing_phase), .web(0),
        .addrb(k_max),
        .dinb(0), .doutb(last_phase_data_out)
    );
    
    // delay write enable and address signals by the read latency of the
    // current phase BRAM
    wire last_phase_write_enable_t;
    assign last_phase_write_enable_t = (done_storing_phase) ? 0: fft_tvalid;
    shift_reg #(.DELAY(2), .DATA_WIDTH(ADDR_WIDTH+1)) last_phase_write_addr_en_delay (
        .clock(clock), .reset_n(reset_n),
        .shift(1),
        .data_in({last_phase_write_enable_t, phase_read_addr}),
        .data_out({last_phase_write_enable, last_phase_write_addr})
    );
    
    //////////////////////
    // Output Generation
    //////////////////////
    assign phase_last = last_phase_data_out;
    assign phase = phase_data_out;
    
    // delay valid signal for 2 cycles to allow BRAM to output data
    wire phase_valid_t;
    assign phase_valid_t = k_max_valid & done_storing_phase;
    shift_reg #(.DELAY(2), .DATA_WIDTH(1)) phase_valid_delay (
        .clock(clock), .reset_n(reset_n),
        .shift(1),
        .data_in(phase_valid_t),
        .data_out(phases_valid)
    );

endmodule
