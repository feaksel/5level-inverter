/**
 * @file soc_regs.h
 * @brief RISC-V SoC Peripheral Register Definitions
 *
 * Hardware register addresses and bitfield definitions for all SoC peripherals.
 */

#ifndef SOC_REGS_H
#define SOC_REGS_H

#include <stdint.h>

//==============================================================================
// Memory Map
//==============================================================================

#define ROM_BASE            0x00000000
#define RAM_BASE            0x00008000
#define PWM_BASE            0x00020000
#define ADC_BASE            0x00020100
#define PROT_BASE           0x00020200
#define TIMER_BASE          0x00020300
#define GPIO_BASE           0x00020400
#define UART_BASE           0x00020500

//==============================================================================
// PWM Accelerator Registers
//==============================================================================

typedef struct {
    volatile uint32_t CTRL;         // 0x00: Control register
    volatile uint32_t FREQ_DIV;     // 0x04: Frequency divider
    volatile uint32_t MOD_INDEX;    // 0x08: Modulation index
    volatile uint32_t SINE_PHASE;   // 0x0C: Sine phase accumulator
    volatile uint32_t SINE_FREQ;    // 0x10: Sine frequency
    volatile uint32_t DEADTIME;     // 0x14: Dead-time value
    volatile uint32_t STATUS;       // 0x18: Status register
    volatile uint32_t PWM_OUT;      // 0x1C: PWM output state (read-only)
} PWM_TypeDef;

#define PWM ((PWM_TypeDef *) PWM_BASE)

// CTRL register bits
#define PWM_CTRL_ENABLE     (1 << 0)
#define PWM_CTRL_AUTO_MODE  (1 << 1)

//==============================================================================
// ADC Interface Registers
//==============================================================================

typedef struct {
    volatile uint32_t CTRL;         // 0x00: Control register
    volatile uint32_t CLK_DIV;      // 0x04: SPI clock divider
    volatile uint32_t CH_SELECT;    // 0x08: Channel selection
    volatile uint32_t DATA_CH0;     // 0x0C: Channel 0 data
    volatile uint32_t DATA_CH1;     // 0x10: Channel 1 data
    volatile uint32_t DATA_CH2;     // 0x14: Channel 2 data
    volatile uint32_t DATA_CH3;     // 0x18: Channel 3 data
    volatile uint32_t STATUS;       // 0x1C: Status register
} ADC_TypeDef;

#define ADC ((ADC_TypeDef *) ADC_BASE)

// CTRL register bits
#define ADC_CTRL_ENABLE     (1 << 0)
#define ADC_CTRL_START      (1 << 1)
#define ADC_CTRL_AUTO_MODE  (1 << 2)

// STATUS register bits
#define ADC_STATUS_BUSY     (1 << 0)

//==============================================================================
// Protection Peripheral Registers
//==============================================================================

typedef struct {
    volatile uint32_t FAULT_STATUS; // 0x00: Fault status (read-only)
    volatile uint32_t FAULT_ENABLE; // 0x04: Fault enable mask
    volatile uint32_t FAULT_CLEAR;  // 0x08: Clear latched faults (write)
    volatile uint32_t WATCHDOG_VAL; // 0x0C: Watchdog timeout value
    volatile uint32_t WATCHDOG_KICK;// 0x10: Kick watchdog (write)
    volatile uint32_t FAULT_LATCH;  // 0x14: Latched fault status
} PROT_TypeDef;

#define PROT ((PROT_TypeDef *) PROT_BASE)

// Fault bits
#define FAULT_OCP       (1 << 0)    // Overcurrent protection
#define FAULT_OVP       (1 << 1)    // Overvoltage protection
#define FAULT_ESTOP     (1 << 2)    // Emergency stop
#define FAULT_WATCHDOG  (1 << 3)    // Watchdog timeout

//==============================================================================
// Timer Registers
//==============================================================================

typedef struct {
    volatile uint32_t CTRL;         // 0x00: Control register
    volatile uint32_t PRESCALER;    // 0x04: Clock prescaler
    volatile uint32_t COUNTER;      // 0x08: Current counter value (read-only)
    volatile uint32_t COMPARE;      // 0x0C: Compare value
    volatile uint32_t STATUS;       // 0x10: Status register
} TIMER_TypeDef;

#define TIMER ((TIMER_TypeDef *) TIMER_BASE)

// CTRL register bits
#define TIMER_CTRL_ENABLE       (1 << 0)
#define TIMER_CTRL_AUTO_RELOAD  (1 << 1)
#define TIMER_CTRL_INT_ENABLE   (1 << 2)

// STATUS register bits
#define TIMER_STATUS_MATCH      (1 << 0)

//==============================================================================
// GPIO Registers
//==============================================================================

typedef struct {
    volatile uint32_t DATA_OUT;     // 0x00: Output data
    volatile uint32_t DATA_IN;      // 0x04: Input data (read-only)
    volatile uint32_t DIR;          // 0x08: Direction (0=in, 1=out)
    volatile uint32_t OUTPUT_EN;    // 0x0C: Output enable
} GPIO_TypeDef;

#define GPIO ((GPIO_TypeDef *) GPIO_BASE)

//==============================================================================
// UART Registers
//==============================================================================

typedef struct {
    volatile uint32_t DATA;         // 0x00: TX/RX data register
    volatile uint32_t STATUS;       // 0x04: Status register
    volatile uint32_t CTRL;         // 0x08: Control register
    volatile uint32_t BAUD_DIV;     // 0x0C: Baud rate divider
} UART_TypeDef;

#define UART ((UART_TypeDef *) UART_BASE)

// STATUS register bits
#define UART_STATUS_RX_READY    (1 << 0)
#define UART_STATUS_TX_EMPTY    (1 << 1)
#define UART_STATUS_RX_OVERRUN  (1 << 2)
#define UART_STATUS_FRAME_ERROR (1 << 3)

// CTRL register bits
#define UART_CTRL_RX_ENABLE     (1 << 0)
#define UART_CTRL_TX_ENABLE     (1 << 1)
#define UART_CTRL_RX_INT_EN     (1 << 2)

//==============================================================================
// Helper Macros
//==============================================================================

#define REG32(addr) (*(volatile uint32_t *)(addr))
#define BIT(n)      (1U << (n))

//==============================================================================
// System Configuration
//==============================================================================

#define F_CPU           50000000    // 50 MHz system clock
#define UART_BAUD       115200      // UART baud rate

#endif // SOC_REGS_H
