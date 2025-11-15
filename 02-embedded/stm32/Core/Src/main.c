/**
 * @file main.c
 * @brief Main application for 5-level cascaded H-bridge inverter
 *
 * Test modes (select with TEST_MODE):
 * 0 = PWM test (50% duty)
 * 1 = Low frequency sine (5 Hz)
 * 2 = Normal operation (50 Hz, 80% MI)
 * 3 = Full power (50 Hz, 100% MI)
 */

#include "main.h"
#include "pwm_control.h"
#include "multilevel_modulation.h"
#include "safety.h"
#include "debug_uart.h"
#include <stdio.h>

/* Test mode selection */
#define TEST_MODE 1  // Change this to select test mode

/* Global handles */
TIM_HandleTypeDef htim1;
TIM_HandleTypeDef htim8;
UART_HandleTypeDef huart2;
ADC_HandleTypeDef hadc1;

/* Application objects */
pwm_controller_t pwm_ctrl;
modulation_t modulator;
safety_monitor_t safety;

/* Statistics */
volatile uint32_t update_count = 0;
volatile uint32_t fault_count = 0;

/* Function prototypes */
void SystemClock_Config(void);
static void MX_GPIO_Init(void);
static void MX_TIM1_Init(void);
static void MX_TIM8_Init(void);
static void MX_USART2_UART_Init(void);
static void MX_ADC1_Init(void);
void apply_test_mode(void);

int main(void)
{
    /* HAL Init */
    HAL_Init();
    SystemClock_Config();

    /* Initialize peripherals */
    MX_GPIO_Init();
    MX_TIM1_Init();
    MX_TIM8_Init();
    MX_USART2_UART_Init();
    MX_ADC1_Init();

    /* Initialize application modules */
    if (pwm_init(&pwm_ctrl, &htim1, &htim8) != 0) {
        debug_print("ERROR: PWM init failed\r\n");
        Error_Handler();
    }

    if (modulation_init(&modulator) != 0) {
        debug_print("ERROR: Modulation init failed\r\n");
        Error_Handler();
    }

    if (safety_init(&safety, &hadc1) != 0) {
        debug_print("ERROR: Safety init failed\r\n");
        Error_Handler();
    }

    if (debug_uart_init(&huart2) != 0) {
        debug_print("ERROR: UART init failed\r\n");
        Error_Handler();
    }

    /* Startup message */
    debug_print("\r\n");
    debug_print("=====================================\r\n");
    debug_print("  5-Level Cascaded H-Bridge Inverter\r\n");
    debug_print("  STM32F401RE Implementation\r\n");
    debug_print("=====================================\r\n");
    debug_printf("Test Mode: %d\r\n", TEST_MODE);
    debug_print("System initialized. Starting PWM...\r\n\r\n");

    /* Apply test mode configuration */
    apply_test_mode();

    /* Start PWM generation */
    if (pwm_start(&pwm_ctrl) != 0) {
        debug_print("ERROR: PWM start failed\r\n");
        Error_Handler();
    }

    debug_print("PWM started. Running...\r\n\r\n");

    uint32_t last_print = 0;

    /* Main loop */
    while (1)
    {
        /* Print status every 1 second */
        if ((HAL_GetTick() - last_print) >= 1000) {
            last_print = HAL_GetTick();

            debug_printf("Updates: %lu, Faults: %lu, MI: %.2f, Freq: %.1f Hz\r\n",
                        update_count, fault_count,
                        modulator.modulation_index, modulator.frequency_hz);

            /* Check for faults */
            if (safety_is_fault(&safety)) {
                debug_printf("FAULT: 0x%02lX\r\n", safety_get_faults(&safety));
            }
        }

        /* Safety monitoring (in real system, would read ADC values) */
        safety_update(&safety, 0.0f, 0.0f);

        /* Small delay */
        HAL_Delay(10);
    }
}

