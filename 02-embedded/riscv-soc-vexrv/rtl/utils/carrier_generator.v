/**
 * @file carrier_generator.v
 * @brief Level-shifted triangular carrier wave generator for 5-level inverter
 *
 * Generates two level-shifted carrier waves:
 * - Carrier 1: -1.0 to 0.0 (for H-bridge 1)
 * - Carrier 2:  0.0 to +1.0 (for H-bridge 2)
 *
 * The carriers are used for level-shifted PWM modulation to synthesize
 * 5 voltage levels: +100V, +50V, 0V, -50V, -100V
 *
 * @param clk           System clock
 * @param rst_n         Active-low reset
 * @param enable        Enable carrier generation
 * @param freq_div      Frequency divider for carrier frequency
 * @param carrier1      Output: Carrier 1 (-32768 to 0, signed 16-bit)
 * @param carrier2      Output: Carrier 2 (0 to +32767, signed 16-bit)
 * @param sync_pulse    Output: Synchronization pulse at carrier peak
 *
 * Configuration:
 * - System clock: 100 MHz
 * - Carrier frequency: 5 kHz (PWM switching frequency)
 * - Resolution: 16-bit signed (-32768 to +32767)
 * - Update rate: Carrier updated every clock cycle
 *
 * Carrier frequency calculation:
 *   f_carrier = f_clk / (2 * freq_div)
 *   For 5 kHz: freq_div = 10000 (100MHz / (2 * 10000) = 5kHz)
 *
 * @author 5-Level Inverter Project
 * @date 2025-11-15
 */

module carrier_generator #(
    parameter CARRIER_WIDTH = 16,           // Carrier bit width
    parameter COUNTER_WIDTH = 16            // Counter bit width
)(
    input  wire                         clk,
    input  wire                         rst_n,
    input  wire                         enable,
    input  wire [COUNTER_WIDTH-1:0]     freq_div,      // Frequency divider
    output reg  signed [CARRIER_WIDTH-1:0]  carrier1,      // Carrier 1: -32768 to -16384
    output reg  signed [CARRIER_WIDTH-1:0]  carrier2,      // Carrier 2: -16384 to 0
    output reg  signed [CARRIER_WIDTH-1:0]  carrier3,      // Carrier 3: 0 to +16384
    output reg  signed [CARRIER_WIDTH-1:0]  carrier4,      // Carrier 4: +16384 to +32767
    output reg                          sync_pulse     // Sync pulse at peak
);

    // Carrier generation constants
    localparam signed CARRIER_MAX = (1 << (CARRIER_WIDTH-1)) - 1;  // +32767
    localparam signed CARRIER_MIN = -(1 << (CARRIER_WIDTH-1));     // -32768
    localparam signed CARRIER_MID = 0;

    // Internal signals
    reg [COUNTER_WIDTH-1:0] counter;
    reg counter_dir;                        // 0 = counting up, 1 = counting down
    reg prev_dir;                           // Previous direction for sync detection

    // Carrier phase accumulator (uses same technique as sine generator)
    reg [31:0] carrier_phase;
    wire [31:0] carrier_increment;

    // Calculate phase increment for smooth triangle wave
    // For freq_div cycles per half-period, we need to increment by:
    // increment = 2^32 / (2 * freq_div)
    // Simplified: increment ≈ 2^31 / freq_div
    assign carrier_increment = 32'h80000000 / freq_div;  // 2^31 / freq_div

    // Use top 16 bits of phase as carrier value
    wire [CARRIER_WIDTH-1:0] carrier_unsigned = carrier_phase[31:16];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 0;
            counter_dir <= 0;
            prev_dir <= 0;
            carrier_phase <= 0;
            carrier1 <= CARRIER_MIN;
            carrier2 <= CARRIER_MIN / 2;
            carrier3 <= CARRIER_MID;
            carrier4 <= CARRIER_MAX / 2;
            sync_pulse <= 0;
        end else begin
            if (enable) begin
                // Generate triangular carrier using phase accumulator
                if (counter >= freq_div - 1) begin
                    counter <= 0;
                    // Toggle direction at each half-period
                    counter_dir <= ~counter_dir;
                    prev_dir <= counter_dir;
                end else begin
                    counter <= counter + 1;
                    prev_dir <= counter_dir;
                end

                // Update phase accumulator
                if (counter_dir == 0) begin
                    // Counting up
                    carrier_phase <= carrier_phase + carrier_increment;
                end else begin
                    // Counting down
                    carrier_phase <= carrier_phase - carrier_increment;
                end

                // Generate 4 level-shifted carriers for 5-level cascaded H-bridge
                // carrier_unsigned goes 0 → 32767 → 0 (triangle wave)
                // Scale each to half range and shift to different DC levels

                // Carrier 1: -32768 to -16384 (bottom quarter)
                // Scale: divide by 2 → 0 to 16383, then shift down
                carrier1 <= $signed({1'b0, carrier_unsigned[15:1]}) - 16'd32768;

                // Carrier 2: -16384 to 0 (lower-mid quarter)
                // Scale: divide by 2 → 0 to 16383, then shift down
                carrier2 <= $signed({1'b0, carrier_unsigned[15:1]}) - 16'd16384;

                // Carrier 3: 0 to +16384 (upper-mid quarter)
                // Scale: divide by 2 → 0 to 16383, no shift needed
                carrier3 <= $signed({1'b0, carrier_unsigned[15:1]});

                // Carrier 4: +16384 to +32767 (top quarter)
                // Scale: divide by 2 → 0 to 16383, then shift up
                carrier4 <= $signed({1'b0, carrier_unsigned[15:1]}) + 16'd16384;

                // Generate sync pulse at carrier peak (direction change from up to down)
                sync_pulse <= (prev_dir == 0) && (counter_dir == 1);

            end else begin
                // Disabled - reset to initial state
                counter <= 0;
                counter_dir <= 0;
                carrier_phase <= 0;
                carrier1 <= CARRIER_MIN;
                carrier2 <= CARRIER_MID;
                sync_pulse <= 0;
            end
        end
    end

endmodule
