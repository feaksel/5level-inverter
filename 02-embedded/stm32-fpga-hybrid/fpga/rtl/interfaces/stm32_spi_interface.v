/**
 * @file stm32_spi_interface.v
 * @brief SPI Slave Interface for STM32-FPGA Communication
 *
 * Provides SPI slave interface for STM32 to read ADC data from FPGA.
 * The STM32 acts as SPI master, FPGA as SPI slave.
 *
 * Features:
 * - SPI Mode 0 (CPOL=0, CPHA=0)
 * - 16-bit data transfers
 * - Register-based addressing
 * - Up to 10 MHz SPI clock (STM32F401RE max: 21 MHz)
 *
 * Register Map (8-bit address):
 * 0x00: STATUS      - Status register [3:0]: Data valid flags
 * 0x01: ADC_CH0_H   - Channel 0 high byte [15:8]
 * 0x02: ADC_CH0_L   - Channel 0 low byte [7:0]
 * 0x03: ADC_CH1_H   - Channel 1 high byte
 * 0x04: ADC_CH1_L   - Channel 1 low byte
 * 0x05: ADC_CH2_H   - Channel 2 high byte
 * 0x06: ADC_CH2_L   - Channel 2 low byte
 * 0x07: ADC_CH3_H   - Channel 3 high byte
 * 0x08: ADC_CH3_L   - Channel 3 low byte
 * 0x09: SAMPLE_CNT  - Sample counter (debug)
 *
 * SPI Transaction Format:
 * Byte 0: Address (write from STM32)
 * Byte 1: Data (read from FPGA)
 */

module stm32_spi_interface (
    input  wire        clk,            // FPGA system clock (50 MHz)
    input  wire        rst_n,          // Active-low reset

    // SPI interface (slave mode)
    input  wire        spi_sck,        // SPI clock from STM32
    input  wire        spi_mosi,       // Master Out Slave In
    output reg         spi_miso,       // Master In Slave Out
    input  wire        spi_cs_n,       // Chip select (active low)

    // ADC data inputs (from Sigma-Delta ADC)
    input  wire [15:0] adc_ch0,
    input  wire [15:0] adc_ch1,
    input  wire [15:0] adc_ch2,
    input  wire [15:0] adc_ch3,
    input  wire [3:0]  adc_data_valid,
    input  wire [31:0] adc_sample_cnt,

    // Status output
    output reg         data_read_strobe  // Pulse when STM32 reads data
);

    //==========================================================================
    // SPI Clock Synchronization
    //==========================================================================

    reg [2:0] spi_sck_sync;
    reg [2:0] spi_cs_sync;
    reg [1:0] spi_mosi_sync;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            spi_sck_sync <= 3'b000;
            spi_cs_sync <= 3'b111;
            spi_mosi_sync <= 2'b00;
        end else begin
            spi_sck_sync <= {spi_sck_sync[1:0], spi_sck};
            spi_cs_sync <= {spi_cs_sync[1:0], spi_cs_n};
            spi_mosi_sync <= {spi_mosi_sync[0], spi_mosi};
        end
    end

    wire spi_sck_rising = (spi_sck_sync[2:1] == 2'b01);
    wire spi_sck_falling = (spi_sck_sync[2:1] == 2'b10);
    wire spi_cs_active = (spi_cs_sync[2] == 1'b0);
    wire spi_mosi_bit = spi_mosi_sync[1];

    //==========================================================================
    // SPI State Machine
    //==========================================================================

    localparam IDLE     = 2'd0;
    localparam ADDR     = 2'd1;
    localparam DATA     = 2'd2;

    reg [1:0]  spi_state;
    reg [3:0]  bit_count;
    reg [7:0]  addr_reg;
    reg [7:0]  data_out;
    reg [7:0]  shift_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            spi_state <= IDLE;
            bit_count <= 4'd0;
            addr_reg <= 8'd0;
            data_out <= 8'd0;
            shift_reg <= 8'd0;
            spi_miso <= 1'b0;
            data_read_strobe <= 1'b0;
        end else begin
            data_read_strobe <= 1'b0;

            if (!spi_cs_active) begin
                // CS inactive - reset state
                spi_state <= IDLE;
                bit_count <= 4'd0;
                spi_miso <= 1'b0;
            end else begin
                // CS active - process SPI transaction
                case (spi_state)
                    IDLE: begin
                        if (spi_cs_active) begin
                            spi_state <= ADDR;
                            bit_count <= 4'd0;
                            shift_reg <= 8'd0;
                        end
                    end

                    ADDR: begin
                        // Receive address byte
                        if (spi_sck_rising) begin
                            shift_reg <= {shift_reg[6:0], spi_mosi_bit};
                            bit_count <= bit_count + 1;

                            if (bit_count == 4'd7) begin
                                // Address received, look up data
                                addr_reg <= {shift_reg[6:0], spi_mosi_bit};
                                spi_state <= DATA;
                                bit_count <= 4'd0;
                            end
                        end
                    end

                    DATA: begin
                        // Send data byte
                        if (bit_count == 4'd0 && spi_sck_falling) begin
                            // Load data on first falling edge
                            case (addr_reg)
                                8'h00: data_out <= {4'd0, adc_data_valid};
                                8'h01: data_out <= adc_ch0[15:8];
                                8'h02: data_out <= adc_ch0[7:0];
                                8'h03: data_out <= adc_ch1[15:8];
                                8'h04: data_out <= adc_ch1[7:0];
                                8'h05: data_out <= adc_ch2[15:8];
                                8'h06: data_out <= adc_ch2[7:0];
                                8'h07: data_out <= adc_ch3[15:8];
                                8'h08: data_out <= adc_ch3[7:0];
                                8'h09: data_out <= adc_sample_cnt[7:0];
                                default: data_out <= 8'hFF;
                            endcase
                            shift_reg <= data_out;
                            spi_miso <= data_out[7];
                            bit_count <= bit_count + 1;
                        end else if (spi_sck_falling && bit_count > 0) begin
                            // Shift out data
                            shift_reg <= {shift_reg[6:0], 1'b0};
                            spi_miso <= shift_reg[7];
                            bit_count <= bit_count + 1;

                            if (bit_count == 4'd8) begin
                                // Data sent, ready for next address
                                spi_state <= ADDR;
                                bit_count <= 4'd0;
                                data_read_strobe <= 1'b1;
                            end
                        end
                    end

                    default: spi_state <= IDLE;
                endcase
            end
        end
    end

endmodule
