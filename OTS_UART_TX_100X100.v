`timescale 1ns/1ps

module OTS_UART_TX_100X100 #(
    parameter NUM_OTS    = 10,
    parameter NUM_TRIALS = 100,
    parameter CLK_FREQ   = 100_000_000,
    parameter BAUD_RATE  = 9600
)(
    input wire clk,
    input wire rst_n,

    //============================================================
    // Start CSV transmission
    //============================================================
    input wire start_tx,

    //============================================================
    // Result memory read interface
    //============================================================
    output reg [6:0] rd_trial,
    output reg [6:0] rd_ots,

    input wire [9:0] rd_delay,
    input wire       rd_success,
    input wire       rd_timeout,

    //============================================================
    // UART
    //============================================================
    output reg tx,
    output reg busy,
    output reg tx_done
);

    //============================================================
    // UART timing
    //============================================================

    localparam integer CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;


    //============================================================
    // UART states
    //============================================================

    localparam UART_IDLE  = 2'd0;
    localparam UART_START = 2'd1;
    localparam UART_DATA  = 2'd2;
    localparam UART_STOP  = 2'd3;

    reg [1:0] uart_state;

    reg [15:0] baud_counter;
    reg [2:0]  bit_index;

    reg [7:0] tx_byte;
    reg       uart_start;
    reg       uart_busy;


    //============================================================
    // CSV states
    //============================================================

    localparam CSV_IDLE         = 5'd0;
    localparam CSV_HEADER_LOAD  = 5'd1;
    localparam CSV_HEADER_SEND  = 5'd2;
    localparam CSV_HEADER_WAIT  = 5'd3;

    localparam CSV_SET_ADDRESS  = 5'd4;
    localparam CSV_WAIT_1       = 5'd5;
    localparam CSV_WAIT_2       = 5'd6;
    localparam CSV_CAPTURE      = 5'd7;

    localparam CSV_TRIAL1_LOAD  = 5'd8;
    localparam CSV_TRIAL1_SEND  = 5'd9;
    localparam CSV_TRIAL1_WAIT  = 5'd10;

    localparam CSV_TRIAL2_LOAD  = 5'd11;
    localparam CSV_TRIAL2_SEND  = 5'd12;
    localparam CSV_TRIAL2_WAIT  = 5'd13;

    localparam CSV_OTS_LOAD     = 5'd14;
    localparam CSV_OTS_SEND     = 5'd15;
    localparam CSV_OTS_WAIT     = 5'd16;

    localparam CSV_D1_LOAD      = 5'd17;
    localparam CSV_D1_SEND      = 5'd18;
    localparam CSV_D1_WAIT      = 5'd19;

    localparam CSV_D2_LOAD      = 5'd20;
    localparam CSV_D2_SEND      = 5'd21;
    localparam CSV_D2_WAIT      = 5'd22;

    localparam CSV_D3_LOAD      = 5'd23;
    localparam CSV_D3_SEND      = 5'd24;
    localparam CSV_D3_WAIT      = 5'd25;

    localparam CSV_D4_LOAD      = 5'd26;
    localparam CSV_D4_SEND      = 5'd27;
    localparam CSV_D4_WAIT      = 5'd28;

    localparam CSV_S_LOAD       = 5'd29;
    localparam CSV_S_SEND       = 5'd30;
    localparam CSV_S_WAIT       = 5'd31;

    //============================================================
    // The remaining states are encoded separately below
    // using a larger state register.
    //============================================================

    localparam CSV_T_LOAD       = 6'd32;
    localparam CSV_T_SEND       = 6'd33;
    localparam CSV_T_WAIT       = 6'd34;

    localparam CSV_CR_LOAD      = 6'd35;
    localparam CSV_CR_SEND      = 6'd36;
    localparam CSV_CR_WAIT      = 6'd37;

    localparam CSV_LF_LOAD      = 6'd38;
    localparam CSV_LF_SEND      = 6'd39;
    localparam CSV_LF_WAIT      = 6'd40;

    localparam CSV_NEXT         = 6'd41;
    localparam CSV_DONE         = 6'd42;


    reg [5:0] csv_state;


    //============================================================
    // Header counter
    //============================================================

    reg [5:0] header_index;


    //============================================================
    // Latched result
    //============================================================

    reg [9:0] delay_latched;
    reg       success_latched;
    reg       timeout_latched;


    //============================================================
    //============================================================
    // UART TRANSMITTER
    //============================================================
    //============================================================

    always @(posedge clk or negedge rst_n)
    begin
        if (!rst_n)
        begin
            uart_state   <= UART_IDLE;
            baud_counter <= 16'd0;
            bit_index    <= 3'd0;
            tx           <= 1'b1;
            uart_busy    <= 1'b0;
        end
        else
        begin

            case (uart_state)

                //================================================
                // IDLE
                //================================================

                UART_IDLE:
                begin
                    tx           <= 1'b1;
                    baud_counter <= 16'd0;
                    bit_index    <= 3'd0;
                    uart_busy    <= 1'b0;

                    if (uart_start)
                    begin
                        uart_busy    <= 1'b1;
                        baud_counter <= 16'd0;
                        bit_index    <= 3'd0;

                        uart_state <= UART_START;
                    end
                end


                //================================================
                // START BIT
                //================================================

                UART_START:
                begin
                    tx <= 1'b0;

                    if (baud_counter == CLKS_PER_BIT-1)
                    begin
                        baud_counter <= 16'd0;
                        bit_index    <= 3'd0;

                        uart_state <= UART_DATA;
                    end
                    else
                    begin
                        baud_counter <= baud_counter + 1'b1;
                    end
                end


                //================================================
                // DATA BITS
                //================================================

                UART_DATA:
                begin
                    tx <= tx_byte[bit_index];

                    if (baud_counter == CLKS_PER_BIT-1)
                    begin
                        baud_counter <= 16'd0;

                        if (bit_index == 3'd7)
                        begin
                            bit_index <= 3'd0;

                            uart_state <= UART_STOP;
                        end
                        else
                        begin
                            bit_index <= bit_index + 1'b1;
                        end
                    end
                    else
                    begin
                        baud_counter <= baud_counter + 1'b1;
                    end
                end


                //================================================
                // STOP BIT
                //================================================

                UART_STOP:
                begin
                    tx <= 1'b1;

                    if (baud_counter == CLKS_PER_BIT-1)
                    begin
                        baud_counter <= 16'd0;
                        uart_busy    <= 1'b0;

                        uart_state <= UART_IDLE;
                    end
                    else
                    begin
                        baud_counter <= baud_counter + 1'b1;
                    end
                end


                default:
                begin
                    uart_state   <= UART_IDLE;
                    baud_counter <= 16'd0;
                    bit_index    <= 3'd0;
                    tx           <= 1'b1;
                    uart_busy    <= 1'b0;
                end

            endcase

        end
    end


    //============================================================
    //============================================================
    // CSV CONTROLLER
    //============================================================
    //============================================================

    always @(posedge clk or negedge rst_n)
    begin
        if (!rst_n)
        begin
            csv_state <= CSV_IDLE;

            rd_trial <= 7'd0;
            rd_ots   <= 7'd0;

            header_index <= 6'd0;

            delay_latched   <= 10'd0;
            success_latched <= 1'b0;
            timeout_latched <= 1'b0;

            tx_byte   <= 8'd0;
            uart_start <= 1'b0;

            busy    <= 1'b0;
            tx_done <= 1'b0;
        end
        else
        begin

            //====================================================
            // Default pulses
            //====================================================

            uart_start <= 1'b0;
            tx_done    <= 1'b0;


            case (csv_state)

                //================================================
                // IDLE
                //================================================

                CSV_IDLE:
                begin
                    busy <= 1'b0;

                    rd_trial <= 7'd0;
                    rd_ots   <= 7'd0;

                    header_index <= 6'd0;

                    if (start_tx)
                    begin
                        busy <= 1'b1;

                        header_index <= 6'd0;

                        csv_state <= CSV_HEADER_LOAD;
                    end
                end


                //================================================
                // HEADER LOAD
                //================================================

                CSV_HEADER_LOAD:
                begin
                    busy <= 1'b1;

                    case (header_index)

                        6'd0:  tx_byte <= "T";
                        6'd1:  tx_byte <= "r";
                        6'd2:  tx_byte <= "i";
                        6'd3:  tx_byte <= "a";
                        6'd4:  tx_byte <= "l";
                        6'd5:  tx_byte <= ",";

                        6'd6:  tx_byte <= "O";
                        6'd7:  tx_byte <= "T";
                        6'd8:  tx_byte <= "S";
                        6'd9:  tx_byte <= ",";

                        6'd10: tx_byte <= "D";
                        6'd11: tx_byte <= "e";
                        6'd12: tx_byte <= "l";
                        6'd13: tx_byte <= "a";
                        6'd14: tx_byte <= "y";
                        6'd15: tx_byte <= ",";

                        6'd16: tx_byte <= "S";
                        6'd17: tx_byte <= "u";
                        6'd18: tx_byte <= "c";
                        6'd19: tx_byte <= "c";
                        6'd20: tx_byte <= "e";
                        6'd21: tx_byte <= "s";
                        6'd22: tx_byte <= "s";
                        6'd23: tx_byte <= ",";

                        6'd24: tx_byte <= "T";
                        6'd25: tx_byte <= "i";
                        6'd26: tx_byte <= "m";
                        6'd27: tx_byte <= "e";
                        6'd28: tx_byte <= "o";
                        6'd29: tx_byte <= "u";
                        6'd30: tx_byte <= "t";

                        6'd31: tx_byte <= 8'h0D;
                        6'd32: tx_byte <= 8'h0A;

                        default:
                            tx_byte <= 8'h0A;

                    endcase

                    csv_state <= CSV_HEADER_SEND;
                end


                //================================================
                // HEADER SEND
                //================================================

                CSV_HEADER_SEND:
                begin
                    busy <= 1'b1;

                    if (!uart_busy)
                    begin
                        uart_start <= 1'b1;

                        csv_state <= CSV_HEADER_WAIT;
                    end
                end


                //================================================
                // HEADER WAIT
                //================================================

                CSV_HEADER_WAIT:
                begin
                    busy <= 1'b1;

                    if (!uart_busy)
                    begin
                        if (header_index == 6'd32)
                        begin
                            header_index <= 6'd0;

                            rd_trial <= 7'd0;
                            rd_ots   <= 7'd0;

                            csv_state <= CSV_SET_ADDRESS;
                        end
                        else
                        begin
                            header_index <= header_index + 1'b1;

                            csv_state <= CSV_HEADER_LOAD;
                        end
                    end
                end


                //================================================
                // SET MEMORY ADDRESS
                //================================================

                CSV_SET_ADDRESS:
                begin
                    busy <= 1'b1;

                    csv_state <= CSV_WAIT_1;
                end


                //================================================
                // BRAM WAIT 1
                //================================================

                CSV_WAIT_1:
                begin
                    busy <= 1'b1;

                    csv_state <= CSV_WAIT_2;
                end


                //================================================
                // BRAM WAIT 2
                //================================================

                CSV_WAIT_2:
                begin
                    busy <= 1'b1;

                    csv_state <= CSV_CAPTURE;
                end


                //================================================
                // CAPTURE MEMORY DATA
                //================================================

                CSV_CAPTURE:
                begin
                    busy <= 1'b1;

                    delay_latched   <= rd_delay;
                    success_latched <= rd_success;
                    timeout_latched <= rd_timeout;

                    csv_state <= CSV_TRIAL1_LOAD;
                end


                //================================================
                // TRIAL DIGIT 1 LOAD
                //================================================

                CSV_TRIAL1_LOAD:
                begin
                    busy <= 1'b1;

                    tx_byte <= "0" + (rd_trial / 10);

                    csv_state <= CSV_TRIAL1_SEND;
                end


                //================================================
                // TRIAL DIGIT 1 SEND
                //================================================

                CSV_TRIAL1_SEND:
                begin
                    busy <= 1'b1;

                    if (!uart_busy)
                    begin
                        uart_start <= 1'b1;

                        csv_state <= CSV_TRIAL1_WAIT;
                    end
                end


                //================================================
                // TRIAL DIGIT 1 WAIT
                //================================================

                CSV_TRIAL1_WAIT:
                begin
                    busy <= 1'b1;

                    if (!uart_busy)
                        csv_state <= CSV_TRIAL2_LOAD;
                end


                //================================================
                // TRIAL DIGIT 2 LOAD
                //================================================

                CSV_TRIAL2_LOAD:
                begin
                    busy <= 1'b1;

                    tx_byte <= "0" + (rd_trial % 10);

                    csv_state <= CSV_TRIAL2_SEND;
                end


                //================================================
                // TRIAL DIGIT 2 SEND
                //================================================

                CSV_TRIAL2_SEND:
                begin
                    busy <= 1'b1;

                    if (!uart_busy)
                    begin
                        uart_start <= 1'b1;

                        csv_state <= CSV_TRIAL2_WAIT;
                    end
                end


                //================================================
                // TRIAL DIGIT 2 WAIT
                //================================================

                CSV_TRIAL2_WAIT:
                begin
                    busy <= 1'b1;

                    if (!uart_busy)
                        csv_state <= CSV_OTS_LOAD;
                end


                //================================================
                // OTS LOAD
                //================================================

                CSV_OTS_LOAD:
                begin
                    busy <= 1'b1;

                    tx_byte <= "0" + rd_ots;

                    csv_state <= CSV_OTS_SEND;
                end


                //================================================
                // OTS SEND
                //================================================

                CSV_OTS_SEND:
                begin
                    busy <= 1'b1;

                    if (!uart_busy)
                    begin
                        uart_start <= 1'b1;

                        csv_state <= CSV_OTS_WAIT;
                    end
                end


                //================================================
                // OTS WAIT
                //================================================

                CSV_OTS_WAIT:
                begin
                    busy <= 1'b1;

                    if (!uart_busy)
                        csv_state <= CSV_D1_LOAD;
                end


                //================================================
                // DELAY DIGIT 1 LOAD
                //================================================

                CSV_D1_LOAD:
                begin
                    busy <= 1'b1;

                    tx_byte <= "0" + (delay_latched / 1000);

                    csv_state <= CSV_D1_SEND;
                end


                CSV_D1_SEND:
                begin
                    busy <= 1'b1;

                    if (!uart_busy)
                    begin
                        uart_start <= 1'b1;
                        csv_state <= CSV_D1_WAIT;
                    end
                end


                CSV_D1_WAIT:
                begin
                    busy <= 1'b1;

                    if (!uart_busy)
                        csv_state <= CSV_D2_LOAD;
                end


                //================================================
                // DELAY DIGIT 2
                //================================================

                CSV_D2_LOAD:
                begin
                    busy <= 1'b1;

                    tx_byte <= "0" +
                               ((delay_latched / 100) % 10);

                    csv_state <= CSV_D2_SEND;
                end


                CSV_D2_SEND:
                begin
                    busy <= 1'b1;

                    if (!uart_busy)
                    begin
                        uart_start <= 1'b1;
                        csv_state <= CSV_D2_WAIT;
                    end
                end


                CSV_D2_WAIT:
                begin
                    busy <= 1'b1;

                    if (!uart_busy)
                        csv_state <= CSV_D3_LOAD;
                end


                //================================================
                // DELAY DIGIT 3
                //================================================

                CSV_D3_LOAD:
                begin
                    busy <= 1'b1;

                    tx_byte <= "0" +
                               ((delay_latched / 10) % 10);

                    csv_state <= CSV_D3_SEND;
                end


                CSV_D3_SEND:
                begin
                    busy <= 1'b1;

                    if (!uart_busy)
                    begin
                        uart_start <= 1'b1;
                        csv_state <= CSV_D3_WAIT;
                    end
                end


                CSV_D3_WAIT:
                begin
                    busy <= 1'b1;

                    if (!uart_busy)
                        csv_state <= CSV_D4_LOAD;
                end


                //================================================
                // DELAY DIGIT 4
                //================================================

                CSV_D4_LOAD:
                begin
                    busy <= 1'b1;

                    tx_byte <= "0" +
                               (delay_latched % 10);

                    csv_state <= CSV_D4_SEND;
                end


                CSV_D4_SEND:
                begin
                    busy <= 1'b1;

                    if (!uart_busy)
                    begin
                        uart_start <= 1'b1;
                        csv_state <= CSV_D4_WAIT;
                    end
                end


                CSV_D4_WAIT:
                begin
                    busy <= 1'b1;

                    if (!uart_busy)
                        csv_state <= CSV_S_LOAD;
                end


                //================================================
                // SUCCESS
                //================================================

                CSV_S_LOAD:
                begin
                    busy <= 1'b1;

                    if (success_latched)
                        tx_byte <= "1";
                    else
                        tx_byte <= "0";

                    csv_state <= CSV_S_SEND;
                end


                CSV_S_SEND:
                begin
                    busy <= 1'b1;

                    if (!uart_busy)
                    begin
                        uart_start <= 1'b1;
                        csv_state <= CSV_S_WAIT;
                    end
                end


                CSV_S_WAIT:
                begin
                    busy <= 1'b1;

                    if (!uart_busy)
                        csv_state <= CSV_T_LOAD;
                end


                //================================================
                // TIMEOUT
                //================================================

                CSV_T_LOAD:
                begin
                    busy <= 1'b1;

                    if (timeout_latched)
                        tx_byte <= "1";
                    else
                        tx_byte <= "0";

                    csv_state <= CSV_T_SEND;
                end


                CSV_T_SEND:
                begin
                    busy <= 1'b1;

                    if (!uart_busy)
                    begin
                        uart_start <= 1'b1;
                        csv_state <= CSV_T_WAIT;
                    end
                end


                CSV_T_WAIT:
                begin
                    busy <= 1'b1;

                    if (!uart_busy)
                        csv_state <= CSV_CR_LOAD;
                end


                //================================================
                // CR
                //================================================

                CSV_CR_LOAD:
                begin
                    busy <= 1'b1;

                    tx_byte <= 8'h0D;

                    csv_state <= CSV_CR_SEND;
                end


                CSV_CR_SEND:
                begin
                    busy <= 1'b1;

                    if (!uart_busy)
                    begin
                        uart_start <= 1'b1;
                        csv_state <= CSV_CR_WAIT;
                    end
                end


                CSV_CR_WAIT:
                begin
                    busy <= 1'b1;

                    if (!uart_busy)
                        csv_state <= CSV_LF_LOAD;
                end


                //================================================
                // LF
                //================================================

                CSV_LF_LOAD:
                begin
                    busy <= 1'b1;

                    tx_byte <= 8'h0A;

                    csv_state <= CSV_LF_SEND;
                end


                CSV_LF_SEND:
                begin
                    busy <= 1'b1;

                    if (!uart_busy)
                    begin
                        uart_start <= 1'b1;
                        csv_state <= CSV_LF_WAIT;
                    end
                end


                CSV_LF_WAIT:
                begin
                    busy <= 1'b1;

                    if (!uart_busy)
                        csv_state <= CSV_NEXT;
                end


                //================================================
                // NEXT RESULT
                //================================================

                CSV_NEXT:
                begin
                    busy <= 1'b1;

                    if (rd_ots < NUM_OTS-1)
                    begin
                        rd_ots <= rd_ots + 1'b1;

                        csv_state <= CSV_SET_ADDRESS;
                    end
                    else
                    begin
                        rd_ots <= 7'd0;

                        if (rd_trial < NUM_TRIALS-1)
                        begin
                            rd_trial <= rd_trial + 1'b1;

                            csv_state <= CSV_SET_ADDRESS;
                        end
                        else
                        begin
                            csv_state <= CSV_DONE;
                        end
                    end
                end


                //================================================
                // COMPLETE
                //================================================

                CSV_DONE:
                begin
                    busy    <= 1'b0;
                    tx_done <= 1'b1;

                    csv_state <= CSV_IDLE;
                end


                //================================================
                // DEFAULT
                //================================================

                default:
                begin
                    csv_state <= CSV_IDLE;

                    rd_trial <= 7'd0;
                    rd_ots   <= 7'd0;

                    header_index <= 6'd0;

                    delay_latched   <= 10'd0;
                    success_latched <= 1'b0;
                    timeout_latched <= 1'b0;

                    tx_byte    <= 8'd0;
                    uart_start <= 1'b0;

                    busy    <= 1'b0;
                    tx_done <= 1'b0;
                end

            endcase

        end
    end

endmodule