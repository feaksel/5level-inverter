/**
 * @file pwm_visual_monitor.v
 * @brief Visual PWM Monitor for Waveform Viewing
 *
 * This module creates human-readable markers and measurements
 * for PWM signals to make waveform viewing easier.
 */

`timescale 1ns / 1ps

module pwm_visual_monitor (
    input wire clk,
    input wire rst_n,
    input wire [7:0] pwm_in,
    input wire [15:0] mod_index
);

    //==========================================================================
    // PWM Measurement Registers (visible in waveform)
    //==========================================================================

    // Per-channel measurements
    reg [31:0] pwm_duty_percent [0:7];    // Duty cycle in percent (0-100)
    reg [31:0] pwm_freq_hz [0:7];         // Frequency in Hz
    reg [31:0] pwm_high_time_ns [0:7];    // High time in nanoseconds
    reg [31:0] pwm_period_ns [0:7];       // Period in nanoseconds

    // Aggregate measurements
    reg [15:0] modulation_index;          // Current modulation index
    reg [7:0]  active_channels;           // Bitmap of active channels
    reg [31:0] total_edges;               // Total edge count (activity indicator)

    // Visual markers (appear in waveform viewer)
    reg pwm_activity;                     // Pulses when PWM changes
    reg [7:0] pwm_pattern;                // Current output pattern

    //==========================================================================
    // Edge Detection and Measurement
    //==========================================================================

    reg [7:0] pwm_prev;
    reg [63:0] edge_time [0:7];
    reg [63:0] high_start [0:7];

    integer i;

    initial begin
        for (i = 0; i < 8; i = i + 1) begin
            pwm_duty_percent[i] = 0;
            pwm_freq_hz[i] = 0;
            pwm_high_time_ns[i] = 0;
            pwm_period_ns[i] = 0;
            edge_time[i] = 0;
            high_start[i] = 0;
        end
        modulation_index = 0;
        active_channels = 0;
        total_edges = 0;
        pwm_activity = 0;
        pwm_pattern = 0;
        pwm_prev = 0;
    end

    always @(posedge clk) begin
        if (!rst_n) begin
            pwm_prev <= 0;
            pwm_activity <= 0;
            total_edges <= 0;
        end else begin
            pwm_prev <= pwm_in;
            pwm_pattern <= pwm_in;
            modulation_index <= mod_index;

            // Detect any PWM activity
            pwm_activity <= (pwm_in != pwm_prev);

            // Track active channels
            active_channels <= |pwm_in ? 8'hFF : 8'h00;

            // Measure each channel
            for (i = 0; i < 8; i = i + 1) begin
                // Rising edge
                if (pwm_prev[i] == 1'b0 && pwm_in[i] == 1'b1) begin
                    high_start[i] <= $time;

                    // Calculate period if we have a previous edge
                    if (edge_time[i] > 0) begin
                        pwm_period_ns[i] <= $time - edge_time[i];

                        // Calculate frequency (in Hz)
                        if (pwm_period_ns[i] > 0) begin
                            pwm_freq_hz[i] <= 1000000000 / pwm_period_ns[i];
                        end
                    end

                    edge_time[i] <= $time;
                    total_edges <= total_edges + 1;
                end

                // Falling edge
                if (pwm_prev[i] == 1'b1 && pwm_in[i] == 1'b0) begin
                    pwm_high_time_ns[i] <= $time - high_start[i];

                    // Calculate duty cycle
                    if (pwm_period_ns[i] > 0) begin
                        pwm_duty_percent[i] <= (pwm_high_time_ns[i] * 100) / pwm_period_ns[i];
                    end

                    total_edges <= total_edges + 1;
                end
            end
        end
    end

    //==========================================================================
    // Display Helper - Updates Console When PWM Changes
    //==========================================================================

    reg [31:0] display_counter;

    initial display_counter = 0;

    always @(posedge clk) begin
        if (pwm_activity) begin
            display_counter <= display_counter + 1;

            // Display summary every 1000 edges to avoid spam
            if (display_counter % 1000 == 0) begin
                $display("[PWM VISUAL] T=%0t ns | Pattern=%08b | Mod=%0d%% | Active=%02X",
                         $time, pwm_pattern, (modulation_index * 100) / 65536, active_channels);
            end
        end
    end

    //==========================================================================
    // Channel Status Summary (appears in waveform as registers)
    //==========================================================================

    // Summary status for each channel (easier to see in waveform)
    reg [7:0] ch0_duty, ch1_duty, ch2_duty, ch3_duty;
    reg [7:0] ch4_duty, ch5_duty, ch6_duty, ch7_duty;

    always @(posedge clk) begin
        ch0_duty <= pwm_duty_percent[0][7:0];
        ch1_duty <= pwm_duty_percent[1][7:0];
        ch2_duty <= pwm_duty_percent[2][7:0];
        ch3_duty <= pwm_duty_percent[3][7:0];
        ch4_duty <= pwm_duty_percent[4][7:0];
        ch5_duty <= pwm_duty_percent[5][7:0];
        ch6_duty <= pwm_duty_percent[6][7:0];
        ch7_duty <= pwm_duty_percent[7][7:0];
    end

endmodule
