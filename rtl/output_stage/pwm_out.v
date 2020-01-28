module pwm_out (
    input clk,
    input rst, 
    input [11:0] level_in, 
    output pwm_out);
        
    reg [9:0] count;
    assign pwm_out = count < level_in[11:2];
    always @(posedge clk) begin
        if (rst) begin
            count <= 10'b0;
        end 
        else begin
            count <= count+10'b1;
        end
    end

endmodule
