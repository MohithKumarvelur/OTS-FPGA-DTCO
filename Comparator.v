`timescale 1ns/1ps

module Comparator (

    input  wire        clk,
    input  wire        rst_n,
    input  wire        enable,

    input  wire [15:0] random_num,
    input  wire [15:0] probability,

    output reg         switch_event

);

always @(posedge clk or negedge rst_n)
begin

    if(!rst_n)
    begin
        switch_event <= 1'b0;
    end

    else if(enable)
    begin

        // Generate one-clock switching pulse
        if(random_num < probability)
            switch_event <= 1'b1;
        else
            switch_event <= 1'b0;

    end

    else
    begin
        switch_event <= 1'b0;
    end

end

endmodule
