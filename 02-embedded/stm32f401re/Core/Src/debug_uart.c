/**
 * @file debug_uart.c
 * @brief UART debug implementation
 */

#include "debug_uart.h"
#include <stdio.h>
#include <stdarg.h>
#include <string.h>

static UART_HandleTypeDef *g_huart = NULL;

int debug_uart_init(UART_HandleTypeDef *huart)
{
    if (huart == NULL) return -1;
    g_huart = huart;
    return 0;
}

void debug_print(const char *msg)
{
    if (g_huart == NULL || msg == NULL) return;
    HAL_UART_Transmit(g_huart, (uint8_t*)msg, strlen(msg), 100);
}

void debug_printf(const char *format, ...)
{
    if (g_huart == NULL || format == NULL) return;

    char buffer[128];
    va_list args;
    va_start(args, format);
    vsnprintf(buffer, sizeof(buffer), format, args);
    va_end(args);

    debug_print(buffer);
}

void debug_print_status(void)
{
    debug_print("\r\n=== 5-Level Inverter Status ===\r\n");
}

void debug_print_measurements(float v_out, float i_out)
{
    debug_printf("V_out: %.2f V, I_out: %.2f A\r\n", v_out, i_out);
}
