/**
 * @file alu.v
 * @brief Arithmetic Logic Unit for RISC-V Core
 *
 * The ALU performs all arithmetic and logic operations for RV32I:
 * - Arithmetic: ADD, SUB
 * - Logic: AND, OR, XOR
 * - Shifts: SLL (left), SRL (logical right), SRA (arithmetic right)
 * - Comparisons: SLT (signed), SLTU (unsigned)
 *
 * This is the SECOND module to implement because:
 * - Pure combinational logic (easy to understand)
 * - No state, no registers
 * - Easy to test with simple testbench
 * - Used by many instructions
 *
 * @author Custom RISC-V Core Team
 * @date 2025-12-03
 */

`include "riscv_defines.vh"

module alu (
    input  wire [31:0] operand_a,   // First operand (usually rs1)
    input  wire [31:0] operand_b,   // Second operand (rs2 or immediate)
    input  wire [3:0]  alu_op,      // Operation select (from decoder)
    output reg  [31:0] result,      // Result of operation
    output wire        zero         // 1 if result is zero (for branches)
);

    //==========================================================================
    // ALU Operation (Combinational)
    //==========================================================================

    /**
     * TODO: Implement all ALU operations
     *
     * See riscv_defines.vh for ALU_OP_* definitions:
     * - `ALU_OP_ADD  : result = operand_a + operand_b
     * - `ALU_OP_SUB  : result = operand_a - operand_b
     * - `ALU_OP_AND  : result = operand_a & operand_b
     * - `ALU_OP_OR   : result = operand_a | operand_b
     * - `ALU_OP_XOR  : result = operand_a ^ operand_b
     * - `ALU_OP_SLL  : result = operand_a << operand_b[4:0]
     * - `ALU_OP_SRL  : result = operand_a >> operand_b[4:0]  (logical)
     * - `ALU_OP_SRA  : result = operand_a >>> operand_b[4:0] (arithmetic)
     * - `ALU_OP_SLT  : result = (signed)operand_a < (signed)operand_b ? 1 : 0
     * - `ALU_OP_SLTU : result = operand_a < operand_b ? 1 : 0  (unsigned)
     */

    always @(*) begin
        case (alu_op)
            `ALU_OP_ADD: begin
                result = 32'h0;  // TODO: Implement ADD
            end

            `ALU_OP_SUB: begin
                result = 32'h0;  // TODO: Implement SUB
            end

            `ALU_OP_AND: begin
                result = 32'h0;  // TODO: Implement AND
            end

            `ALU_OP_OR: begin
                result = 32'h0;  // TODO: Implement OR
            end

            `ALU_OP_XOR: begin
                result = 32'h0;  // TODO: Implement XOR
            end

            `ALU_OP_SLL: begin
                result = 32'h0;  // TODO: Implement Shift Left Logical
            end

            `ALU_OP_SRL: begin
                result = 32'h0;  // TODO: Implement Shift Right Logical
            end

            `ALU_OP_SRA: begin
                result = 32'h0;  // TODO: Implement Shift Right Arithmetic
            end

            `ALU_OP_SLT: begin
                result = 32'h0;  // TODO: Implement Set Less Than (signed)
            end

            `ALU_OP_SLTU: begin
                result = 32'h0;  // TODO: Implement Set Less Than Unsigned
            end

            default: begin
                result = 32'hXXXXXXXX;  // Invalid operation
            end
        endcase
    end

    //==========================================================================
    // Zero Flag (for branch instructions)
    //==========================================================================

    /**
     * Zero flag is used by branch instructions (BEQ, BNE)
     * It should be 1 if result is all zeros
     */

    assign zero = (result == 32'h0);

    //==========================================================================
    // IMPLEMENTATION HINTS
    //==========================================================================

    /**
     * ARITHMETIC OPERATIONS:
     *
     * ADD:  result = operand_a + operand_b;
     * SUB:  result = operand_a - operand_b;
     *
     * LOGIC OPERATIONS:
     *
     * AND:  result = operand_a & operand_b;
     * OR:   result = operand_a | operand_b;
     * XOR:  result = operand_a ^ operand_b;
     *
     * SHIFT OPERATIONS:
     *
     * SLL:  result = operand_a << operand_b[4:0];  // Left shift
     * SRL:  result = operand_a >> operand_b[4:0];  // Right shift (logical)
     * SRA:  result = $signed(operand_a) >>> operand_b[4:0];  // Arithmetic shift
     *
     * Note: Only use lower 5 bits of operand_b for shift amount (max shift = 31)
     *
     * COMPARISON OPERATIONS:
     *
     * SLT:  result = ($signed(operand_a) < $signed(operand_b)) ? 32'd1 : 32'd0;
     * SLTU: result = (operand_a < operand_b) ? 32'd1 : 32'd0;
     */

    /**
     * TESTING:
     *
     * Test each operation with known values:
     *
     * ADD:  10 + 20 = 30
     * SUB:  30 - 10 = 20
     * AND:  0xFF & 0x0F = 0x0F
     * OR:   0xF0 | 0x0F = 0xFF
     * XOR:  0xFF ^ 0x0F = 0xF0
     * SLL:  1 << 5 = 32
     * SRL:  32 >> 2 = 8
     * SRA:  -32 >>> 2 = -8  (sign extended)
     * SLT:  -5 < 10 = 1
     * SLTU: 0xFFFFFFFF < 10 = 0  (unsigned: 4294967295 > 10)
     */

endmodule
