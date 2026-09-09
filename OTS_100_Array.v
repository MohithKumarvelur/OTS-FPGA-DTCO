`timescale 1ns/1ps

module OTS_10_Array #(
    parameter NUM_OTS  = 10,
    parameter MEM_FILE = "LUT3.4V.mem"
)(
    input wire clk,
    input wire rst_n,
    input wire start,

    // 10-bit delay for each OTS
    output wire [NUM_OTS*10-1:0] switching_delay,

    // One-cycle completion pulse from each OTS
    output wire [NUM_OTS-1:0] done,

    // Latched completion status from each OTS
    output wire [NUM_OTS-1:0] done_latched,

    // Success status from each OTS
    output wire [NUM_OTS-1:0] switch_success,

    // Timeout status from each OTS
    output wire [NUM_OTS-1:0] timeout_flag
);

    genvar i;

    generate

        for(i = 0; i < NUM_OTS; i = i + 1)
        begin : GEN_OTS

            OTS_Top #(
                .MEM_FILE  (MEM_FILE),
                .LFSR_SEED (16'hACE1 + i)
            ) u_ots_top (

                .clk             (clk),
                .rst_n           (rst_n),
                .start           (start),

                .done            (done[i]),
                .done_latched    (done_latched[i]),

                .timeout_flag    (timeout_flag[i]),

                .switching_delay (
                    switching_delay[i*10 +: 10]
                ),

                .switch_success (
                    switch_success[i]
                )

            );

        end

    endgenerate

endmodule