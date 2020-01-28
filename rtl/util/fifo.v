// fifo.v - Reed Foster
// Parametrized Synchronous FIFO

module fifo
    #( // parameters
        parameter ADDRWIDTH = 12,
        parameter WIDTH = 12
    )( // ports
        input clock, reset,
        input dequeue, enqueue,
        input [WIDTH-1:0] data_in,
        output [WIDTH-1:0] data_out,
        output data_valid,
        output full, empty
    );
    // extra bit to detect rollover count
    // if [width-1:0] bits are equal, and the msbs are different, fifo is full
    // if lsbs are equal and msbs are the same, fifo is empty
    reg [ADDRWIDTH:0] deq_addr, enq_addr;   // enq_addr points to empty, deq_addr points to full
    wire full_t, empty_t;
    
    blk_mem_gen_2 data_mem (
      .clka(clock),    // input wire clka
      .ena(1'b1),      // input wire ena
      .wea(enqueue),      // input wire [0 : 0] wea
      .addra(enq_addr),  // input wire [10 : 0] addra
      .dina(data_in),    // input wire [11 : 0] dina
      .douta(),  // output wire [11 : 0] douta
      .clkb(clock),    // input wire clkb
      .enb(1'b1),      // input wire enb
      .web(1'b0),      // input wire [0 : 0] web
      .addrb(deq_addr),  // input wire [10 : 0] addrb
      .dinb(12'b0),    // input wire [11 : 0] dinb
      .doutb(data_out)  // output wire [11 : 0] doutb
    );
    
    shift_reg#(.DELAY(2), .DATA_WIDTH(1)) valid_shift_reg(.clock(clock), 
                                                          .reset_n(~reset), 
                                                          .shift(1'b1), 
                                                          .data_in(dequeue && !empty_t),
                                                          .data_out(data_valid));
    // read_ptr
    always @(posedge clock)
    begin
        if (reset)
            deq_addr <= 0;
        else if (dequeue && !empty_t)
            deq_addr <= deq_addr + 1;
    end

    // write
    always @(posedge clock)
    begin
        if (reset)
            enq_addr <= 0;
        else if (enqueue && !full_t)
            enq_addr <= enq_addr + 1;
    end

    assign full_t = (deq_addr[ADDRWIDTH-1:0] == enq_addr[ADDRWIDTH-1:0]) && (deq_addr[ADDRWIDTH] != enq_addr[ADDRWIDTH]);
    assign empty_t = (deq_addr[ADDRWIDTH-1:0] == enq_addr[ADDRWIDTH-1:0]) && (deq_addr[ADDRWIDTH] == enq_addr[ADDRWIDTH]);
    assign full = full_t;
    assign empty = empty_t;

endmodule
