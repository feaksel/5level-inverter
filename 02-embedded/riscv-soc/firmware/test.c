/**
 * @file test.c
 * @brief Ultra-simple test to verify CPU, bus, and UART operation
 */

int main(void) {
    // GPIO registers
    volatile unsigned int *gpio_data_out = (unsigned int *)0x00020400;
    volatile unsigned int *gpio_dir      = (unsigned int *)0x00020408;
    volatile unsigned int *gpio_out_en   = (unsigned int *)0x0002040C;

    // UART registers
    volatile unsigned int *uart_data     = (unsigned int *)0x00020500;
    volatile unsigned int *uart_ctrl     = (unsigned int *)0x00020508;
    volatile unsigned int *uart_baud_div = (unsigned int *)0x0002050C;

    // Configure GPIO as outputs
    *gpio_dir = 0xFFFF;
    *gpio_out_en = 0xFFFF;
    *gpio_data_out = 0x0001;  // LED0 on

    // Initialize UART
    *uart_baud_div = 434;  // 50MHz / 115200
    *uart_ctrl = 0x03;     // TX_EN | RX_EN

    // Send 'A' via UART
    *uart_data = 0x41;

    // Delay
    for (volatile int j = 0; j < 100000; j++);

    // Send 'B' via UART
    *uart_data = 0x42;

    // Delay
    for (volatile int j = 0; j < 100000; j++);

    // Infinite loop - blink GPIO
    int counter = 0;
    while(1) {
        *gpio_data_out = counter++;
        for(volatile int i = 0; i < 100000; i++);
    }

    return 0;
}
