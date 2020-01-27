// maximum_stream.v - Reed Foster
// keeps track of the maximum magnitude (unsigned) over a set stream length
// takes in value and index (indices expected to be increasing)

module maximum_stream
    #( // parameters
        parameter MAG_WIDTH = 96,
        parameter K_WIDTH = 11
    )( // ports
        input clock,
        input reset_n, // should be reset when FFT IP starts outputting new data
        input data_valid,
        input [MAG_WIDTH-1:0] data_in,
        input [K_WIDTH-1:0] k_in,
        output [K_WIDTH-1:0] max_k,
        output max_k_valid // goes high when k_in reaches DEPTH - 1; only goes to 0 on reset
    );
    // architecture
    
    reg [63:0] tmp;
    always @(posedge clock)
    begin
        if (data_valid)
            tmp <= data_in[71:8];
    end

    localparam MAX_K = (1 << K_WIDTH) - 1;
    
    reg [MAG_WIDTH-1:0] max = 0;
    reg [K_WIDTH-1:0] max_k_t = 0;
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
            if (k_in == MAX_K)
            begin
                output_valid <= 1;
            end
        end
    end

endmodule
