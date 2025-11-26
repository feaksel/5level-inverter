/**
 * @file main.c
 * @brief RISC-V SoC Firmware - 5-Level Inverter Control
 *
 * Main firmware for the RISC-V-based inverter control system.
 * This is a basic demonstration showing peripheral initialization.
 */

#include "soc_regs.h"

//==============================================================================
// Function Prototypes
//==============================================================================

void uart_init(void);
void uart_putc(char c);
void uart_puts(const char *s);
void delay_ms(uint32_t ms);
void system_init(void);

//==============================================================================
// UART Functions
//==============================================================================

void uart_init(void) {
    // Calculate baud rate divider: F_CPU / BAUD_RATE
    uint32_t baud_div = F_CPU / UART_BAUD;

    UART->BAUD_DIV = baud_div;
    UART->CTRL = UART_CTRL_RX_ENABLE | UART_CTRL_TX_ENABLE;
}

void uart_putc(char c) {
    // Wait for TX buffer to be empty
    while (!(UART->STATUS & UART_STATUS_TX_EMPTY));

    UART->DATA = c;
}

void uart_puts(const char *s) {
    while (*s) {
        uart_putc(*s++);
    }
}

void uart_print_hex(uint32_t val) {
    const char hex[] = "0123456789ABCDEF";
    uart_puts("0x");
    for (int i = 28; i >= 0; i -= 4) {
        uart_putc(hex[(val >> i) & 0xF]);
    }
}

//==============================================================================
// Delay Function
//==============================================================================

void delay_ms(uint32_t ms) {
    // Simple delay loop (approximate)
    // At 50 MHz, each loop iteration takes ~4 cycles
    // For 1 ms: 50,000 cycles / 4 = 12,500 iterations
    volatile uint32_t count = ms * 12500;
    while (count--);
}

//==============================================================================
// System Initialization
//==============================================================================

void system_init(void) {
    // Initialize UART
    uart_init();

    // Initialize Protection Peripheral
    PROT->FAULT_ENABLE = FAULT_OCP | FAULT_OVP | FAULT_ESTOP | FAULT_WATCHDOG;
    PROT->WATCHDOG_VAL = F_CPU;  // 1 second watchdog timeout
    PROT->FAULT_CLEAR = 0xFFFFFFFF;  // Clear any latched faults

    // Initialize Timer (not enabled yet)
    TIMER->PRESCALER = 49999;  // 50MHz / 50000 = 1 kHz timer
    TIMER->COMPARE = 1000;     // 1 second

    // Initialize GPIO (LEDs as outputs)
    GPIO->DIR = 0x0000FFFF;       // Lower 16 bits as outputs
    GPIO->OUTPUT_EN = 0x0000FFFF;
    GPIO->DATA_OUT = 0x0001;      // LED0 on (power indicator)

    // Initialize ADC Interface
    ADC->CLK_DIV = 100;  // SPI clock = 500 kHz
    ADC->CTRL = ADC_CTRL_ENABLE;

    // Initialize PWM Accelerator (disabled initially)
    PWM->FREQ_DIV = 10000;    // 50MHz / 10000 = 5 kHz carrier
    PWM->MOD_INDEX = 32768;   // 50% modulation index
    PWM->SINE_FREQ = 50;      // 50 Hz sine wave
    PWM->DEADTIME = 50;       // 1 us dead-time @ 50 MHz
    PWM->CTRL = 0;            // Disabled for now
}

//==============================================================================
// Main Function
//==============================================================================

int main(void) {
    // Initialize system peripherals
    system_init();

    // Print startup banner
    uart_puts("\r\n");
    uart_puts("========================================\r\n");
    uart_puts("RISC-V SoC - 5-Level Inverter Control\r\n");
    uart_puts("========================================\r\n");
    uart_puts("CPU:      VexRiscv RV32IMC\r\n");
    uart_puts("Clock:    50 MHz\r\n");
    uart_puts("ROM:      32 KB\r\n");
    uart_puts("RAM:      64 KB\r\n");
    uart_puts("========================================\r\n\r\n");

    uart_puts("System initialized successfully.\r\n");
    uart_puts("All peripherals ready.\r\n\r\n");

    // Check for any faults
    uint32_t faults = PROT->FAULT_STATUS;
    if (faults) {
        uart_puts("WARNING: Faults detected: ");
        uart_print_hex(faults);
        uart_puts("\r\n");

        if (faults & FAULT_OCP) uart_puts("  - Overcurrent Protection\r\n");
        if (faults & FAULT_OVP) uart_puts("  - Overvoltage Protection\r\n");
        if (faults & FAULT_ESTOP) uart_puts("  - Emergency Stop Active\r\n");
        if (faults & FAULT_WATCHDOG) uart_puts("  - Watchdog Timeout\r\n");

        uart_puts("System halted. Clear faults to continue.\r\n\r\n");
    } else {
        uart_puts("No faults detected. System ready.\r\n\r\n");
    }

    // Main loop
    uint32_t counter = 0;
    uart_puts("Entering main loop...\r\n");

    while (1) {
        // Kick watchdog
        PROT->WATCHDOG_KICK = 1;

        // Toggle LED every second
        if (counter % 50 == 0) {
            GPIO->DATA_OUT ^= 0x0002;  // Toggle LED1

            // Print status
            uart_puts("Status: ");
            uart_print_hex(counter);
            uart_puts(" | Faults: ");
            uart_print_hex(PROT->FAULT_STATUS);
            uart_puts("\r\n");
        }

        // Sample ADC channels (example)
        if (counter % 100 == 0) {
            // Trigger ADC conversion on channel 0
            ADC->CH_SELECT = 0;
            ADC->CTRL |= ADC_CTRL_START;

            // Wait for conversion (in real code, use interrupt)
            delay_ms(1);

            // Read result
            uint32_t adc_val = ADC->DATA_CH0;
            uart_puts("ADC CH0: ");
            uart_print_hex(adc_val);
            uart_puts("\r\n");
        }

        // Delay
        delay_ms(20);
        counter++;
    }

    return 0;  // Never reached
}

//==============================================================================
// Interrupt Handlers (Placeholders)
//==============================================================================

/**
 * Note: VexRiscv interrupt handling requires proper CSR setup.
 * This is a simplified example. In production code:
 * - Set up mtvec register to point to interrupt vector
 * - Enable interrupts in mstatus
 * - Handle each interrupt source appropriately
 */

void __attribute__((interrupt)) irq_handler(void) {
    // Placeholder interrupt handler
    // In real code, check interrupt source and handle accordingly
}
