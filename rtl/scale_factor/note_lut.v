// note_lut.v - Reed Foster
// BRAM lookup tables for f0 and 1/f0 where f0 is the frequency of a note that
// is in key (based on the selection of key_select)

module note_lut
    #( // parameters
        parameter NOTE_DATA_WIDTH = 38, // 16Q21
        parameter NOTE_ADDR_WIDTH = 6
    )( // ports
        input clock,
        input [1:0] key_select,
        input [NOTE_ADDR_WIDTH-1:0] note_addr,
        output [NOTE_DATA_WIDTH-1:0] note_inv_note
    );
    
    // each BRAM IP is generated with the same configs except for the
    // initialization vector

    wire [NOTE_DATA_WIDTH-1:0] note_luts_out [3:0];
    blk_mem_gen_0 note_lut_0 (
        .addra(note_addr),
        .clka(clock),
        .douta(note_luts_out[0])
    );
    blk_mem_gen_1 note_lut_1 (
        .addra(note_addr),
        .clka(clock),
        .douta(note_luts_out[1])
    );
    blk_mem_gen_2 note_lut_2 (
        .addra(note_addr),
        .clka(clock),
        .douta(note_luts_out[2])
    );
    blk_mem_gen_3 note_lut_3 (
        .addra(note_addr),
        .clka(clock),
        .douta(note_luts_out[3])
    );

    assign note_inv_note = note_luts_out[key_select];

endmodule
