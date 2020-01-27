// input_queue.v - Reed Foster
// toplevel of input queue module
// interfaces between ADC sampler and AXI-Stream FFT IP

module input_queue
    #( // parameters
        ADDR_WIDTH = 11 // 2048 point DFT (need to regenerate Block RAM IP when changing this)
    )( // ports
        input clock, reset_n,

        // ADC sampler interface
        input [11:0] adc_sample,
        input adc_valid,
        
        // AXI-Stream interface
        output [11:0] data,
        output valid,
        input ready,
        output last
    );
    
    wire ram_read, ram_write;
    // shift_reg delays used to keep 
    // valid/last signals in sync with data
    shift_reg #(.DELAY(2), .DATA_WIDTH(1)) valid_delay (
        .clock(clock),
        .reset_n(reset_n),
        .shift(ready),
        .data_in(ram_read),
        .data_out(valid)
    );
    wire last_t;
    shift_reg #(.DELAY(2), .DATA_WIDTH(1)) last_delay (
        .clock(clock),
        .reset_n(reset_n),
        .shift(ready),
        .data_in(last_t),
        .data_out(last)
    );

    // Block RAM IP
    wire [ADDR_WIDTH-1:0] window_addr;
    wire [ADDR_WIDTH-1:0] read_addr, write_addr;
    // generation options
    // Native, True Dual Port RAM with common clock
    // 2048x12
    // 2 clock cycle read latency
    blk_mem_gen_0 sample_data ( 
        .clka(clock), .clkb(clock),
        .ena(1), .wea(ram_write),
        .addra(write_addr),
        .dina(adc_sample), .douta(),
        .enb(ram_read), .web(0),
        .addrb(read_addr),
        .dinb(0), .doutb(data)
    );
    
    // Address manager (fancy FIFO with half-window shiftback)
    window_address_manager #(.ADDRWIDTH(ADDR_WIDTH)) addr_gen (
        .clock(clock), .reset_n(reset_n),
        .dequeue(ready),
        .enqueue(adc_valid),
        .read_addr(read_addr),
        .write_addr(write_addr),
        .read(ram_read),
        .write(ram_write),
        .last(last_t)
    );
        
endmodule
