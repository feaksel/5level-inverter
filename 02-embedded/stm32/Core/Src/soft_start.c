/**
 * @file soft_start.c
 * @brief Soft-start implementation
 */

#include "soft_start.h"
#include "stm32f4xx_hal.h"
#include <string.h>

void soft_start_init(soft_start_t *ss, uint32_t ramp_time_ms)
{
    if (ss == NULL) return;

    memset(ss, 0, sizeof(soft_start_t));
    ss->ramp_duration = ramp_time_ms;
    ss->state = SOFTSTART_IDLE;
}

void soft_start_begin(soft_start_t *ss, float target_mi)
{
    if (ss == NULL) return;

    // Clamp target MI
    if (target_mi < 0.0f) target_mi = 0.0f;
    if (target_mi > 1.0f) target_mi = 1.0f;

    ss->target_mi = target_mi;
    ss->current_mi = 0.0f;
    ss->start_time = HAL_GetTick();
    ss->ramp_rate = target_mi / (float)ss->ramp_duration;
    ss->state = SOFTSTART_RAMPING;
}

void soft_start_update(soft_start_t *ss)
{
    if (ss == NULL) return;
    if (ss->state != SOFTSTART_RAMPING) return;

    uint32_t elapsed = HAL_GetTick() - ss->start_time;

    if (elapsed >= ss->ramp_duration) {
        // Ramp complete
        ss->current_mi = ss->target_mi;
        ss->state = SOFTSTART_COMPLETE;
    } else {
        // Calculate current MI based on elapsed time
        ss->current_mi = ss->ramp_rate * elapsed;

        // Clamp to target (in case of timing issues)
        if (ss->current_mi > ss->target_mi) {
            ss->current_mi = ss->target_mi;
        }
    }
}

float soft_start_get_mi(const soft_start_t *ss)
{
    if (ss == NULL) return 0.0f;
    return ss->current_mi;
}

bool soft_start_is_complete(const soft_start_t *ss)
{
    if (ss == NULL) return false;
    return (ss->state == SOFTSTART_COMPLETE);
}

void soft_start_abort(soft_start_t *ss)
{
    if (ss == NULL) return;

    ss->current_mi = 0.0f;
    ss->state = SOFTSTART_IDLE;
}
