`timescale 1ns / 1ps

module error_detector (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        packet_valid,
    input  wire        packet_error,
    output reg         error_detected,
    output reg [31:0]  error_count
);

    always @(posedge clk) begin
        if (!rst_n) begin
            error_detected <= 1'b0;
            error_count    <= 32'd0;
        end else begin
            if (packet_valid && packet_error) begin
                error_detected <= 1'b1;
                error_count <= error_count + 1'b1;
            end else begin
                error_detected <= 1'b0;
            end
        end
    end

endmodule
