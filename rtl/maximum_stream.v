// maximum_stream.v - Reed Foster
// keeps track of the maximum magnitude over a set stream length

module maximum_stream
    #( // parameters
        parameter DEPTH = 4096,
        parameter MAG_WIDTH = 96,
        parameter K_WIDTH = 12
    )( // ports
        input clock,
        input reset_n,
        input data_valid,
        input [MAG_WIDTH-1:0] data_in,
        input [K_WIDTH-1:0] k_in,
        output [K_WIDTH-1:0] max_k,
        output max_k_valid
    );
    // architecture
    
    reg [MAG_WIDTH-1:0] max;
    reg [K_WIDTH-1:0] max_k_t;
    assign max_k = max_k_t;

    reg output_valid = 0;
    assign max_k_valid = output_valid;

    always @(posedge clock)
    begin
        if (reset_n == 0)
        begin
            max <= 0;
            max_k_t <= 0;
            output_valid <= 0;
        end
        else
        begin
            if (data_valid)
            begin
                if (max < data_in)
                begin
                    max <= data_in;
                    max_k_t <= k_in;
                end
            end
            if (k_in == DEPTH - 1)
            begin
                output_valid <= 1;
            end
        end
    end

endmodule
