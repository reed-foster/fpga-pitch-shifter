// window_address_manager.sv - Reed Foster
// address manager for FIFO storing overlapped windows

module window_address_manager
    #( // parameters
        parameter ADDRWIDTH = 12
    )( // ports
        input clock,
        input reset_n,
        input dequeue, 
        input enqueue,
        output full,
        output empty,
        output [ADDRWIDTH-1:0] read_addr,
        output [ADDRWIDTH-1:0] write_addr,
        output [ADDRWIDTH-1:0] window_addr,
        output read,
        output write,
        output last
    );
    // architecture

    localparam SHIFT = 2 ** (ADDRWIDTH - 1) - 1; // oversampling factor of 2
    localparam WINDOW_DONE = 2 ** (ADDRWIDTH) - 1;

    // extra bit to detect rollover count
    // if [width-1:0] bits are equal, and the msbs are different, fifo is full
    // if lsbs are equal and msbs are the same, fifo is empty
    reg [ADDRWIDTH:0] deq_addr = 0, enq_addr = 0; // dequeue and enqueue addresses
    
    // deq_addr and (deq_addr - SHIFT) are multiplexed based on how far into the window we are for full detection
    // (don't want to overwrite data that needs to be read again for a subsequent window)
    wire [ADDRWIDTH:0] deq_addr_to_compare;

    wire [ADDRWIDTH:0] shifted_deq_addr; // (deq_addr - SHIFT)
    wire shift_back; // shift deq_addr back by SHIFT whenever a window is completed

    wire full_t, empty_t;

    // counter to track which index we're at in a window (used for window function LUT)
    reg [ADDRWIDTH-1:0] window_addr_t = 0;

    // ram
    always @(posedge clock)
    begin
        if (reset_n == 0)
        begin 
            deq_addr <= 0;
            enq_addr <= 0;
            window_addr_t <= 0;
        end 
        else
        begin
            if (shift_back)
            begin
                deq_addr <= shifted_deq_addr;
            end
            // dequeue
            if (dequeue && !empty_t)
            begin
                deq_addr <= deq_addr + 1;
                window_addr_t <= window_addr_t + 1;
            end
            // enqueue
            if (enqueue && !full_t)
            begin
                enq_addr <= enq_addr + 1;
            end
        end
    end
   
    assign window_addr = window_addr_t;
    assign read_addr = deq_addr;
    assign write_addr = enq_addr;

    assign shift_back = (window_addr_t == WINDOW_DONE);
    assign last = shift_back;
    assign shifted_deq_addr = (deq_addr - SHIFT);
    assign deq_addr_to_compare = (window_addr_t[ADDRWIDTH-1] == 1'b0 ? deq_addr : shifted_deq_addr);

    assign full_t = (deq_addr_to_compare[ADDRWIDTH-1:0] == enq_addr[ADDRWIDTH-1:0]) && (deq_addr_to_compare[ADDRWIDTH] != enq_addr[ADDRWIDTH]);
    assign empty_t = (deq_addr[ADDRWIDTH-1:0] == enq_addr[ADDRWIDTH-1:0]) && (deq_addr[ADDRWIDTH] == enq_addr[ADDRWIDTH]);
    assign full = full_t;
    assign empty = empty_t;
    
    assign read = dequeue && !(empty_t);
    assign write = enqueue && !(full_t);

endmodule
