/**
 * @file stm32f3xx_hal_conf.h
 * @brief HAL configuration file for STM32F303RE
 */

#ifndef __STM32F3xx_HAL_CONF_H
#define __STM32F3xx_HAL_CONF_H

#ifdef __cplusplus
 extern "C" {
#endif

/* Module Selection */
#define HAL_MODULE_ENABLED
#define HAL_CORTEX_MODULE_ENABLED
#define HAL_DMA_MODULE_ENABLED
#define HAL_RCC_MODULE_ENABLED
#define HAL_FLASH_MODULE_ENABLED
#define HAL_GPIO_MODULE_ENABLED
#define HAL_PWR_MODULE_ENABLED
#define HAL_TIM_MODULE_ENABLED
#define HAL_UART_MODULE_ENABLED
#define HAL_ADC_MODULE_ENABLED

/* Oscillator Values */
#if !defined  (HSE_VALUE)
  #define HSE_VALUE    8000000U  /*!< STM32F303RE Nucleo uses 8MHz HSE */
#endif

#if !defined  (HSI_VALUE)
  #define HSI_VALUE    8000000U  /*!< F3 series HSI is 8MHz */
#endif

#if !defined  (LSE_VALUE)
  #define LSE_VALUE    32768U
#endif

#if !defined  (LSI_VALUE)
  #define LSI_VALUE    40000U    /*!< F3 series LSI is 40kHz */
#endif

#if !defined  (EXTERNAL_CLOCK_VALUE)
  #define EXTERNAL_CLOCK_VALUE    8000000U
#endif

/* System Configuration */
#define  VDD_VALUE                    3300U
#define  TICK_INT_PRIORITY            0U
#define  USE_RTOS                     0U
#define  PREFETCH_ENABLE              1U
#define  INSTRUCTION_CACHE_ENABLE     0U    /* F3 doesn't have I-cache */
#define  DATA_CACHE_ENABLE            0U    /* F3 doesn't have D-cache */

/* HAL Configuration */
#define  USE_HAL_ADC_REGISTER_CALLBACKS         0U
#define  USE_HAL_CAN_REGISTER_CALLBACKS         0U
#define  USE_HAL_COMP_REGISTER_CALLBACKS        0U
#define  USE_HAL_DAC_REGISTER_CALLBACKS         0U
#define  USE_HAL_DMA_REGISTER_CALLBACKS         0U
#define  USE_HAL_HRTIM_REGISTER_CALLBACKS       0U
#define  USE_HAL_I2C_REGISTER_CALLBACKS         0U
#define  USE_HAL_I2S_REGISTER_CALLBACKS         0U
#define  USE_HAL_IRDA_REGISTER_CALLBACKS        0U
#define  USE_HAL_OPAMP_REGISTER_CALLBACKS       0U
#define  USE_HAL_PCD_REGISTER_CALLBACKS         0U
#define  USE_HAL_RTC_REGISTER_CALLBACKS         0U
#define  USE_HAL_SDADC_REGISTER_CALLBACKS       0U
#define  USE_HAL_SMARTCARD_REGISTER_CALLBACKS   0U
#define  USE_HAL_SMBUS_REGISTER_CALLBACKS       0U
#define  USE_HAL_SPI_REGISTER_CALLBACKS         0U
#define  USE_HAL_TIM_REGISTER_CALLBACKS         0U
#define  USE_HAL_TSC_REGISTER_CALLBACKS         0U
#define  USE_HAL_UART_REGISTER_CALLBACKS        0U
#define  USE_HAL_USART_REGISTER_CALLBACKS       0U
#define  USE_HAL_WWDG_REGISTER_CALLBACKS        0U

/* Includes */
#ifdef HAL_RCC_MODULE_ENABLED
  #include "stm32f3xx_hal_rcc.h"
#endif

#ifdef HAL_GPIO_MODULE_ENABLED
  #include "stm32f3xx_hal_gpio.h"
#endif

#ifdef HAL_DMA_MODULE_ENABLED
  #include "stm32f3xx_hal_dma.h"
#endif

#ifdef HAL_CORTEX_MODULE_ENABLED
  #include "stm32f3xx_hal_cortex.h"
#endif

#ifdef HAL_ADC_MODULE_ENABLED
  #include "stm32f3xx_hal_adc.h"
#endif

#ifdef HAL_FLASH_MODULE_ENABLED
  #include "stm32f3xx_hal_flash.h"
#endif

#ifdef HAL_PWR_MODULE_ENABLED
  #include "stm32f3xx_hal_pwr.h"
#endif

#ifdef HAL_TIM_MODULE_ENABLED
  #include "stm32f3xx_hal_tim.h"
#endif

#ifdef HAL_UART_MODULE_ENABLED
  #include "stm32f3xx_hal_uart.h"
#endif

/* Assert macro */
#ifdef  USE_FULL_ASSERT
  #define assert_param(expr) ((expr) ? (void)0U : assert_failed((uint8_t *)__FILE__, __LINE__))
  void assert_failed(uint8_t* file, uint32_t line);
#else
  #define assert_param(expr) ((void)0U)
#endif

#ifdef __cplusplus
}
#endif

#endif /* __STM32F3xx_HAL_CONF_H */
