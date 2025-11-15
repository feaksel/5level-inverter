/**
 * @file multilevel_modulation.h
 * @brief Level-shifted PWM modulation for 5-level cascaded H-bridge
 *
 * LEVEL-SHIFTED CARRIER STRATEGY:
 * - Carrier 1: Triangle wave from -1 to 0 (for H-bridge 1)
 * - Carrier 2: Triangle wave from 0 to +1 (for H-bridge 2)
 * - Reference: Sine wave from -1 to +1
 * - Each carrier at same frequency but vertically offset
 *
 * @author 5-Level Inverter Project
 * @date 2025-11-15
 */

#ifndef MULTILEVEL_MODULATION_H
#define MULTILEVEL_MODULATION_H

#include "stm32f4xx_hal.h"
#include <stdint.h>
#include <stdbool.h>

/* Configuration */
#define SYSTEM_CLOCK_HZ         84000000  // STM32F401 @ 84MHz
#define PWM_FREQUENCY_HZ        10000     // Switching frequency
#define OUTPUT_FREQUENCY_HZ     50        // Output sine wave frequency

// PWM_PERIOD = (SYSTEM_CLOCK_HZ / PWM_FREQUENCY_HZ) - 1
// For 10kHz: (84000000 / 10000) - 1 = 8399
// For 20kHz: (84000000 / 20000) - 1 = 4199
#define PWM_PERIOD              8399

#define SINE_TABLE_SIZE         200       // Full cycle samples

/* IMPORTANT: To change switching frequency:
 * 1. Change PWM_FREQUENCY_HZ above
 * 2. Recalculate PWM_PERIOD using formula above
 * 3. Update htim1.Init.Period in main.c (line ~238)
 * 4. Update htim8.Init.Period in main.c (line ~300)
 */

/* Structures */
typedef struct {
    uint16_t ch1;  // Channel 1 duty
    uint16_t ch2;  // Channel 2 duty
} hbridge_duty_t;

typedef struct {
    hbridge_duty_t hbridge1;  // TIM1 - Level 1 (carrier -1 to 0)
    hbridge_duty_t hbridge2;  // TIM8 - Level 2 (carrier 0 to +1)
} inverter_duty_t;

typedef struct {
    float modulation_index;   // 0.0 to 1.0
    float frequency_hz;
    uint32_t sample_index;
    bool enabled;
} modulation_t;

/* Functions */
int modulation_init(modulation_t *mod);
int modulation_calculate_duties(modulation_t *mod, inverter_duty_t *duties);
void modulation_update(modulation_t *mod);
void modulation_set_index(modulation_t *mod, float mi);
void modulation_set_frequency(modulation_t *mod, float freq);

#endif
