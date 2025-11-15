/**
 * @file pwm_control.c
 * @brief PWM control implementation for 5-level cascaded H-bridge inverter
 *
 * @author 5-Level Inverter Project
 * @date 2025-11-15
 * @version 1.0
 */

#include "pwm_control.h"
#include <string.h>

/* ========================================================================= */
/*                             PRIVATE FUNCTIONS                              */
/* ========================================================================= */

/**
 * @brief Validate duty cycle value
 * @param duty Duty cycle value to validate
 * @return true if valid, false otherwise
 */
static bool is_valid_duty(uint16_t duty)
{
    return (duty <= PWM_MAX_DUTY);
}

/**
 * @brief Disable all PWM outputs
 * @param ctrl Pointer to PWM controller structure
 */
static void disable_all_outputs(pwm_controller_t *ctrl)
{
    if (ctrl == NULL) return;

    // Stop TIM1 complementary channels
    HAL_TIMEx_PWMN_Stop(ctrl->hbridge1.htim, TIM_CHANNEL_1);
    HAL_TIM_PWM_Stop(ctrl->hbridge1.htim, TIM_CHANNEL_1);
    HAL_TIMEx_PWMN_Stop(ctrl->hbridge1.htim, TIM_CHANNEL_2);
    HAL_TIM_PWM_Stop(ctrl->hbridge1.htim, TIM_CHANNEL_2);

    // Stop TIM8 complementary channels
    HAL_TIMEx_PWMN_Stop(ctrl->hbridge2.htim, TIM_CHANNEL_1);
    HAL_TIM_PWM_Stop(ctrl->hbridge2.htim, TIM_CHANNEL_1);
    HAL_TIMEx_PWMN_Stop(ctrl->hbridge2.htim, TIM_CHANNEL_2);
    HAL_TIM_PWM_Stop(ctrl->hbridge2.htim, TIM_CHANNEL_2);
}

/* ========================================================================= */
/*                             PUBLIC FUNCTIONS                               */
/* ========================================================================= */

int pwm_init(pwm_controller_t *ctrl, TIM_HandleTypeDef *htim1, TIM_HandleTypeDef *htim8)
{
    // Input validation
    if (ctrl == NULL || htim1 == NULL || htim8 == NULL) {
        return -1;
    }

    // Clear controller structure
    memset(ctrl, 0, sizeof(pwm_controller_t));

    // Initialize H-bridge 1 (TIM1)
    ctrl->hbridge1.htim = htim1;
    ctrl->hbridge1.channel_high1 = TIM_CHANNEL_1;
    ctrl->hbridge1.channel_high2 = TIM_CHANNEL_2;
    ctrl->hbridge1.duty_cycle1 = 0;
    ctrl->hbridge1.duty_cycle2 = 0;

    // Initialize H-bridge 2 (TIM8)
    ctrl->hbridge2.htim = htim8;
    ctrl->hbridge2.channel_high1 = TIM_CHANNEL_1;
    ctrl->hbridge2.channel_high2 = TIM_CHANNEL_2;
    ctrl->hbridge2.duty_cycle1 = 0;
    ctrl->hbridge2.duty_cycle2 = 0;

    // Set initial state
    ctrl->state = PWM_STATE_IDLE;
    ctrl->fault_count = 0;
    ctrl->emergency_stop = false;

    // Configure timer synchronization
    // TIM1 is master (generates TRGO on update event)
    // TIM8 is slave (triggered by TIM1 TRGO)
    // This is already configured in the .ioc file

    return 0;
}

int pwm_start(pwm_controller_t *ctrl)
{
    // Input validation
    if (ctrl == NULL) {
        return -1;
    }

    // Check for emergency stop
    if (ctrl->emergency_stop) {
        return -2;
    }

    // Check for fault state
    if (ctrl->state == PWM_STATE_FAULT) {
        return -3;
    }

    // Set initial duty cycles to 0
    ctrl->hbridge1.duty_cycle1 = 0;
    ctrl->hbridge1.duty_cycle2 = 0;
    ctrl->hbridge2.duty_cycle1 = 0;
    ctrl->hbridge2.duty_cycle2 = 0;

    // Configure duty cycles
    __HAL_TIM_SET_COMPARE(ctrl->hbridge1.htim, TIM_CHANNEL_1, 0);
    __HAL_TIM_SET_COMPARE(ctrl->hbridge1.htim, TIM_CHANNEL_2, 0);
    __HAL_TIM_SET_COMPARE(ctrl->hbridge2.htim, TIM_CHANNEL_1, 0);
    __HAL_TIM_SET_COMPARE(ctrl->hbridge2.htim, TIM_CHANNEL_2, 0);

    // Start TIM1 (master) - both high-side and low-side (complementary)
    if (HAL_TIM_PWM_Start(ctrl->hbridge1.htim, TIM_CHANNEL_1) != HAL_OK) {
        return -4;
    }
    if (HAL_TIMEx_PWMN_Start(ctrl->hbridge1.htim, TIM_CHANNEL_1) != HAL_OK) {
        return -5;
    }
    if (HAL_TIM_PWM_Start(ctrl->hbridge1.htim, TIM_CHANNEL_2) != HAL_OK) {
        return -6;
    }
    if (HAL_TIMEx_PWMN_Start(ctrl->hbridge1.htim, TIM_CHANNEL_2) != HAL_OK) {
        return -7;
    }

    // Start TIM8 (slave) - both high-side and low-side (complementary)
    if (HAL_TIM_PWM_Start(ctrl->hbridge2.htim, TIM_CHANNEL_1) != HAL_OK) {
        return -8;
    }
    if (HAL_TIMEx_PWMN_Start(ctrl->hbridge2.htim, TIM_CHANNEL_1) != HAL_OK) {
        return -9;
    }
    if (HAL_TIM_PWM_Start(ctrl->hbridge2.htim, TIM_CHANNEL_2) != HAL_OK) {
        return -10;
    }
    if (HAL_TIMEx_PWMN_Start(ctrl->hbridge2.htim, TIM_CHANNEL_2) != HAL_OK) {
        return -11;
    }

    // Update state
    ctrl->state = PWM_STATE_RUNNING;

    return 0;
}

