`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Tim Magoun 1/24/2020 
//////////////////////////////////////////////////////////////////////////////////


module resampler(
    input clk,
    input rst,
    input [79:0] fft_data,
    input [11:0] fft_user,
    input fft_valid,
    input fft_last,
    input [23:0] scale_factor,
    input scale_factor_valid,
    output [79:0] data_out,
    output output_valid,
    output output_last,
    input output_ready,
    output [11:0] output_k
    );
    
    // CONSTANTS
    wire [11:0] center_bin = 12'd2048;
    wire [12:0] center_bin_2 = 2 * center_bin;
    
    // Address out and COUNT
    reg [11:0] count;       // counter reg (i)
    wire [11:0] idx_out;    // write index out after #5
    
    shift_reg#(.DELAY(5),.DATA_WIDTH(12)) count_shift_reg ( // ports
                                .clock(clk),
                                .reset_n(~rst),
                                .shift(1'b1),
                                .data_in(count),
                                .data_out(idx_out));
        
    // Mux related for data out
    wire count_le_c = count <= center_bin;        // counter less than c
    wire idx_sel;           // count_le_c, but after #3, also idx_comp select to switch between idx1_le_c and idx_l_c
    wire conj_sel;          // count_le_c after #5, used to select if conjugate is used after half way
    
    shift_reg#(.DELAY(3),.DATA_WIDTH(1)) count_le_c_shift_reg ( // ports
                                .clock(clk),
                                .reset_n(~rst),
                                .shift(1'b1),
                                .data_in(count_le_c),
                                .data_out(idx_sel));
                                
    shift_reg#(.DELAY(2),.DATA_WIDTH(1)) idx_sel_shift_reg ( // ports
                                .clock(clk),
                                .reset_n(~rst),
                                .shift(1'b1),
                                .data_in(idx_sel),
                                .data_out(conj_sel));
    
    // Data out
    wire [79:0] data_out_b;
    wire [79:0] data_out_b_conj = {data_out_b[79:40], -data_out_b[39:0]};
    wire [79:0] final_data_out_b = conj_sel ? data_out_b : data_out_b_conj; // Before zero select
    
    // Address options out of multipliers and shifters
    wire [11:0] final_read_addr = idx_sel ? final_idx1 : final_idx2;
    wire [35:0] idx1;
    wire [35:0] idx2;
    wire [11:0] final_idx1 = idx1[32:21];    // Floor of scaled idx
    wire [11:0] final_idx2 = idx2[32:21];    // Floor of scaled idx mirrored
     
    // Comparisions for index bound
    wire idx1_le_c = (final_idx1 <= center_bin);
    wire idx2_l_c = (final_idx2 < center_bin);
    wire not_zero_sel = idx_sel ? idx1_le_c : idx2_l_c;
    wire not_zero_sel_delayed;
    shift_reg#(.DELAY(2),.DATA_WIDTH(1)) not_zero_sel_shift_reg ( // ports
                                .clock(clk),
                                .reset_n(~rst),
                                .shift(1'b1),
                                .data_in(not_zero_sel),
                                .data_out(not_zero_sel_delayed));
    
    assign data_out = not_zero_sel_delayed ? final_data_out_b : 80'b0;
    
    assign output_last = (idx_out == (center_bin_2 - 1'b1));
    
    mult_gen_0 mult_idx1 (
      .CLK(clk),  // input wire CLK
      .A(count),      // input wire [11 : 0] A
      .B(scale_factor),      // input wire [23 : 0] B
      .P(idx1)      // output wire [35 : 0] P
    );
    mult_gen_0 mult_idx2 (
        .CLK(clk),  // input wire CLK
        .A(center_bin_2 - count),      // input wire [11 : 0] A
        .B(scale_factor),      // input wire [23 : 0] B
        .P(idx2)      // output wire [35 : 0] P
    );
    
    blk_mem_gen_0 fft_content (
          .clka(clk),    // input wire clka
          .ena(1'b1),      // input wire ena
          .wea(fft_valid),      // input wire [0 : 0] wea
          .addra(fft_user),  // input wire [11 : 0] addra
          .dina(fft_data),    // input wire [79 : 0] dina
          .douta(),  // output wire [79 : 0] douta --NC--
          .clkb(clk),    // input wire clkb
          .enb(1'b1),      // input wire enb
          .web(1'b0),      // input wire [0 : 0] web
          .addrb(final_read_addr),  // input wire [11 : 0] addrb
          .dinb(80'b0),    // input wire [79 : 0] dinb
          .doutb(data_out_b)  // output wire [79 : 0] doutb
    );
    
    
    
    // Status
    reg input_complete = 1'b0;
    reg busy = 1'b0; // Register to keep track of state: high when
                       // it has complete data from fft and is outputting
    
    shift_reg#(.DELAY(5),.DATA_WIDTH(1)) output_ready_shift_reg ( // ports
                                .clock(clk),
                                .reset_n(~rst),
                                .shift(1'b1),
                                .data_in(busy),
                                .data_out(output_valid));
                                
    shift_reg#(.DELAY(5),.DATA_WIDTH(12)) output_k_shift_reg ( // ports
                                .clock(clk),
                                .reset_n(~rst),
                                .shift(1'b1),
                                .data_in(count),
                                .data_out(output_k));
    
    // Reset logic
    always@(posedge clk) begin
        if (rst == 1'b1) begin
            count <= 12'd0;
            busy <= 1'b0;
            input_complete <= 1'b0;
        end
    end
    
    always@(posedge clk) begin
        // Handles last to start working
        if (fft_last) begin
            input_complete <= 1'b1;
            count <= 0;
        end else if (fft_valid) begin
            input_complete <= 1'b0;
        end
        // Enters processing stage
        if (input_complete && output_ready && scale_factor_valid) begin
            busy <= 1'b1;
        end
        else begin
            busy <= 1'b0;
        end
        
        // Increments one cycle after starting to process
        if (busy) begin
            if (count < 12'd4095) begin
                count <= count + 1;
            end
            else begin
                count <= 0;
                busy <= 0;
                input_complete <= 0; // TESTING ONLY
            end
        end
    end
endmodule
