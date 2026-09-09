`timescale 1ns/1ps

module OTS_FSM(

    input  wire clk,
    input  wire rst_n,

    input  wire start,
    input  wire switch_event,
    input  wire timeout,

    output reg counter_enable,
    output reg stats_valid,
    output reg done,
    output reg timeout_flag

);

    localparam IDLE            = 2'b00;
    localparam WAIT_FOR_SWITCH = 2'b01;
    localparam SWITCHED        = 2'b10;
    localparam TIMEOUT         = 2'b11;

    reg [1:0] current_state;
    reg [1:0] next_state;

    //----------------------------------------------------
    // State Register
    //----------------------------------------------------

    always @(posedge clk or negedge rst_n)
    begin

        if(!rst_n)
            current_state <= IDLE;

        else
            current_state <= next_state;

    end

    //----------------------------------------------------
    // Next State Logic
    //----------------------------------------------------

    always @(*)
    begin

        next_state = current_state;

        case(current_state)

            IDLE:
            begin
                if(start)
                    next_state = WAIT_FOR_SWITCH;
            end

            WAIT_FOR_SWITCH:
            begin

                if(switch_event)
                    next_state = SWITCHED;

                else if(timeout)
                    next_state = TIMEOUT;

            end

            SWITCHED:
            begin
                next_state = IDLE;
            end

            TIMEOUT:
            begin
                next_state = IDLE;
            end

            default:
            begin
                next_state = IDLE;
            end

        endcase

    end

    //----------------------------------------------------
    // Output Logic
    //----------------------------------------------------

    always @(*)
    begin

        counter_enable = 1'b0;
        stats_valid    = 1'b0;
        done           = 1'b0;
        timeout_flag   = 1'b0;

        case(current_state)

            IDLE:
            begin
                counter_enable = 1'b0;
            end

            WAIT_FOR_SWITCH:
            begin
                counter_enable = 1'b1;
            end

            SWITCHED:
            begin
                counter_enable = 1'b0;
                stats_valid    = 1'b1;
                done           = 1'b1;
                timeout_flag   = 1'b0;
            end

            TIMEOUT:
            begin
                counter_enable = 1'b0;
                stats_valid    = 1'b1;
                done           = 1'b1;
                timeout_flag   = 1'b1;
            end

            default:
            begin
                counter_enable = 1'b0;
                stats_valid    = 1'b0;
                done           = 1'b0;
                timeout_flag   = 1'b0;
            end

        endcase

    end

endmodule
