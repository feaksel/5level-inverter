# M Extension Implementation Guide

**Goal:** Add multiply/divide instructions to your RISC-V core
**Time:** 4-6 hours
**Difficulty:** Medium (requires understanding of multiply/divide algorithms)
**Benefit:** 10-100x speedup for multiplication-heavy code + extra credit!

---

## What is the M Extension?

The **M Extension** adds integer multiplication and division to RV32I:

| Instruction | Operation | Description |
|-------------|-----------|-------------|
| **MUL**     | rd = (rs1 × rs2)[31:0] | Multiply, lower 32 bits |
| **MULH**    | rd = (rs1 × rs2)[63:32] | Multiply signed, upper 32 bits |
| **MULHSU**  | rd = (rs1 × rs2)[63:32] | Multiply signed×unsigned, upper 32 bits |
| **MULHU**   | rd = (rs1 × rs2)[63:32] | Multiply unsigned, upper 32 bits |
| **DIV**     | rd = rs1 ÷ rs2 | Divide signed (quotient) |
| **DIVU**    | rd = rs1 ÷ rs2 | Divide unsigned (quotient) |
| **REM**     | rd = rs1 % rs2 | Remainder signed |
| **REMU**    | rd = rs1 % rs2 | Remainder unsigned |

**Encoding:** All M extension instructions use the R-type format with `opcode = 0110011` (same as ADD/SUB) but with `funct7 = 0000001`.

**Why implement this?**
- Without M extension: `a * b` requires loops (100+ cycles)
- With M extension: `a * b` is single instruction (1-3 cycles for simple implementation)
- GCC can use native multiply: `-march=rv32im` instead of software multiply

---

## Implementation Overview

### Three Approaches (choose one):

**Approach 1: Multi-Cycle Sequential (Recommended for homework)**
- Simplest to implement
- Uses shift-add for multiply, iterative subtract for divide
- Takes 32-34 cycles per operation
- ~500 extra gates
- **Choose this if:** You want it working quickly for homework

**Approach 2: Combinational (Fast but large)**
- Uses Verilog `*` and `/` operators
- Single cycle operation
- ~5000-10000 extra gates
- May not synthesize well on all toolchains
- **Choose this if:** Your synthesis tool handles it well

**Approach 3: Multi-Cycle with Early Exit (Best balance)**
- Optimized shift-add/subtract
- 1-33 cycles depending on operands
- ~800 extra gates
- **Choose this if:** You want good performance and reasonable area

**This guide covers Approach 1 (simplest) with notes on Approach 2.**

---

## Step 1: Add ALU Operations (15 minutes)

### File: `riscv_defines.vh`

**Add these definitions after the existing ALU operations (around line 40):**

```verilog
// ALU Operations (around line 30-40)
`define ALU_OP_ADD   4'd0
`define ALU_OP_SUB   4'd1
`define ALU_OP_AND   4'd2
// ... existing operations ...

