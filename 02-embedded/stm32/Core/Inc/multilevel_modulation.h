/**
 * @file multilevel_modulation.h
 * @brief Phase-shifted PWM modulation for 5-level cascaded H-bridge
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
#define PWM_FREQUENCY_HZ        10000
#define OUTPUT_FREQUENCY_HZ     50
#define PWM_PERIOD              8399
#define SINE_TABLE_SIZE         200      // Full cycle samples

/* Structures */
typedef struct {
    uint16_t ch1;  // Channel 1 duty
    uint16_t ch2;  // Channel 2 duty
} hbridge_duty_t;

typedef struct {
    hbridge_duty_t hbridge1;  // TIM1 - 0° phase
    hbridge_duty_t hbridge2;  // TIM8 - 180° phase shift
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