void apply_test_mode(void)
{
    switch (TEST_MODE) {
        case 0:  // PWM Test - 50% duty
            debug_print("Mode 0: PWM Test (50% duty cycle)\r\n");
            modulator.enabled = false;
            pwm_test_50_percent(&pwm_ctrl);
            break;

        case 1:  // Low frequency test - 5 Hz
            debug_print("Mode 1: Low Frequency Test (5 Hz, 50% MI)\r\n");
            modulator.enabled = true;
            modulation_set_index(&modulator, 0.5f);
            modulation_set_frequency(&modulator, 5.0f);
            break;

        case 2:  // Normal operation - 50 Hz, 80% MI
            debug_print("Mode 2: Normal Operation (50 Hz, 80% MI)\r\n");
            modulator.enabled = true;
            modulation_set_index(&modulator, 0.8f);
            modulation_set_frequency(&modulator, 50.0f);
            break;

        case 3:  // Full power - 50 Hz, 100% MI
            debug_print("Mode 3: Full Power (50 Hz, 100% MI)\r\n");
            modulator.enabled = true;
            modulation_set_index(&modulator, 1.0f);
            modulation_set_frequency(&modulator, 50.0f);
            break;

        default:
            debug_print("Invalid test mode, using Mode 1\r\n");
            modulator.enabled = true;
            modulation_set_index(&modulator, 0.5f);
            modulation_set_frequency(&modulator, 5.0f);
            break;
    }
}

/**
 * @brief Timer update interrupt callback
 * Called at PWM frequency (10 kHz)
 */
void HAL_TIM_PeriodElapsedCallback(TIM_HandleTypeDef *htim)
{
    if (htim->Instance == TIM1) {
        inverter_duty_t duties;

        /* Check safety */
        if (!safety_check(&safety)) {
            pwm_emergency_stop(&pwm_ctrl);
            fault_count++;
            return;
        }

        /* Calculate duty cycles */
        modulation_calculate_duties(&modulator, &duties);

        /* Update PWM outputs */
        pwm_set_hbridge1_duty(&pwm_ctrl, duties.hbridge1.ch1, duties.hbridge1.ch2);
        pwm_set_hbridge2_duty(&pwm_ctrl, duties.hbridge2.ch1, duties.hbridge2.ch2);

        /* Advance to next sample */
        modulation_update(&modulator);

        update_count++;
    }
}

void SystemClock_Config(void)
{
    RCC_OscInitTypeDef RCC_OscInitStruct = {0};
    RCC_ClkInitTypeDef RCC_ClkInitStruct = {0};

    __HAL_RCC_PWR_CLK_ENABLE();
    __HAL_PWR_VOLTAGESCALING_CONFIG(PWR_REGULATOR_VOLTAGE_SCALE2);

    RCC_OscInitStruct.OscillatorType = RCC_OSCILLATORTYPE_HSI;
    RCC_OscInitStruct.HSIState = RCC_HSI_ON;
    RCC_OscInitStruct.HSICalibrationValue = RCC_HSICALIBRATION_DEFAULT;
    RCC_OscInitStruct.PLL.PLLState = RCC_PLL_ON;
    RCC_OscInitStruct.PLL.PLLSource = RCC_PLLSOURCE_HSI;
    RCC_OscInitStruct.PLL.PLLM = 8;
    RCC_OscInitStruct.PLL.PLLN = 84;
    RCC_OscInitStruct.PLL.PLLP = RCC_PLLP_DIV2;
    RCC_OscInitStruct.PLL.PLLQ = 4;
    if (HAL_RCC_OscConfig(&RCC_OscInitStruct) != HAL_OK) {
        Error_Handler();
    }

    RCC_ClkInitStruct.ClockType = RCC_CLOCKTYPE_HCLK|RCC_CLOCKTYPE_SYSCLK
                                |RCC_CLOCKTYPE_PCLK1|RCC_CLOCKTYPE_PCLK2;
    RCC_ClkInitStruct.SYSCLKSource = RCC_SYSCLKSOURCE_PLLCLK;
    RCC_ClkInitStruct.AHBCLKDivider = RCC_SYSCLK_DIV1;
    RCC_ClkInitStruct.APB1CLKDivider = RCC_HCLK_DIV2;
    RCC_ClkInitStruct.APB2CLKDivider = RCC_HCLK_DIV1;
    if (HAL_RCC_ClockConfig(&RCC_ClkInitStruct, FLASH_LATENCY_2) != HAL_OK) {
        Error_Handler();
    }
}

