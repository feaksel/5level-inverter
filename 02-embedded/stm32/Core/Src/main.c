/**
 * @file main.c
 * @brief Main application for 5-level cascaded H-bridge inverter
 *
 * Test modes (select with TEST_MODE):
 * 0 = PWM test (50% duty)
 * 1 = Low frequency sine (5 Hz)
 * 2 = Normal operation (50 Hz, 80% MI)
 * 3 = Full power (50 Hz, 100% MI)
 * 4 = Closed-loop current control (PR controller test)
 */

#include "main.h"
#include "pwm_control.h"
#include "multilevel_modulation.h"
#include "safety.h"
#include "debug_uart.h"
#include "adc_sensing.h"
#include "data_logger.h"
#include "soft_start.h"
#include "pr_controller.h"
#include <stdio.h>

/* Test mode selection */
#define TEST_MODE 1  // Change this to select test mode

/* Global handles */
TIM_HandleTypeDef htim1;
TIM_HandleTypeDef htim8;
UART_HandleTypeDef huart2;
ADC_HandleTypeDef hadc1;
DMA_HandleTypeDef hdma_adc1;

/* Application objects */
pwm_controller_t pwm_ctrl;
modulation_t modulator;
safety_monitor_t safety;
adc_sensor_t adc_sensor;
data_logger_t logger;
soft_start_t soft_start;
pr_controller_t pr_ctrl;

/* Statistics */
volatile uint32_t update_count = 0;
volatile uint32_t fault_count = 0;

