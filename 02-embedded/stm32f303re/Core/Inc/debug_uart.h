/**
 * @file debug_uart.h
 * @brief UART debug output functions
 */

#ifndef DEBUG_UART_H
#define DEBUG_UART_H

#include "stm32f3xx_hal.h"
#include <stdint.h>
#include <stdbool.h>

/* Functions */
int debug_uart_init(UART_HandleTypeDef *huart);
void debug_print(const char *msg);
void debug_printf(const char *format, ...);
void debug_print_status(void);
void debug_print_measurements(float v_out, float i_out);

#endif
