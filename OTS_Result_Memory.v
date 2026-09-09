`timescale 1ns/1ps

module OTS_Result_Memory #(
    parameter NUM_OTS    = 10,
    parameter NUM_TRIALS = 100
)(
    input wire clk,
    input wire rst_n,

    //============================================================
    // WRITE INTERFACE
    //============================================================

    input wire results_valid,
    input wire [6:0] trial_index,

    input wire [NUM_OTS*10-1:0] switching_delay,
    input wire [NUM_OTS-1:0]    switch_success,
    input wire [NUM_OTS-1:0]    timeout_flag,

    //============================================================
    // READ INTERFACE
    //============================================================

    input wire [6:0] rd_trial,
    input wire [6:0] rd_ots,

    output reg [9:0] rd_delay,
    output reg       rd_success,
    output reg       rd_timeout,

    //============================================================
    // STATUS
    //============================================================

    output reg       storage_done,
    output reg [6:0] stored_trial_count
);


    //============================================================
    // MEMORY ORGANIZATION
    //
    // Each result:
    //
    //   Delay   = 10 bits
    //   Success = 1 bit
    //   Timeout = 1 bit
    //
    // Total = 12 bits per OTS
    //
    // Three OTS results are packed into one 36-bit memory word.
    //
    // MEM0 -> OTS 0,1,2
    // MEM1 -> OTS 3,4,5
    // MEM2 -> OTS 6,7,8
    // MEM3 -> OTS 9
    //
    // 100 trials -> 100 memory locations
    //============================================================

    (* ram_style = "block" *)
    reg [35:0] result_mem0 [0:NUM_TRIALS-1];

    (* ram_style = "block" *)
    reg [35:0] result_mem1 [0:NUM_TRIALS-1];

    (* ram_style = "block" *)
    reg [35:0] result_mem2 [0:NUM_TRIALS-1];

    (* ram_style = "block" *)
    reg [35:0] result_mem3 [0:NUM_TRIALS-1];


    //============================================================
    // READ PIPELINE REGISTER
    //============================================================

    reg [35:0] read_word;


    //============================================================
    // WRITE LOGIC
    //============================================================

    always @(posedge clk or negedge rst_n)
    begin

        if (!rst_n)
        begin
            storage_done       <= 1'b0;
            stored_trial_count <= 7'd0;
        end

        else
        begin
            // Default: pulse signal
            storage_done <= 1'b0;


            if (results_valid)
            begin

                //================================================
                // BANK 0
                //
                // OTS 2 | OTS 1 | OTS 0
                //================================================

                result_mem0[trial_index] <=
                {
                    switching_delay[2*10 +: 10],
                    switch_success[2],
                    timeout_flag[2],

                    switching_delay[1*10 +: 10],
                    switch_success[1],
                    timeout_flag[1],

                    switching_delay[0*10 +: 10],
                    switch_success[0],
                    timeout_flag[0]
                };


                //================================================
                // BANK 1
                //
                // OTS 5 | OTS 4 | OTS 3
                //================================================

                result_mem1[trial_index] <=
                {
                    switching_delay[5*10 +: 10],
                    switch_success[5],
                    timeout_flag[5],

                    switching_delay[4*10 +: 10],
                    switch_success[4],
                    timeout_flag[4],

                    switching_delay[3*10 +: 10],
                    switch_success[3],
                    timeout_flag[3]
                };


                //================================================
                // BANK 2
                //
                // OTS 8 | OTS 7 | OTS 6
                //================================================

                result_mem2[trial_index] <=
                {
                    switching_delay[8*10 +: 10],
                    switch_success[8],
                    timeout_flag[8],

                    switching_delay[7*10 +: 10],
                    switch_success[7],
                    timeout_flag[7],

                    switching_delay[6*10 +: 10],
                    switch_success[6],
                    timeout_flag[6]
                };


                //================================================
                // BANK 3
                //
                // Only OTS 9 is required.
                //
                // Upper 24 bits are unused.
                //================================================

                result_mem3[trial_index] <=
                {
                    24'd0,

                    switching_delay[9*10 +: 10],
                    switch_success[9],
                    timeout_flag[9]
                };


                //================================================
                // Update stored trial count
                //================================================

                stored_trial_count <= trial_index + 1'b1;


                //================================================
                // Last trial stored
                //================================================

                if (trial_index == NUM_TRIALS-1)
                    storage_done <= 1'b1;

            end
        end

    end


    //============================================================
    // SYNCHRONOUS BRAM READ
    //
    // Address is applied:
    //
    //       rd_trial
    //       rd_ots
    //
    // At the rising clock edge, the selected memory word
    // is loaded into read_word.
    //
    // IMPORTANT:
    // rd_ots determines which memory bank is selected.
    //============================================================

    always @(posedge clk or negedge rst_n)
    begin

        if (!rst_n)
        begin
            read_word <= 36'd0;
        end

        else
        begin

            case (rd_ots)

                7'd0,
                7'd1,
                7'd2:
                    read_word <= result_mem0[rd_trial];


                7'd3,
                7'd4,
                7'd5:
                    read_word <= result_mem1[rd_trial];


                7'd6,
                7'd7,
                7'd8:
                    read_word <= result_mem2[rd_trial];


                7'd9:
                    read_word <= result_mem3[rd_trial];


                default:
                    read_word <= 36'd0;

            endcase

        end

    end


    //============================================================
    // READ DATA DECODE
    //
    // This is deliberately separate from the BRAM read above.
    //
    // Therefore:
    //
    // Clock N:
    //     BRAM address -> read_word
    //
    // Clock N+1:
    //     read_word -> rd_delay/success/timeout
    //
    // This makes the BRAM latency explicit.
    //============================================================

    always @(posedge clk or negedge rst_n)
    begin

        if (!rst_n)
        begin
            rd_delay   <= 10'd0;
            rd_success <= 1'b0;
            rd_timeout <= 1'b0;
        end

        else
        begin

            case (rd_ots % 3)

                //================================================
                // OTS 0,3,6,9
                //================================================

                0:
                begin
                    rd_delay   <= read_word[11:2];
                    rd_success <= read_word[1];
                    rd_timeout <= read_word[0];
                end


                //================================================
                // OTS 1,4,7
                //================================================

                1:
                begin
                    rd_delay   <= read_word[23:14];
                    rd_success <= read_word[13];
                    rd_timeout <= read_word[12];
                end


                //================================================
                // OTS 2,5,8
                //================================================

                2:
                begin
                    rd_delay   <= read_word[35:26];
                    rd_success <= read_word[25];
                    rd_timeout <= read_word[24];
                end


                default:
                begin
                    rd_delay   <= 10'd0;
                    rd_success <= 1'b0;
                    rd_timeout <= 1'b0;
                end

            endcase

        end

    end

endmodule