/**
 * @file multilevel_modulation.c
 * @brief Phase-shifted carrier PWM implementation
 */

#include "multilevel_modulation.h"
#include <math.h>
#include <string.h>

// Sine lookup table (pre-calculated)
static float sine_table[SINE_TABLE_SIZE];

int modulation_init(modulation_t *mod)
{
    if (mod == NULL) return -1;

    // Clear structure
    memset(mod, 0, sizeof(modulation_t));

    // Default values
    mod->modulation_index = 0.8f;
    mod->frequency_hz = OUTPUT_FREQUENCY_HZ;
    mod->sample_index = 0;
    mod->enabled = false;

    // Generate sine lookup table
    for (int i = 0; i < SINE_TABLE_SIZE; i++) {
        sine_table[i] = sinf(2.0f * M_PI * i / SINE_TABLE_SIZE);
    }

    return 0;
}

int modulation_calculate_duties(modulation_t *mod, inverter_duty_t *duties)
{
    if (mod == NULL || duties == NULL) return -1;
    if (!mod->enabled) {
        // Output zero when disabled
        duties->hbridge1.ch1 = PWM_PERIOD / 2;
        duties->hbridge1.ch2 = PWM_PERIOD / 2;
        duties->hbridge2.ch1 = PWM_PERIOD / 2;
        duties->hbridge2.ch2 = PWM_PERIOD / 2;
        return 0;
    }

    // Get modulation reference (sine wave)
    float ref = sine_table[mod->sample_index] * mod->modulation_index;

    // Phase-shifted carrier comparison
    // H-bridge 1: carrier at 0°
    // H-bridge 2: carrier at 180° (inverted comparison achieves phase shift)

    // For bipolar PWM: duty = (1 + ref) / 2 * period
    uint16_t duty1 = (uint16_t)((1.0f + ref) * PWM_PERIOD / 2.0f);
    uint16_t duty2 = (uint16_t)((1.0f - ref) * PWM_PERIOD / 2.0f);  // 180° shift

    // H-bridge 1 (TIM1)
    duties->hbridge1.ch1 = duty1;
    duties->hbridge1.ch2 = PWM_PERIOD - duty1;  // Complementary for bipolar

    // H-bridge 2 (TIM8) - phase shifted
    duties->hbridge2.ch1 = duty2;
    duties->hbridge2.ch2 = PWM_PERIOD - duty2;  // Complementary for bipolar

    return 0;
}

void modulation_update(modulation_t *mod)
{
    if (mod == NULL) return;

    // Calculate step size based on output frequency
    uint32_t step = (uint32_t)((float)SINE_TABLE_SIZE * mod->frequency_hz / PWM_FREQUENCY_HZ);

    mod->sample_index += step;
    if (mod->sample_index >= SINE_TABLE_SIZE) {
        mod->sample_index -= SINE_TABLE_SIZE;
    }
}

void modulation_set_index(modulation_t *mod, float mi)
{
    if (mod == NULL) return;

    // Clamp to valid range
    if (mi < 0.0f) mi = 0.0f;
    if (mi > 1.0f) mi = 1.0f;

    mod->modulation_index = mi;
}

void modulation_set_frequency(modulation_t *mod, float freq)
{
    if (mod == NULL) return;
    if (freq < 1.0f || freq > 400.0f) return;

    mod->frequency_hz = freq;
}
