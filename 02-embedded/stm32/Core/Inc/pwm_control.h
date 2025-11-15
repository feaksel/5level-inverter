/**
 * @file pwm_control.h
 * @brief PWM control for 5-level cascaded H-bridge inverter
 *
 * Controls 2 H-bridges (8 switches) using TIM1 and TIM8 for
 * complementary PWM generation with dead-time insertion.
 *
 * Pin mapping:
 *   H-Bridge 1 (TIM1):
 *     S1 (G1): PA8  - TIM1_CH1
 *     S2 (G2): PB13 - TIM1_CH1N
 *     S3 (G3): PA9  - TIM1_CH2
 *     S4 (G4): PB14 - TIM1_CH2N
 *
 *   H-Bridge 2 (TIM8):
 *     S5 (G5): PC6  - TIM8_CH1
 *     S6 (G6): PC10 - TIM8_CH1N
 *     S7 (G7): PC7  - TIM8_CH2
 *     S8 (G8): PC11 - TIM8_CH2N
 *
 * @author 5-Level Inverter Project
 * @date 2025-11-15
 * @version 1.0
 */

#ifndef PWM_CONTROL_H
#define PWM_CONTROL_H

#include "stm32f4xx_hal.h"
#include <stdint.h>
#include <stdbool.h>

/* ========================================================================= */
/*                             CONSTANTS                                      */
/* ========================================================================= */

#define PWM_FREQUENCY_HZ        10000    // 10 kHz switching frequency
#define PWM_DEAD_TIME_NS        1000     // 1 μs dead-time
#define SYSTEM_CLOCK_HZ         84000000 // 84 MHz system clock

// PWM period calculation: (84MHz / 10kHz) - 1 = 8399
#define PWM_PERIOD              8399
#define PWM_MAX_DUTY            8399

/* ========================================================================= */
/*                             ENUMERATIONS                                   */
/* ========================================================================= */

/**
 * @brief PWM operational states
 */
typedef enum {
    PWM_STATE_IDLE = 0,          ///< PWM stopped, outputs disabled
    PWM_STATE_RUNNING,           ///< PWM active, generating outputs
    PWM_STATE_FAULT              ///< Fault detected, outputs disabled
} pwm_state_t;

/**
 * @brief Voltage levels for 5-level inverter
 */
typedef enum {
    LEVEL_NEG_2V = 0,           ///< -2Vdc
    LEVEL_NEG_1V,               ///< -Vdc
    LEVEL_ZERO,                 ///< 0V
    LEVEL_POS_1V,               ///< +Vdc
    LEVEL_POS_2V                ///< +2Vdc
} voltage_level_t;

/* ========================================================================= */
/*                             STRUCTURES                                     */
/* ========================================================================= */

/**
 * @brief H-Bridge control structure
 */
typedef struct {
    TIM_HandleTypeDef *htim;    ///< Timer handle
    uint32_t channel_high1;     ///< Channel for high-side switch 1
    uint32_t channel_high2;     ///< Channel for high-side switch 2
    uint16_t duty_cycle1;       ///< Duty cycle for channel 1 (0-8399)
    uint16_t duty_cycle2;       ///< Duty cycle for channel 2 (0-8399)
} hbridge_t;

/**
 * @brief PWM controller structure
 */
typedef struct {
    hbridge_t hbridge1;         ///< H-bridge 1 (TIM1)
    hbridge_t hbridge2;         ///< H-bridge 2 (TIM8)
    pwm_state_t state;          ///< Current state
    uint32_t fault_count;       ///< Fault counter
    bool emergency_stop;        ///< Emergency stop flag
} pwm_controller_t;

/* ========================================================================= */
/*                             PUBLIC FUNCTIONS                               */
/* ========================================================================= */

/**
 * @brief Initialize PWM controller
 *
 * Configures both TIM1 and TIM8 for complementary PWM output with
 * dead-time insertion and synchronization.
 *
 * @param ctrl Pointer to PWM controller structure
 * @param htim1 Pointer to TIM1 handle
 * @param htim8 Pointer to TIM8 handle
 * @return 0 on success, negative error code on failure
 */
int pwm_init(pwm_controller_t *ctrl, TIM_HandleTypeDef *htim1, TIM_HandleTypeDef *htim8);

/**
 * @brief Start PWM generation
 *
 * Enables PWM outputs on both H-bridges with initial 0% duty cycle.
 *
 * @param ctrl Pointer to PWM controller structure
 * @return 0 on success, negative error code on failure
 */
int pwm_start(pwm_controller_t *ctrl);

/**
 * @brief Stop PWM generation
 *
 * Disables all PWM outputs safely.
 *
 * @param ctrl Pointer to PWM controller structure
 * @return 0 on success, negative error code on failure
 */
int pwm_stop(pwm_controller_t *ctrl);

/**
 * @brief Emergency stop - immediate shutdown
 *
 * Immediately disables all PWM outputs for safety.
 *
 * @param ctrl Pointer to PWM controller structure
 */
void pwm_emergency_stop(pwm_controller_t *ctrl);

/**
 * @brief Set duty cycle for H-bridge 1
 *
 * @param ctrl Pointer to PWM controller structure
 * @param ch1_duty Duty cycle for channel 1 (0-8399)
 * @param ch2_duty Duty cycle for channel 2 (0-8399)
 * @return 0 on success, negative error code on failure
 */
int pwm_set_hbridge1_duty(pwm_controller_t *ctrl, uint16_t ch1_duty, uint16_t ch2_duty);

/**
 * @brief Set duty cycle for H-bridge 2
 *
 * @param ctrl Pointer to PWM controller structure
 * @param ch1_duty Duty cycle for channel 1 (0-8399)
 * @param ch2_duty Duty cycle for channel 2 (0-8399)
 * @return 0 on success, negative error code on failure
 */
int pwm_set_hbridge2_duty(pwm_controller_t *ctrl, uint16_t ch1_duty, uint16_t ch2_duty);

/**
 * @brief Get current PWM state
 *
 * @param ctrl Pointer to PWM controller structure
 * @return Current PWM state
 */
pwm_state_t pwm_get_state(const pwm_controller_t *ctrl);

/**
 * @brief Test function - 50% duty cycle on all channels
 *
 * For initial hardware validation with oscilloscope.
 *
 * @param ctrl Pointer to PWM controller structure
 * @return 0 on success, negative error code on failure
 */
int pwm_test_50_percent(pwm_controller_t *ctrl);

#endif // PWM_CONTROL_H