int pwm_stop(pwm_controller_t *ctrl)
{
    // Input validation
    if (ctrl == NULL) {
        return -1;
    }

    // Disable all outputs
    disable_all_outputs(ctrl);

    // Reset duty cycles
    ctrl->hbridge1.duty_cycle1 = 0;
    ctrl->hbridge1.duty_cycle2 = 0;
    ctrl->hbridge2.duty_cycle1 = 0;
    ctrl->hbridge2.duty_cycle2 = 0;

    // Update state
    ctrl->state = PWM_STATE_IDLE;

    return 0;
}

void pwm_emergency_stop(pwm_controller_t *ctrl)
{
    if (ctrl == NULL) return;

    // Set emergency stop flag
    ctrl->emergency_stop = true;

    // Immediately disable all outputs
    disable_all_outputs(ctrl);

    // Set fault state
    ctrl->state = PWM_STATE_FAULT;
    ctrl->fault_count++;
}

int pwm_set_hbridge1_duty(pwm_controller_t *ctrl, uint16_t ch1_duty, uint16_t ch2_duty)
{
    // Input validation
    if (ctrl == NULL) {
        return -1;
    }

    // Validate duty cycles
    if (!is_valid_duty(ch1_duty) || !is_valid_duty(ch2_duty)) {
        return -2;
    }

    // Check state
    if (ctrl->state != PWM_STATE_RUNNING) {
        return -3;
    }

    // Update duty cycles
    ctrl->hbridge1.duty_cycle1 = ch1_duty;
    ctrl->hbridge1.duty_cycle2 = ch2_duty;

    // Apply to timer
    __HAL_TIM_SET_COMPARE(ctrl->hbridge1.htim, TIM_CHANNEL_1, ch1_duty);
    __HAL_TIM_SET_COMPARE(ctrl->hbridge1.htim, TIM_CHANNEL_2, ch2_duty);

    return 0;
}

int pwm_set_hbridge2_duty(pwm_controller_t *ctrl, uint16_t ch1_duty, uint16_t ch2_duty)
{
    // Input validation
    if (ctrl == NULL) {
        return -1;
    }

    // Validate duty cycles
    if (!is_valid_duty(ch1_duty) || !is_valid_duty(ch2_duty)) {
        return -2;
    }

    // Check state
    if (ctrl->state != PWM_STATE_RUNNING) {
        return -3;
    }

    // Update duty cycles
    ctrl->hbridge2.duty_cycle1 = ch1_duty;
    ctrl->hbridge2.duty_cycle2 = ch2_duty;

    // Apply to timer
    __HAL_TIM_SET_COMPARE(ctrl->hbridge2.htim, TIM_CHANNEL_1, ch1_duty);
    __HAL_TIM_SET_COMPARE(ctrl->hbridge2.htim, TIM_CHANNEL_2, ch2_duty);

    return 0;
}

pwm_state_t pwm_get_state(const pwm_controller_t *ctrl)
{
    if (ctrl == NULL) {
        return PWM_STATE_FAULT;
    }

    return ctrl->state;
}

int pwm_test_50_percent(pwm_controller_t *ctrl)
{
    // Input validation
    if (ctrl == NULL) {
        return -1;
    }

    // Calculate 50% duty cycle
    uint16_t duty_50 = PWM_PERIOD / 2;

    // Set 50% on both H-bridges
    if (pwm_set_hbridge1_duty(ctrl, duty_50, duty_50) != 0) {
        return -2;
    }

    if (pwm_set_hbridge2_duty(ctrl, duty_50, duty_50) != 0) {
        return -3;
    }

    return 0;
}
