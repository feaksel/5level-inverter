/**
 * @file main.c
 * @brief STM32F401RE + FPGA Hybrid System - Main Application
 *
 * This application demonstrates the STM32+FPGA hybrid architecture:
 * - STM32F401RE: Main control algorithm, PWM generation
 * - FPGA: High-speed sensing with Sigma-Delta ADC
 *
 * System Overview:
 * 1. FPGA continuously samples analog sensors via Sigma-Delta ADC
 * 2. STM32 reads ADC data from FPGA via SPI (10 kHz rate)
 * 3. STM32 runs control algorithm (PR + PI control)
 * 4. STM32 generates PWM outputs for H-bridge control
 *
 * @author 5-Level Inverter Project
 * @date 2025-12-02
 */

#include "main.h"
#include "fpga_interface.h"
#include <stdio.h>

//==========================================================================
// Private Variables
//==========================================================================

SPI_HandleTypeDef hspi1;
UART_HandleTypeDef huart2;
TIM_HandleTypeDef htim1;

//==========================================================================
// Function Prototypes
//==========================================================================

void SystemClock_Config(void);
static void MX_GPIO_Init(void);
static void MX_SPI1_Init(void);
static void MX_USART2_UART_Init(void);
static void MX_TIM1_Init(void);

void control_loop(void);
void debug_print_sensors(fpga_sensor_values_t *sensors);

//==========================================================================
// Main Function
//==========================================================================

int main(void)
{
    // Initialize HAL
    HAL_Init();

    // Configure system clock (84 MHz)
    SystemClock_Config();

    // Initialize peripherals
    MX_GPIO_Init();
    MX_SPI1_Init();
    MX_USART2_UART_Init();
    MX_TIM1_Init();

    // Initialize FPGA interface
    if (fpga_init(&hspi1) != HAL_OK) {
        Error_Handler();
    }

    // Print startup message
    printf("\r\n===========================================\r\n");
    printf("STM32F401RE + FPGA Hybrid System\r\n");
    printf("5-Level Cascaded H-Bridge Inverter\r\n");
    printf("===========================================\r\n\r\n");

    // Wait for FPGA to initialize
    HAL_Delay(100);

    // Check FPGA communication
    uint8_t status = fpga_read_status();
    printf("FPGA Status: 0x%02X\r\n", status);

    // Start PWM generation (disabled by default for safety)
    // HAL_TIM_PWM_Start(&htim1, TIM_CHANNEL_1);

    // Main control loop
    uint32_t loop_count = 0;

    while (1)
    {
        // Run control loop at 10 kHz (100 µs period)
        control_loop();

        // Debug output every 1000 loops (10 Hz)
        loop_count++;
        if (loop_count >= 1000) {
            loop_count = 0;

            // Read and print sensor values
            fpga_adc_data_t adc_data;
            fpga_sensor_values_t sensor_values;

            if (fpga_read_all_adc(&adc_data) == HAL_OK) {
                fpga_convert_to_physical(&adc_data, &sensor_values);
                debug_print_sensors(&sensor_values);
            }
        }

        // Wait for next control cycle (100 µs = 10 kHz)
        HAL_Delay(0);  // Replace with timer interrupt for precise timing
    }
}

//==========================================================================
// Control Loop (10 kHz rate)
//==========================================================================

void control_loop(void)
{
    static fpga_adc_data_t adc_data;
    static fpga_sensor_values_t sensor_values;

    // Read sensor data from FPGA
    if (fpga_read_all_adc(&adc_data) == HAL_OK) {
        // Convert to physical values
        fpga_convert_to_physical(&adc_data, &sensor_values);

        // TODO: Implement control algorithm
        // 1. PR (Proportional-Resonant) current control
        // 2. PI (Proportional-Integral) voltage control
        // 3. PWM duty cycle calculation
        // 4. Update PWM outputs

        // Example: Read current and voltage
        float ac_current = sensor_values.ac_current_a;
        float ac_voltage = sensor_values.ac_voltage_v;
        float dc_bus1 = sensor_values.dc_bus1_v;
        float dc_bus2 = sensor_values.dc_bus2_v;

        // Placeholder for control algorithm
        (void)ac_current;
        (void)ac_voltage;
        (void)dc_bus1;
        (void)dc_bus2;

        // Safety checks
        if (dc_bus1 > 60.0f || dc_bus2 > 60.0f) {
            // Overvoltage protection
            // TODO: Disable PWM
        }

        if (ac_current > 15.0f || ac_current < -15.0f) {
            // Overcurrent protection
            // TODO: Disable PWM
        }
    }
}

//==========================================================================
// Debug Functions
//==========================================================================

