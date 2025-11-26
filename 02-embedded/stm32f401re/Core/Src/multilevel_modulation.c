/**
 * @file multilevel_modulation.c
 * @brief Level-shifted carrier PWM implementation
 *
 * LEVEL-SHIFTED CARRIERS:
 * Carrier 1: -1.0 to 0.0 (lower level)
 * Carrier 2:  0.0 to +1.0 (upper level)
 * Reference: -1.0 to +1.0 (sine wave)
 *
 * This creates natural 5-level output:
 * +2V: ref > 0, both carriers triggered
 * +1V: ref between 0 and carrier2
 * 0V:  ref crosses zero
 * -1V: ref between carrier1 and 0
 * -2V: ref < carrier1
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
        // Output zero when disabled (50% duty = zero output for bipolar)
        duties->hbridge1.ch1 = PWM_PERIOD / 2;
        duties->hbridge1.ch2 = PWM_PERIOD / 2;
        duties->hbridge2.ch1 = PWM_PERIOD / 2;
        duties->hbridge2.ch2 = PWM_PERIOD / 2;
        return 0;
    }

    // Get modulation reference (sine wave) from -1 to +1
    float ref = sine_table[mod->sample_index] * mod->modulation_index;

    /*
     * LEVEL-SHIFTED CARRIER COMPARISON:
     *
     * Carrier 1 (H-bridge 1): Ranges from -1 to 0
     * Carrier 2 (H-bridge 2): Ranges from 0 to +1
     *
     * For each H-bridge:
     * - If ref > carrier_min → positive output
     * - If ref < carrier_min → zero/negative output
     *
     * H-Bridge 1 comparison:
     * ref > -1 → activates when ref is in range [-1, 0]
     * Normalized: (ref + 1) / 2 gives 0 to 0.5 when ref is -1 to 0
     *
     * H-Bridge 2 comparison:
     * ref > 0 → activates when ref is in range [0, +1]
     * Normalized: ref / 2 + 0.5 gives 0.5 to 1.0 when ref is 0 to +1
     */

    // H-bridge 1: Compare ref with carrier from -1 to 0
    // When ref = -1, duty = 0%
    // When ref = 0, duty = 100%
    float duty1_normalized = (ref + 1.0f) * 0.5f;  // Maps [-1,+1] to [0,1]
    if (duty1_normalized < 0.0f) duty1_normalized = 0.0f;
    if (duty1_normalized > 1.0f) duty1_normalized = 1.0f;

    // H-bridge 2: Compare ref with carrier from 0 to +1
    // When ref = 0, duty = 0%
    // When ref = +1, duty = 100%
    float duty2_normalized = ref;  // Already in [-1,+1], but we need [0,1] for ref > 0
    if (duty2_normalized < 0.0f) duty2_normalized = 0.0f;
    if (duty2_normalized > 1.0f) duty2_normalized = 1.0f;

    // Convert normalized duty (0.0-1.0) to timer counts
    uint16_t duty1 = (uint16_t)(duty1_normalized * PWM_PERIOD);
    uint16_t duty2 = (uint16_t)(duty2_normalized * PWM_PERIOD);

    // For bipolar PWM: complementary legs
    // H-bridge 1 (TIM1)
    duties->hbridge1.ch1 = duty1;
    duties->hbridge1.ch2 = PWM_PERIOD - duty1;

    // H-bridge 2 (TIM8)
    duties->hbridge2.ch1 = duty2;
    duties->hbridge2.ch2 = PWM_PERIOD - duty2;

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
