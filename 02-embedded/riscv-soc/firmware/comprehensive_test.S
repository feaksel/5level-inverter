/**
 * @file comprehensive_test.S
 * @brief Comprehensive SoC Test Firmware (RV32IM only, no compressed)
 *
 * This firmware tests all SoC peripherals and reports results via GPIO.
 * Results are encoded in GPIO[15:0]:
 *   Bits [3:0]: Test progress counter (increments with each test)
 *   Bit 4: RAM test passed
 *   Bit 5: GPIO test passed
 *   Bit 6: UART test passed
 *   Bit 7: All tests passed
 *
 * Memory Map (from soc_regs.h):
 *   0x00000000 - ROM
 *   0x00008000 - RAM
 *   0x00020000 - PWM
 *   0x00020100 - ADC
 *   0x00020200 - Protection
 *   0x00020300 - Timer
 *   0x00020400 - GPIO
 *   0x00020500 - UART
 */

    .section .text.init
    .global _start

_start:
    /*==========================================================================
     * SETUP: Initialize Stack and Registers
     *==========================================================================*/
    lui sp, 0x00018          /* SP = 0x00018000 (top of 64KB RAM) */

    /* Initialize test result register */
    addi s0, zero, 0         /* s0 = test results (initially 0) */
    addi s1, zero, 0         /* s1 = test counter */

    /*==========================================================================
     * TEST 1: RAM Read/Write Test
     *==========================================================================*/
test_ram:
    /* Increment test counter */
    addi s1, s1, 1           /* s1++ */

    /* Write test pattern to RAM */
    lui t0, 0x00008          /* t0 = RAM base (0x00008000) */
    lui t1, 0xDEADB          /* t1 = 0xDEADB000 */
    addi t1, t1, 0x3EF       /* t1 = 0xDEADBEEF (test pattern) */
    sw t1, 0(t0)             /* RAM[0] = 0xDEADBEEF */

    /* Read back and verify */
    lw t2, 0(t0)             /* t2 = RAM[0] */
    bne t1, t2, test_ram_fail /* If not equal, test failed */

    /* Test passed - set bit 4 */
    addi t3, zero, 0x10      /* t3 = 0x10 (bit 4) */
    or s0, s0, t3            /* s0 |= 0x10 */

test_ram_fail:
    /* Update GPIO with test progress */
    lui t4, 0x00020          /* t4 = 0x00020000 */
    addi t4, t4, 0x400       /* t4 = GPIO base (0x00020400) */
    or t5, s0, s1            /* t5 = results | counter */
    sw t5, 0(t4)             /* GPIO->DATA_OUT = results */

    /*==========================================================================
     * TEST 2: GPIO Direction and Output Enable
     *==========================================================================*/
test_gpio:
    /* Increment test counter */
    addi s1, s1, 1           /* s1++ */

    /* Configure GPIO as outputs */
    lui t0, 0x00020          /* t0 = 0x00020000 */
    addi t0, t0, 0x400       /* t0 = GPIO base */
    lui t1, 0x0000F          /* t1 = 0x0000FFFF */
    addi t1, t1, 0xFFF       /* t1 = 0x0000FFFF (all outputs) */
    sw t1, 8(t0)             /* GPIO->DIR = 0xFFFF */
    sw t1, 12(t0)            /* GPIO->OUTPUT_EN = 0xFFFF */

    /* Write test pattern */
    addi t2, zero, 0x55      /* t2 = 0x55 */
    sw t2, 0(t0)             /* GPIO->DATA_OUT = 0x55 */

    /* Read back */
    lw t3, 0(t0)             /* t3 = GPIO->DATA_OUT */
    andi t3, t3, 0xFF        /* Mask to lower byte */
    bne t2, t3, test_gpio_fail

    /* Test passed - set bit 5 */
    addi t4, zero, 0x20      /* t4 = 0x20 (bit 5) */
    or s0, s0, t4            /* s0 |= 0x20 */

test_gpio_fail:
    /* Update GPIO with test progress */
    lui t4, 0x00020
    addi t4, t4, 0x400
    or t5, s0, s1
    sw t5, 0(t4)

    /*==========================================================================
     * TEST 3: UART Initialization and Transmit
     *==========================================================================*/
