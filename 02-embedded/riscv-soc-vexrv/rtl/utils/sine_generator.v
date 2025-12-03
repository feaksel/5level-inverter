/**
 * @file sine_generator.v
 * @brief Sine wave reference generator using lookup table (LUT)
 *
 * Generates sinusoidal modulation reference for 5-level inverter.
 * Uses 256-entry LUT for one complete sine wave period.
 *
 * Features:
 * - Programmable frequency (via phase accumulator)
 * - Programmable modulation index (amplitude scaling)
 * - 16-bit signed output (-32768 to +32767)
 * - Phase accumulator for smooth frequency control
 *
 * @param clk               System clock (100 MHz)
 * @param rst_n             Active-low reset
 * @param enable            Enable sine generation
 * @param freq_increment    Phase increment per clock cycle
 * @param modulation_index  Modulation index (0 to 32767, where 32767 = 100% MI)
 * @param sine_out          Sine wave output (-32768 to +32767)
 * @param phase             Current phase (0 to 255)
 *
 * Frequency calculation:
 *   f_out = (freq_increment * f_clk) / (2^32)
 *   For 50Hz @ 100MHz: freq_increment = 21474836 (0x01470000)
 *
 * Modulation index:
 *   0      = 0% MI (no output)
 *   16384  = 50% MI
 *   32767  = 100% MI (full amplitude)
 *
 * @author 5-Level Inverter Project
 * @date 2025-11-15
 */

module sine_generator #(
    parameter DATA_WIDTH = 16,
    parameter PHASE_WIDTH = 32,
    parameter LUT_ADDR_WIDTH = 8            // 256-entry LUT
)(
    input  wire                         clk,
    input  wire                         rst_n,
    input  wire                         enable,
    input  wire [PHASE_WIDTH-1:0]       freq_increment,
    input  wire [DATA_WIDTH-1:0]        modulation_index,
    output reg  signed [DATA_WIDTH-1:0] sine_out,
    output wire [LUT_ADDR_WIDTH-1:0]    phase
);

    // Phase accumulator
    reg [PHASE_WIDTH-1:0] phase_acc;

    // Use upper bits of phase accumulator as LUT address
    assign phase = phase_acc[PHASE_WIDTH-1:PHASE_WIDTH-LUT_ADDR_WIDTH];

    // Sine LUT (256 entries, 16-bit signed values)
    // Values represent sine from 0 to 2π
    reg signed [DATA_WIDTH-1:0] sine_lut [0:(1<<LUT_ADDR_WIDTH)-1];

    // Scaled sine value
    wire signed [2*DATA_WIDTH-1:0] sine_scaled;

    // Initialize LUT with sine values
    integer i;
    real pi = 3.14159265359;
    real angle;
    initial begin
        for (i = 0; i < (1<<LUT_ADDR_WIDTH); i = i + 1) begin
            angle = (2.0 * pi * i) / (1 << LUT_ADDR_WIDTH);
            sine_lut[i] = $rtoi(32767.0 * $sin(angle));
        end
    end

    // Scale sine by modulation index
    // sine_scaled = (sine_lut[phase] * modulation_index) / 32768
    assign sine_scaled = sine_lut[phase] * $signed(modulation_index);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            phase_acc <= 0;
            sine_out <= 0;
        end else begin
            if (enable) begin
                // Increment phase accumulator
                phase_acc <= phase_acc + freq_increment;

                // Output scaled sine (divide by 32768 = right shift by 15)
                sine_out <= sine_scaled >>> (DATA_WIDTH - 1);

            end else begin
                phase_acc <= 0;
                sine_out <= 0;
            end
        end
    end

endmodule
