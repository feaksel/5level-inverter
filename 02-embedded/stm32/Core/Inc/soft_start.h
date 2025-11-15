/**
 * @file soft_start.h
 * @brief Soft-start sequence for inverter
 *
 * Gradually ramps modulation index from 0 to target value
 * to prevent inrush current and voltage spikes.
 *
 * @author 5-Level Inverter Project
 * @date 2025-11-15
 */

#ifndef SOFT_START_H
#define SOFT_START_H

#include <stdint.h>
#include <stdbool.h>

/* Configuration */
#define SOFT_START_RAMP_TIME_MS     2000     // 2 second ramp
#define SOFT_START_STEP_TIME_MS     10       // Update every 10ms

/* Soft-start states */
typedef enum {
    SOFTSTART_IDLE = 0,
    SOFTSTART_RAMPING,
    SOFTSTART_COMPLETE
} softstart_state_t;

/* Soft-start structure */
typedef struct {
    float target_mi;            // Target modulation index
    float current_mi;           // Current modulation index
    float ramp_rate;            // MI per ms
    uint32_t start_time;        // Start timestamp
    uint32_t ramp_duration;     // Ramp duration in ms
    softstart_state_t state;
} soft_start_t;

/* Functions */
void soft_start_init(soft_start_t *ss, uint32_t ramp_time_ms);
void soft_start_begin(soft_start_t *ss, float target_mi);
void soft_start_update(soft_start_t *ss);
float soft_start_get_mi(const soft_start_t *ss);
bool soft_start_is_complete(const soft_start_t *ss);
void soft_start_abort(soft_start_t *ss);

#endif // SOFT_START_H
