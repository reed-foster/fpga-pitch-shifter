//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/25/2020 09:46:57 PM
// Design Name: 
// Module Name: frame_overlap_gen
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module frame_overlap_gen
    #( // parameters
        parameter OUTPUT_RATE = 12'd2267 // Clock cycles per output
    )(
    input clk, rst,
    input [35:0] ifft_data,
    input [11:0] ifft_user,
    input ifft_valid,
    output ifft_ready,
    output [11:0] output_data,
    output output_valid
    );
    
    // 1 bram for combining data, and 1 fifo for output queue, automatically dequeues at
    //      output sample rate (44100 kSa/s)
    wire accumulator_mem_wea = ifft_valid & ifft_user[11]; // Write when it is the second half
    wire [11:0]mem_data_out; // Doutb
    wire [11:0]input_data_delayed;
    
    wire added_frame_valid;
    wire [11:0]added_frame_out = input_data_delayed + mem_data_out; // Output of first half + prev. last half

    reg [11:0] output_counter;
    wire dequeue = (output_counter == OUTPUT_RATE);
    
    // Dequeue once per OUTPUT_RATE, approx 44,100kHz output rate
    always @(posedge clk) begin
        if (rst) begin
            output_counter <= 12'b0;
        end
        else if (dequeue) begin
            output_counter <= 12'b0;
        end
        else begin
            output_counter <= output_counter + 12'b1;
        end
    end
    
    
    shift_reg#(.DELAY(2), .DATA_WIDTH(12)) input_data_shift_reg(.clock(clk),    // Delays input data to be added
                                                          .reset_n(~rst), 
                                                          .shift(1'b1), 
                                                          .data_in(ifft_data[35:24]),
                                                          .data_out(input_data_delayed));
        
    shift_reg#(.DELAY(2), .DATA_WIDTH(1)) addition_valid_shift_reg(.clock(clk),   // Delay if it is first half of data
                                                          .reset_n(~rst), 
                                                          .shift(1'b1), 
                                                          .data_in(ifft_valid & ~ifft_user[11]),   // Read stage is also addition stage, first half of frame
                                                          .data_out(added_frame_valid));   
    
    blk_mem_gen_1 accumulator_mem (     // Stores second half of every frame, waiting to be added to first half of next frame
          .clka(clk),    // input wire clka
          .ena(1'b1),      // input wire ena
          .wea(accumulator_mem_wea),      // input wire [0 : 0] wea
          .addra(ifft_user[10:0]),  // input wire [10 : 0] addra
          .dina(ifft_data[35:24]),    // input wire [11 : 0] dina
          .douta(),  // output wire [11 : 0] douta
          .clkb(clk),    // input wire clkb
          .enb(1'b1),      // input wire enb
          .web(1'b0),      // input wire [0 : 0] web
          .addrb(ifft_user[10:0]),  // input wire [10 : 0] addrb
          .dinb(12'b0),    // input wire [11 : 0] dinb
          .doutb(mem_data_out)  // output wire [11 : 0] doutb
    );
    
    fifo#() output_fifo(.clock(clk),
                        .reset(rst),
                        .dequeue(dequeue),
                        .enqueue(added_frame_valid),
                        .data_in(added_frame_out),
                        .data_out(output_data),
                        .data_valid(output_valid),
                        .full(),
                        .empty());
    
    
   
endmodule