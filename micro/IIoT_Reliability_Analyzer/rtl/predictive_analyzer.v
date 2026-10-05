`timescale 1ns / 1ps

module predictive_analyzer #(
    parameter [7:0] WARNING_ERROR_RATE  = 8'd10,
    parameter [7:0] CRITICAL_ERROR_RATE = 8'd25,
    parameter [7:0] WARNING_SCORE       = 8'd80,
    parameter [7:0] CRITICAL_SCORE      = 8'd50,
    parameter [7:0] TREND_MARGIN        = 8'd5
) (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       sample_valid,
    input  wire [7:0] error_rate,
    input  wire [7:0] reliability_score,
    output reg  [1:0] status,
    output reg        trend_up
);

    localparam [1:0] STATUS_NORMAL   = 2'b00;
    localparam [1:0] STATUS_WARNING  = 2'b01;
    localparam [1:0] STATUS_CRITICAL = 2'b10;

    reg [7:0] previous_reliability_score;
    reg [1:0] base_status;

    always @* begin
        if ((error_rate >= CRITICAL_ERROR_RATE) ||
            (reliability_score <= CRITICAL_SCORE))
            base_status = STATUS_CRITICAL;
        else if ((error_rate >= WARNING_ERROR_RATE) ||
                 (reliability_score <= WARNING_SCORE))
            base_status = STATUS_WARNING;
        else
            base_status = STATUS_NORMAL;

        // A rising error rate predicts one level of additional risk.
        if (trend_up && (base_status == STATUS_NORMAL))
            status = STATUS_WARNING;
        else if (trend_up && (base_status == STATUS_WARNING))
            status = STATUS_CRITICAL;
        else
            status = base_status;
    end

    always @(posedge clk) begin
        if (!rst_n) begin
            previous_reliability_score <= 8'd100;
            trend_up            <= 1'b0;
        end else if (sample_valid) begin
            // trend_up means reliability has worsened by at least the margin
            // since the previous analyzer sample.
            trend_up <= (reliability_score + TREND_MARGIN <=
                         previous_reliability_score);
            previous_reliability_score <= reliability_score;
        end
    end

endmodule
