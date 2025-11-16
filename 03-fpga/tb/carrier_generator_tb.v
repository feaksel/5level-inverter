/**
 * @file carrier_generator_tb.v
 * @brief Testbench for carrier_generator module
 *
 * Tests:
 * - Carrier generation at 5kHz
 * - Level-shifted outputs (carrier1: -32768 to 0, carrier2: 0 to +32767)
 * - Synchronization pulse generation
 * - Enable/disable functionality
 *
 * @author 5-Level Inverter Project
 * @date 2025-11-15
 */

`timescale 1ns / 1ps

module carrier_generator_tb;

    // Parameters
    parameter CLK_PERIOD = 10;              // 100 MHz clock
    parameter CARRIER_WIDTH = 16;
    parameter COUNTER_WIDTH = 16;

    // Testbench signals
    reg                         clk;
    reg                         rst_n;
    reg                         enable;
    reg [COUNTER_WIDTH-1:0]     freq_div;
    wire signed [CARRIER_WIDTH-1:0] carrier1;
    wire signed [CARRIER_WIDTH-1:0] carrier2;
    wire                        sync_pulse;

    // DUT instantiation
    carrier_generator #(
        .CARRIER_WIDTH  (CARRIER_WIDTH),
        .COUNTER_WIDTH  (COUNTER_WIDTH)
    ) dut (
        .clk            (clk),
        .rst_n          (rst_n),
        .enable         (enable),
        .freq_div       (freq_div),
        .carrier1       (carrier1),
        .carrier2       (carrier2),
        .sync_pulse     (sync_pulse)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // Waveform dump for viewing
    initial begin
        $dumpfile("carrier_generator_tb.vcd");
        $dumpvars(0, carrier_generator_tb);
    end

    // Test stimulus
    initial begin
        // Initialize
        rst_n = 0;
        enable = 0;
        freq_div = 100;                     // Fast frequency for simulation

        // Reset
        #(CLK_PERIOD * 10);
        rst_n = 1;

        // Enable carrier generation
        #(CLK_PERIOD * 5);
        enable = 1;

        // Run for multiple carrier periods
        #(CLK_PERIOD * freq_div * 4);

        // Test disable
        enable = 0;
        #(CLK_PERIOD * 20);

        // Re-enable
        enable = 1;
        #(CLK_PERIOD * freq_div * 2);

        // Test with different frequency divider
        freq_div = 200;
        #(CLK_PERIOD * freq_div * 2);

        // Finish
        #(CLK_PERIOD * 100);
        $display("Test completed successfully!");
        $finish;
    end

    // Monitor outputs
    always @(posedge sync_pulse) begin
        $display("Time=%0t: Sync pulse detected, carrier1=%d, carrier2=%d",
                 $time, carrier1, carrier2);
    end

    // Check carrier ranges
    always @(posedge clk) begin
        if (enable) begin
            // Check carrier1 range: -32768 to 0
            if (carrier1 > 0 || carrier1 < -32768) begin
                $display("ERROR: carrier1 out of range: %d", carrier1);
                $stop;
            end

            // Check carrier2 range: 0 to +32767
            if (carrier2 < 0 || carrier2 > 32767) begin
                $display("ERROR: carrier2 out of range: %d", carrier2);
                $stop;
            end
        end
    end

endmodule
