/**
 * @file system_stm32f3xx.c
 * @brief CMSIS System Source File for STM32F3xx
 */

#include "stm32f3xx.h"

#if !defined  (HSE_VALUE)
  #define HSE_VALUE    8000000U  /*!< STM32F303RE Nucleo uses 8MHz HSE */
#endif

#if !defined  (HSI_VALUE)
  #define HSI_VALUE    8000000U  /*!< F3 series HSI is 8MHz */
#endif

uint32_t SystemCoreClock = 72000000;  /* 72 MHz system clock */
const uint8_t AHBPrescTable[16] = {0, 0, 0, 0, 0, 0, 0, 0, 1, 2, 3, 4, 6, 7, 8, 9};
const uint8_t APBPrescTable[8]  = {0, 0, 0, 0, 1, 2, 3, 4};

void SystemInit(void)
{
  /* FPU settings */
  #if (__FPU_PRESENT == 1) && (__FPU_USED == 1)
    SCB->CPACR |= ((3UL << 10*2)|(3UL << 11*2));  /* Enable FPU */
  #endif

  /* Reset RCC clock configuration to default state */
  RCC->CR |= (uint32_t)0x00000001;          /* Set HSION bit */
  RCC->CFGR &= (uint32_t)0xF87FC00C;        /* Reset SW, HPRE, PPRE1, PPRE2, ADCPRE and MCO bits */
  RCC->CR &= (uint32_t)0xFEF6FFFF;          /* Reset HSEON, CSSON and PLLON bits */
  RCC->CR &= (uint32_t)0xFFFBFFFF;          /* Reset HSEBYP bit */
  RCC->CFGR &= (uint32_t)0xFF80FFFF;        /* Reset PLLSRC, PLLXTPRE, PLLMUL and USBPRE bits */
  RCC->CFGR2 = 0x00000000;                  /* Reset CFGR2 register */
  RCC->CFGR3 = 0x00000000;                  /* Reset CFGR3 register */
  RCC->CIR = 0x00000000;                    /* Disable all interrupts */

  /* Configure Vector Table location */
  #ifdef VECT_TAB_SRAM
    SCB->VTOR = SRAM_BASE | VECT_TAB_OFFSET;  /* Vector Table in SRAM */
  #else
    SCB->VTOR = FLASH_BASE | VECT_TAB_OFFSET; /* Vector Table in FLASH */
  #endif
}

void SystemCoreClockUpdate(void)
{
  uint32_t tmp = 0, pllmull = 0, pllsource = 0, predivfactor = 0;

  /* Get SYSCLK source */
  tmp = RCC->CFGR & RCC_CFGR_SWS;

  switch (tmp)
  {
    case RCC_CFGR_SWS_HSI:  /* HSI used as system clock */
      SystemCoreClock = HSI_VALUE;
      break;

    case RCC_CFGR_SWS_HSE:  /* HSE used as system clock */
      SystemCoreClock = HSE_VALUE;
      break;

    case RCC_CFGR_SWS_PLL:  /* PLL used as system clock */
      /* Get PLL clock source and multiplication factor */
      pllmull = RCC->CFGR & RCC_CFGR_PLLMUL;
      pllsource = RCC->CFGR & RCC_CFGR_PLLSRC;
      pllmull = ( pllmull >> 18) + 2;

      if (pllsource == 0x00)
      {
        /* HSI oscillator clock divided by 2 selected as PLL clock entry */
        SystemCoreClock = (HSI_VALUE >> 1) * pllmull;
      }
      else
      {
        predivfactor = (RCC->CFGR2 & RCC_CFGR2_PREDIV) + 1;
        /* HSE oscillator clock selected as PREDIV1 clock entry */
        SystemCoreClock = (HSE_VALUE / predivfactor) * pllmull;
      }
      break;

    default: /* HSI used as system clock */
      SystemCoreClock = HSI_VALUE;
      break;
  }

  /* Compute HCLK clock frequency */
  tmp = AHBPrescTable[((RCC->CFGR & RCC_CFGR_HPRE) >> 4)];
  SystemCoreClock >>= tmp;
}
