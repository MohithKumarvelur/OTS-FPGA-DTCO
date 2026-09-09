`timescale 1ns/1ps

module Delay_Counter #(
    parameter MAX_COUNT = 1023
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        start,          // Reset counter at the beginning of each trial
    input  wire        enable,
    input  wire        switch_event,

    output reg [9:0]   delay_count,
    output wire        done
);

    //----------------------------------------------------
    // Delay Counter
    //----------------------------------------------------

    always @(posedge clk or negedge rst_n)
    begin

        if(!rst_n)
        begin
            delay_count <= 10'd0;
        end

        // Reset counter whenever a new experiment starts
        else if(start)
        begin
            delay_count <= 10'd0;
        end

        // Count until switching or timeout
        else if(enable && !switch_event && !done)
        begin
            delay_count <= delay_count + 10'd1;
        end

    end

    //----------------------------------------------------
    // Timeout Detection
    //----------------------------------------------------

    assign done = (delay_count == MAX_COUNT);

endmodule
