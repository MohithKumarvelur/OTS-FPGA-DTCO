`timescale 1ns/1ps

module OTS_100_Controller #(
    parameter NUM_OTS    = 10,
    parameter NUM_TRIALS = 100
)(
    input wire clk,
    input wire rst_n,
    input wire start,

    // Done status from each OTS
    input wire [NUM_OTS-1:0] ots_done_latched,

    // Control signals
    output reg start_trial,
    output reg results_valid,
    output reg all_trials_done,

    // Trial counter
    output reg [6:0] trial_index,

    // Controller busy
    output reg busy
);

    //============================================================
    // FSM states
    //============================================================
    localparam S_IDLE       = 3'd0;
    localparam S_START      = 3'd1;
    localparam S_WAIT_CLEAR = 3'd2;
    localparam S_WAIT_DONE  = 3'd3;
    localparam S_STORE      = 3'd4;
    localparam S_NEXT       = 3'd5;
    localparam S_FINISH     = 3'd6;

    reg [2:0] state;

    //============================================================
    // All OTS devices completed?
    //
    // Every OTS has its own done_latched signal.
    // '&' means all 10 must be HIGH.
    //============================================================
    wire all_ots_done;

    assign all_ots_done = &ots_done_latched;


    //============================================================
    // Sequential FSM
    //============================================================
    always @(posedge clk or negedge rst_n)
    begin

        if (!rst_n)
        begin
            state          <= S_IDLE;
            start_trial    <= 1'b0;
            results_valid  <= 1'b0;
            all_trials_done <= 1'b0;
            trial_index    <= 7'd0;
            busy           <= 1'b0;
        end

        else
        begin

            // Default: pulse signals are LOW
            start_trial   <= 1'b0;
            results_valid <= 1'b0;

            case (state)

                //================================================
                // IDLE
                //================================================
                S_IDLE:
                begin
                    busy            <= 1'b0;
                    all_trials_done <= 1'b0;
                    trial_index     <= 7'd0;

                    if (start)
                    begin
                        busy       <= 1'b1;
                        trial_index <= 7'd0;
                        state      <= S_START;
                    end
                end


                //================================================
                // START
                //
                // Generate one-cycle start pulse.
                // All 10 OTS devices receive this simultaneously.
                //================================================
                S_START:
                begin
                    busy        <= 1'b1;
                    start_trial <= 1'b1;

                    state <= S_WAIT_CLEAR;
                end


                //================================================
                // WAIT_CLEAR
                //
                // The OTS done_latched signals are cleared by
                // start_trial.
                //
                // Wait until all of them are LOW before beginning
                // to monitor the new trial.
                //================================================
                S_WAIT_CLEAR:
                begin
                    busy <= 1'b1;

                    if (!all_ots_done)
                    begin
                        state <= S_WAIT_DONE;
                    end
                end


                //================================================
                // WAIT_DONE
                //
                // Wait until every one of the 10 OTS devices
                // finishes its switching trial.
                //================================================
                S_WAIT_DONE:
                begin
                    busy <= 1'b1;

                    if (all_ots_done)
                    begin
                        state <= S_STORE;
                    end
                end


                //================================================
                // STORE
                //
                // Tell the result memory that the current trial
                // results are valid.
                //================================================
                S_STORE:
                begin
                    busy         <= 1'b1;
                    results_valid <= 1'b1;

                    state <= S_NEXT;
                end


                //================================================
                // NEXT
                //
                // Check whether 100 trials are complete.
                //================================================
                S_NEXT:
                begin
                    busy <= 1'b1;

                    if (trial_index == NUM_TRIALS-1)
                    begin
                        // Trial 99 = 100th trial
                        state <= S_FINISH;
                    end

                    else
                    begin
                        // Move to next trial
                        trial_index <= trial_index + 1'b1;

                        state <= S_START;
                    end
                end


                //================================================
                // FINISH
                //
                // Entire experiment completed:
                // 10 OTS × 100 trials = 1000 results
                //================================================
                S_FINISH:
                begin
                    busy            <= 1'b0;
                    all_trials_done <= 1'b1;

                    state <= S_IDLE;
                end


                //================================================
                // DEFAULT
                //================================================
                default:
                begin
                    state          <= S_IDLE;
                    start_trial    <= 1'b0;
                    results_valid  <= 1'b0;
                    all_trials_done <= 1'b0;
                    trial_index    <= 7'd0;
                    busy           <= 1'b0;
                end

            endcase
        end
    end

endmodule