/* Function prototypes */
void SystemClock_Config(void);
static void MX_GPIO_Init(void);
static void MX_DMA_Init(void);
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

    /* Initialize peripherals (DMA must be before ADC) */
    MX_GPIO_Init();
    MX_DMA_Init();
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

    /* Initialize new modules */
    if (adc_sensor_init(&adc_sensor, &hadc1, &hdma_adc1) != 0) {
        debug_print("ERROR: ADC sensor init failed\r\n");
        Error_Handler();
    }

    if (logger_init(&logger, &huart2) != 0) {
        debug_print("ERROR: Logger init failed\r\n");
        Error_Handler();
    }

    soft_start_init(&soft_start, SOFT_START_RAMP_TIME_MS);

    pr_controller_init(&pr_ctrl, PR_KP_DEFAULT, PR_KR_DEFAULT, PR_WC_DEFAULT);
    pr_controller_set_limits(&pr_ctrl, 0.0f, 1.0f);  // MI limits

    /* Startup message */
    debug_print("\r\n");
    debug_print("=====================================\r\n");
    debug_print("  5-Level Cascaded H-Bridge Inverter\r\n");
    debug_print("  STM32F401RE Implementation\r\n");
    debug_print("  With ADC, Logging, Soft-Start, PR\r\n");
    debug_print("=====================================\r\n");
    debug_printf("Test Mode: %d\r\n", TEST_MODE);
    debug_print("System initialized. Starting PWM...\r\n\r\n");

    /* Apply test mode configuration */
    apply_test_mode();

    /* Start ADC with DMA */
    if (adc_sensor_start(&adc_sensor) != 0) {
        debug_print("ERROR: ADC start failed\r\n");
        Error_Handler();
    }

    /* Start PWM generation */
    if (pwm_start(&pwm_ctrl) != 0) {
        debug_print("ERROR: PWM start failed\r\n");
        Error_Handler();
    }

    /* Start soft-start sequence if modulation is enabled */
    if (modulator.enabled && TEST_MODE != 0) {
        soft_start_begin(&soft_start, modulator.modulation_index);
        debug_printf("Soft-start: Ramping to MI=%.2f over %lu ms\r\n\r\n",
                    modulator.modulation_index, SOFT_START_RAMP_TIME_MS);
    }

    /* Enable data logging (default: STATUS mode) */
    logger_set_mode(&logger, LOG_MODE_STATUS);
    logger_enable(&logger, true);

    debug_print("All systems started. Running...\r\n\r\n");

    uint32_t last_print = 0;
    uint32_t last_log = 0;

    /* Main loop */
    while (1)
    {
        /* Update soft-start (must be called regularly) */
        soft_start_update(&soft_start);

        /* Update ADC sensor data */
        adc_sensor_update(&adc_sensor);
        const sensor_data_t *sensor = adc_sensor_get_data(&adc_sensor);

        /* Safety monitoring with real sensor values */
        safety_update(&safety, sensor->output_current, sensor->dc_bus1_voltage);

        /* Log status every 1 second */
        if ((HAL_GetTick() - last_log) >= 1000) {
            last_log = HAL_GetTick();
            logger_log_status(&logger, sensor, &modulator);
        }

        /* Print debug status every 1 second */
        if ((HAL_GetTick() - last_print) >= 1000) {
            last_print = HAL_GetTick();

            debug_printf("Updates: %lu, Faults: %lu, MI: %.2f, Freq: %.1f Hz\r\n",
                        update_count, fault_count,
                        modulator.modulation_index, modulator.frequency_hz);

            debug_printf("I=%.2fA, V=%.1fV, DC1=%.1fV, DC2=%.1fV\r\n",
                        sensor->output_current,
                        sensor->output_voltage,
                        sensor->dc_bus1_voltage,
                        sensor->dc_bus2_voltage);

            /* Check for faults */
            if (safety_is_fault(&safety)) {
                debug_printf("FAULT: 0x%02lX\r\n", safety_get_faults(&safety));
            }

            /* Soft-start status */
            if (!soft_start_is_complete(&soft_start)) {
                debug_printf("Soft-start: %.1f%%\r\n",
                            (soft_start_get_mi(&soft_start) / modulator.modulation_index) * 100.0f);
            }
        }

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

        case 4:  // Closed-loop current control with PR controller
            debug_print("Mode 4: Closed-Loop Current Control (PR Controller)\r\n");
            debug_print("        Target: 5A sine @ 50Hz\r\n");
            modulator.enabled = true;
            modulation_set_frequency(&modulator, 50.0f);
            modulation_set_index(&modulator, 0.5f);  // Initial MI
            // PR controller will adjust MI to track current reference
            pr_controller_reset(&pr_ctrl);
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
 * Called at PWM frequency (5 kHz)
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

        /* Apply soft-start modulation index */
        if (!soft_start_is_complete(&soft_start)) {
            float soft_mi = soft_start_get_mi(&soft_start);
            modulation_set_index(&modulator, soft_mi);
        }

        /* Mode 4: Closed-loop current control with PR controller */
        if (TEST_MODE == 4 && soft_start_is_complete(&soft_start)) {
            // Generate sine reference current (5A amplitude @ 50Hz)
            float time = (float)update_count / PR_SAMPLE_FREQ;
            float current_ref = 5.0f * sinf(2.0f * 3.14159265359f * 50.0f * time);

            // Get measured current from ADC
            const sensor_data_t *sensor = adc_sensor_get_data(&adc_sensor);
            float current_meas = sensor->output_current;

            // Update PR controller to get new MI
            float new_mi = pr_controller_update(&pr_ctrl, current_ref, current_meas);
            modulation_set_index(&modulator, new_mi);
        }

        /* Calculate duty cycles */
        modulation_calculate_duties(&modulator, &duties);

        /* Update PWM outputs */
        pwm_set_hbridge1_duty(&pwm_ctrl, duties.hbridge1.ch1, duties.hbridge1.ch2);
        pwm_set_hbridge2_duty(&pwm_ctrl, duties.hbridge2.ch1, duties.hbridge2.ch2);

        /* Log waveform data if in waveform mode */
        if (logger.mode == LOG_MODE_WAVEFORM) {
            const sensor_data_t *sensor = adc_sensor_get_data(&adc_sensor);
            logger_log_waveform(&logger,
                               sensor->output_current,
                               sensor->output_voltage,
                               duties.hbridge1.ch1,
                               duties.hbridge1.ch2);
        }

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
    htim1.Init.Period = 16799;  // 5kHz switching
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
    htim8.Init.Period = 16799;  // 5kHz switching
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

static void MX_DMA_Init(void)
{
    /* DMA controller clock enable */
    __HAL_RCC_DMA2_CLK_ENABLE();

    /* DMA interrupt init */
    /* DMA2_Stream0_IRQn interrupt configuration */
    HAL_NVIC_SetPriority(DMA2_Stream0_IRQn, 0, 0);
    HAL_NVIC_EnableIRQ(DMA2_Stream0_IRQn);
}

static void MX_ADC1_Init(void)
{
    ADC_ChannelConfTypeDef sConfig = {0};

    /* ADC1 DMA Init */
    hdma_adc1.Instance = DMA2_Stream0;
    hdma_adc1.Init.Channel = DMA_CHANNEL_0;
    hdma_adc1.Init.Direction = DMA_PERIPH_TO_MEMORY;
    hdma_adc1.Init.PeriphInc = DMA_PINC_DISABLE;
    hdma_adc1.Init.MemInc = DMA_MINC_ENABLE;
    hdma_adc1.Init.PeriphDataAlignment = DMA_PDATAALIGN_HALFWORD;
    hdma_adc1.Init.MemDataAlignment = DMA_MDATAALIGN_HALFWORD;
    hdma_adc1.Init.Mode = DMA_CIRCULAR;
    hdma_adc1.Init.Priority = DMA_PRIORITY_HIGH;
    hdma_adc1.Init.FIFOMode = DMA_FIFOMODE_DISABLE;
    if (HAL_DMA_Init(&hdma_adc1) != HAL_OK) {
        Error_Handler();
    }

    __HAL_LINKDMA(&hadc1, DMA_Handle, hdma_adc1);

    /* ADC1 configuration for 4-channel scan */
    hadc1.Instance = ADC1;
    hadc1.Init.ClockPrescaler = ADC_CLOCK_SYNC_PCLK_DIV2;
    hadc1.Init.Resolution = ADC_RESOLUTION_12B;
    hadc1.Init.ScanConvMode = ENABLE;  // Enable scan mode for multiple channels
    hadc1.Init.ContinuousConvMode = ENABLE;  // Continuous conversion
    hadc1.Init.DiscontinuousConvMode = DISABLE;
    hadc1.Init.ExternalTrigConvEdge = ADC_EXTERNALTRIGCONVEDGE_NONE;
    hadc1.Init.ExternalTrigConv = ADC_SOFTWARE_START;
    hadc1.Init.DataAlign = ADC_DATAALIGN_RIGHT;
    hadc1.Init.NbrOfConversion = 4;  // 4 channels
    hadc1.Init.DMAContinuousRequests = ENABLE;  // Enable DMA continuous requests
    hadc1.Init.EOCSelection = ADC_EOC_SEQ_CONV;  // End of sequence
    if (HAL_ADC_Init(&hadc1) != HAL_OK) {
        Error_Handler();
    }

    /* Configure ADC channels */
    // Channel 0: Output current (PA0)
    sConfig.Channel = ADC_CHANNEL_0;
    sConfig.Rank = 1;
    sConfig.SamplingTime = ADC_SAMPLETIME_15CYCLES;
    if (HAL_ADC_ConfigChannel(&hadc1, &sConfig) != HAL_OK) {
        Error_Handler();
    }

    // Channel 1: Output voltage (PA1)
    sConfig.Channel = ADC_CHANNEL_1;
    sConfig.Rank = 2;
    if (HAL_ADC_ConfigChannel(&hadc1, &sConfig) != HAL_OK) {
        Error_Handler();
    }

    // Channel 4: DC bus 1 voltage (PA4)
    sConfig.Channel = ADC_CHANNEL_4;
    sConfig.Rank = 3;
    if (HAL_ADC_ConfigChannel(&hadc1, &sConfig) != HAL_OK) {
        Error_Handler();
    }

    // Channel 5: DC bus 2 voltage (PA5)
    sConfig.Channel = ADC_CHANNEL_5;
    sConfig.Rank = 4;
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

/**
 * @brief DMA2 Stream0 interrupt handler for ADC1
 */
void DMA2_Stream0_IRQHandler(void)
{
    HAL_DMA_IRQHandler(&hdma_adc1);
}
