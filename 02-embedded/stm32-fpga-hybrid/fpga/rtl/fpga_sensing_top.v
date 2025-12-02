/**
 * @file fpga_sensing_top.v
 * @brief FPGA Sensing Accelerator Top Module for STM32+FPGA Hybrid System
 *
 * This module integrates:
 * - 4-channel Sigma-Delta ADC with CIC decimation
 * - SPI slave interface for STM32 communication
 * - External comparator interface (LM339)
 *
 * System Architecture:
 * ```
 * Analog Sensors (AMC1301, ACS724)
 *        ↓
 * LM339 Comparators (4×)
 *        ↓ comp_in[3:0]
 * ┌─────────────────────────────────┐
 * │         FPGA (This module)       │
 * │                                  │
 * │  ┌──────────────────────────┐   │
 * │  │  Sigma-Delta ADC (4-ch)  │   │
 * │  │  - 12-14 bit ENOB        │   │
 * │  │  - 10 kHz sampling       │   │
 * │  │  - 100× OSR              │   │
 * │  └──────────┬───────────────┘   │
 * │             │                    │
 * │  ┌──────────▼───────────────┐   │
 * │  │  SPI Slave Interface     │   │
 * │  │  (Register-based)        │   │
 * │  └──────────┬───────────────┘   │
 * │             │ SPI              │
 * └─────────────┼──────────────────┘
 *               ↓
 *         STM32F401RE
 *         (Control Algorithm)
 * ```
 *
 * Target FPGA: Digilent Basys 3 (Xilinx Artix-7 XC7A35T)
 * or similar low-cost FPGA boards
 *
 * Clock: 50 MHz system clock
 * Resources: ~1500 LUTs, ~20 BRAMs (minimal)
 */

