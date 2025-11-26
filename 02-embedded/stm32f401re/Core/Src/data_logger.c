/**
 * @file data_logger.c
 * @brief Data logging implementation
 */

#include "data_logger.h"
#include "debug_uart.h"
#include <stdio.h>
#include <string.h>

int logger_init(data_logger_t *logger, UART_HandleTypeDef *huart)
{
    if (logger == NULL || huart == NULL) {
        return -1;
    }

    memset(logger, 0, sizeof(data_logger_t));
    logger->huart = huart;
    logger->mode = LOG_MODE_STATUS;
    logger->decimation = PWM_FREQUENCY_HZ / LOG_SAMPLE_RATE;
    logger->enabled = false;

    return 0;
}

void logger_set_mode(data_logger_t *logger, log_mode_t mode)
{
    if (logger == NULL) return;
    logger->mode = mode;
}

void logger_enable(data_logger_t *logger, bool enable)
{
    if (logger == NULL) return;
    logger->enabled = enable;

    if (enable && logger->mode == LOG_MODE_WAVEFORM) {
        logger_log_header(logger);
    }
}

void logger_log_status(data_logger_t *logger, const sensor_data_t *sensor, const modulation_t *mod)
{
    if (logger == NULL || !logger->enabled) return;
    if (logger->mode != LOG_MODE_STATUS) return;

    snprintf(logger->buffer, LOG_BUFFER_SIZE,
             "I=%.2fA, V=%.1fV, DC1=%.1fV, DC2=%.1fV, MI=%.2f, F=%.1fHz\r\n",
             sensor->output_current,
             sensor->output_voltage,
             sensor->dc_bus1_voltage,
             sensor->dc_bus2_voltage,
             mod->modulation_index,
             mod->frequency_hz);

    HAL_UART_Transmit(logger->huart, (uint8_t*)logger->buffer, strlen(logger->buffer), 100);
}

void logger_log_waveform(data_logger_t *logger, float current, float voltage, uint16_t duty1, uint16_t duty2)
{
    if (logger == NULL || !logger->enabled) return;
    if (logger->mode != LOG_MODE_WAVEFORM) return;

    // Decimation: only log every Nth sample
    logger->sample_counter++;
    if (logger->sample_counter < logger->decimation) {
        return;
    }
    logger->sample_counter = 0;

    // CSV format: time,current,voltage,duty1,duty2
    snprintf(logger->buffer, LOG_BUFFER_SIZE,
             "%lu,%.3f,%.2f,%u,%u\r\n",
             HAL_GetTick(),
             current,
             voltage,
             duty1,
             duty2);

    HAL_UART_Transmit(logger->huart, (uint8_t*)logger->buffer, strlen(logger->buffer), 10);
}

void logger_log_header(data_logger_t *logger)
{
    if (logger == NULL) return;

    const char *header = "time_ms,current_A,voltage_V,duty1,duty2\r\n";
    HAL_UART_Transmit(logger->huart, (uint8_t*)header, strlen(header), 100);
}

void logger_log_message(data_logger_t *logger, const char *msg)
{
    if (logger == NULL || msg == NULL) return;

    HAL_UART_Transmit(logger->huart, (uint8_t*)msg, strlen(msg), 100);
}
