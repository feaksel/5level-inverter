/**
 * @file pwm_test_simple.c
 * @brief Simple PWM test for STM32F303RE
 *
 * This is a minimal test to verify PWM output on oscilloscope
 * Connect oscilloscope to:
 * - PA8  (TIM1_CH1)  - Should see 50% duty PWM
 * - PA9  (TIM1_CH2)  - Should see 50% duty PWM
 * - PB13 (TIM1_CH1N) - Should see inverted PA8 with dead-time
 * - PB14 (TIM1_CH2N) - Should see inverted PA9 with dead-time
 */

#include "stm32f3xx_hal.h"

/* Global handles */
TIM_HandleTypeDef htim1;
UART_HandleTypeDef huart2;

/* Function prototypes */
void SystemClock_Config(void);
void Error_Handler(void);
static void MX_GPIO_Init(void);
static void MX_TIM1_Init(void);
static void MX_USART2_UART_Init(void);
void HAL_TIM_MspPostInit(TIM_HandleTypeDef* htim);

int main(void)
{
    /* Initialize HAL */
    HAL_Init();

    /* Configure system clock - 72MHz from HSI */
    SystemClock_Config();

    /* Initialize peripherals */
    MX_GPIO_Init();
    MX_TIM1_Init();
    MX_USART2_UART_Init();

    /* Print startup message */
    const char *msg = "\r\n=== STM32F303RE PWM Test ===\r\n";
    HAL_UART_Transmit(&huart2, (uint8_t*)msg, strlen(msg), 1000);
    msg = "Starting PWM on PA8 and PA9...\r\n";
    HAL_UART_Transmit(&huart2, (uint8_t*)msg, strlen(msg), 1000);

    /* Set 50% duty cycle */
    uint16_t period = __HAL_TIM_GET_AUTORELOAD(&htim1);
    uint16_t duty_50 = period / 2;

    __HAL_TIM_SET_COMPARE(&htim1, TIM_CHANNEL_1, duty_50);
    __HAL_TIM_SET_COMPARE(&htim1, TIM_CHANNEL_2, duty_50);

    /* Start PWM on all channels */
    HAL_TIM_PWM_Start(&htim1, TIM_CHANNEL_1);      // PA8
    HAL_TIMEx_PWMN_Start(&htim1, TIM_CHANNEL_1);   // PB13 (complementary)
    HAL_TIM_PWM_Start(&htim1, TIM_CHANNEL_2);      // PA9
    HAL_TIMEx_PWMN_Start(&htim1, TIM_CHANNEL_2);   // PB14 (complementary)

    msg = "PWM Started! Check oscilloscope on PA8/PA9\r\n";
    HAL_UART_Transmit(&huart2, (uint8_t*)msg, strlen(msg), 1000);

    /* Blink LED to show we're alive */
    while (1)
    {
        HAL_GPIO_TogglePin(GPIOA, GPIO_PIN_5);  // Toggle LED
        HAL_Delay(500);
    }
}

/**
 * @brief System Clock Configuration for STM32F303RE
 * Uses HSI (8MHz internal) with PLL to get 64MHz
 * (Conservative speed to ensure it works)
 */
