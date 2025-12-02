/**
 * @file fpga_interface.h
 * @brief FPGA Sensing Accelerator Interface Driver for STM32F401RE
 *
 * This driver provides high-level interface to read ADC data from the
 * FPGA sensing accelerator via SPI.
 *
 * Features:
 * - SPI communication with FPGA (up to 10 MHz)
 * - Register-based access to 4-channel ADC data
 * - Non-blocking and blocking read modes
 * - Data valid checking
 *
 * Hardware Connections (STM32F401RE):
 * - SPI1 used for FPGA communication
 * - PA5: SPI1_SCK  → FPGA SPI_SCK
 * - PA6: SPI1_MISO ← FPGA SPI_MISO
 * - PA7: SPI1_MOSI → FPGA SPI_MOSI
 * - PA4: GPIO_OUT  → FPGA SPI_CS_N (chip select)
 *
 * @author 5-Level Inverter Project
 * @date 2025-12-02
 */

#ifndef FPGA_INTERFACE_H
#define FPGA_INTERFACE_H

#include "stm32f4xx_hal.h"
#include <stdint.h>
#include <stdbool.h>

//==========================================================================
// FPGA Register Addresses
//==========================================================================

#define FPGA_REG_STATUS      0x00  // Status register [3:0]: Data valid flags
#define FPGA_REG_ADC_CH0_H   0x01  // Channel 0 high byte [15:8]
#define FPGA_REG_ADC_CH0_L   0x02  // Channel 0 low byte [7:0]
#define FPGA_REG_ADC_CH1_H   0x03  // Channel 1 high byte
#define FPGA_REG_ADC_CH1_L   0x04  // Channel 1 low byte
#define FPGA_REG_ADC_CH2_H   0x05  // Channel 2 high byte
#define FPGA_REG_ADC_CH2_L   0x06  // Channel 2 low byte
#define FPGA_REG_ADC_CH3_H   0x07  // Channel 3 high byte
#define FPGA_REG_ADC_CH3_L   0x08  // Channel 3 low byte
#define FPGA_REG_SAMPLE_CNT  0x09  // Sample counter (debug)

//==========================================================================
// Data Structures
//==========================================================================

/**
 * @brief ADC channel enumeration
 */
typedef enum {
    FPGA_ADC_CH0 = 0,  // DC Bus 1 voltage
    FPGA_ADC_CH1 = 1,  // DC Bus 2 voltage
    FPGA_ADC_CH2 = 2,  // AC output voltage
    FPGA_ADC_CH3 = 3   // AC output current
} fpga_adc_channel_t;

/**
 * @brief ADC data structure (all 4 channels)
 */
typedef struct {
    uint16_t ch0;      // DC Bus 1 voltage (raw ADC value 0-65535)
    uint16_t ch1;      // DC Bus 2 voltage
    uint16_t ch2;      // AC output voltage
    uint16_t ch3;      // AC output current
    uint8_t  valid;    // Data valid flags [3:0]
} fpga_adc_data_t;

/**
 * @brief Physical sensor values (converted to real units)
 */
typedef struct {
    float dc_bus1_v;   // DC Bus 1 voltage (V)
    float dc_bus2_v;   // DC Bus 2 voltage (V)
    float ac_voltage_v; // AC output voltage (V)
    float ac_current_a; // AC output current (A)
} fpga_sensor_values_t;

//==========================================================================
// Public Functions
//==========================================================================

/**
 * @brief Initialize FPGA interface
 *
 * Configures SPI1 peripheral and CS GPIO for FPGA communication.
 * Must be called before any other FPGA functions.
 *
 * @param hspi Pointer to SPI handle (SPI1)
 * @return HAL_OK on success, HAL_ERROR on failure
 */
HAL_StatusTypeDef fpga_init(SPI_HandleTypeDef *hspi);

/**
 * @brief Read single register from FPGA
 *
 * Performs SPI transaction to read one byte from specified register.
 *
 * @param addr Register address (0x00-0x09)
 * @param data Pointer to store read data
 * @return HAL_OK on success, HAL_ERROR on failure
 */
HAL_StatusTypeDef fpga_read_register(uint8_t addr, uint8_t *data);

/**
 * @brief Read status register
 *
 * Reads FPGA status register to check data valid flags.
 *
 * @return Status byte [3:0]: Data valid flags for channels 3-0
 */
uint8_t fpga_read_status(void);

/**
 * @brief Read single ADC channel (16-bit)
 *
 * Reads 16-bit ADC value for specified channel.
 *
 * @param channel ADC channel (0-3)
 * @param value Pointer to store 16-bit ADC value
 * @return HAL_OK on success, HAL_ERROR on failure
 */
HAL_StatusTypeDef fpga_read_adc_channel(fpga_adc_channel_t channel, uint16_t *value);

/**
 * @brief Read all ADC channels at once
 *
 * Reads all 4 ADC channels in a single burst operation.
 * This is the recommended method for reading sensor data.
 *
 * @param data Pointer to structure to store ADC data
 * @return HAL_OK on success, HAL_ERROR on failure
 */
HAL_StatusTypeDef fpga_read_all_adc(fpga_adc_data_t *data);

/**
 * @brief Convert raw ADC values to physical sensor values
 *
 * Converts 16-bit ADC values to real-world units (V, A) based on
 * sensor characteristics (AMC1301, ACS724).
 *
 * @param raw_data Raw ADC data from FPGA
 * @param sensor_values Pointer to structure to store converted values
 */
void fpga_convert_to_physical(const fpga_adc_data_t *raw_data,
                               fpga_sensor_values_t *sensor_values);

/**
 * @brief Check if new ADC data is available
 *
 * Checks status register to see if FPGA has new ADC data.
 *
 * @return true if new data available, false otherwise
 */
bool fpga_is_data_ready(void);

/**
 * @brief Read sample counter (debug)
 *
 * Reads FPGA sample counter for debugging and verification.
 *
 * @return Sample count value
 */
uint32_t fpga_read_sample_count(void);

/**
 * @brief CS pin control (low-level)
 *
 * Manually control chip select pin.
 *
 * @param state true = CS high (inactive), false = CS low (active)
 */
void fpga_cs_control(bool state);

#endif // FPGA_INTERFACE_H
