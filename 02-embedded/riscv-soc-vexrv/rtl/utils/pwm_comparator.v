/**
 * @file pwm_comparator.v
 * @brief PWM comparator with complementary outputs and dead-time insertion
 *
 * Compares a modulation reference signal with a carrier wave to generate
 * complementary PWM signals with programmable dead-time insertion.
 *
 * This module is used twice in the 5-level inverter:
 * - Once for H-bridge 1 (with carrier 1)
 * - Once for H-bridge 2 (with carrier 2)
 *
 * Features:
 * - Level-shifted carrier PWM comparison
 * - Complementary output generation
 * - Programmable dead-time insertion (prevents shoot-through)
 * - Synchronization support
 *
 * @param clk           System clock (100 MHz)
 * @param rst_n         Active-low reset
 * @param enable        Enable PWM generation
 * @param reference     Modulation reference signal (-32768 to +32767)
 * @param carrier       Carrier wave signal (-32768 to +32767)
 * @param deadtime      Dead-time in clock cycles (e.g., 100 for 1μs @ 100MHz)
 * @param pwm_high      PWM high-side output
 * @param pwm_low       PWM low-side output (complementary with dead-time)
 *
 * Dead-time insertion:
 * - When switching from high to low, insert dead-time
 * - When switching from low to high, insert dead-time
 * - Both outputs are LOW during dead-time
 *
 * @author 5-Level Inverter Project
 * @date 2025-11-15
 */

module pwm_comparator #(
    parameter DATA_WIDTH = 16,              // Signal bit width
    parameter DEADTIME_WIDTH = 8            // Dead-time counter width
)(
    input  wire                         clk,
    input  wire                         rst_n,
    input  wire                         enable,
    input  wire signed [DATA_WIDTH-1:0] reference,
    input  wire signed [DATA_WIDTH-1:0] carrier,
    input  wire [DEADTIME_WIDTH-1:0]    deadtime,
    output reg                          pwm_high,
    output reg                          pwm_low
);

    // Internal signals
    reg pwm_raw;                            // Raw PWM before dead-time
    reg pwm_raw_prev;                       // Previous raw PWM state
    reg [DEADTIME_WIDTH-1:0] deadtime_counter;
    reg deadtime_active;                    // Dead-time insertion active

    // Edge detection
    wire rising_edge;
    wire falling_edge;

    assign rising_edge = pwm_raw && !pwm_raw_prev;
    assign falling_edge = !pwm_raw && pwm_raw_prev;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pwm_raw <= 0;
            pwm_raw_prev <= 0;
            deadtime_counter <= 0;
            deadtime_active <= 0;
            pwm_high <= 0;
            pwm_low <= 0;
        end else begin
            if (enable) begin
                // Generate raw PWM by comparing reference with carrier
                // PWM is high when reference > carrier
                pwm_raw <= (reference > carrier) ? 1'b1 : 1'b0;
                pwm_raw_prev <= pwm_raw;

                // Dead-time insertion state machine
                if (rising_edge || falling_edge) begin
                    // Start dead-time insertion on any edge
                    deadtime_active <= 1;
                    deadtime_counter <= deadtime;
                    // Set both outputs LOW during dead-time
                    pwm_high <= 0;
                    pwm_low <= 0;
                end else if (deadtime_active) begin
                    // Count down dead-time
                    if (deadtime_counter > 0) begin
                        deadtime_counter <= deadtime_counter - 1;
                        pwm_high <= 0;
                        pwm_low <= 0;
                    end else begin
                        // Dead-time complete, apply new PWM state
                        deadtime_active <= 0;
                        pwm_high <= pwm_raw;
                        pwm_low <= ~pwm_raw;
                    end
                end else begin
                    // Normal operation - complementary outputs
                    pwm_high <= pwm_raw;
                    pwm_low <= ~pwm_raw;
                end

            end else begin
                // Disabled - all outputs LOW (safe state)
                pwm_raw <= 0;
                pwm_raw_prev <= 0;
                deadtime_counter <= 0;
                deadtime_active <= 0;
                pwm_high <= 0;
                pwm_low <= 0;
            end
        end
    end

endmodule