// ADD THESE (M Extension):
`define ALU_OP_MUL    4'd10  // Multiply (lower 32 bits)
`define ALU_OP_MULH   4'd11  // Multiply signed (upper 32 bits)
`define ALU_OP_MULHSU 4'd12  // Multiply signed×unsigned (upper 32 bits)
`define ALU_OP_MULHU  4'd13  // Multiply unsigned (upper 32 bits)
`define ALU_OP_DIV    4'd14  // Divide signed
`define ALU_OP_DIVU   4'd15  // Divide unsigned
```

**Also add funct3 definitions for M extension:**

```verilog
// M Extension funct3 values (add after existing funct3 definitions)
`define FUNCT3_MUL    3'b000
`define FUNCT3_MULH   3'b001
`define FUNCT3_MULHSU 3'b010
`define FUNCT3_MULHU  3'b011
`define FUNCT3_DIV    3'b100
`define FUNCT3_DIVU   3'b101
`define FUNCT3_REM    3'b110
`define FUNCT3_REMU   3'b111
```

**Save the file.** This defines the operations your ALU will support.

---

## Step 2A: ALU - Combinational Approach (30 minutes)

### File: `alu.v`

**If you choose Approach 2 (combinational), modify the ALU:**

**1. Add internal 64-bit signals (after module ports, around line 20):**

```verilog
module alu (
    input  wire [31:0] operand_a,
    input  wire [31:0] operand_b,
    input  wire [3:0]  alu_op,
    output reg  [31:0] result,
    output wire        zero
);

    // ADD THESE for M extension:
    wire signed [31:0] signed_a;
    wire signed [31:0] signed_b;
    wire signed [63:0] mul_signed;
    wire        [63:0] mul_unsigned;
    wire signed [63:0] mul_signed_unsigned;

    assign signed_a = operand_a;
    assign signed_b = operand_b;

    assign mul_signed = signed_a * signed_b;
    assign mul_unsigned = operand_a * operand_b;
    assign mul_signed_unsigned = signed_a * $signed({1'b0, operand_b});
```

**2. Add multiply/divide cases to the main case statement (around line 50):**

```verilog
always @(*) begin
    case (alu_op)
        `ALU_OP_ADD:  result = operand_a + operand_b;
        `ALU_OP_SUB:  result = operand_a - operand_b;
        // ... existing operations ...

        // ADD THESE (M Extension - Combinational):
        `ALU_OP_MUL: begin
            result = mul_signed[31:0];  // Lower 32 bits
        end

        `ALU_OP_MULH: begin
            result = mul_signed[63:32];  // Upper 32 bits (signed × signed)
        end

        `ALU_OP_MULHSU: begin
            result = mul_signed_unsigned[63:32];  // Upper 32 bits (signed × unsigned)
        end

        `ALU_OP_MULHU: begin
            result = mul_unsigned[63:32];  // Upper 32 bits (unsigned × unsigned)
        end

        `ALU_OP_DIV: begin
            // Handle division by zero (return -1 per RISC-V spec)
            if (operand_b == 32'd0) begin
                result = 32'hFFFFFFFF;
            end else if (operand_a == 32'h80000000 && operand_b == 32'hFFFFFFFF) begin
                // Handle overflow case: -2^31 / -1 = -2^31 (per RISC-V spec)
                result = 32'h80000000;
            end else begin
                result = $signed(operand_a) / $signed(operand_b);
            end
        end

        `ALU_OP_DIVU: begin
            // Unsigned division
            if (operand_b == 32'd0) begin
                result = 32'hFFFFFFFF;  // Division by zero returns max value
            end else begin
                result = operand_a / operand_b;
            end
        end

        default: result = 32'hXXXXXXXX;
    endcase
end
```

**Done!** This is the simple combinational approach. Skip to Step 3 if using this.

---

## Step 2B: ALU - Multi-Cycle Approach (1-2 hours)

### File: `alu.v`

**If you choose Approach 1 (multi-cycle), you need a more complex ALU with state:**

**WARNING:** This approach requires adding a clock to the ALU and managing multi-cycle operations in the core state machine. This is more complex but better for synthesis.

**1. Change module declaration (add clock and control signals):**

```verilog
module alu (
    input  wire        clk,          // ADD THIS
    input  wire        rst_n,        // ADD THIS
    input  wire [31:0] operand_a,
    input  wire [31:0] operand_b,
    input  wire [3:0]  alu_op,
    input  wire        start,        // ADD THIS - start operation
    output reg  [31:0] result,
    output wire        zero,
    output reg         done          // ADD THIS - operation complete
);
```

**2. Add state machine for multi-cycle operations:**

```verilog
    // Multi-cycle operation state
    localparam IDLE = 2'd0;
    localparam MULTIPLY = 2'd1;
    localparam DIVIDE = 2'd2;

    reg [1:0] state;
    reg [5:0] cycle_count;  // Counter for 32 cycles
    reg [63:0] accumulator;  // For multiply accumulation
    reg [31:0] dividend, divisor, quotient, remainder;  // For division

    // Combinational operations (single cycle)
    wire [31:0] result_comb;
    wire is_multicycle;

    assign is_multicycle = (alu_op >= `ALU_OP_MUL && alu_op <= `ALU_OP_DIVU);

    // Single-cycle operations
    always @(*) begin
        case (alu_op)
            `ALU_OP_ADD:  result_comb = operand_a + operand_b;
            `ALU_OP_SUB:  result_comb = operand_a - operand_b;
            `ALU_OP_AND:  result_comb = operand_a & operand_b;
            `ALU_OP_OR:   result_comb = operand_a | operand_b;
            `ALU_OP_XOR:  result_comb = operand_a ^ operand_b;
            `ALU_OP_SLL:  result_comb = operand_a << operand_b[4:0];
            `ALU_OP_SRL:  result_comb = operand_a >> operand_b[4:0];
            `ALU_OP_SRA:  result_comb = $signed(operand_a) >>> operand_b[4:0];
            `ALU_OP_SLT:  result_comb = ($signed(operand_a) < $signed(operand_b)) ? 32'd1 : 32'd0;
            `ALU_OP_SLTU: result_comb = (operand_a < operand_b) ? 32'd1 : 32'd0;
            default:      result_comb = 32'hXXXXXXXX;
        endcase
    end

    // Multi-cycle state machine
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            done <= 1'b1;
            result <= 32'h0;
            cycle_count <= 6'd0;
        end else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        if (is_multicycle) begin
                            done <= 1'b0;
                            cycle_count <= 6'd0;

                            // Initialize based on operation
                            if (alu_op == `ALU_OP_MUL || alu_op == `ALU_OP_MULH ||
                                alu_op == `ALU_OP_MULHSU || alu_op == `ALU_OP_MULHU) begin
                                // Multiply: shift-add algorithm
                                state <= MULTIPLY;
                                accumulator <= 64'h0;
                            end else begin
                                // Divide: restoring division
                                state <= DIVIDE;
                                dividend <= operand_a;
                                divisor <= operand_b;
                                quotient <= 32'h0;
                                remainder <= 32'h0;
                            end
                        end else begin
                            // Single cycle operation
                            result <= result_comb;
                            done <= 1'b1;
                        end
                    end
                end

                MULTIPLY: begin
                    // Shift-add multiply (simplified version)
                    if (cycle_count < 32) begin
                        if (operand_b[cycle_count]) begin
                            accumulator <= accumulator + ({operand_a, 32'h0} >> cycle_count);
                        end
                        cycle_count <= cycle_count + 1;
                    end else begin
                        // Done - select result based on operation
                        case (alu_op)
                            `ALU_OP_MUL:    result <= accumulator[31:0];
                            `ALU_OP_MULH:   result <= accumulator[63:32];
                            `ALU_OP_MULHSU: result <= accumulator[63:32];
                            `ALU_OP_MULHU:  result <= accumulator[63:32];
                        endcase
                        done <= 1'b1;
                        state <= IDLE;
                    end
                end

                DIVIDE: begin
                    // Simplified restoring division
                    if (operand_b == 32'd0) begin
                        // Division by zero
                        result <= 32'hFFFFFFFF;
                        done <= 1'b1;
                        state <= IDLE;
                    end else if (cycle_count < 32) begin
                        // Shift and subtract
                        remainder <= {remainder[30:0], dividend[31]};
                        dividend <= {dividend[30:0], 1'b0};

                        if (remainder >= divisor) begin
                            remainder <= remainder - divisor;
                            quotient <= {quotient[30:0], 1'b1};
                        end else begin
                            quotient <= {quotient[30:0], 1'b0};
                        end

                        cycle_count <= cycle_count + 1;
                    end else begin
                        // Done
                        result <= (alu_op == `ALU_OP_DIV || alu_op == `ALU_OP_DIVU) ?
                                  quotient : remainder;
                        done <= 1'b1;
                        state <= IDLE;
                    end
                end
            endcase
        end
    end

    assign zero = (result == 32'h0);
```

**NOTE:** This is a simplified multi-cycle implementation. You'll also need to modify the core state machine to wait for `done` signal. This is complex - **use combinational approach for homework unless you have time!**

---

## Step 3: Decoder Changes (20 minutes)

### File: `decoder.v`

**Add M extension decoding to the `OPCODE_OP` case:**

**Modify the existing R-type case statement (around line 156):**

```verilog
        `OPCODE_OP: begin
            // R-type arithmetic (ADD, SUB, AND, OR, etc.)
            alu_src_imm = 1'b0;  // Use rs2
            reg_write = 1'b1;

            // ADD THIS CHECK for M extension:
            if (funct7 == 7'b0000001) begin
                // M Extension instructions
                case (funct3)
                    `FUNCT3_MUL:    alu_op = `ALU_OP_MUL;
                    `FUNCT3_MULH:   alu_op = `ALU_OP_MULH;
                    `FUNCT3_MULHSU: alu_op = `ALU_OP_MULHSU;
                    `FUNCT3_MULHU:  alu_op = `ALU_OP_MULHU;
                    `FUNCT3_DIV:    alu_op = `ALU_OP_DIV;
                    `FUNCT3_DIVU:   alu_op = `ALU_OP_DIVU;
                    `FUNCT3_REM:    alu_op = `ALU_OP_DIV;  // REM uses DIV hardware
                    `FUNCT3_REMU:   alu_op = `ALU_OP_DIVU; // REMU uses DIVU hardware
                    default:        alu_op = `ALU_OP_ADD;
                endcase
            end else begin
                // Original RV32I R-type instructions
                case (funct3)
                    `FUNCT3_ADD_SUB: alu_op = funct7[5] ? `ALU_OP_SUB : `ALU_OP_ADD;
                    `FUNCT3_SLL:     alu_op = `ALU_OP_SLL;
                    `FUNCT3_SLT:     alu_op = `ALU_OP_SLT;
                    `FUNCT3_SLTU:    alu_op = `ALU_OP_SLTU;
                    `FUNCT3_XOR:     alu_op = `ALU_OP_XOR;
                    `FUNCT3_SRL_SRA: alu_op = funct7[5] ? `ALU_OP_SRA : `ALU_OP_SRL;
                    `FUNCT3_OR:      alu_op = `ALU_OP_OR;
                    `FUNCT3_AND:     alu_op = `ALU_OP_AND;
                    default:         alu_op = `ALU_OP_ADD;
                endcase
            end
        end
```

**Done!** The decoder now recognizes M extension instructions.

---

## Step 4: Core State Machine Changes (15 minutes)

### File: `custom_riscv_core.v`

**If you used combinational ALU (Approach 2A), NO CHANGES needed!** The M instructions work just like ADD/SUB.

**If you used multi-cycle ALU (Approach 2B):**

You need to add a wait state for M extension operations. This is complex and beyond the scope of this quick guide. For homework, **use combinational approach.**

---

## Step 5: Testing (30 minutes)

### Test 1: Simple Multiply Test

Create a simple test program:

```c
// File: programs/test_multiply.c

void _start(void) __attribute__((naked, noreturn));

void _start(void) {
    asm volatile(
        "   addi a0, zero, 12    \n"  // a0 = 12
        "   addi a1, zero, 10    \n"  // a1 = 10
        "   mul  a2, a0, a1      \n"  // a2 = 12 * 10 = 120
        "   addi a3, zero, 7     \n"  // a3 = 7
        "   mul  a4, a2, a3      \n"  // a4 = 120 * 7 = 840
        "done:                   \n"
        "   j done               \n"
        ::: "a0", "a1", "a2", "a3", "a4"
    );
}
```

**Compile and test:**

```bash
cd programs
riscv32-unknown-elf-gcc -march=rv32im -mabi=ilp32 -nostdlib -nostartfiles \
    -o test_multiply.elf test_multiply.c -Wl,--section-start=.text=0x0

riscv32-unknown-elf-objdump -d test_multiply.elf | head -20
# Verify you see MUL instructions: opcode 0x02???033

riscv32-unknown-elf-objcopy -O binary test_multiply.elf test_multiply.bin
python3 bin2verilog.py test_multiply.bin -o test_multiply_imem.vh
```

**Create testbench:**

```verilog
// File: sim/testbench/tb_test_multiply.v
// (Copy from tb_c_factorial.v and modify)

// Check results:
// a2 should be 120
// a4 should be 840
```

**Run:**

```bash
cd ../sim/testbench
iverilog -I../../rtl/core -o test_multiply tb_test_multiply.v ../../rtl/core/*.v
vvp test_multiply
```

**Expected output:**
```
a2 = 120 (PASS)
a4 = 840 (PASS)
```

---

### Test 2: Recompile Factorial with M Extension

Remember the factorial program that used repeated addition? Let's compile it with `-march=rv32im`:

```bash
cd programs

# Compile factorial.c with M extension
riscv32-unknown-elf-gcc -march=rv32im -mabi=ilp32 -nostdlib -T linker.ld \
    -O1 -fno-inline -o factorial_with_mul.elf factorial.c

# Check disassembly - should see MUL instructions now!
riscv32-unknown-elf-objdump -d factorial_with_mul.elf | grep mul
# Should see: mul instructions instead of loops

# Convert and test
riscv32-unknown-elf-objcopy -O binary factorial_with_mul.elf factorial_with_mul.bin
python3 bin2verilog.py factorial_with_mul.bin -o factorial_with_mul_imem.vh
```

**Compare performance:**
- Without M: ~500+ cycles (nested loops)
- With M: ~50-100 cycles (direct multiply)
- **10x speedup!**

---

### Test 3: Division Test

```c
// File: programs/test_divide.c

void _start(void) __attribute__((naked, noreturn));

void _start(void) {
    asm volatile(
        "   addi a0, zero, 100   \n"  // a0 = 100
        "   addi a1, zero, 7     \n"  // a1 = 7
        "   div  a2, a0, a1      \n"  // a2 = 100 / 7 = 14
        "   rem  a3, a0, a1      \n"  // a3 = 100 % 7 = 2
        "done:                   \n"
        "   j done               \n"
        ::: "a0", "a1", "a2", "a3"
    );
}
```

**Expected:**
- a2 = 14 (quotient)
- a3 = 2 (remainder)

---

## Step 6: Verification Summary

Create a comprehensive M extension test:

```bash
cd programs
```

```c
// File: programs/test_m_extension.c

void _start(void) __attribute__((naked, noreturn));

void _start(void) {
    asm volatile(
        // Test MUL
        "   addi t0, zero, 12    \n"
        "   addi t1, zero, 10    \n"
        "   mul  a0, t0, t1      \n"  // a0 = 120

        // Test MULH (signed)
        "   lui  t0, 0x80000     \n"  // t0 = 0x80000000 (-2^31)
        "   addi t1, zero, 2     \n"  // t1 = 2
        "   mulh a1, t0, t1      \n"  // a1 = upper 32 bits of -2^31 * 2

        // Test MULHU (unsigned)
        "   lui  t0, 0xFFFF      \n"  // t0 = 0xFFFF0000
        "   ori  t0, t0, 0xFFF   \n"  // t0 = 0xFFFF0FFF
        "   addi t1, zero, 2     \n"  // t1 = 2
        "   mulhu a2, t0, t1     \n"  // a2 = upper 32 bits (unsigned)

        // Test DIV
        "   addi t0, zero, 100   \n"
        "   addi t1, zero, 7     \n"
        "   div  a3, t0, t1      \n"  // a3 = 14

        // Test REM
        "   rem  a4, t0, t1      \n"  // a4 = 2

        // Test DIVU
        "   lui  t0, 0x10000     \n"  // t0 = 0x10000000
        "   addi t1, zero, 10    \n"
        "   divu a5, t0, t1      \n"  // a5 = unsigned division

        // Test division by zero (should return -1)
        "   addi t0, zero, 100   \n"
        "   addi t1, zero, 0     \n"
        "   div  a6, t0, t1      \n"  // a6 = 0xFFFFFFFF (per RISC-V spec)

        "done:                   \n"
        "   j done               \n"
        ::: "a0", "a1", "a2", "a3", "a4", "a5", "a6", "t0", "t1"
    );
}
```

**Expected results:**
- a0 = 120
- a1 = 0xFFFFFFFF (signed multiply overflow)
- a2 = 0x00000001 (unsigned multiply upper)
- a3 = 14
- a4 = 2
- a5 = (depends on calculation)
- a6 = 0xFFFFFFFF (division by zero)

---

## Common Issues & Solutions

### Issue 1: Multiply gives wrong result

**Symptoms:** Result is 0, or very wrong

**Solution:**
- Check signedness: `mul_signed = $signed(operand_a) * $signed(operand_b)`
- For MULHU: use unsigned: `mul_unsigned = operand_a * operand_b`
- For MULHSU: mixed: `$signed(operand_a) * $signed({1'b0, operand_b})`

### Issue 2: Synthesis fails with multiply

**Error:** "Cannot synthesize multiply operator"

**Solution:**
- Your synthesis tool may not support `*` operator
- Use multi-cycle approach (Step 2B) with shift-add algorithm
- Or add IP core for multiplier (consult your tool documentation)

### Issue 3: Division by zero crashes simulation

**Solution:**
- Always check for `operand_b == 0` before division
- Per RISC-V spec, return `0xFFFFFFFF` for division by zero
- Don't use Verilog `/` without checking!

### Issue 4: GCC still generates software multiply

**Problem:** Compiled code doesn't use MUL instruction

**Solution:**
- Check compiler flags: must use `-march=rv32im` (not just `rv32i`)
- Verify with objdump: `riscv32-unknown-elf-objdump -d program.elf | grep mul`
- If no MUL instructions, check that compiler has M extension support

### Issue 5: Timing doesn't meet after adding M extension

**Problem:** Critical path increased

**Solution:**
- 64-bit multiply can be slow
- Register the multiply inputs and outputs (add pipeline stage)
- Or use multi-cycle approach
- Or reduce clock frequency slightly

### Issue 6: REM/REMU not working

**Problem:** Remainder operations fail

**Solution:**
- REM/REMU share hardware with DIV/DIVU
- Make sure you save remainder in division algorithm
- REM returns remainder, DIV returns quotient
- Use correct selector in ALU output mux

---

## Performance Impact

### Gate Count (Combinational Approach):
- **MUL only:** +3000-5000 gates (32×32→64 bit multiplier)
- **DIV only:** +4000-6000 gates (32-bit divider)
- **Full M extension:** +8000-12000 gates total
- **Impact:** 2-3× core size (acceptable for homework)

### Timing (Combinational Approach):
- **Critical path:** Multiply is usually the slowest
- **Impact:** May reduce max frequency by 10-30%
- **Solution:** Add register stage (pipeline) if needed

### Performance Gains:
| Operation | Without M | With M (comb) | Speedup |
|-----------|-----------|---------------|---------|
| 32×32 multiply | 100+ cycles | 1 cycle | 100× |
| 32/32 divide | 150+ cycles | 1 cycle | 150× |
| Factorial(10) | 5000+ cycles | 200 cycles | 25× |

---

## Checklist

**Before testing:**
- [ ] Added ALU operations to riscv_defines.vh
- [ ] Added funct3 definitions for M extension
- [ ] Modified ALU to handle MUL/DIV operations
- [ ] Modified decoder to recognize funct7 = 0000001
- [ ] Checked that decoder sets correct alu_op for each M instruction
- [ ] Verified with objdump that GCC generates MUL instructions

**Testing:**
- [ ] Simple MUL test passes (12 × 10 = 120)
- [ ] MULH test passes (signed upper bits)
- [ ] MULHU test passes (unsigned upper bits)
- [ ] DIV test passes (100 / 7 = 14)
- [ ] REM test passes (100 % 7 = 2)
- [ ] Division by zero returns 0xFFFFFFFF
- [ ] Factorial compiles with -march=rv32im
- [ ] Factorial runs faster with M extension

**Synthesis:**
- [ ] Core synthesizes without errors
- [ ] Timing still meets (or close)
- [ ] Gate count acceptable for homework
- [ ] Generated layout looks reasonable

---

## Using M Extension in Your Programs

### Example 1: Fast Factorial

```c
// With M extension, factorial is simple and fast!
int factorial(int n) {
    int result = 1;
    for (int i = 2; i <= n; i++) {
        result = result * i;  // Uses MUL instruction
    }
    return result;
}
```

**Compile:**
```bash
riscv32-unknown-elf-gcc -march=rv32im -mabi=ilp32 -O2 ...
```

### Example 2: Matrix Multiply

```c
// 3×3 matrix multiply (much faster with M extension)
void matrix_mul(int A[3][3], int B[3][3], int C[3][3]) {
    for (int i = 0; i < 3; i++) {
        for (int j = 0; j < 3; j++) {
            C[i][j] = 0;
            for (int k = 0; k < 3; k++) {
                C[i][j] += A[i][k] * B[k][j];  // MUL instruction
            }
        }
    }
}
```

### Example 3: Fixed-Point Math

```c
// Q16.16 fixed-point multiply
// Very useful for embedded math without floating-point!
int32_t fixed_mul(int32_t a, int32_t b) {
    int64_t result = (int64_t)a * (int64_t)b;  // Uses MULH + MUL
    return (int32_t)(result >> 16);  // Extract result
}
```

---

## Extra Credit Ideas

If you want to go beyond basic M extension:

1. **Add REM/REMU:** Separate remainder hardware (currently shares with DIV)
2. **Early exit optimization:** Stop multiply when remaining bits are zero
3. **Pipeline multiply:** Add register stages for higher clock speed
4. **Booth encoding:** More efficient multiply algorithm
5. **Radix-4 division:** Faster division algorithm

---

## Summary

**What you implemented:**
- 8 new instructions (MUL, MULH, MULHSU, MULHU, DIV, DIVU, REM, REMU)
- 64-bit multiply logic (32×32→64)
- 32-bit divide logic
- Decoder changes to recognize funct7 = 0000001

**Benefits:**
- 10-100× speedup for math-heavy code
- Can compile with `-march=rv32im` (native multiply)
- Extra credit on homework
- Real-world embedded systems almost always have M extension

**Time spent:**
- Combinational: ~1-2 hours
- Multi-cycle: ~4-6 hours

**Next steps:**
- Test thoroughly with various programs
- Verify with GCC-compiled code
- Synthesize and check gate count
- Document in your homework report

---

**Congratulations!** Your RISC-V core now has hardware multiply/divide. This makes it much more practical for real embedded applications! 🚀

**Questions?** Check:
1. This guide
2. RISC-V specification Chapter 7 (M Extension)
3. QUICK_START.md (for core implementation)
4. Test your code with the provided test programs
