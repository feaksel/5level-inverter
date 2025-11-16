/**
 * @file inverter_5level_top_tb.v
 * @brief Testbench for complete 5-level inverter
 *
 * Tests:
 * - Complete PWM generation system
 * - Level-shifted carrier modulation
 * - Dead-time insertion
 * - Modulation index control
 * - All 8 PWM outputs
 *
 * @author 5-Level Inverter Project
 * @date 2025-11-15
 */

`timescale 1ns / 1ps

module inverter_5level_top_tb;

    // Parameters
    parameter CLK_PERIOD = 10;              // 100 MHz clock (10ns period)
    parameter DATA_WIDTH = 16;
    parameter PHASE_WIDTH = 32;
    parameter DEADTIME_WIDTH = 8;
    parameter CARRIER_DIV_WIDTH = 16;

    // Testbench signals
    reg                         clk;
    reg                         rst_n;
    reg                         enable;
    reg [PHASE_WIDTH-1:0]       freq_50hz;
    reg [DATA_WIDTH-1:0]        modulation_index;
    reg [DEADTIME_WIDTH-1:0]    deadtime_cycles;
    reg [CARRIER_DIV_WIDTH-1:0] carrier_freq_div;

    // H-Bridge 1 outputs
    wire pwm1_ch1_high, pwm1_ch1_low;
    wire pwm1_ch2_high, pwm1_ch2_low;

    // H-Bridge 2 outputs
    wire pwm2_ch1_high, pwm2_ch1_low;
    wire pwm2_ch2_high, pwm2_ch2_low;

    // Status
    wire sync_pulse;
    wire fault;

    // DUT instantiation
    inverter_5level_top #(
        .DATA_WIDTH         (DATA_WIDTH),
        .PHASE_WIDTH        (PHASE_WIDTH),
        .DEADTIME_WIDTH     (DEADTIME_WIDTH),
        .CARRIER_DIV_WIDTH  (CARRIER_DIV_WIDTH)
    ) dut (
        .clk                (clk),
        .rst_n              (rst_n),
        .enable             (enable),
        .freq_50hz          (freq_50hz),
        .modulation_index   (modulation_index),
        .deadtime_cycles    (deadtime_cycles),
        .carrier_freq_div   (carrier_freq_div),
        .pwm1_ch1_high      (pwm1_ch1_high),
        .pwm1_ch1_low       (pwm1_ch1_low),
        .pwm1_ch2_high      (pwm1_ch2_high),
        .pwm1_ch2_low       (pwm1_ch2_low),
        .pwm2_ch1_high      (pwm2_ch1_high),
        .pwm2_ch1_low       (pwm2_ch1_low),
        .pwm2_ch2_high      (pwm2_ch2_high),
        .pwm2_ch2_low       (pwm2_ch2_low),
        .sync_pulse         (sync_pulse),
        .fault              (fault)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // Waveform dump
    initial begin
        $dumpfile("inverter_5level_top_tb.vcd");
        $dumpvars(0, inverter_5level_top_tb);
    end

    // Test stimulus
    initial begin
        // Initialize
        $display("=== 5-Level Inverter Testbench Starting ===");
        rst_n = 0;
        enable = 0;

        // Configuration
        // For 50Hz output @ 100MHz clock:
        // freq_increment = (50 * 2^32) / 100e6 = 2147483 = 0x0020C49C
        freq_50hz = 32'h0020C49C;           // 50Hz output frequency

        // For 5kHz carrier @ 100MHz clock:
        // carrier_freq_div = 100MHz / (2 * 5kHz) = 10000
        carrier_freq_div = 10000;           // 5kHz carrier (realistic)
        // For simulation (faster): use smaller value
        carrier_freq_div = 100;             // ~500kHz carrier (for fast sim)

        modulation_index = 16384;           // 50% MI (0.5 * 32768)
        deadtime_cycles = 100;              // 1μs dead-time @ 100MHz

        // Reset
        #(CLK_PERIOD * 20);
        rst_n = 1;
        $display("Time=%0t: Reset released", $time);

        // Enable inverter
        #(CLK_PERIOD * 10);
        enable = 1;
        $display("Time=%0t: Inverter enabled", $time);

        // Run for multiple output cycles
        #(CLK_PERIOD * carrier_freq_div * 20);

        // Test: Change modulation index to 80%
        $display("Time=%0t: Changing MI to 80%%", $time);
        modulation_index = 26214;           // 80% MI (0.8 * 32768)
        #(CLK_PERIOD * carrier_freq_div * 10);

        // Test: Change to 100% MI
        $display("Time=%0t: Changing MI to 100%%", $time);
        modulation_index = 32767;           // 100% MI
        #(CLK_PERIOD * carrier_freq_div * 10);

        // Test: Disable
        $display("Time=%0t: Disabling inverter", $time);
        enable = 0;
        #(CLK_PERIOD * 100);

        // Test: Re-enable with 25% MI
        $display("Time=%0t: Re-enabling with 25%% MI", $time);
        modulation_index = 8192;            // 25% MI
        enable = 1;
        #(CLK_PERIOD * carrier_freq_div * 10);

        // Finish simulation
        $display("=== Test Completed Successfully ===");
        $finish;
    end

    // Monitor sync pulses
    integer sync_count = 0;
    always @(posedge sync_pulse) begin
        sync_count = sync_count + 1;
        if (sync_count % 10 == 0) begin
            $display("Time=%0t: Sync pulse #%0d", $time, sync_count);
        end
    end

    // Dead-time violation checker
    always @(*) begin
        // Check H-Bridge 1 Channel 1
        if (pwm1_ch1_high && pwm1_ch1_low) begin
            $display("ERROR: Dead-time violation on H-Bridge 1 CH1 at time=%0t", $time);
            $stop;
        end

        // Check H-Bridge 1 Channel 2
        if (pwm1_ch2_high && pwm1_ch2_low) begin
            $display("ERROR: Dead-time violation on H-Bridge 1 CH2 at time=%0t", $time);
            $stop;
        end

        // Check H-Bridge 2 Channel 1
        if (pwm2_ch1_high && pwm2_ch1_low) begin
            $display("ERROR: Dead-time violation on H-Bridge 2 CH1 at time=%0t", $time);
            $stop;
        end

        // Check H-Bridge 2 Channel 2
        if (pwm2_ch2_high && pwm2_ch2_low) begin
            $display("ERROR: Dead-time violation on H-Bridge 2 CH2 at time=%0t", $time);
            $stop;
        end
    end

    // Statistics
    integer pwm1_transitions = 0;
    integer pwm2_transitions = 0;

    always @(posedge pwm1_ch1_high or negedge pwm1_ch1_high) pwm1_transitions++;
    always @(posedge pwm2_ch1_high or negedge pwm2_ch1_high) pwm2_transitions++;

    // Final statistics
    final begin
        $display("\n=== Simulation Statistics ===");
        $display("Sync pulses: %0d", sync_count);
        $display("PWM1 transitions: %0d", pwm1_transitions);
        $display("PWM2 transitions: %0d", pwm2_transitions);
        $display("Fault status: %b", fault);
    end

endmodule