void SystemClock_Config(void)
{
    RCC_OscInitTypeDef RCC_OscInitStruct = {0};
    RCC_ClkInitTypeDef RCC_ClkInitStruct = {0};

    /* Configure the main internal regulator output voltage */
    HAL_PWR_EnableBkUpAccess();

    /* Initializes the RCC Oscillators - Use HSI for simplicity */
    RCC_OscInitStruct.OscillatorType = RCC_OSCILLATORTYPE_HSI;
    RCC_OscInitStruct.HSIState = RCC_HSI_ON;
    RCC_OscInitStruct.HSICalibrationValue = RCC_HSICALIBRATION_DEFAULT;
    RCC_OscInitStruct.PLL.PLLState = RCC_PLL_ON;
    RCC_OscInitStruct.PLL.PLLSource = RCC_PLLSOURCE_HSI;
    RCC_OscInitStruct.PLL.PLLMUL = RCC_PLL_MUL16;  // 8MHz / 2 * 16 = 64MHz
    RCC_OscInitStruct.PLL.PREDIV = RCC_PREDIV_DIV2;

    if (HAL_RCC_OscConfig(&RCC_OscInitStruct) != HAL_OK)
    {
        Error_Handler();
    }

    /* Initializes the CPU, AHB and APB buses clocks */
    RCC_ClkInitStruct.ClockType = RCC_CLOCKTYPE_HCLK | RCC_CLOCKTYPE_SYSCLK
                                | RCC_CLOCKTYPE_PCLK1 | RCC_CLOCKTYPE_PCLK2;
    RCC_ClkInitStruct.SYSCLKSource = RCC_SYSCLKSOURCE_PLLCLK;
    RCC_ClkInitStruct.AHBCLKDivider = RCC_SYSCLK_DIV1;   // 64MHz
    RCC_ClkInitStruct.APB1CLKDivider = RCC_HCLK_DIV2;    // 32MHz
    RCC_ClkInitStruct.APB2CLKDivider = RCC_HCLK_DIV1;    // 64MHz

    if (HAL_RCC_ClockConfig(&RCC_ClkInitStruct, FLASH_LATENCY_2) != HAL_OK)
    {
        Error_Handler();
    }
}

/**
 * @brief TIM1 Initialization - Simple 1kHz PWM for testing
 */
static void MX_TIM1_Init(void)
{
    TIM_ClockConfigTypeDef sClockSourceConfig = {0};
    TIM_MasterConfigTypeDef sMasterConfig = {0};
    TIM_OC_InitTypeDef sConfigOC = {0};
    TIM_BreakDeadTimeConfigTypeDef sBreakDeadTimeConfig = {0};

    /* TIM1 clock = 64 MHz (from APB2) */
    /* For 1 kHz PWM: Period = 64000000 / 1000 = 64000 */
    /* For easier viewing on scope, let's use 1 kHz */

    htim1.Instance = TIM1;
    htim1.Init.Prescaler = 0;
    htim1.Init.CounterMode = TIM_COUNTERMODE_UP;
    htim1.Init.Period = 63999;  // 64MHz / 64000 = 1kHz (easy to see on scope)
    htim1.Init.ClockDivision = TIM_CLOCKDIVISION_DIV1;
    htim1.Init.RepetitionCounter = 0;
    htim1.Init.AutoReloadPreload = TIM_AUTORELOAD_PRELOAD_ENABLE;

    if (HAL_TIM_Base_Init(&htim1) != HAL_OK)
    {
        Error_Handler();
    }

    sClockSourceConfig.ClockSource = TIM_CLOCKSOURCE_INTERNAL;
    if (HAL_TIM_ConfigClockSource(&htim1, &sClockSourceConfig) != HAL_OK)
    {
        Error_Handler();
    }

    if (HAL_TIM_PWM_Init(&htim1) != HAL_OK)
    {
        Error_Handler();
    }

    /* Configure PWM channels */
    sConfigOC.OCMode = TIM_OCMODE_PWM1;
    sConfigOC.Pulse = 0;
    sConfigOC.OCPolarity = TIM_OCPOLARITY_HIGH;
    sConfigOC.OCNPolarity = TIM_OCNPOLARITY_HIGH;
    sConfigOC.OCFastMode = TIM_OCFAST_DISABLE;
    sConfigOC.OCIdleState = TIM_OCIDLESTATE_RESET;
    sConfigOC.OCNIdleState = TIM_OCNIDLESTATE_RESET;

    if (HAL_TIM_PWM_ConfigChannel(&htim1, &sConfigOC, TIM_CHANNEL_1) != HAL_OK)
    {
        Error_Handler();
    }
    if (HAL_TIM_PWM_ConfigChannel(&htim1, &sConfigOC, TIM_CHANNEL_2) != HAL_OK)
    {
        Error_Handler();
    }

    /* Configure dead-time (about 1us at 64MHz = 64 ticks) */
    sBreakDeadTimeConfig.OffStateRunMode = TIM_OSSR_DISABLE;
    sBreakDeadTimeConfig.OffStateIDLEMode = TIM_OSSI_DISABLE;
    sBreakDeadTimeConfig.LockLevel = TIM_LOCKLEVEL_OFF;
    sBreakDeadTimeConfig.DeadTime = 64;  // ~1us dead-time
    sBreakDeadTimeConfig.BreakState = TIM_BREAK_DISABLE;
    sBreakDeadTimeConfig.BreakPolarity = TIM_BREAKPOLARITY_HIGH;
    sBreakDeadTimeConfig.AutomaticOutput = TIM_AUTOMATICOUTPUT_DISABLE;

    if (HAL_TIMEx_ConfigBreakDeadTime(&htim1, &sBreakDeadTimeConfig) != HAL_OK)
    {
        Error_Handler();
    }

    /* Initialize GPIO */
    HAL_TIM_MspPostInit(&htim1);
}

