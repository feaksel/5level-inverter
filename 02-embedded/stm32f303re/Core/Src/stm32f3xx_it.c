/**
 * @file stm32f3xx_it.c
 * @brief Interrupt Service Routines for STM32F303RE
 */

#include "main.h"
#include "stm32f3xx_it.h"

extern TIM_HandleTypeDef htim1;
extern UART_HandleTypeDef huart2;
extern ADC_HandleTypeDef hadc1;

/******************************************************************************/
/*           Cortex-M4 Processor Interruption and Exception Handlers          */
/******************************************************************************/

void NMI_Handler(void)
{
  while (1) {}
}

void HardFault_Handler(void)
{
  while (1) {}
}

void MemManage_Handler(void)
{
  while (1) {}
}

void BusFault_Handler(void)
{
  while (1) {}
}

void UsageFault_Handler(void)
{
  while (1) {}
}

void SVC_Handler(void)
{
}

void DebugMon_Handler(void)
{
}

void PendSV_Handler(void)
{
}

void SysTick_Handler(void)
{
  HAL_IncTick();
}

/******************************************************************************/
/* STM32F3xx Peripheral Interrupt Handlers                                    */
/******************************************************************************/

void TIM1_UP_TIM16_IRQHandler(void)
{
  HAL_TIM_IRQHandler(&htim1);
}

void USART2_IRQHandler(void)
{
  HAL_UART_IRQHandler(&huart2);
}

void ADC1_2_IRQHandler(void)
{
  HAL_ADC_IRQHandler(&hadc1);
}
