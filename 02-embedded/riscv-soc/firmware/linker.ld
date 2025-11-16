/**
 * @file linker.ld
 * @brief RISC-V Linker Script for SoC
 *
 * Defines memory layout and section placement for firmware.
 *
 * Memory Map:
 *   ROM: 0x00000000 - 0x00007FFF (32 KB) - Code and constants
 *   RAM: 0x00008000 - 0x00017FFF (64 KB) - Data, BSS, stack, heap
 */

OUTPUT_ARCH("riscv")
ENTRY(_start)

MEMORY
{
    ROM (rx)  : ORIGIN = 0x00000000, LENGTH = 32K
    RAM (rwx) : ORIGIN = 0x00008000, LENGTH = 64K
}

SECTIONS
{
    /*==========================================================================
     * CODE SECTION (in ROM)
     *==========================================================================*/

    .text : {
        *(.text.init)           /* Startup code first */
        *(.text*)               /* All code */
        *(.rodata*)             /* Read-only data (constants, strings) */
        . = ALIGN(4);
    } > ROM

    /*==========================================================================
     * DATA SECTION (in RAM, initialized from ROM)
     *==========================================================================*/

    /* End of ROM */
    _etext = .;

    .data : AT(_etext) {
        _sdata = .;             /* Start of data in RAM */
        *(.data*)               /* Initialized data */
        . = ALIGN(4);
        _edata = .;             /* End of data */
    } > RAM

    /*==========================================================================
     * BSS SECTION (in RAM, zero-initialized)
     *==========================================================================*/

    .bss : {
        _sbss = .;              /* Start of BSS */
        *(.bss*)                /* Uninitialized data */
        *(COMMON)
        . = ALIGN(4);
        _ebss = .;              /* End of BSS */
    } > RAM

    /*==========================================================================
     * HEAP (in RAM, managed by malloc)
     *==========================================================================*/

    .heap : {
        _sheap = .;             /* Start of heap */
        . = . + 8K;             /* 8 KB heap */
        . = ALIGN(4);
        _eheap = .;             /* End of heap */
    } > RAM

    /*==========================================================================
     * STACK (in RAM, grows downward from end of RAM)
     *==========================================================================*/

    _stack_size = 8K;           /* 8 KB stack */
    _sp = ORIGIN(RAM) + LENGTH(RAM);  /* Stack pointer starts at end of RAM */

    /*==========================================================================
     * SYMBOLS FOR C RUNTIME
     *==========================================================================*/

    PROVIDE(_stack_start = _sp);
    PROVIDE(_stack_end = _sp - _stack_size);

    /*==========================================================================
     * DEBUGGING SYMBOLS
     *==========================================================================*/

    /* Discard debug sections (keep if needed for GDB) */
    /DISCARD/ : {
        *(.comment)
    }

    /* Or keep them (uncomment if using GDB)
    .debug_info     0 : { *(.debug_info) }
    .debug_abbrev   0 : { *(.debug_abbrev) }
    .debug_line     0 : { *(.debug_line) }
    .debug_str      0 : { *(.debug_str) }
    */
}
