`timescale 1ns/1ps

module Basys3_100_Top #(
    parameter NUM_OTS    = 10,
    parameter NUM_TRIALS = 100,
    parameter CLK_FREQ   = 100_000_000,
    parameter BAUD_RATE  = 9600,
    parameter MEM_FILE   = "LUT3.4V.mem"
)(
    input wire clk,
    input wire rst_n,
    input wire start,

    output wire uart_tx,

    output wire [3:0] led,

    output wire [6:0] seg,
    output wire [3:0] an,
    output wire dp
);


    //============================================================
    // OTS ARRAY SIGNALS
    //============================================================

    wire [NUM_OTS*10-1:0] ots_delay;
    wire [NUM_OTS-1:0]    ots_done;
    wire [NUM_OTS-1:0]    ots_done_latched;
    wire [NUM_OTS-1:0]    ots_success;
    wire [NUM_OTS-1:0]    ots_timeout;


    //============================================================
    // CONTROLLER SIGNALS
    //============================================================

    wire       start_trial;
    wire       results_valid;
    wire       controller_done;
    wire [6:0] trial_index;
    wire       controller_busy;


    //============================================================
    // RESULT MEMORY SIGNALS
    //============================================================

    wire       storage_done;
    wire [6:0] stored_trial_count;


    //============================================================
    // UART SIGNALS
    //============================================================

    wire       uart_busy;
    wire       uart_done;

    wire [6:0] uart_rd_trial;
    wire [6:0] uart_rd_ots;

    wire [9:0] uart_rd_delay;
    wire       uart_rd_success;
    wire       uart_rd_timeout;


    //============================================================
    // 1. 10 OTS ARRAY
    //============================================================

    OTS_10_Array #(
        .NUM_OTS  (NUM_OTS),
        .MEM_FILE (MEM_FILE)
    )
    u_ots_array
    (
        .clk             (clk),
        .rst_n           (rst_n),
        .start           (start_trial),

        .switching_delay (ots_delay),
        .done             (ots_done),
        .done_latched    (ots_done_latched),
        .switch_success  (ots_success),
        .timeout_flag    (ots_timeout)
    );


    //============================================================
    // 2. TRIAL CONTROLLER
    //
    // 10 OTS devices
    // 100 trials
    // 1000 total results
    //============================================================

    OTS_100_Controller #(
        .NUM_OTS    (NUM_OTS),
        .NUM_TRIALS (NUM_TRIALS)
    )
    u_controller
    (
        .clk              (clk),
        .rst_n            (rst_n),
        .start            (start),

        .ots_done_latched (ots_done_latched),

        .start_trial      (start_trial),
        .results_valid    (results_valid),
        .all_trials_done  (controller_done),

        .trial_index      (trial_index),
        .busy             (controller_busy)
    );


    //============================================================
    // 3. RESULT MEMORY
    //
    // Four 36-bit BRAM banks:
    //
    // Bank 0 -> OTS 0,1,2
    // Bank 1 -> OTS 3,4,5
    // Bank 2 -> OTS 6,7,8
    // Bank 3 -> OTS 9
    //============================================================

    OTS_Result_Memory #(
        .NUM_OTS    (NUM_OTS),
        .NUM_TRIALS (NUM_TRIALS)
    )
    u_result_memory
    (
        .clk                (clk),
        .rst_n              (rst_n),

        .results_valid      (results_valid),
        .trial_index        (trial_index),

        .switching_delay    (ots_delay),
        .switch_success     (ots_success),
        .timeout_flag       (ots_timeout),

        // UART read address
        .rd_trial           (uart_rd_trial),
        .rd_ots             (uart_rd_ots),

        // UART read data
        .rd_delay           (uart_rd_delay),
        .rd_success         (uart_rd_success),
        .rd_timeout         (uart_rd_timeout),

        // Storage status
        .storage_done       (storage_done),
        .stored_trial_count (stored_trial_count)
    );


    //============================================================
    // 4. UART TRANSMITTER
    //
    // Starts after all 100 trials have been stored.
    //============================================================

    OTS_UART_TX_100X100 #(
        .NUM_OTS    (NUM_OTS),
        .NUM_TRIALS (NUM_TRIALS),
        .CLK_FREQ   (CLK_FREQ),
        .BAUD_RATE  (BAUD_RATE)
    )
    u_uart_tx
    (
        .clk        (clk),
        .rst_n      (rst_n),

        .start_tx   (storage_done),

        .rd_trial   (uart_rd_trial),
        .rd_ots     (uart_rd_ots),

        .rd_delay   (uart_rd_delay),
        .rd_success (uart_rd_success),
        .rd_timeout (uart_rd_timeout),

        .tx         (uart_tx),
        .busy       (uart_busy),
        .tx_done    (uart_done)
    );


    //============================================================
    // 5. DEBUG LED LATCHES
    //
    // LD0 = Experiment currently running
    // LD1 = 100 trials completed
    // LD2 = UART currently transmitting
    // LD3 = UART transmission completed
    //
    // controller_done and uart_done are one-clock pulses.
    // Therefore LD1 and LD3 are latched.
    //============================================================

    reg experiment_done_latched;
    reg uart_done_latched;


    always @(posedge clk or negedge rst_n)
    begin
        if (!rst_n)
        begin
            experiment_done_latched <= 1'b0;
            uart_done_latched       <= 1'b0;
        end
        else
        begin

            // Start a new experiment -> clear old status
            if (start)
            begin
                experiment_done_latched <= 1'b0;
                uart_done_latched       <= 1'b0;
            end

            // Entire 100-trial experiment completed
            if (controller_done)
            begin
                experiment_done_latched <= 1'b1;
            end

            // Entire UART CSV transmission completed
            if (uart_done)
            begin
                uart_done_latched <= 1'b1;
            end

        end
    end


    //============================================================
    // LED ASSIGNMENTS
    //============================================================

    // LD0
    // Controller is running
    assign led[0] = controller_busy;

    // LD1
    // 100 trials completed
    assign led[1] = experiment_done_latched;

    // LD2
    // UART is currently transmitting
    assign led[2] = uart_busy;

    // LD3
    // UART transmission completed
    assign led[3] = uart_done_latched;


    //============================================================
    // 6. SEVEN-SEGMENT DISPLAY
    //
    // Before completion:
    //     Display stored trial count.
    //
    // After completion:
    //     Display 1000.
    //
    // Four digits are multiplexed continuously.
    //============================================================

    reg [6:0] seg_reg;
    reg [3:0] an_reg;
    reg       dp_reg;

    reg [1:0] digit_select;
    reg [15:0] display_number;

    reg [16:0] refresh_counter;


    //============================================================
    // Seven-segment refresh counter
    //
    // 100 MHz clock.
    //
    // Counter reaches 99999:
    //
    // 100000 clock cycles = 1 ms
    //
    // One digit changes every 1 ms.
    // Four digits are therefore refreshed every 4 ms.
    //============================================================

    always @(posedge clk or negedge rst_n)
    begin
        if (!rst_n)
        begin
            refresh_counter <= 17'd0;
            digit_select    <= 2'd0;
        end
        else
        begin
            if (refresh_counter == 17'd99999)
            begin
                refresh_counter <= 17'd0;
                digit_select    <= digit_select + 1'b1;
            end
            else
            begin
                refresh_counter <= refresh_counter + 1'b1;
            end
        end
    end


    //============================================================
    // Number selected for display
    //
    // During experiment:
    //     stored_trial_count
    //
    // After experiment:
    //     1000
    //============================================================

    always @(*)
    begin
        if (experiment_done_latched)
            display_number = 16'd1000;
        else
            display_number = stored_trial_count;
    end


    //============================================================
    // Seven-segment multiplexing
    //
    // Basys 3 seven-segment display is active LOW.
    //
    // an = 1110 -> rightmost digit
    // an = 1101 -> second digit
    // an = 1011 -> third digit
    // an = 0111 -> leftmost digit
    //============================================================

    always @(*)
    begin

        // Decimal point OFF
        dp_reg = 1'b1;

        case (digit_select)

            //================================================
            // Digit 0 - rightmost
            //================================================
            2'd0:
            begin

                an_reg = 4'b1110;

                case (display_number % 10)

                    0: seg_reg = 7'b1000000;
                    1: seg_reg = 7'b1111001;
                    2: seg_reg = 7'b0100100;
                    3: seg_reg = 7'b0110000;
                    4: seg_reg = 7'b0011001;
                    5: seg_reg = 7'b0010010;
                    6: seg_reg = 7'b0000010;
                    7: seg_reg = 7'b1111000;
                    8: seg_reg = 7'b0000000;
                    9: seg_reg = 7'b0010000;

                    default:
                        seg_reg = 7'b1111111;

                endcase

            end


            //================================================
            // Digit 1 - second from right
            //================================================
            2'd1:
            begin

                an_reg = 4'b1101;

                case ((display_number / 10) % 10)

                    0: seg_reg = 7'b1000000;
                    1: seg_reg = 7'b1111001;
                    2: seg_reg = 7'b0100100;
                    3: seg_reg = 7'b0110000;
                    4: seg_reg = 7'b0011001;
                    5: seg_reg = 7'b0010010;
                    6: seg_reg = 7'b0000010;
                    7: seg_reg = 7'b1111000;
                    8: seg_reg = 7'b0000000;
                    9: seg_reg = 7'b0010000;

                    default:
                        seg_reg = 7'b1111111;

                endcase

            end


            //================================================
            // Digit 2 - second from left
            //================================================
            2'd2:
            begin

                an_reg = 4'b1011;

                case ((display_number / 100) % 10)

                    0: seg_reg = 7'b1000000;
                    1: seg_reg = 7'b1111001;
                    2: seg_reg = 7'b0100100;
                    3: seg_reg = 7'b0110000;
                    4: seg_reg = 7'b0011001;
                    5: seg_reg = 7'b0010010;
                    6: seg_reg = 7'b0000010;
                    7: seg_reg = 7'b1111000;
                    8: seg_reg = 7'b0000000;
                    9: seg_reg = 7'b0010000;

                    default:
                        seg_reg = 7'b1111111;

                endcase

            end


            //================================================
            // Digit 3 - leftmost
            //================================================
            2'd3:
            begin

                an_reg = 4'b0111;

                case ((display_number / 1000) % 10)

                    0: seg_reg = 7'b1000000;
                    1: seg_reg = 7'b1111001;
                    2: seg_reg = 7'b0100100;
                    3: seg_reg = 7'b0110000;
                    4: seg_reg = 7'b0011001;
                    5: seg_reg = 7'b0010010;
                    6: seg_reg = 7'b0000010;
                    7: seg_reg = 7'b1111000;
                    8: seg_reg = 7'b0000000;
                    9: seg_reg = 7'b0010000;

                    default:
                        seg_reg = 7'b1111111;

                endcase

            end


            //================================================
            // Default
            //================================================
            default:
            begin
                an_reg  = 4'b1111;
                seg_reg = 7'b1111111;
            end

        endcase

    end


    //============================================================
    // Seven-segment outputs
    //============================================================

    assign seg = seg_reg;
    assign an  = an_reg;
    assign dp  = dp_reg;


endmodule