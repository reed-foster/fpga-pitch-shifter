// shift_reg.v - Reed Foster
// parameterizable shift register

module shift_reg
    #( // parameters
        parameter DELAY = 1,
        parameter DATAWIDTH = 1
    )( // ports
        input clock,
        input reset_n,
        input shift,
        input [DATAWIDTH-1:0] data_in,
        output [DATAWIDTH-1:0] data_out
    );
    // architecture
    
    reg [DATAWIDTH-1:0] data [DELAY-1:0];

    always @(posedge clock)
    begin
        if (reset_n == 0)
        begin
            for (integer i=0; i<DELAY; i=i+1) data[i] <= 0;
        end
        else
        begin
            if (shift)
            begin
                data[0] <= data_in;
                for (integer i=1; i<DELAY; i=i+1) data[i] <= data[i-1];
            end
        end
    end

    assign data_out = data[DELAY-1];
   
    endmodule
