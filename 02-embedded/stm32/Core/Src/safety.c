/**
 * @file safety.c
 * @brief Safety monitoring implementation
 */

#include "safety.h"
#include <string.h>

static ADC_HandleTypeDef *g_hadc = NULL;

int safety_init(safety_monitor_t *safety, ADC_HandleTypeDef *hadc)
{
    if (safety == NULL) return -1;

    memset(safety, 0, sizeof(safety_monitor_t));
    g_hadc = hadc;

    return 0;
}

void safety_update(safety_monitor_t *safety, float current, float voltage)
{
    if (safety == NULL) return;

    safety->current_a = current;
    safety->voltage_v = voltage;

    // Check overcurrent
    if (current > MAX_CURRENT_A) {
        safety->fault_flags |= FAULT_OVERCURRENT;
        safety->fault_timestamp = HAL_GetTick();
    }

    // Check overvoltage
    if (voltage > MAX_VOLTAGE_V) {
        safety->fault_flags |= FAULT_OVERVOLTAGE;
        safety->fault_timestamp = HAL_GetTick();
    }
}

bool safety_check(safety_monitor_t *safety)
{
    if (safety == NULL) return false;
    return (safety->fault_flags == FAULT_NONE);
}

void safety_clear_faults(safety_monitor_t *safety)
{
    if (safety == NULL) return;

    uint32_t current_time = HAL_GetTick();
    if ((current_time - safety->fault_timestamp) > FAULT_RESET_DELAY_MS) {
        safety->fault_flags = FAULT_NONE;
        safety->estop_active = false;
    }
}

bool safety_is_fault(const safety_monitor_t *safety)
{
    if (safety == NULL) return true;
    return (safety->fault_flags != FAULT_NONE);
}

uint32_t safety_get_faults(const safety_monitor_t *safety)
{
    if (safety == NULL) return 0;
    return safety->fault_flags;
}

void safety_emergency_stop(safety_monitor_t *safety)
{
    if (safety == NULL) return;

    safety->fault_flags |= FAULT_EMERGENCY_STOP;
    safety->estop_active = true;
    safety->fault_timestamp = HAL_GetTick();
}
