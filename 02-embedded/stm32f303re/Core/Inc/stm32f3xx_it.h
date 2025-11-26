/**
 * @file stm32f3xx_it.h
 * @brief Interrupt handlers header for STM32F303RE
 */

#ifndef __STM32F3xx_IT_H
#define __STM32F3xx_IT_H

#ifdef __cplusplus
 extern "C" {
#endif

void NMI_Handler(void);
void HardFault_Handler(void);
void MemManage_Handler(void);
void BusFault_Handler(void);
void UsageFault_Handler(void);
void SVC_Handler(void);
void DebugMon_Handler(void);
void PendSV_Handler(void);
void SysTick_Handler(void);
void TIM1_UP_TIM16_IRQHandler(void);  /* F303 has different IRQ names */
void USART2_IRQHandler(void);
void ADC1_2_IRQHandler(void);         /* F303 has combined ADC interrupts */

#ifdef __cplusplus
}
#endif

#endif /* __STM32F3xx_IT_H */
