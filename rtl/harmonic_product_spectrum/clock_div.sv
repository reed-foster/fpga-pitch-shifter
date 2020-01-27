// clock_div.sv - Reed Foster
// parameterizable counter, updates every FACTOR clocks

module clock_div
    #( // parameters
        parameter FACTOR = 1,
        parameter WIDTH = 12
    )( // ports
        input clock, reset_n,
        input clock_enable,
        output [WIDTH-1:0] count
    );
    reg [$clog2(FACTOR+1):0] prescale_counter = 0;
    
    reg [WIDTH-1:0] counter = 0;
    assign count = counter;

    always @(posedge clock)
    begin
        if (reset_n == 0)
            counter <= 0;
        else if (clock_enable)
        begin
            if (prescale_counter == FACTOR-1)
            begin
                counter <= counter + 1;
                prescale_counter <= 0;
            end
            else
                prescale_counter <= prescale_counter + 1;
        end
    end
endmodule