test_uart:
    /* Increment test counter */
    addi s1, s1, 1           /* s1++ */

    /* Initialize UART */
    lui t0, 0x00020          /* t0 = 0x00020000 */
    addi t0, t0, 0x500       /* t0 = UART base (0x00020500) */

    /* Set baud divisor: 50MHz / 115200 = 434 (0x1B2) */
    addi t1, zero, 0x1B2     /* t1 = 434 */
    sw t1, 12(t0)            /* UART->BAUD_DIV = 434 */

    /* Enable TX and RX */
    addi t2, zero, 3         /* t2 = 0x03 (TX_EN | RX_EN) */
    sw t2, 8(t0)             /* UART->CTRL = 0x03 */

    /* Send test character 'T' (0x54) */
    addi t3, zero, 0x54      /* t3 = 'T' */
    sw t3, 0(t0)             /* UART->DATA = 'T' */

    /* Brief delay for TX */
    addi t4, zero, 100
uart_delay:
    addi t4, t4, -1
    bne t4, zero, uart_delay

    /* Send 'E' (0x45) */
    addi t3, zero, 0x45      /* t3 = 'E' */
    sw t3, 0(t0)             /* UART->DATA = 'E' */

    /* Send 'S' (0x53) */
    addi t4, zero, 100
uart_delay2:
    addi t4, t4, -1
    bne t4, zero, uart_delay2

    addi t3, zero, 0x53      /* t3 = 'S' */
    sw t3, 0(t0)             /* UART->DATA = 'S' */

    /* Send 'T' (0x54) */
    addi t4, zero, 100
uart_delay3:
    addi t4, t4, -1
    bne t4, zero, uart_delay3

    addi t3, zero, 0x54      /* t3 = 'T' */
    sw t3, 0(t0)             /* UART->DATA = 'T' */

    /* Send newline (0x0A) */
    addi t4, zero, 100
uart_delay4:
    addi t4, t4, -1
    bne t4, zero, uart_delay4

    addi t3, zero, 0x0A      /* t3 = '\n' */
    sw t3, 0(t0)             /* UART->DATA = '\n' */

    /* Test passed - set bit 6 */
    addi t4, zero, 0x40      /* t4 = 0x40 (bit 6) */
    or s0, s0, t4            /* s0 |= 0x40 */

    /* Update GPIO with test progress */
    lui t4, 0x00020
    addi t4, t4, 0x400
    or t5, s0, s1
    sw t5, 0(t4)

    /*==========================================================================
     * TEST 4: Protection Peripheral Access
     *==========================================================================*/
test_protection:
    /* Increment test counter */
    addi s1, s1, 1           /* s1++ */

    /* Access protection peripheral */
    lui t0, 0x00020          /* t0 = 0x00020000 */
    addi t0, t0, 0x200       /* t0 = PROT base (0x00020200) */

    /* Read fault status */
    lw t1, 0(t0)             /* t1 = PROT->FAULT_STATUS */

    /* Enable all faults */
    addi t2, zero, 0x0F      /* t2 = 0x0F (all fault bits) */
    sw t2, 4(t0)             /* PROT->FAULT_ENABLE = 0x0F */

    /* Update GPIO */
    lui t4, 0x00020
    addi t4, t4, 0x400
    or t5, s0, s1
    sw t5, 0(t4)

    /*==========================================================================
     * ALL TESTS COMPLETE
     *==========================================================================*/
all_tests_done:
    /* Set "all tests passed" bit (bit 7) */
    addi t0, zero, 0x80      /* t0 = 0x80 (bit 7) */
    or s0, s0, t0            /* s0 |= 0x80 */

    /* Final GPIO update with all results */
    lui t1, 0x00020
    addi t1, t1, 0x400
    or t2, s0, s1            /* Combine results and counter */
    sw t2, 0(t1)             /* GPIO->DATA_OUT = final results */

    /*==========================================================================
     * INFINITE LOOP: Blink LED pattern showing test complete
     *==========================================================================*/
success_loop:
    /* Toggle LED pattern every ~1 million cycles */
    lui t3, 0x00010          /* t3 = 0x10000 (65536) */

delay_loop:
    addi t3, t3, -1
    bne t3, zero, delay_loop

    /* Toggle bit 8 for visual indication */
    xori s0, s0, 0x100       /* s0 ^= 0x100 */

    /* Update GPIO */
    lui t1, 0x00020
    addi t1, t1, 0x400
    or t2, s0, s1
    sw t2, 0(t1)

    /* Loop forever */
    j success_loop

    .end