static void MX_TIM1_Init(void)
{
    TIM_ClockConfigTypeDef sClockSourceConfig = {0};
    TIM_MasterConfigTypeDef sMasterConfig = {0};
    TIM_OC_InitTypeDef sConfigOC = {0};
    TIM_BreakDeadTimeConfigTypeDef sBreakDeadTimeConfig = {0};

    htim1.Instance = TIM1;
    htim1.Init.Prescaler = 0;
    htim1.Init.CounterMode = TIM_COUNTERMODE_UP;
    htim1.Init.Period = 8399;
    htim1.Init.ClockDivision = TIM_CLOCKDIVISION_DIV1;
    htim1.Init.RepetitionCounter = 0;
    htim1.Init.AutoReloadPreload = TIM_AUTORELOAD_PRELOAD_ENABLE;
    if (HAL_TIM_Base_Init(&htim1) != HAL_OK) {
        Error_Handler();
    }

    sClockSourceConfig.ClockSource = TIM_CLOCKSOURCE_INTERNAL;
    if (HAL_TIM_ConfigClockSource(&htim1, &sClockSourceConfig) != HAL_OK) {
        Error_Handler();
    }

    if (HAL_TIM_PWM_Init(&htim1) != HAL_OK) {
        Error_Handler();
    }

    sMasterConfig.MasterOutputTrigger = TIM_TRGO_UPDATE;
    sMasterConfig.MasterSlaveMode = TIM_MASTERSLAVEMODE_ENABLE;
    if (HAL_TIMEx_MasterConfigSynchronization(&htim1, &sMasterConfig) != HAL_OK) {
        Error_Handler();
    }

    sConfigOC.OCMode = TIM_OCMODE_PWM1;
    sConfigOC.Pulse = 0;
    sConfigOC.OCPolarity = TIM_OCPOLARITY_HIGH;
    sConfigOC.OCNPolarity = TIM_OCNPOLARITY_HIGH;
    sConfigOC.OCFastMode = TIM_OCFAST_DISABLE;
    sConfigOC.OCIdleState = TIM_OCIDLESTATE_RESET;
    sConfigOC.OCNIdleState = TIM_OCNIDLESTATE_RESET;
    if (HAL_TIM_PWM_ConfigChannel(&htim1, &sConfigOC, TIM_CHANNEL_1) != HAL_OK) {
        Error_Handler();
    }
    if (HAL_TIM_PWM_ConfigChannel(&htim1, &sConfigOC, TIM_CHANNEL_2) != HAL_OK) {
        Error_Handler();
    }

    sBreakDeadTimeConfig.OffStateRunMode = TIM_OSSR_DISABLE;
    sBreakDeadTimeConfig.OffStateIDLEMode = TIM_OSSI_DISABLE;
    sBreakDeadTimeConfig.LockLevel = TIM_LOCKLEVEL_OFF;
    sBreakDeadTimeConfig.DeadTime = 84;  // 1μs at 84MHz
    sBreakDeadTimeConfig.BreakState = TIM_BREAK_DISABLE;
    sBreakDeadTimeConfig.BreakPolarity = TIM_BREAKPOLARITY_HIGH;
    sBreakDeadTimeConfig.AutomaticOutput = TIM_AUTOMATICOUTPUT_DISABLE;
    if (HAL_TIMEx_ConfigBreakDeadTime(&htim1, &sBreakDeadTimeConfig) != HAL_OK) {
        Error_Handler();
    }

    HAL_TIM_MspPostInit(&htim1);
    HAL_TIM_Base_Start_IT(&htim1);
}

