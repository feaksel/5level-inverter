/**
 * @file adc_sensing.h
 * @brief ADC-based current and voltage sensing
 *
 * Hardware connections:
 * - PA0 (ADC1_IN0): Output current sensing
 * - PA1 (ADC1_IN1): Output voltage sensing
 * - PA4 (ADC1_IN4): DC bus 1 voltage
 * - PA5 (ADC1_IN5): DC bus 2 voltage
 *
 * Sensing strategy:
 * - DMA transfers 4 channels continuously
 * - Synchronized with PWM for consistent sampling
 * - Scaling and calibration applied
 *
 * @author 5-Level Inverter Project
 * @date 2025-11-15
 */

#ifndef ADC_SENSING_H
#define ADC_SENSING_H

#include "stm32f4xx_hal.h"
#include <stdint.h>
#include <stdbool.h>

/* Configuration */
#define ADC_CHANNELS            4        // Number of ADC channels
#define ADC_RESOLUTION          4096     // 12-bit ADC
#define ADC_VREF                3.3f     // Reference voltage

/* Scaling factors (adjust based on hardware) */
#define CURRENT_SCALE           10.0f    // A/V (hall sensor: 0.1V/A → 10A/V)
#define VOLTAGE_SCALE           50.0f    // V/V (voltage divider: 1:50)
#define DC_BUS_SCALE            25.0f    // V/V (voltage divider: 1:25)

/* Calibration offsets */
#define CURRENT_OFFSET          0.0f     // Offset in Amps
#define VOLTAGE_OFFSET          0.0f     // Offset in Volts

/* Structures */
typedef struct {
    float output_current;       // Output current (A)
    float output_voltage;       // Output voltage (V RMS or peak)
    float dc_bus1_voltage;      // DC bus 1 voltage (V)
    float dc_bus2_voltage;      // DC bus 2 voltage (V)
    uint32_t sample_count;      // Total samples taken
    bool valid;                 // Data validity flag
} sensor_data_t;

typedef struct {
    ADC_HandleTypeDef *hadc;
    DMA_HandleTypeDef *hdma;
    uint16_t adc_buffer[ADC_CHANNELS];
    sensor_data_t data;
    float current_cal;          // Current calibration factor
    float voltage_cal;          // Voltage calibration factor
    bool initialized;
} adc_sensor_t;

/* Functions */
int adc_sensor_init(adc_sensor_t *sensor, ADC_HandleTypeDef *hadc, DMA_HandleTypeDef *hdma);
int adc_sensor_start(adc_sensor_t *sensor);
int adc_sensor_stop(adc_sensor_t *sensor);
void adc_sensor_update(adc_sensor_t *sensor);
const sensor_data_t* adc_sensor_get_data(const adc_sensor_t *sensor);
void adc_sensor_calibrate(adc_sensor_t *sensor, float current_cal, float voltage_cal);

/* Helper functions */
float adc_to_voltage(uint16_t adc_value);
float voltage_to_current(float voltage);
float voltage_to_bus_voltage(float voltage);

#endif // ADC_SENSING_H
