`timescale 1ns / 1ps

module tb_top;

    reg clk;
    reg rst_n;
    reg packet_valid;
    reg packet_error;

    wire error_detected;
    wire [31:0] error_count;
    wire [31:0] packet_count;
    wire [7:0] error_rate;
    wire [7:0] reliability_score;
    wire [1:0] predictive_status;
    wire trend_up;

    localparam [1:0] STATUS_NORMAL   = 2'b00;
    localparam [1:0] STATUS_WARNING  = 2'b01;
    localparam [1:0] STATUS_CRITICAL = 2'b10;

    reliability_analyzer dut (
        .clk               (clk),
        .rst_n             (rst_n),
        .packet_valid      (packet_valid),
        .packet_error      (packet_error),
        .error_detected    (error_detected),
        .error_count       (error_count),
        .packet_count      (packet_count),
        .error_rate        (error_rate),
        .reliability_score (reliability_score),
        .predictive_status (predictive_status),
        .trend_up          (trend_up)
    );

    always #5 clk = ~clk;

    task send_packet;
        input is_error;
        begin
            @(negedge clk);
            packet_valid = 1'b1;
            packet_error = is_error;
            @(negedge clk);
            packet_valid = 1'b0;
            packet_error = 1'b0;
            #1;
        end
    endtask

    task send_batch;
        input integer packet_total;
        input integer error_total;
        integer i;
        begin
            for (i = 0; i < packet_total; i = i + 1)
                send_packet(i < error_total);
        end
    endtask

    task show_status;
        begin
            $display("t=%0t packets=%0d errors=%0d rate=%0d%% score=%0d status=%0d trend_up=%0b",
                     $time, packet_count, error_count, error_rate,
                     reliability_score, predictive_status, trend_up);
        end
    endtask

    task sample_window;
        begin
            // Allow the analyzer's registered ten-packet sample to be consumed.
            @(posedge clk);
            #1;
            show_status;
            if (error_detected !== 1'b0)
                $fatal(1, "error_detected did not clear after packet processing");
        end
    endtask

    initial begin
        clk          = 1'b0;
        rst_n        = 1'b0;
        packet_valid = 1'b0;
        packet_error = 1'b0;

        repeat (2) @(negedge clk);
        rst_n = 1'b1;
        #1;

        // Window 1: healthy link, 0% errors, full reliability.
        send_batch(10, 0);
        sample_window;
        if ((error_rate !== 0) || (reliability_score !== 100) ||
            (predictive_status !== STATUS_NORMAL))
            $fatal(1, "Healthy-link check failed");

        // Window 2: reliability drops by five points; prediction raises WARNING.
        send_batch(10, 1);
        sample_window;
        if ((packet_count !== 20) || (error_count !== 1) ||
            (error_rate !== 5) || (reliability_score !== 95) ||
            (predictive_status !== STATUS_WARNING) || (trend_up !== 1'b1))
            $fatal(1, "Worsening-trend check failed");

        // Window 3: reliability improves, so the predicted trend clears.
        send_batch(10, 0);
        sample_window;
        if ((packet_count !== 30) || (error_count !== 1) ||
            (error_rate !== 3) || (predictive_status !== STATUS_NORMAL) ||
            (trend_up !== 1'b0))
            $fatal(1, "Improving-trend check failed");

        // Window 4: severe degradation reaches the critical error-rate limit.
        send_batch(10, 9);
        sample_window;
        if ((packet_count !== 40) || (error_count !== 10) ||
            (error_rate !== 25) || (predictive_status !== STATUS_CRITICAL))
            $fatal(1, "Critical-level check failed");

        $display("PASS: all reliability analyzer scenarios completed.");
        $finish;
    end

endmodule
