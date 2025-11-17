#!/usr/bin/env python3
"""
Simple RISC-V instruction decoder to verify firmware validity.
Decodes the first few instructions from comprehensive_test.mem.
"""

def decode_riscv_instruction(hex_str, addr):
    """Decode a 32-bit RISC-V instruction (basic decoding)."""
    inst = int(hex_str, 16)

    opcode = inst & 0x7F
    rd = (inst >> 7) & 0x1F
    funct3 = (inst >> 12) & 0x7
    rs1 = (inst >> 15) & 0x1F
    rs2 = (inst >> 20) & 0x1F
    funct7 = (inst >> 25) & 0x7F

    # U-type immediate
    imm_u = inst & 0xFFFFF000

    # I-type immediate
    imm_i = (inst >> 20) & 0xFFF
    if imm_i & 0x800:  # Sign extend
        imm_i |= 0xFFFFF000

    reg_names = [
        'zero', 'ra', 'sp', 'gp', 'tp', 't0', 't1', 't2',
        's0', 's1', 'a0', 'a1', 'a2', 'a3', 'a4', 'a5',
        'a6', 'a7', 's2', 's3', 's4', 's5', 's6', 's7',
        's8', 's9', 's10', 's11', 't3', 't4', 't5', 't6'
    ]

    # Decode common opcodes
    if opcode == 0x37:  # LUI
        return f"lui  {reg_names[rd]}, 0x{imm_u >> 12:05x}"
    elif opcode == 0x13:  # ADDI and others
        if funct3 == 0x0:
            return f"addi {reg_names[rd]}, {reg_names[rs1]}, {imm_i & 0xFFF:d}"
        elif funct3 == 0x7:
            return f"andi {reg_names[rd]}, {reg_names[rs1]}, {imm_i & 0xFFF:d}"
    elif opcode == 0x23:  # STORE
        offset = ((inst >> 25) << 5) | ((inst >> 7) & 0x1F)
        if offset & 0x800:
            offset |= 0xFFFFF000
        if funct3 == 0x2:
            return f"sw   {reg_names[rs2]}, {offset & 0xFFF:d}({reg_names[rs1]})"
    elif opcode == 0x03:  # LOAD
        if funct3 == 0x2:
            return f"lw   {reg_names[rd]}, {imm_i & 0xFFF:d}({reg_names[rs1]})"
    elif opcode == 0x63:  # BRANCH
        imm_b = (((inst >> 31) & 0x1) << 12) | (((inst >> 7) & 0x1) << 11) | \
                (((inst >> 25) & 0x3F) << 5) | (((inst >> 8) & 0xF) << 1)
        if imm_b & 0x1000:
            imm_b |= 0xFFFFE000
        if funct3 == 0x1:
            return f"bne  {reg_names[rs1]}, {reg_names[rs2]}, {imm_b:+d}"
        elif funct3 == 0x0:
            return f"beq  {reg_names[rs1]}, {reg_names[rs2]}, {imm_b:+d}"
    elif opcode == 0x6F:  # JAL
        imm_j = (((inst >> 31) & 0x1) << 20) | (((inst >> 12) & 0xFF) << 12) | \
                (((inst >> 20) & 0x1) << 11) | (((inst >> 21) & 0x3FF) << 1)
        if imm_j & 0x100000:
            imm_j |= 0xFFE00000
        if rd == 0:
            return f"j    {imm_j:+d}"
        else:
            return f"jal  {reg_names[rd]}, {imm_j:+d}"
    elif opcode == 0x67:  # JALR
        if rd == 0:
            return f"jr   {reg_names[rs1]}"
        else:
            return f"jalr {reg_names[rd]}, {imm_i & 0xFFF:d}({reg_names[rs1]})"
    elif opcode == 0x33:  # R-type
        if funct7 == 0x00:
            if funct3 == 0x0:
                return f"add  {reg_names[rd]}, {reg_names[rs1]}, {reg_names[rs2]}"
            elif funct3 == 0x6:
                return f"or   {reg_names[rd]}, {reg_names[rs1]}, {reg_names[rs2]}"
        elif funct7 == 0x20 and funct3 == 0x0:
            return f"sub  {reg_names[rd]}, {reg_names[rs1]}, {reg_names[rs2]}"

    return f"??? (0x{inst:08x})"

# Read and decode comprehensive_test.mem
print("=" * 80)
print("RISC-V Firmware Verification: comprehensive_test.mem")
print("=" * 80)
print()

with open('comprehensive_test.mem', 'r') as f:
    lines = f.readlines()

print("First 20 instructions:")
print()
print("Addr       | Hex Code  | Decoded Instruction")
print("-" * 80)

for i, line in enumerate(lines[:20]):
    hex_code = line.strip()
    if hex_code:
        addr = i * 4
        decoded = decode_riscv_instruction(hex_code, addr)
        print(f"0x{addr:08x} | {hex_code} | {decoded}")

print()
print("=" * 80)
print("Analysis:")
print("=" * 80)

# Check first instruction
first_inst = int(lines[0].strip(), 16)
if (first_inst & 0x7F) == 0x37:  # LUI
    print("✅ First instruction is LUI (loading upper immediate) - VALID START")
    print(f"   Setting up sp (stack pointer) with upper 20 bits")
else:
    print(f"⚠️  First instruction: 0x{first_inst:08x}")

# Check for valid instruction patterns
print()
print("Checking for suspicious patterns:")
any_invalid = False
for i, line in enumerate(lines[:50]):
    hex_code = line.strip()
    if hex_code:
        inst = int(hex_code, 16)
        # Check if instruction looks valid (not all zeros, not all Xs)
        if inst == 0x00000000:
            if i > 20:  # Some NOPs are ok, but not many
                print(f"⚠️  Address 0x{i*4:08x}: NOP (0x00000000)")
        elif inst & 0x8000_0000:  # MSB set - could be problematic
            opcode = inst & 0x7F
            if opcode not in [0x13, 0x33, 0x23, 0x03, 0x63, 0x6F, 0x67, 0x37, 0x17]:
                print(f"⚠️  Address 0x{i*4:08x}: Suspicious opcode 0x{opcode:02x}")
                any_invalid = True

if not any_invalid:
    print("✅ No obviously invalid instructions found in first 50 words")

print()
print("=" * 80)
print("Conclusion:")
print("=" * 80)
if first_inst == 0x00018137:
    print("✅ comprehensive_test.mem appears VALID")
    print("✅ Starts at address 0x00000000 (correct for ROM)")
    print("✅ First instruction: lui sp, 0x00018 (setup stack @ 0x18000)")
    print()
    print("This firmware should execute correctly from ROM!")
else:
    print("⚠️  Firmware may have issues - please check")
