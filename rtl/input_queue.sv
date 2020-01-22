// input_queue.sv - Reed Foster
// Synchronous FIFO with shifting back for overlapping sampling windows

module input_queue
    #( // parameters
        parameter ADDRWIDTH = 12,
        parameter WIDTH = 12
    )( // ports
        input clock, reset,
        input shift_back,
        input dequeue, enqueue,
        input [WIDTH-1:0] data_in,
        output reg [WIDTH-1:0] data_out,
        output full, empty
    );
    // architecture

    localparam DEPTH = 2 ** ADDRWIDTH;
    localparam SHIFT = 2 ** (ADDRWIDTH - 1); // oversampling factor of 2

    // extra bit to detect rollover count
    // if [width-1:0] bits are equal, and the msbs are different, fifo is full
    // if lsbs are equal and msbs are the same, fifo is empty
    reg [ADDRWIDTH:0] deq_addr, enq_addr;
    wire full_t, empty_t;

    // ram
    reg [WIDTH-1:0] memory [DEPTH-1:0];
    always_ff @(posedge clock)
    begin
        if (reset) begin 
            data_out <= 0;
            deq_addr <= 0;
            enq_addr <= 0;
        end 
        else if (shift_back)
            deq_addr <= deq_addr - signed(SHIFT);
        else begin
            // dequeue
            if (dequeue && !empty_t) begin
                data_out <= memory[deq_addr[ADDRWIDTH-1:0]];
                deq_addr <= deq_addr + 1;
            end
            // enqueue
            if (!reset && enqueue && !full_t) begin
                memory[enq_addr[ADDRWIDTH-1:0]] <= data_in;
                enq_addr <= enq_addr + 1;
            end
        end
    end

    assign full_t = (deq_addr[ADDRWIDTH-1:0] == enq_addr[ADDRWIDTH-1:0]) && (deq_addr[ADDRWIDTH] != enq_addr[ADDRWIDTH]);
    assign empty_t = (deq_addr[ADDRWIDTH-1:0] == enq_addr[ADDRWIDTH-1:0]) && (deq_addr[ADDRWIDTH] == enq_addr[ADDRWIDTH]);
    assign full = full_t;
    assign empty = empty_t;

endmodule
