// scale_factor.v - Reed Foster
// calculates the scale factor required to shift fundamental to be in key 

module scale_factor
    #( // parameters
        parameter FUNDAMENTAL_WIDTH = 38, // 16Q21
        parameter SCALE_WIDTH = 24, // 2Q21
        parameter NOTE_ADDR_WIDTH = 6 // number of slots for notes in key
    )( // ports
        input clock, reset_n,
        input [FUNDAMENTAL_WIDTH-1:0] fundamental,
        input fundamental_valid,
        input [1:0] key_select,
        output [SCALE_WIDTH-1:0] factor,
        output factor_valid
    );
    
    reg enable_module = 0;
    always @(posedge clock)
    begin
        if (reset_n == 0)
            enable_module <= 0;
        else
        begin
            if (fundamental_valid)
                enable_module <= 1;
            else
                enable_module <= 0;
        end
    end

    // note counter, iterates over all notes in LUT
    reg [NOTE_ADDR_WIDTH-1:0] counter = 0;
    wire overflow = counter == (1 << NOTE_ADDR_WIDTH) - 1;
    always @(posedge clock)
    begin
        if (reset_n == 0 || ~enable_module)
            counter <= 0;
        else if (~overflow)
            counter <= counter + 1;
    end
    
    // delay valid signal to be synchronized with calculated scale factor
    // 2 (bram read) + 4 (add/sub) + 1 (min_track) + 7 (mpy)
    shift_reg #(.DELAY(14), .DATA_WIDTH(1)) valid_delayer (
        .clock(clock), .reset_n(reset_n & enable_module),
        .shift(1),
        .data_in(overflow),
        .data_out(factor_valid)
    );
    
    // Note LUT
    wire [FUNDAMENTAL_WIDTH*2-1:0] note_data; // {note, 1/note}
    note_lut #(
        .NOTE_ADDR_WIDTH(NOTE_ADDR_WIDTH),
        .NOTE_DATA_WIDTH(FUNDAMENTAL_WIDTH*2)
    ) note_lut_0 (
        .clock(clock),
        .key_select(key_select),
        .note_addr(counter),
        .note_inv_note(note_data)
    );

    wire enable_module_sync;
    shift_reg #(.DELAY(1), .DATA_WIDTH(1)) sync_enable_signal (
        .clock(clock), .reset_n(reset_n),
        .shift(1),
        .data_in(enable_module),
        .data_out(enable_module_sync)
    );
    
    // tracks the minimum |note - fundamental| and outputs the corresponding
    // 1/note
    wire [FUNDAMENTAL_WIDTH-1:0] inv_note;
    closest_note #(.FUNDAMENTAL_WIDTH(FUNDAMENTAL_WIDTH)) get_inv_note (
        .clock(clock), .reset_n(reset_n & enable_module),
        .note_data(note_data),
        .note_valid(enable_module_sync),
        .fundamental(fundamental),
        .inv_note(inv_note)
    );

    // get scale factor from fundamental * 1/note
    // Multiplier IP
    // A: 38-bit unsigned
    // B: 38-bit unsigned
    // P: 24-bit unsigned [44:21] of full product (2Q21 format)
    // optimal latency 7 cycles
    mult_gen_0 mpy_fundamental_inv_note ( // 7 cycle latency
        .CLK(clock),
        .A(inv_note),
        .B(fundamental),
        .P(factor)
    );
    
endmodule