static void MX_TIM8_Init(void)
{
    TIM_ClockConfigTypeDef sClockSourceConfig = {0};
    TIM_SlaveConfigTypeDef sSlaveConfig = {0};
    TIM_OC_InitTypeDef sConfigOC = {0};
    TIM_BreakDeadTimeConfigTypeDef sBreakDeadTimeConfig = {0};

    htim8.Instance = TIM8;
    htim8.Init.Prescaler = 0;
    htim8.Init.CounterMode = TIM_COUNTERMODE_UP;
    htim8.Init.Period = 8399;
    htim8.Init.ClockDivision = TIM_CLOCKDIVISION_DIV1;
    htim8.Init.RepetitionCounter = 0;
    htim8.Init.AutoReloadPreload = TIM_AUTORELOAD_PRELOAD_ENABLE;
    if (HAL_TIM_Base_Init(&htim8) != HAL_OK) {
        Error_Handler();
    }

    sClockSourceConfig.ClockSource = TIM_CLOCKSOURCE_INTERNAL;
    if (HAL_TIM_ConfigClockSource(&htim8, &sClockSourceConfig) != HAL_OK) {
        Error_Handler();
    }

    if (HAL_TIM_PWM_Init(&htim8) != HAL_OK) {
        Error_Handler();
    }

    sSlaveConfig.SlaveMode = TIM_SLAVEMODE_TRIGGER;
    sSlaveConfig.InputTrigger = TIM_TS_ITR0;  // TIM1 TRGO
    if (HAL_TIM_SlaveConfigSynchro(&htim8, &sSlaveConfig) != HAL_OK) {
        Error_Handler();
    }

    sConfigOC.OCMode = TIM_OCMODE_PWM1;
    sConfigOC.Pulse = 0;
    sConfigOC.OCPolarity = TIM_OCPOLARITY_HIGH;
    sConfigOC.OCNPolarity = TIM_OCNPOLARITY_HIGH;
    sConfigOC.OCFastMode = TIM_OCFAST_DISABLE;
    sConfigOC.OCIdleState = TIM_OCIDLESTATE_RESET;
    sConfigOC.OCNIdleState = TIM_OCNIDLESTATE_RESET;
    if (HAL_TIM_PWM_ConfigChannel(&htim8, &sConfigOC, TIM_CHANNEL_1) != HAL_OK) {
        Error_Handler();
    }
    if (HAL_TIM_PWM_ConfigChannel(&htim8, &sConfigOC, TIM_CHANNEL_2) != HAL_OK) {
        Error_Handler();
    }

    sBreakDeadTimeConfig.OffStateRunMode = TIM_OSSR_DISABLE;
    sBreakDeadTimeConfig.OffStateIDLEMode = TIM_OSSI_DISABLE;
    sBreakDeadTimeConfig.LockLevel = TIM_LOCKLEVEL_OFF;
    sBreakDeadTimeConfig.DeadTime = 84;  // 1μs at 84MHz
    sBreakDeadTimeConfig.BreakState = TIM_BREAK_DISABLE;
    sBreakDeadTimeConfig.BreakPolarity = TIM_BREAKPOLARITY_HIGH;
    sBreakDeadTimeConfig.AutomaticOutput = TIM_AUTOMATICOUTPUT_DISABLE;
    if (HAL_TIMEx_ConfigBreakDeadTime(&htim8, &sBreakDeadTimeConfig) != HAL_OK) {
        Error_Handler();
    }

    HAL_TIM_MspPostInit(&htim8);
}

static void MX_USART2_UART_Init(void)
{
    huart2.Instance = USART2;
    huart2.Init.BaudRate = 115200;
    huart2.Init.WordLength = UART_WORDLENGTH_8B;
    huart2.Init.StopBits = UART_STOPBITS_1;
    huart2.Init.Parity = UART_PARITY_NONE;
    huart2.Init.Mode = UART_MODE_TX_RX;
    huart2.Init.HwFlowCtl = UART_HWCONTROL_NONE;
    huart2.Init.OverSampling = UART_OVERSAMPLING_16;
    if (HAL_UART_Init(&huart2) != HAL_OK) {
        Error_Handler();
    }
}