void debug_print_sensors(fpga_sensor_values_t *sensors)
{
    if (sensors == NULL) return;

    printf("Sensors: DC1=%.2fV, DC2=%.2fV, AC_V=%.2fV, AC_I=%.2fA\r\n",
           sensors->dc_bus1_v,
           sensors->dc_bus2_v,
           sensors->ac_voltage_v,
           sensors->ac_current_a);
}

//==========================================================================
// Peripheral Initialization Functions
//==========================================================================

void SystemClock_Config(void)
{
    RCC_OscInitTypeDef RCC_OscInitStruct = {0};
    RCC_ClkInitTypeDef RCC_ClkInitStruct = {0};

    // Configure main internal regulator output voltage
    __HAL_RCC_PWR_CLK_ENABLE();
    __HAL_PWR_VOLTAGESCALING_CONFIG(PWR_REGULATOR_VOLTAGE_SCALE2);

    // Initialize CPU, AHB, APB clocks
    RCC_OscInitStruct.OscillatorType = RCC_OSCILLATORTYPE_HSI;
    RCC_OscInitStruct.HSIState = RCC_HSI_ON;
    RCC_OscInitStruct.HSICalibrationValue = RCC_HSICALIBRATION_DEFAULT;
    RCC_OscInitStruct.PLL.PLLState = RCC_PLL_ON;
    RCC_OscInitStruct.PLL.PLLSource = RCC_PLLSOURCE_HSI;
    RCC_OscInitStruct.PLL.PLLM = 16;
    RCC_OscInitStruct.PLL.PLLN = 336;
    RCC_OscInitStruct.PLL.PLLP = RCC_PLLP_DIV4;
    RCC_OscInitStruct.PLL.PLLQ = 7;
    if (HAL_RCC_OscConfig(&RCC_OscInitStruct) != HAL_OK) {
        Error_Handler();
    }

    // Initialize CPU, AHB and APB buses clocks
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

static void MX_SPI1_Init(void)
{
    // SPI1 for FPGA communication
    hspi1.Instance = SPI1;
    hspi1.Init.Mode = SPI_MODE_MASTER;
    hspi1.Init.Direction = SPI_DIRECTION_2LINES;
    hspi1.Init.DataSize = SPI_DATASIZE_8BIT;
    hspi1.Init.CLKPolarity = SPI_POLARITY_LOW;      // CPOL = 0
    hspi1.Init.CLKPhase = SPI_PHASE_1EDGE;          // CPHA = 0
    hspi1.Init.NSS = SPI_NSS_SOFT;
    hspi1.Init.BaudRatePrescaler = SPI_BAUDRATEPRESCALER_8;  // 84MHz/8 = 10.5 MHz
    hspi1.Init.FirstBit = SPI_FIRSTBIT_MSB;
    hspi1.Init.TIMode = SPI_TIMODE_DISABLE;
    hspi1.Init.CRCCalculation = SPI_CRCCALCULATION_DISABLE;

    if (HAL_SPI_Init(&hspi1) != HAL_OK) {
        Error_Handler();
    }
}

static void MX_USART2_UART_Init(void)
{
    // UART2 for debug output
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

static void MX_TIM1_Init(void)
{
    // TIM1 for PWM generation (to be implemented)
    // This is a placeholder - full PWM configuration needed
    htim1.Instance = TIM1;
    htim1.Init.Prescaler = 0;
    htim1.Init.CounterMode = TIM_COUNTERMODE_UP;
    htim1.Init.Period = 8400 - 1;  // 10 kHz PWM @ 84 MHz
    htim1.Init.ClockDivision = TIM_CLOCKDIVISION_DIV1;
    htim1.Init.AutoReloadPreload = TIM_AUTORELOAD_PRELOAD_ENABLE;

    if (HAL_TIM_PWM_Init(&htim1) != HAL_OK) {
        Error_Handler();
    }
}

static void MX_GPIO_Init(void)
{
    // Enable GPIO clocks
    __HAL_RCC_GPIOA_CLK_ENABLE();
    __HAL_RCC_GPIOB_CLK_ENABLE();
    __HAL_RCC_GPIOC_CLK_ENABLE();

    // Configure GPIO pins (LEDs, buttons, etc.)
    // Add your GPIO configuration here
}

//==========================================================================
// Error Handler
//==========================================================================

void Error_Handler(void)
{
    // Error handler - blink LED or halt
    __disable_irq();
    while (1) {
        // Stay here
    }
}

//==========================================================================
// Printf Redirect (for UART debug output)
//==========================================================================

#ifdef __GNUC__
int _write(int file, char *ptr, int len)
{
    HAL_UART_Transmit(&huart2, (uint8_t*)ptr, len, HAL_MAX_DELAY);
    return len;
}
#endif