module fpga_sensing_top #(
    parameter CLK_FREQ = 50_000_000,   // 50 MHz system clock
    parameter OSR = 100,                // Oversampling ratio
    parameter CIC_ORDER = 3             // CIC filter order
)(
    // Clock and Reset
    input  wire        clk_50mhz,      // 50 MHz system clock
    input  wire        rst_n,          // Active-low reset

    // ADC Comparator Interface (to LM339)
    input  wire [3:0]  comp_in,        // Comparator inputs from LM339
    output wire [3:0]  dac_out,        // 1-bit DAC outputs to RC filters

    // SPI Interface to STM32 (slave mode)
    input  wire        spi_sck,        // SPI clock from STM32
    input  wire        spi_mosi,       // Master Out Slave In
    output wire        spi_miso,       // Master In Slave Out
    input  wire        spi_cs_n,       // Chip select (active low)

    // Status outputs (optional - for debugging)
    output wire [3:0]  led,            // Status LEDs
    output wire        adc_data_ready  // Pulse when new ADC data available
);

    //==========================================================================
    // Clock and Reset
    //==========================================================================

    wire clk = clk_50mhz;

    // Reset synchronization
    reg [2:0] rst_sync;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            rst_sync <= 3'b000;
        else
            rst_sync <= {rst_sync[1:0], 1'b1};
    end

    wire rst_n_sync = rst_sync[2];

    //==========================================================================
    // Sigma-Delta ADC (4 channels)
    //==========================================================================

    wire [15:0] adc_ch0, adc_ch1, adc_ch2, adc_ch3;
    wire [3:0]  adc_data_valid;
    wire [31:0] adc_sample_cnt;
    reg         adc_enable;

    // Auto-enable ADC on reset
    always @(posedge clk or negedge rst_n_sync) begin
        if (!rst_n_sync)
            adc_enable <= 1'b0;
        else
            adc_enable <= 1'b1;
    end

    // Instantiate 4 ADC channels
    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin : adc_channels
            sigma_delta_channel #(
                .OSR(OSR),
                .CIC_ORDER(CIC_ORDER)
            ) adc_ch (
                .clk(clk),
                .rst_n(rst_n_sync),
                .enable(adc_enable),
                .comp_in(comp_in[i]),
                .dac_out(dac_out[i]),
                .adc_data(i == 0 ? adc_ch0 :
                          i == 1 ? adc_ch1 :
                          i == 2 ? adc_ch2 : adc_ch3),
                .data_valid(adc_data_valid[i])
            );
        end
    endgenerate

    // Sample counter for debug
    reg [31:0] sample_counter;

    always @(posedge clk or negedge rst_n_sync) begin
        if (!rst_n_sync)
            sample_counter <= 32'd0;
        else if (adc_data_valid[0])
            sample_counter <= sample_counter + 1;
    end

    assign adc_sample_cnt = sample_counter;
    assign adc_data_ready = (adc_data_valid == 4'hF);

    //==========================================================================
    // SPI Interface to STM32
    //==========================================================================

    wire data_read_strobe;

    stm32_spi_interface spi_if (
        .clk(clk),
        .rst_n(rst_n_sync),

        // SPI pins
        .spi_sck(spi_sck),
        .spi_mosi(spi_mosi),
        .spi_miso(spi_miso),
        .spi_cs_n(spi_cs_n),

        // ADC data
        .adc_ch0(adc_ch0),
        .adc_ch1(adc_ch1),
        .adc_ch2(adc_ch2),
        .adc_ch3(adc_ch3),
        .adc_data_valid(adc_data_valid),
        .adc_sample_cnt(adc_sample_cnt),

        .data_read_strobe(data_read_strobe)
    );

    //==========================================================================
    // Status LEDs (for debugging)
    //==========================================================================

    assign led[0] = rst_n_sync;           // Power indicator
    assign led[1] = adc_data_ready;       // ADC data ready
    assign led[2] = ~spi_cs_n;            // SPI active
    assign led[3] = data_read_strobe;     // Data read from STM32

endmodule

//==========================================================================
// Sigma-Delta ADC Channel Module (copied from sigma_delta_adc.v)
//==========================================================================

module sigma_delta_channel #(
    parameter OSR = 100,
    parameter CIC_ORDER = 3,
    parameter W = 32                    // Internal width
)(
    input  wire        clk,             // 50 MHz system clock
    input  wire        rst_n,
    input  wire        enable,
    input  wire        comp_in,         // Comparator input (1-bit)
    output reg         dac_out,         // 1-bit DAC output
    output wire [15:0] adc_data,        // 16-bit ADC result
    output wire        data_valid       // Data valid strobe
);

    //==========================================================================
    // Clock Divider: 50 MHz → 1 MHz (for 1 MHz sampling)
    //==========================================================================

    localparam CLK_DIV = 50;            // 50 MHz / 50 = 1 MHz

    reg [6:0] clk_div_counter;
    reg       clk_1mhz;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clk_div_counter <= 7'd0;
            clk_1mhz <= 1'b0;
        end else if (enable) begin
            if (clk_div_counter == CLK_DIV - 1) begin
                clk_div_counter <= 7'd0;
                clk_1mhz <= ~clk_1mhz;  // Toggle at 1 MHz
            end else begin
                clk_div_counter <= clk_div_counter + 1;
            end
        end
    end

    wire clk_1mhz_posedge = (clk_div_counter == 0) && clk_1mhz && enable;

    //==========================================================================
    // Sigma-Delta Modulator (1st order)
    //==========================================================================

    reg signed [31:0] integrator;
    reg               bitstream;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            integrator <= 32'sd0;
            dac_out <= 1'b0;
            bitstream <= 1'b0;
        end else if (clk_1mhz_posedge) begin
            // Error signal = input - feedback
            integrator <= integrator +
                          (comp_in ? 32'sd32768 : -32'sd32768) -
                          (dac_out ? 32'sd32768 : -32'sd32768);

            // 1-bit quantizer
            dac_out <= (integrator >= 0);
            bitstream <= dac_out;
        end
    end

    //==========================================================================
    // CIC Decimation Filter (3rd order)
    //==========================================================================

    // Integrator stages (run at 1 MHz)
    reg [W-1:0] integrator_stage [0:CIC_ORDER-1];
    integer i;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < CIC_ORDER; i = i + 1)
                integrator_stage[i] <= 0;
        end else if (clk_1mhz_posedge) begin
            // First integrator
            integrator_stage[0] <= integrator_stage[0] + (bitstream ? 1 : 0);

            // Cascaded integrators
            for (i = 1; i < CIC_ORDER; i = i + 1)
                integrator_stage[i] <= integrator_stage[i] + integrator_stage[i-1];
        end
    end

    // Decimation counter
    reg [7:0] decim_count;
    reg [W-1:0] snapshot;
    reg snapshot_valid;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            decim_count <= 8'd0;
            snapshot <= 0;
            snapshot_valid <= 1'b0;
        end else if (clk_1mhz_posedge) begin
            decim_count <= decim_count + 1;
            snapshot_valid <= 1'b0;

            if (decim_count == OSR - 1) begin
                decim_count <= 8'd0;
                snapshot <= integrator_stage[CIC_ORDER-1];
                snapshot_valid <= 1'b1;
            end
        end
    end

    // Comb stages (run at 10 kHz)
    reg [W-1:0] comb [0:CIC_ORDER-1];
    reg [W-1:0] comb_delay [0:CIC_ORDER-1];
    reg [15:0]  adc_result;
    reg         result_valid;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < CIC_ORDER; i = i + 1) begin
                comb[i] <= 0;
                comb_delay[i] <= 0;
            end
            adc_result <= 16'd0;
            result_valid <= 1'b0;
        end else if (snapshot_valid) begin
            // First comb
            comb[0] <= snapshot - comb_delay[0];
            comb_delay[0] <= snapshot;

            // Cascaded combs
            for (i = 1; i < CIC_ORDER; i = i + 1) begin
                comb[i] <= comb[i-1] - comb_delay[i];
                comb_delay[i] <= comb[i-1];
            end

            // Output (take top 16 bits, scaled appropriately)
            adc_result <= comb[CIC_ORDER-1][W-1:W-16];
            result_valid <= 1'b1;
        end else begin
            result_valid <= 1'b0;
        end
    end

    assign adc_data = adc_result;
    assign data_valid = result_valid;

endmodule
