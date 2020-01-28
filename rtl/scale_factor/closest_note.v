// closest_note.v - Reed Foster
// Finds 1/note for the note closest to fundamental

module closest_note // latency = 5
    #( // parameters
        parameter FUNDAMENTAL_WIDTH = 38 // 16Q21
    )( // ports
        input clock, reset_n,
        input [FUNDAMENTAL_WIDTH*2-1:0] note_data,
        input note_valid,
        input [FUNDAMENTAL_WIDTH-1:0] fundamental,
        output [FUNDAMENTAL_WIDTH-1:0] inv_note
    );
    
    localparam DELTA_NOTE_LATENCY = 4;

    // Calculate |fundamental - note|
    wire [FUNDAMENTAL_WIDTH-1:0] delta_f;
    wire [FUNDAMENTAL_WIDTH-1:0] delta_f_abs = (delta_f[FUNDAMENTAL_WIDTH-1] ? ~delta_f + 1 : delta_f);
    // Add/Sub IP
    // A: 38-bit signed
    // B: 38-bit signed
    // S: 38-bit signed
    // autolatency 4 cycles
    // no clock enable
    c_addsub_0 sub_note_fundamental (
        .CLK(clock),
        .A(note_data[FUNDAMENTAL_WIDTH*2-1:FUNDAMENTAL_WIDTH]), // upper half of note_data corresponds to note
        .B(fundamental),
        .S(delta_f)
    );
    
    wire [FUNDAMENTAL_WIDTH-1:0] inv_note_sync;
    wire note_valid_sync;
    shift_reg #(.DELAY(DELTA_NOTE_LATENCY), .DATA_WIDTH(FUNDAMENTAL_WIDTH+1)) delay_inv_note ( 
        .clock(clock), .reset_n(reset_n),
        .shift(1),
        .data_in({note_valid, note_data[FUNDAMENTAL_WIDTH-1:0]}), // lower half of note_data corresponds to 1/note
        .data_out({note_valid_sync, inv_note_sync})
    );
    
    // track note and 1/note that corresponds to minimum |fundamental - note|
    reg [FUNDAMENTAL_WIDTH-1:0] note = 0;
    reg [FUNDAMENTAL_WIDTH-1:0] inv_note_t = 0;
    assign inv_note = inv_note_t;
    wire new_min = (note > delta_f_abs);
    always @(posedge clock)
    begin
        if (reset_n == 0 || ~note_valid_sync)
        begin
            note <= (1 << FUNDAMENTAL_WIDTH) - 1;
            inv_note_t <= 0;
        end
        else
        begin
            if (new_min & note_valid_sync)
            begin
                note <= delta_f_abs;
                inv_note_t <= inv_note_sync;
            end
        end
    end

endmodule
