/**
 * @file fpga_interface.c
 * @brief FPGA Sensing Accelerator Interface Driver Implementation
 *
 * @author 5-Level Inverter Project
 * @date 2025-12-02
 */

#include "fpga_interface.h"

//==========================================================================
// Private Variables
//==========================================================================

static SPI_HandleTypeDef *g_hspi = NULL;

// Chip select pin configuration
#define FPGA_CS_PORT    GPIOA
#define FPGA_CS_PIN     GPIO_PIN_4

// SPI timeout
#define SPI_TIMEOUT_MS  100

//==========================================================================
// Sensor Calibration Constants
//==========================================================================

// AMC1301 isolated voltage sensor
// - Measures DC bus voltage (0-60V)
// - External voltage divider: R1=196kΩ, R2=1kΩ (ratio 1:197)
// - AMC1301 gain: 8.2 V/V
// - Output: 0-2.048V for 0-50V input
#define AMC1301_GAIN            8.2f
#define VOLTAGE_DIVIDER_RATIO   196.0f
#define ADC_FULL_SCALE          65535.0f
#define ADC_VREF                3.3f

// ACS724 current sensor
// - Bidirectional ±30A range
// - Sensitivity: 200 mV/A
// - Zero current output: 2.5V
#define ACS724_SENSITIVITY      0.2f    // V/A
#define ACS724_ZERO_CURRENT_V   2.5f    // V

//==========================================================================
// Public Functions
//==========================================================================

HAL_StatusTypeDef fpga_init(SPI_HandleTypeDef *hspi)
{
    if (hspi == NULL) {
        return HAL_ERROR;
    }

    g_hspi = hspi;

    // Configure CS pin as output (push-pull)
    GPIO_InitTypeDef GPIO_InitStruct = {0};
    GPIO_InitStruct.Pin = FPGA_CS_PIN;
    GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP;
    GPIO_InitStruct.Pull = GPIO_NOPULL;
    GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_HIGH;
    HAL_GPIO_Init(FPGA_CS_PORT, &GPIO_InitStruct);

    // Set CS high (inactive)
    fpga_cs_control(true);

    return HAL_OK;
}

void fpga_cs_control(bool state)
{
    if (state) {
        HAL_GPIO_WritePin(FPGA_CS_PORT, FPGA_CS_PIN, GPIO_PIN_SET);   // CS high
    } else {
        HAL_GPIO_WritePin(FPGA_CS_PORT, FPGA_CS_PIN, GPIO_PIN_RESET); // CS low
    }
}

HAL_StatusTypeDef fpga_read_register(uint8_t addr, uint8_t *data)
{
    if (g_hspi == NULL || data == NULL) {
        return HAL_ERROR;
    }

    HAL_StatusTypeDef status;
    uint8_t tx_data[2] = {addr, 0x00};  // Send address, dummy byte
    uint8_t rx_data[2] = {0};

    // CS low (select FPGA)
    fpga_cs_control(false);

    // Small delay for CS setup time
    for (volatile int i = 0; i < 10; i++);

    // Transmit address and receive data
    status = HAL_SPI_TransmitReceive(g_hspi, tx_data, rx_data, 2, SPI_TIMEOUT_MS);

    // CS high (deselect FPGA)
    fpga_cs_control(true);

    if (status == HAL_OK) {
        *data = rx_data[1];  // Second byte contains the data
    }

    return status;
}

uint8_t fpga_read_status(void)
{
    uint8_t status = 0;
    fpga_read_register(FPGA_REG_STATUS, &status);
    return status & 0x0F;  // Only lower 4 bits are valid
}

HAL_StatusTypeDef fpga_read_adc_channel(fpga_adc_channel_t channel, uint16_t *value)
{
    if (value == NULL || channel > FPGA_ADC_CH3) {
        return HAL_ERROR;
    }

    uint8_t addr_high = FPGA_REG_ADC_CH0_H + (channel * 2);
    uint8_t addr_low = addr_high + 1;
    uint8_t data_high, data_low;

    // Read high byte
    if (fpga_read_register(addr_high, &data_high) != HAL_OK) {
        return HAL_ERROR;
    }

    // Read low byte
    if (fpga_read_register(addr_low, &data_low) != HAL_OK) {
        return HAL_ERROR;
    }

    // Combine bytes
    *value = ((uint16_t)data_high << 8) | data_low;

    return HAL_OK;
}

HAL_StatusTypeDef fpga_read_all_adc(fpga_adc_data_t *data)
{
    if (data == NULL) {
        return HAL_ERROR;
    }

    HAL_StatusTypeDef status;

    // Read status
    data->valid = fpga_read_status();

    // Read all 4 channels
    status = fpga_read_adc_channel(FPGA_ADC_CH0, &data->ch0);
    if (status != HAL_OK) return status;

    status = fpga_read_adc_channel(FPGA_ADC_CH1, &data->ch1);
    if (status != HAL_OK) return status;

    status = fpga_read_adc_channel(FPGA_ADC_CH2, &data->ch2);
    if (status != HAL_OK) return status;

    status = fpga_read_adc_channel(FPGA_ADC_CH3, &data->ch3);
    if (status != HAL_OK) return status;

    return HAL_OK;
}

void fpga_convert_to_physical(const fpga_adc_data_t *raw_data,
                               fpga_sensor_values_t *sensor_values)
{
    if (raw_data == NULL || sensor_values == NULL) {
        return;
    }

    // Convert Channel 0: DC Bus 1 Voltage
    // ADC → Voltage → Pre-divider voltage → Actual voltage
    float vout_adc_ch0 = ((float)raw_data->ch0 * ADC_VREF) / ADC_FULL_SCALE;
    float vin_amc_ch0 = vout_adc_ch0 / AMC1301_GAIN;
    sensor_values->dc_bus1_v = vin_amc_ch0 * VOLTAGE_DIVIDER_RATIO;

    // Convert Channel 1: DC Bus 2 Voltage
    float vout_adc_ch1 = ((float)raw_data->ch1 * ADC_VREF) / ADC_FULL_SCALE;
    float vin_amc_ch1 = vout_adc_ch1 / AMC1301_GAIN;
    sensor_values->dc_bus2_v = vin_amc_ch1 * VOLTAGE_DIVIDER_RATIO;

    // Convert Channel 2: AC Output Voltage (similar to DC bus)
    float vout_adc_ch2 = ((float)raw_data->ch2 * ADC_VREF) / ADC_FULL_SCALE;
    float vin_amc_ch2 = vout_adc_ch2 / AMC1301_GAIN;
    sensor_values->ac_voltage_v = vin_amc_ch2 * VOLTAGE_DIVIDER_RATIO;

    // Convert Channel 3: AC Output Current (ACS724)
    // ACS724: 200mV/A, 2.5V @ 0A
    float vout_adc_ch3 = ((float)raw_data->ch3 * ADC_VREF) / ADC_FULL_SCALE;
    sensor_values->ac_current_a = (vout_adc_ch3 - ACS724_ZERO_CURRENT_V) / ACS724_SENSITIVITY;
}

bool fpga_is_data_ready(void)
{
    uint8_t status = fpga_read_status();
    return (status == 0x0F);  // All 4 channels have valid data
}

uint32_t fpga_read_sample_count(void)
{
    uint8_t count_low = 0;
    fpga_read_register(FPGA_REG_SAMPLE_CNT, &count_low);
    return (uint32_t)count_low;  // Only low byte available via SPI
}
