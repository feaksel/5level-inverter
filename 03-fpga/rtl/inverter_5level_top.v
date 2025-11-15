/**
 * @file inverter_5level_top.v
 * @brief Top-level module for 5-level cascaded H-bridge inverter
 *
 * Integrates all PWM generation components:
 * - Sine wave reference generator
 * - Dual level-shifted carrier generators
 * - PWM comparators with dead-time insertion
 * - Gate driver outputs for 2 H-bridges (8 switches total)
 *
 * Output voltage levels:
 * +100V: Both bridges positive
 * +50V:  Bridge 1 positive, Bridge 2 zero
 * 0V:    Both bridges zero (or opposite polarities)
 * -50V:  Bridge 1 negative, Bridge 2 zero
 * -100V: Both bridges negative
 *
 * Pin mapping:
 * H-Bridge 1 (S1-S4):
 *   pwm1_ch1_high  = S1 (PA8  - TIM1_CH1)
 *   pwm1_ch1_low   = S2 (PB13 - TIM1_CH1N)
 *   pwm1_ch2_high  = S3 (PA9  - TIM1_CH2)
 *   pwm1_ch2_low   = S4 (PB14 - TIM1_CH2N)
 *
 * H-Bridge 2 (S5-S8):
 *   pwm2_ch1_high  = S5 (PC6  - TIM8_CH1)
 *   pwm2_ch1_low   = S6 (PC10 - TIM8_CH1N)
 *   pwm2_ch2_high  = S7 (PC7  - TIM8_CH2)
 *   pwm2_ch2_low   = S8 (PC11 - TIM8_CH2N)
 *
 * @param clk               System clock (100 MHz)
 * @param rst_n             Active-low reset
 * @param enable            Enable inverter operation
 * @param freq_50hz         Frequency increment for 50Hz output
 * @param modulation_index  Modulation index (0-32767)
 * @param deadtime_cycles   Dead-time in clock cycles
 * @param pwm1_*            H-Bridge 1 PWM outputs
 * @param pwm2_*            H-Bridge 2 PWM outputs
 * @param sync_pulse        Synchronization pulse output
 * @param fault             Fault output (reserved for future use)
 *
 * @author 5-Level Inverter Project
 * @date 2025-11-15
 */

module inverter_5level_top #(
    parameter DATA_WIDTH = 16,
    parameter PHASE_WIDTH = 32,
    parameter DEADTIME_WIDTH = 8,
    parameter CARRIER_DIV_WIDTH = 16
)(
    // System signals
    input  wire                         clk,
    input  wire                         rst_n,
    input  wire                         enable,

    // Configuration
    input  wire [PHASE_WIDTH-1:0]       freq_50hz,          // Phase increment for 50Hz
    input  wire [DATA_WIDTH-1:0]        modulation_index,   // MI: 0-32767
    input  wire [DEADTIME_WIDTH-1:0]    deadtime_cycles,    // Dead-time
    input  wire [CARRIER_DIV_WIDTH-1:0] carrier_freq_div,   // Carrier frequency divider

    // H-Bridge 1 outputs (S1-S4)
    output wire                         pwm1_ch1_high,      // S1
    output wire                         pwm1_ch1_low,       // S2
    output wire                         pwm1_ch2_high,      // S3
    output wire                         pwm1_ch2_low,       // S4

    // H-Bridge 2 outputs (S5-S8)
    output wire                         pwm2_ch1_high,      // S5
    output wire                         pwm2_ch1_low,       // S6
    output wire                         pwm2_ch2_high,      // S7
    output wire                         pwm2_ch2_low,       // S8

    // Status outputs
    output wire                         sync_pulse,
    output wire                         fault
);

    // Internal signals
    wire signed [DATA_WIDTH-1:0] sine_ref;
    wire signed [DATA_WIDTH-1:0] carrier1;
    wire signed [DATA_WIDTH-1:0] carrier2;

    // Sine wave reference generator
    sine_generator #(
        .DATA_WIDTH     (DATA_WIDTH),
        .PHASE_WIDTH    (PHASE_WIDTH)
    ) sine_gen (
        .clk                (clk),
        .rst_n              (rst_n),
        .enable             (enable),
        .freq_increment     (freq_50hz),
        .modulation_index   (modulation_index),
        .sine_out           (sine_ref),
        .phase              ()                  // Not used
    );

    // Level-shifted carrier generator
    carrier_generator #(
        .CARRIER_WIDTH  (DATA_WIDTH),
        .COUNTER_WIDTH  (CARRIER_DIV_WIDTH)
    ) carrier_gen (
        .clk            (clk),
        .rst_n          (rst_n),
        .enable         (enable),
        .freq_div       (carrier_freq_div),
        .carrier1       (carrier1),
        .carrier2       (carrier2),
        .sync_pulse     (sync_pulse)
    );

    // PWM comparators for H-Bridge 1 (uses carrier1: -32768 to 0)
    // Channel 1 (S1/S2)
    pwm_comparator #(
        .DATA_WIDTH         (DATA_WIDTH),
        .DEADTIME_WIDTH     (DEADTIME_WIDTH)
    ) pwm1_ch1 (
        .clk        (clk),
        .rst_n      (rst_n),
        .enable     (enable),
        .reference  (sine_ref),
        .carrier    (carrier1),
        .deadtime   (deadtime_cycles),
        .pwm_high   (pwm1_ch1_high),
        .pwm_low    (pwm1_ch1_low)
    );

    // Channel 2 (S3/S4) - same reference and carrier
    pwm_comparator #(
        .DATA_WIDTH         (DATA_WIDTH),
        .DEADTIME_WIDTH     (DEADTIME_WIDTH)
    ) pwm1_ch2 (
        .clk        (clk),
        .rst_n      (rst_n),
        .enable     (enable),
        .reference  (sine_ref),
        .carrier    (carrier1),
        .deadtime   (deadtime_cycles),
        .pwm_high   (pwm1_ch2_high),
        .pwm_low    (pwm1_ch2_low)
    );

    // PWM comparators for H-Bridge 2 (uses carrier2: 0 to +32767)
    // Channel 1 (S5/S6)
    pwm_comparator #(
        .DATA_WIDTH         (DATA_WIDTH),
        .DEADTIME_WIDTH     (DEADTIME_WIDTH)
    ) pwm2_ch1 (
        .clk        (clk),
        .rst_n      (rst_n),
        .enable     (enable),
        .reference  (sine_ref),
        .carrier    (carrier2),
        .deadtime   (deadtime_cycles),
        .pwm_high   (pwm2_ch1_high),
        .pwm_low    (pwm2_ch1_low)
    );

    // Channel 2 (S7/S8) - same reference and carrier
    pwm_comparator #(
        .DATA_WIDTH         (DATA_WIDTH),
        .DEADTIME_WIDTH     (DEADTIME_WIDTH)
    ) pwm2_ch2 (
        .clk        (clk),
        .rst_n      (rst_n),
        .enable     (enable),
        .reference  (sine_ref),
        .carrier    (carrier2),
        .deadtime   (deadtime_cycles),
        .pwm_high   (pwm2_ch2_high),
        .pwm_low    (pwm2_ch2_low)
    );

    // Fault output (not implemented yet, reserved for future use)
    assign fault = 1'b0;

endmodule
