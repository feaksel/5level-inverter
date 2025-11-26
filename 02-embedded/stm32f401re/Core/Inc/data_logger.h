/**
 * @file data_logger.h
 * @brief Real-time data logging to UART
 *
 * Logs waveform data for analysis:
 * - Current and voltage samples
 * - PWM duty cycles
 * - Modulation parameters
 *
 * Output format: CSV for easy plotting in Python/MATLAB
 *
 * @author 5-Level Inverter Project
 * @date 2025-11-15
 */

#ifndef DATA_LOGGER_H
#define DATA_LOGGER_H

#include "stm32f4xx_hal.h"
#include "adc_sensing.h"
#include "multilevel_modulation.h"
#include <stdint.h>
#include <stdbool.h>

/* Configuration */
#define LOG_BUFFER_SIZE         256      // Buffer size for log messages
#define LOG_SAMPLE_RATE         1000     // Samples per second to log

/* Logging modes */
typedef enum {
    LOG_MODE_OFF = 0,
    LOG_MODE_STATUS,        // Periodic status updates
    LOG_MODE_WAVEFORM,      // Continuous waveform data
    LOG_MODE_DEBUG          // Verbose debug info
} log_mode_t;

/* Logger structure */
typedef struct {
    UART_HandleTypeDef *huart;
    log_mode_t mode;
    uint32_t sample_counter;
    uint32_t decimation;    // Decimation factor for sample rate
    bool enabled;
    char buffer[LOG_BUFFER_SIZE];
} data_logger_t;

/* Functions */
int logger_init(data_logger_t *logger, UART_HandleTypeDef *huart);
void logger_set_mode(data_logger_t *logger, log_mode_t mode);
void logger_enable(data_logger_t *logger, bool enable);

// Logging functions
void logger_log_status(data_logger_t *logger, const sensor_data_t *sensor, const modulation_t *mod);
void logger_log_waveform(data_logger_t *logger, float current, float voltage, uint16_t duty1, uint16_t duty2);
void logger_log_header(data_logger_t *logger);
void logger_log_message(data_logger_t *logger, const char *msg);

#endif // DATA_LOGGER_H
