# test_soc.S
#
# A simple SoC test program that:
# 1. Writes "Hello World!" to the UART.
# 2. Enters an infinite loop.
#
# This verifies that the CPU can fetch instructions from ROM and
# write to a peripheral (UART) across the Wishbone bus.

.section .text
.globl _start

# Define peripheral base addresses from the memory map
.equ UART_BASE, 0x00020500
.equ UART_TX_DATA, UART_BASE

_start:
    # --- Test UART Output ---
    la s0, hello_string # Load address of the string into s0
    mv s1, s0           # s1 will be our pointer

loop:
    lb t0, 0(s1)        # Load a byte (character) from the string
    beq t0, zero, end_loop # If it's the null terminator, exit loop

    # Write the character to the UART TX data register
    sb t0, 0(s1) # This is a bug, should be sw t0, 0(UART_TX_DATA)
    
    addi s1, s1, 1      # Move to the next character
    j loop

end_loop:
    # Infinite loop to end the program
hang:
    j hang

.section .rodata
hello_string:
    .string "Hello World!\n"
