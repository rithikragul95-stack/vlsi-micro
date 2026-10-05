# IIoT Reliability Analyzer

A synthesizable Verilog design and Vivado simulation for monitoring packet integrity in an industrial IoT link.

## Project structure

- `rtl/error_detector.v` — detects and counts invalid packets when `packet_valid` and `packet_error` are both high.
- `rtl/packet_counter.v` — counts valid packets.
- `rtl/reliability_analyzer.v` — top-level design; calculates cumulative error rate and reliability score.
- `rtl/predictive_analyzer.v` — classifies link health and flags worsening reliability.
- `sim/tb_top.v` — testbench sampling health after each ten-packet window.

## Signal behavior

Drive `packet_valid` for one clock cycle per received packet. Set `packet_error` high for that cycle when the packet failed an integrity check (for example, CRC or parity validation). Both counters update on the rising clock edge. `error_detected` is a one-cycle pulse for a bad valid packet.

The cumulative metrics are:

- `error_rate = floor(error_count * 100 / packet_count)`; it is 0 before the first packet.
- `reliability_score = 100 - error_rate`.
- Status encoding: `00` NORMAL, `01` WARNING, `10` CRITICAL.
- Default warning thresholds: error rate >= 10% or score <= 80.
- Default critical thresholds: error rate >= 25% or score <= 50.
- The analyzer samples trend once per ten valid packets. A reliability-score drop of at least 5 points since the previous window marks the trend as worsening and raises predicted status by one level. An improving or stable window clears the trend flag.

These thresholds are parameters in `predictive_analyzer.v` and can be tuned for the target network.

## Run in Vivado

1. Create a new RTL project and select the target FPGA or choose **Do not specify part** for simulation-only use.
2. Add all files under `rtl/` as **Design Sources**.
3. Add `sim/tb_top.v` as a **Simulation Source** and set `tb_top` as the simulation top.
4. Run **Run Simulation → Run Behavioral Simulation**.
5. The testbench prints packet/error totals, error rate, reliability score, and status after each ten-packet window. It ends with `PASS` if normal, worsening-trend, improving-trend, and critical assertions succeed.

The design top is `reliability_analyzer`; the simulation top is `tb_top`.
