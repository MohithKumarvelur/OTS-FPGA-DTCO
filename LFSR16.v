`timescale 1ns/1ps

module LFSR16 #(
    parameter SEED = 16'hACE1
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        enable,

    output reg [15:0]  random_num
);

    //====================================================
    // Primitive Polynomial:
    // x^16 + x^14 + x^13 + x^11 + 1
    //====================================================

    wire feedback;

    assign feedback = random_num[15] ^
                      random_num[13] ^
                      random_num[12] ^
                      random_num[10];

    always @(posedge clk or negedge rst_n)
    begin

        if(!rst_n)
            random_num <= SEED;

        else if(enable)
            random_num <= {random_num[14:0], feedback};

    end

endmodule
