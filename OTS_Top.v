`timescale 1ns/1ps

module OTS_Top #(

    parameter MEM_FILE  = "LUT3.4V.mem",
    parameter LFSR_SEED = 16'hACE1

)(

    input  wire clk,
    input  wire rst_n,
    input  wire start,

    output wire done,
    output wire done_latched,
    output wire timeout_flag,

    output wire [9:0] switching_delay,
    output wire switch_success

);

    //----------------------------------------------------
    // Internal Signals
    //----------------------------------------------------

    wire [9:0]  delay_count;
    wire [15:0] probability;
    wire [15:0] random_num;

    wire switch_event;
    wire counter_enable;
    wire stats_valid;
    wire timeout;

    //----------------------------------------------------
    // Delay Counter
    //----------------------------------------------------

    Delay_Counter u_delay_counter(

        .clk          (clk),
        .rst_n        (rst_n),
        .start        (start),
        .enable       (counter_enable),
        .switch_event (switch_event),

        .delay_count  (delay_count),
        .done         (timeout)

    );

    //----------------------------------------------------
    // Probability ROM
    //----------------------------------------------------

    Probability_ROM #(

        .MEM_FILE(MEM_FILE)

    ) u_probability_rom(

        .clk        (clk),
        .addr       (delay_count),
        .probability(probability)

    );

    //----------------------------------------------------
    // LFSR
    //----------------------------------------------------

    LFSR16 #(

        .SEED(LFSR_SEED)

    ) u_lfsr(

        .clk        (clk),
        .rst_n      (rst_n),
        .enable     (counter_enable),
        .random_num (random_num)

    );

    //----------------------------------------------------
    // Comparator
    //----------------------------------------------------

    Comparator u_comparator(

        .clk         (clk),
        .rst_n       (rst_n),
        .enable      (counter_enable),

        .random_num  (random_num),
        .probability (probability),

        .switch_event(switch_event)

    );

    //----------------------------------------------------
    // OTS FSM
    //----------------------------------------------------

    OTS_FSM u_fsm(

        .clk            (clk),
        .rst_n          (rst_n),

        .start          (start),
        .switch_event   (switch_event),
        .timeout        (timeout),

        .counter_enable (counter_enable),
        .stats_valid    (stats_valid),
        .done           (done),
        .timeout_flag   (timeout_flag)

    );

    //----------------------------------------------------
    // Latched Completion Flag
    //----------------------------------------------------
    // done       : one-clock pulse from FSM
    // done_latched: remains HIGH after this OTS finishes
    // until the next trial starts.

    reg done_latched_reg;

    assign done_latched = done_latched_reg;

    always @(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
            done_latched_reg <= 1'b0;

        else if(start)
            done_latched_reg <= 1'b0;

        else if(done)
            done_latched_reg <= 1'b1;
    end

    //----------------------------------------------------
    // Statistics Collector
    //----------------------------------------------------

    Statistics_Collector u_statistics(

        .clk             (clk),
        .rst_n           (rst_n),

        .stats_valid     (stats_valid),
        .timeout_flag    (timeout_flag),

        .delay_count     (delay_count),

        .switching_delay (switching_delay),
        .switch_success  (switch_success),

        .timeout_event   ()

    );

endmodule