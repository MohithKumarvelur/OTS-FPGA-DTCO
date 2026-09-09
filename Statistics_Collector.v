`timescale 1ns/1ps

module Statistics_Collector(

    input  wire        clk,
    input  wire        rst_n,

    input  wire        stats_valid,
    input  wire        timeout_flag,

    input  wire [9:0]  delay_count,

    output reg [9:0]   switching_delay,
    output reg         switch_success,
    output reg         timeout_event

);

    //----------------------------------------------------
    // Store Result of Current Trial
    //----------------------------------------------------

    always @(posedge clk or negedge rst_n)
    begin

        if(!rst_n)
        begin
            switching_delay <= 10'd0;
            switch_success  <= 1'b0;
            timeout_event   <= 1'b0;
        end

        else if(stats_valid)
        begin

            switching_delay <= delay_count;

            if(timeout_flag)
            begin
                switch_success <= 1'b0;
                timeout_event  <= 1'b1;
            end
            else
            begin
                switch_success <= 1'b1;
                timeout_event  <= 1'b0;
            end

        end

    end

endmodule
