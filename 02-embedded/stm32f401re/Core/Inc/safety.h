/**
 * @file safety.h
 * @brief Safety monitoring and protection
 */

#ifndef SAFETY_H
#define SAFETY_H

#include "stm32f4xx_hal.h"
#include <stdint.h>
#include <stdbool.h>

/* Safety limits */
#define MAX_CURRENT_A           15.0f    // Maximum output current
#define MAX_VOLTAGE_V           125.0f   // Maximum output voltage (100V RMS + margin)
#define MAX_TEMPERATURE_C       85.0f    // Maximum temperature
#define FAULT_RESET_DELAY_MS    5000     // Delay before fault can be reset

/* Fault flags */
typedef enum {
    FAULT_NONE              = 0x00,
    FAULT_OVERCURRENT       = 0x01,
    FAULT_OVERVOLTAGE       = 0x02,
    FAULT_OVERTEMPERATURE   = 0x04,
    FAULT_EMERGENCY_STOP    = 0x08,
    FAULT_HARDWARE          = 0x10
} fault_flag_t;

/* Safety state */
typedef struct {
    uint32_t fault_flags;
    float current_a;
    float voltage_v;
    float temperature_c;
    uint32_t fault_timestamp;
    bool estop_active;
} safety_monitor_t;

/* Functions */
int safety_init(safety_monitor_t *safety, ADC_HandleTypeDef *hadc);
void safety_update(safety_monitor_t *safety, float current, float voltage);
bool safety_check(safety_monitor_t *safety);
void safety_clear_faults(safety_monitor_t *safety);
bool safety_is_fault(const safety_monitor_t *safety);
uint32_t safety_get_faults(const safety_monitor_t *safety);
void safety_emergency_stop(safety_monitor_t *safety);

#endif
