#!/usr/bin/env python3
"""Decode RISC-V firmware hex to understand main loop"""

# Main loop section from hex file (lines 68-93)
instructions = [
    ("deadc537", "lui   a0, 0xdead"),
    ("00000e93", "addi  t4, zero, 0"),
    # Loop start
    ("0002a703", "lw    a4, 0(t0)"),          # Read PROT_STATUS
    ("00071663", "bnez  a4, fault_handler"),  # If fault, jump to handler
    ("00a2a623", "sw    a0, 12(t0)"),         # Write deadc to PROT_WD_KICK?
    # ADC section
    ("00020fb7", "lui   t6, 0x00020"),
    ("100f8f93", "addi  t6, t6, 0x100"),      # t6 = 0x00020100 (ADC base)
    ("00100513", "addi  a0, zero, 1"),
    ("00afa023", "sw    a0, 0(t6)"),          # ADC_CTRL = 1
    ("004fa703", "lw    a4, 4(t6)"),          # Read ADC_STATUS
    ("00177713", "andi  a4, a4, 1"),          # Check busy bit
    ("fe071ee3", "bnez  a4, wait_adc"),       # Wait while busy
    ("008fa503", "lw    a0, 8(t6)"),          # Read ADC_DATA
    # LED toggle
    ("000e2703", "lw    a4, 0(t3)"),          # t3 = GPIO base, read current
    ("00476713", "ori   a4, a4, 4"),          # Set bit 2
    ("00ee2023", "sw    a4, 0(t3)"),          # Write back
    # Delay
    ("01000f13", "addi  t5, zero, 16"),
    ("ffff0f13", "addi  t5, t5, -1"),
    ("fe0f1ee3", "bnez  t5, delay_loop"),
    ("001e8e93", "addi  t4, t4, 1"),          # Increment loop counter
    ("f6dff06f", "jal   zero, loop_start"),   # Jump back to loop
    # Fault handler
    ("00000513", "addi  a0, zero, 0"),
    ("00a32023", "sw    a0, 0(t1)"),          # PWM_CTRL = 0 (disable PWM!)
    ("04600513", "addi  a0, zero, 0x46"),     # 'F'
    ("0045a703", "lw    a4, 4(a1)"),          # UART_STATUS
    ("00277713", "andi  a4, a4, 2"),          # Check TX_EMPTY
    ("fe070ee3", "bnez  a4, wait_uart"),
    ("00a5a023", "sw    a0, 0(a1)"),          # Send 'F'
    ("f00f0063", "beq   zero, zero, hang"),   # Infinite loop
]

print("=== FIRMWARE MAIN LOOP ANALYSIS ===\n")
print("Memory Map:")
print("  t0 (x5) = 0x00020200 (Protection base)")
print("  t1 (x6) = 0x00020000 (PWM base)")
print("  t3 (x28) = 0x00020400 (GPIO base)")
print("  a1 (x11) = 0x00020500 (UART base)")
print("  a0 (x10) = 0xdead0000 (constant)")
print()

print("Loop Sequence:")
print("1. Read PROT_STATUS (offset 0x00)")
print("2. If fault detected → jump to fault_handler")
print("3. Write 0xdead0000 to offset 12(t0) = PROT_WD_KICK ✓")
print("4. Read ADC")
print("5. Toggle LED")
print("6. Delay")
print("7. Loop forever")
print()

print("Fault Handler:")
print("1. Write 0 to PWM_CTRL → DISABLES PWM!")
print("2. Send 'F' via UART")
print("3. Hang forever")
print()

print("PROBLEM IDENTIFIED:")
print("  Line 'bnez a4, fault_handler' (0x00071663)")
print("  If ANY bit in PROT_STATUS is set, it disables PWM forever!")
print()
print("  The firmware DOES kick the watchdog (line 0x00a2a623)")
print("  BUT it checks for faults BEFORE kicking watchdog!")
print()
print("  If watchdog expires before first loop iteration,")
print("  PROT_STATUS will have FAULT_WATCHDOG bit set,")
print("  and PWM gets disabled immediately!")
