/**
 * @file pr_controller.h
 * @brief Proportional-Resonant (PR) current controller
 *
 * PR Controller for sinusoidal current tracking:
 * - Zero steady-state error at fundamental frequency
 * - Better than PI for AC signals
 * - Tuned for 50Hz fundamental
 *
 * Transfer function:
 * PR(s) = Kp + (2*Kr*ωc*s) / (s² + 2*ωc*s + ω₀²)
 *
 * Where:
 * - Kp: Proportional gain
 * - Kr: Resonant gain
 * - ω₀: Resonant frequency (2π*50)
 * - ωc: Cutoff frequency (bandwidth)
 *
 * @author 5-Level Inverter Project
 * @date 2025-11-15
 */

#ifndef PR_CONTROLLER_H
#define PR_CONTROLLER_H

#include <stdint.h>
#include <stdbool.h>

/* Configuration */
#define PR_FUNDAMENTAL_FREQ     50.0f    // 50 Hz
#define PR_SAMPLE_FREQ          5000.0f  // 5 kHz (PWM frequency)

/* Default gains (tune these for your system) */
#define PR_KP_DEFAULT           1.0f     // Proportional gain
#define PR_KR_DEFAULT           50.0f    // Resonant gain
#define PR_WC_DEFAULT           10.0f    // Cutoff frequency (rad/s)

/* PR controller structure */
typedef struct {
    // Gains
    float kp;               // Proportional gain
    float kr;               // Resonant gain
    float wc;               // Cutoff frequency

    // Discrete coefficients (calculated from continuous)
    float b0, b1, b2;       // Numerator coefficients
    float a1, a2;           // Denominator coefficients

    // State variables
    float x1, x2;           // State memory
    float y1, y2;           // Output memory

    // Limits
    float output_min;
    float output_max;

    // Status
    bool initialized;
    uint32_t sample_count;
} pr_controller_t;

/* Functions */
void pr_controller_init(pr_controller_t *pr, float kp, float kr, float wc);
void pr_controller_reset(pr_controller_t *pr);
float pr_controller_update(pr_controller_t *pr, float reference, float measured);
void pr_controller_set_limits(pr_controller_t *pr, float min, float max);
void pr_controller_set_gains(pr_controller_t *pr, float kp, float kr);

#endif // PR_CONTROLLER_H
