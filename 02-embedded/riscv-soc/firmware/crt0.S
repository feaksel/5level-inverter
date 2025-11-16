/**
 * @file crt0.S
 * @brief RISC-V Startup Code (C Runtime Initialization)
 *
 * This code executes first after reset:
 * 1. Set up stack pointer
 * 2. Initialize .data section (copy from ROM to RAM)
 * 3. Zero out .bss section
 * 4. Call main()
 * 5. Infinite loop if main returns
 */

    .section .text.init
    .global _start

_start:
    /*==========================================================================
     * Setup Stack Pointer
     *==========================================================================*/
    la sp, _sp                  /* Load stack pointer address */

    /*==========================================================================
     * Initialize .data section (copy from ROM to RAM)
     *==========================================================================*/
    la t0, _etext               /* Source: end of .text in ROM */
    la t1, _sdata               /* Destination: start of .data in RAM */
    la t2, _edata               /* End of .data */

    beq t1, t2, 2f              /* Skip if no data to copy */

1:
    lw t3, 0(t0)                /* Load word from ROM */
    sw t3, 0(t1)                /* Store word to RAM */
    addi t0, t0, 4              /* Increment source */
    addi t1, t1, 4              /* Increment destination */
    blt t1, t2, 1b              /* Loop until done */

2:
    /*==========================================================================
     * Zero out .bss section
     *==========================================================================*/
    la t0, _sbss                /* Start of .bss */
    la t1, _ebss                /* End of .bss */

    beq t0, t1, 4f              /* Skip if no BSS */

3:
    sw zero, 0(t0)              /* Write zero */
    addi t0, t0, 4              /* Increment address */
    blt t0, t1, 3b              /* Loop until done */

4:
    /*==========================================================================
     * Call main()
     *==========================================================================*/
    call main                   /* Jump to main C function */

    /*==========================================================================
     * If main returns, loop forever
     *==========================================================================*/
5:
    j 5b                        /* Infinite loop */

    .end