static void MX_ADC1_Init(void)
{
    ADC_ChannelConfTypeDef sConfig = {0};

    hadc1.Instance = ADC1;
    hadc1.Init.ClockPrescaler = ADC_CLOCK_SYNC_PCLK_DIV2;
    hadc1.Init.Resolution = ADC_RESOLUTION_12B;
    hadc1.Init.ScanConvMode = DISABLE;
    hadc1.Init.ContinuousConvMode = DISABLE;
    hadc1.Init.DiscontinuousConvMode = DISABLE;
    hadc1.Init.ExternalTrigConvEdge = ADC_EXTERNALTRIGCONVEDGE_NONE;
    hadc1.Init.ExternalTrigConv = ADC_SOFTWARE_START;
    hadc1.Init.DataAlign = ADC_DATAALIGN_RIGHT;
    hadc1.Init.NbrOfConversion = 1;
    hadc1.Init.DMAContinuousRequests = DISABLE;
    hadc1.Init.EOCSelection = ADC_EOC_SINGLE_CONV;
    if (HAL_ADC_Init(&hadc1) != HAL_OK) {
        Error_Handler();
    }

    sConfig.Channel = ADC_CHANNEL_0;
    sConfig.Rank = 1;
    sConfig.SamplingTime = ADC_SAMPLETIME_3CYCLES;
    if (HAL_ADC_ConfigChannel(&hadc1, &sConfig) != HAL_OK) {
        Error_Handler();
    }
}

static void MX_GPIO_Init(void)
{
    __HAL_RCC_GPIOA_CLK_ENABLE();
    __HAL_RCC_GPIOB_CLK_ENABLE();
    __HAL_RCC_GPIOC_CLK_ENABLE();
    __HAL_RCC_GPIOH_CLK_ENABLE();
}

void HAL_TIM_MspPostInit(TIM_HandleTypeDef* htim)
{
    GPIO_InitTypeDef GPIO_InitStruct = {0};

    if(htim->Instance==TIM1)
    {
        __HAL_RCC_GPIOA_CLK_ENABLE();
        __HAL_RCC_GPIOB_CLK_ENABLE();

        // PA8  - TIM1_CH1
        // PA9  - TIM1_CH2
        GPIO_InitStruct.Pin = GPIO_PIN_8|GPIO_PIN_9;
        GPIO_InitStruct.Mode = GPIO_MODE_AF_PP;
        GPIO_InitStruct.Pull = GPIO_NOPULL;
        GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_VERY_HIGH;
        GPIO_InitStruct.Alternate = GPIO_AF1_TIM1;
        HAL_GPIO_Init(GPIOA, &GPIO_InitStruct);

        // PB13 - TIM1_CH1N
        // PB14 - TIM1_CH2N
        GPIO_InitStruct.Pin = GPIO_PIN_13|GPIO_PIN_14;
        GPIO_InitStruct.Alternate = GPIO_AF1_TIM1;
        HAL_GPIO_Init(GPIOB, &GPIO_InitStruct);
    }
    else if(htim->Instance==TIM8)
    {
        __HAL_RCC_GPIOC_CLK_ENABLE();

        // PC6  - TIM8_CH1
        // PC7  - TIM8_CH2
        GPIO_InitStruct.Pin = GPIO_PIN_6|GPIO_PIN_7;
        GPIO_InitStruct.Mode = GPIO_MODE_AF_PP;
        GPIO_InitStruct.Pull = GPIO_NOPULL;
        GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_VERY_HIGH;
        GPIO_InitStruct.Alternate = GPIO_AF3_TIM8;
        HAL_GPIO_Init(GPIOC, &GPIO_InitStruct);

        // PC10 - TIM8_CH1N
        // PC11 - TIM8_CH2N
        GPIO_InitStruct.Pin = GPIO_PIN_10|GPIO_PIN_11;
        GPIO_InitStruct.Alternate = GPIO_AF3_TIM8;
        HAL_GPIO_Init(GPIOC, &GPIO_InitStruct);
    }
}

void Error_Handler(void)
{
    __disable_irq();
    while (1) {
    }
}
