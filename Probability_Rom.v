`timescale 1ns/1ps

module Probability_ROM #(
    parameter ADDR_WIDTH = 10,
    parameter DATA_WIDTH = 16,
    parameter DEPTH      = 1024,
    parameter MEM_FILE   = "LUT3.4V.mem"
)(
    input wire                  clk,
    input wire [ADDR_WIDTH-1:0] addr,

    output reg [DATA_WIDTH-1:0] probability
);

    //====================================================
    // Distributed ROM
    //
    // Force implementation using LUTs instead of BRAM.
    // This frees Block RAM for result storage.
    //====================================================

    (* rom_style = "distributed" *)
    reg [DATA_WIDTH-1:0] rom [0:DEPTH-1];

    //====================================================
    // Initialize ROM from .mem file
    //====================================================

    initial
    begin
        $readmemh(MEM_FILE, rom);
    end

    //====================================================
    // Synchronous ROM Read
    //====================================================

    always @(posedge clk)
    begin
        if(addr < DEPTH)
            probability <= rom[addr];
        else
            probability <= {DATA_WIDTH{1'b0}};
    end

endmodule