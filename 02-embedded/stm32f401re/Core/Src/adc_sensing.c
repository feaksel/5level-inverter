/**
 * @file adc_sensing.c
 * @brief ADC sensing implementation
 */

#include "adc_sensing.h"
#include <string.h>
#include <math.h>

/* Helper functions */
float adc_to_voltage(uint16_t adc_value)
{
    return ((float)adc_value / ADC_RESOLUTION) * ADC_VREF;
}

float voltage_to_current(float voltage)
{
    // Assuming current sensor outputs voltage proportional to current
    // Typical hall sensor: 2.5V offset, 0.1V/A sensitivity
    // Adjust based on your sensor
    float offset_voltage = ADC_VREF / 2.0f;  // 1.65V center
    return (voltage - offset_voltage) * CURRENT_SCALE + CURRENT_OFFSET;
}

float voltage_to_bus_voltage(float voltage)
{
    // Voltage divider scaling
    return voltage * VOLTAGE_SCALE;
}

/* Public functions */
int adc_sensor_init(adc_sensor_t *sensor, ADC_HandleTypeDef *hadc, DMA_HandleTypeDef *hdma)
{
    if (sensor == NULL || hadc == NULL) {
        return -1;
    }

    // Clear structure
    memset(sensor, 0, sizeof(adc_sensor_t));

    sensor->hadc = hadc;
    sensor->hdma = hdma;
    sensor->current_cal = 1.0f;
    sensor->voltage_cal = 1.0f;
    sensor->initialized = true;
    sensor->data.valid = false;

    return 0;
}

int adc_sensor_start(adc_sensor_t *sensor)
{
    if (sensor == NULL || !sensor->initialized) {
        return -1;
    }

    // Start ADC with DMA
    if (HAL_ADC_Start_DMA(sensor->hadc, (uint32_t*)sensor->adc_buffer, ADC_CHANNELS) != HAL_OK) {
        return -2;
    }

    return 0;
}

int adc_sensor_stop(adc_sensor_t *sensor)
{
    if (sensor == NULL || !sensor->initialized) {
        return -1;
    }

    HAL_ADC_Stop_DMA(sensor->hadc);
    sensor->data.valid = false;

    return 0;
}

void adc_sensor_update(adc_sensor_t *sensor)
{
    if (sensor == NULL || !sensor->initialized) {
        return;
    }

    // Convert ADC buffer to voltages
    float adc_voltages[ADC_CHANNELS];
    for (int i = 0; i < ADC_CHANNELS; i++) {
        adc_voltages[i] = adc_to_voltage(sensor->adc_buffer[i]);
    }

    // Channel 0: Output current
    sensor->data.output_current = voltage_to_current(adc_voltages[0]) * sensor->current_cal;

    // Channel 1: Output voltage
    sensor->data.output_voltage = voltage_to_bus_voltage(adc_voltages[1]) * sensor->voltage_cal;

    // Channel 2: DC bus 1
    sensor->data.dc_bus1_voltage = voltage_to_bus_voltage(adc_voltages[2]);

    // Channel 3: DC bus 2
    sensor->data.dc_bus2_voltage = voltage_to_bus_voltage(adc_voltages[3]);

    sensor->data.sample_count++;
    sensor->data.valid = true;
}

const sensor_data_t* adc_sensor_get_data(const adc_sensor_t *sensor)
{
    if (sensor == NULL || !sensor->initialized) {
        return NULL;
    }

    return &sensor->data;
}

void adc_sensor_calibrate(adc_sensor_t *sensor, float current_cal, float voltage_cal)
{
    if (sensor == NULL) {
        return;
    }

    sensor->current_cal = current_cal;
    sensor->voltage_cal = voltage_cal;
}
