`timescale 1ns / 1ps

module reliability_analyzer (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        packet_valid,
    input  wire        packet_error,
    output wire        error_detected,
    output wire [31:0] error_count,
    output wire [31:0] packet_count,
    output reg  [7:0]  error_rate,
    output reg  [7:0]  reliability_score,
    output wire [1:0]  predictive_status,
    output wire        trend_up
);

    reg [63:0] scaled_error_count;
    reg [3:0] packets_in_window;
    reg window_sample_valid;

    error_detector u_error_detector (
        .clk            (clk),
        .rst_n          (rst_n),
        .packet_valid   (packet_valid),
        .packet_error   (packet_error),
        .error_detected (error_detected),
        .error_count    (error_count)
    );

    packet_counter u_packet_counter (
        .clk          (clk),
        .rst_n        (rst_n),
        .packet_valid (packet_valid),
        .packet_count (packet_count)
    );

    // Compare reliability once per ten valid packets, not on every packet.
    always @(posedge clk) begin
        if (!rst_n) begin
            packets_in_window <= 4'd0;
            window_sample_valid <= 1'b0;
        end else begin
            window_sample_valid <= 1'b0;
            if (packet_valid) begin
                if (packets_in_window == 4'd9) begin
                    packets_in_window <= 4'd0;
                    window_sample_valid <= 1'b1;
                end else begin
                    packets_in_window <= packets_in_window + 1'b1;
                end
            end
        end
    end

    // Integer percentage, rounded down. No packets means a perfect initial score.
    always @* begin
        scaled_error_count = error_count * 64'd100;
        if (packet_count == 0) begin
            error_rate = 8'd0;
        end else begin
            error_rate = scaled_error_count / packet_count;
        end
        reliability_score = 8'd100 - error_rate;
    end

    predictive_analyzer u_predictive_analyzer (
        .clk               (clk),
        .rst_n             (rst_n),
        .sample_valid      (window_sample_valid),
        .error_rate        (error_rate),
        .reliability_score (reliability_score),
        .status            (predictive_status),
        .trend_up          (trend_up)
    );

endmodule