/**
 * @brief USART2 Initialization for debug output
 */
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
    huart2.Init.OneBitSampling = UART_ONE_BIT_SAMPLE_DISABLE;
    huart2.AdvancedInit.AdvFeatureInit = UART_ADVFEATURE_NO_INIT;

    if (HAL_UART_Init(&huart2) != HAL_OK)
    {
        Error_Handler();
    }
}

/**
 * @brief GPIO Initialization
 */
static void MX_GPIO_Init(void)
{
    GPIO_InitTypeDef GPIO_InitStruct = {0};

    /* GPIO Ports Clock Enable */
    __HAL_RCC_GPIOA_CLK_ENABLE();
    __HAL_RCC_GPIOB_CLK_ENABLE();
    __HAL_RCC_GPIOC_CLK_ENABLE();

    /* Configure LED pin PA5 */
    GPIO_InitStruct.Pin = GPIO_PIN_5;
    GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP;
    GPIO_InitStruct.Pull = GPIO_NOPULL;
    GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_LOW;
    HAL_GPIO_Init(GPIOA, &GPIO_InitStruct);
}

/**
 * @brief TIM MSP Initialization - Configure GPIO for PWM
 */
void HAL_TIM_MspPostInit(TIM_HandleTypeDef* htim)
{
    GPIO_InitTypeDef GPIO_InitStruct = {0};

    if(htim->Instance == TIM1)
    {
        __HAL_RCC_GPIOA_CLK_ENABLE();
        __HAL_RCC_GPIOB_CLK_ENABLE();

        /* TIM1 GPIO Configuration
         * PA8  ------> TIM1_CH1
         * PA9  ------> TIM1_CH2
         * PB13 ------> TIM1_CH1N
         * PB14 ------> TIM1_CH2N
         */

        /* Configure PA8 and PA9 */
        GPIO_InitStruct.Pin = GPIO_PIN_8 | GPIO_PIN_9;
        GPIO_InitStruct.Mode = GPIO_MODE_AF_PP;
        GPIO_InitStruct.Pull = GPIO_NOPULL;
        GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_HIGH;
        GPIO_InitStruct.Alternate = GPIO_AF6_TIM1;  // F303RE uses AF6 for TIM1!
        HAL_GPIO_Init(GPIOA, &GPIO_InitStruct);

        /* Configure PB13 and PB14 */
        GPIO_InitStruct.Pin = GPIO_PIN_13 | GPIO_PIN_14;
        GPIO_InitStruct.Alternate = GPIO_AF6_TIM1;  // F303RE uses AF6 for TIM1!
        HAL_GPIO_Init(GPIOB, &GPIO_InitStruct);
    }
}

/**
 * @brief  This function is executed in case of error occurrence.
 */
void Error_Handler(void)
{
    __disable_irq();
    while (1)
    {
        /* Blink LED rapidly to indicate error */
        HAL_GPIO_TogglePin(GPIOA, GPIO_PIN_5);
        for(volatile int i=0; i<100000; i++);
    }
}
