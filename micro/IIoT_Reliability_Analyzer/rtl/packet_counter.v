`timescale 1ns / 1ps

module packet_counter (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        packet_valid,
    output reg [31:0]  packet_count
);

    always @(posedge clk) begin
        if (!rst_n)
            packet_count <= 32'd0;
        else if (packet_valid)
            packet_count <= packet_count + 1'b1;
    end

endmodule
