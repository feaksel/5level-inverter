/**
 * @file pr_controller.c
 * @brief PR controller implementation
 */

#include "pr_controller.h"
#include <math.h>
#include <string.h>

#define PI 3.14159265359f

/* Private functions */
static void calculate_coefficients(pr_controller_t *pr)
{
    // Discretize PR controller using tustin/bilinear transform
    float Ts = 1.0f / PR_SAMPLE_FREQ;
    float w0 = 2.0f * PI * PR_FUNDAMENTAL_FREQ;
    float wc = pr->wc;

    // Resonant part coefficients (bilinear transform)
    // H(s) = (2*Kr*wc*s) / (s² + 2*wc*s + w0²)
    // After bilinear: H(z) = (b0 + b1*z^-1 + b2*z^-2) / (1 + a1*z^-1 + a2*z^-2)

    float T = Ts;
    float w0_sq = w0 * w0;
    float wc2 = 2.0f * wc;

    // Denominator
    float denom = 4.0f + wc2*T + w0_sq*T*T;
    pr->a1 = (2.0f*w0_sq*T*T - 8.0f) / denom;
    pr->a2 = (4.0f - wc2*T + w0_sq*T*T) / denom;

    // Numerator
    float num_scale = 2.0f * pr->kr * wc * T;
    pr->b0 = num_scale * 2.0f / denom;
    pr->b1 = 0.0f;
    pr->b2 = -num_scale * 2.0f / denom;
}

/* Public functions */
void pr_controller_init(pr_controller_t *pr, float kp, float kr, float wc)
{
    if (pr == NULL) return;

    memset(pr, 0, sizeof(pr_controller_t));

    pr->kp = kp;
    pr->kr = kr;
    pr->wc = wc;

    // Calculate discrete coefficients
    calculate_coefficients(pr);

    // Default limits (modulation index range)
    pr->output_min = 0.0f;
    pr->output_max = 1.0f;

    pr->initialized = true;
}

void pr_controller_reset(pr_controller_t *pr)
{
    if (pr == NULL) return;

    pr->x1 = 0.0f;
    pr->x2 = 0.0f;
    pr->y1 = 0.0f;
    pr->y2 = 0.0f;
    pr->sample_count = 0;
}

float pr_controller_update(pr_controller_t *pr, float reference, float measured)
{
    if (pr == NULL || !pr->initialized) return 0.0f;

    // Calculate error
    float error = reference - measured;

    // Proportional term
    float p_term = pr->kp * error;

    // Resonant term (using direct form II transposed)
    // y[n] = b0*x[n] + b1*x[n-1] + b2*x[n-2] - a1*y[n-1] - a2*y[n-2]
    float r_term = pr->b0 * error + pr->b1 * pr->x1 + pr->b2 * pr->x2
                   - pr->a1 * pr->y1 - pr->a2 * pr->y2;

    // Update state
    pr->x2 = pr->x1;
    pr->x1 = error;
    pr->y2 = pr->y1;
    pr->y1 = r_term;

    // Total output
    float output = p_term + r_term;

    // Apply limits
    if (output > pr->output_max) output = pr->output_max;
    if (output < pr->output_min) output = pr->output_min;

    pr->sample_count++;

    return output;
}

void pr_controller_set_limits(pr_controller_t *pr, float min, float max)
{
    if (pr == NULL) return;

    pr->output_min = min;
    pr->output_max = max;
}

void pr_controller_set_gains(pr_controller_t *pr, float kp, float kr)
{
    if (pr == NULL) return;

    pr->kp = kp;
    pr->kr = kr;

    // Recalculate coefficients
    calculate_coefficients(pr);
}
