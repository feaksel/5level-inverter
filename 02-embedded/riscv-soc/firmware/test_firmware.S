/**
 * @file test_firmware.S
 * @brief Minimal RISC-V test firmware (32-bit instructions only)
 *
 * This is a minimal test to verify the SoC boots correctly.
 * Written in pure assembly with only RV32IM instructions (no compressed).
 */

    .section .text.init
    .global _start

_start:
    /* Set stack pointer */
    lui sp, 0x00018          /* SP = 0x00018000 (96KB into RAM) */

    /* Write to GPIO to show we're alive */
    lui t0, 0x00020          /* t0 = 0x00020000 (GPIO base) */
    addi t1, zero, 1         /* t1 = 1 (LED0 on) */
    sw t1, 16(t0)            /* GPIO->DATA_OUT = 1 */

    /* Try to write 'A' (0x41) to UART */
    lui t2, 0x00021          /* t2 = 0x00021000 (UART base) */
    addi t3, zero, 65        /* t3 = 0x41 ('A') */
    sw t3, 0(t2)             /* UART->DATA = 'A' */

    /* Infinite loop */
loop:
    addi t4, t4, 1           /* Increment counter */
    j loop                   /* Jump back */

    .end
