// harmonic_product_spectrum.v - Reed Foster
// estimates the DFT index k which corresponds to the bin containing the
// fundamental frequency of the original signal

module harmonic_product_spectrum
    #( // parameters
        parameter K_WIDTH = 11 // 2048 point DFT
    )( // ports
        input clock, reset_n,
        input [47:0] fft_tdata,
        input fft_tvalid, fft_tlast,
        input [15:0] fft_tuser,
        input cordic_ready,
        output [K_WIDTH-1:0] k_max,
        output k_max_valid
    );
    
    wire [31:0] mag;
    complex_mag complex_mag_0 (
        .clock(clock),
        .complex(fft_tdata),
        .magnitude(mag)
    );
    
    wire [31:0] mag_ram_data; // output of BRAM to triple_element_product
    wire [95:0] max_stream_in; // output of triple_element_product to maximum_stream
    triple_element_product hps_product_gen (
        .clock(clock),
        .data_in(mag_ram_data), .product(max_stream_in)
    );
    
    reg done_storing_mag = 0; // goes high when all magnitudes are stored to RAM, enabling this module
    wire [K_WIDTH-2:0] k_out; // output of addr_gen, input to maximum_stream to determine argmax
    wire hps_addr_done; // when all addresses are finished, this resets done_storing_mag, so module can process new data
    wire hps_mag_ram_en; 
    wire [K_WIDTH-2:0] hps_mag_ram_addr;
    // temp for product valid, generated for every third magnitude read
    // so the only the product of consecutive triples is checked against the
    // current max in maximum_stream
    wire product_valid_t; 

    hps_address_gen #(.K_WIDTH(K_WIDTH)) hps_addr ( // 2048 point DFT (only processes first 1024)
        .clock(clock), .reset_n(reset_n),
        .done_storing_mag(done_storing_mag),
        .k(k_out),
        .ram_addr(hps_mag_ram_addr), .ram_enable(hps_mag_ram_en),
        .done(hps_addr_done),
        .triple_complete(product_valid_t)
    );
       
    wire fft_tvalid_delayed, fft_tlast_delayed;
    wire [K_WIDTH-1:0] k_in_delayed;
    shift_reg #(.DELAY(6), .DATA_WIDTH(K_WIDTH+2)) tlast_tvalid_k_in_delay (
        .clock(clock), .reset_n(reset_n),
        .shift(cordic_ready),
        .data_in({fft_tlast, fft_tvalid, fft_tuser[K_WIDTH-1:0]}),
        .data_out({fft_tlast_delayed, fft_tvalid_delayed, k_in_delayed})
    );

    blk_mem_gen_0 mag_ram (
        .clka(clock),
        .ena(1), .wea(fft_tvalid_delayed & ~k_in_delayed[K_WIDTH-1]), // only write if the FFT data is valid and is in the first half of the DFT
        .addra(k_in_delayed[K_WIDTH-2:0]),
        .dina(mag), .douta(),
        .clkb(clock),
        .enb(hps_mag_ram_en), .web(0),
        .addrb(hps_mag_ram_addr),
        .dinb(32'b0), .doutb(mag_ram_data)
    );
    
    wire hps_product_valid;
    wire [K_WIDTH-2:0] hps_product_k;
    shift_reg #(.DELAY(16), .DATA_WIDTH(K_WIDTH)) product_k_delay_16 (
        .clock(clock), .reset_n(reset_n),
        .shift(1),
        .data_in({product_valid_t, k_out}),
        .data_out({hps_product_valid, hps_product_k})
    );
    assign k_max[K_WIDTH-1] = 0;
    maximum_stream #(.MAG_WIDTH(96), .K_WIDTH(K_WIDTH-1)) k_max_tracker (
        .clock(clock), .reset_n(reset_n || fft_tvalid),
        .data_valid(hps_product_valid),
        .data_in(max_stream_in),
        .k_in(hps_product_k),
        .max_k(k_max[K_WIDTH-2:0]),
        .max_k_valid(k_max_valid)
    );
    
    always @(posedge clock)
    begin
        if (fft_tlast_delayed)
            done_storing_mag <= 1;
        else if (hps_addr_done)
            done_storing_mag <= 0;
    end
endmodule
