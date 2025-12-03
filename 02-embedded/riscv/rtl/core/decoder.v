/**
 * @file decoder.v
 * @brief Instruction Decoder for RISC-V Core
 *
 * The decoder:
 * - Extracts fields from 32-bit instruction
 * - Generates control signals for the datapath
 * - Identifies instruction type (R, I, S, B, U, J)
 * - Computes immediate values
 * - Generates ALU operation codes
 *
 * This is the THIRD module to implement because:
 * - Builds on understanding of RISC-V ISA
 * - Pure combinational logic
 * - Critical for correct instruction execution
 *
 * @author Custom RISC-V Core Team
 * @date 2025-12-03
 */

`include "riscv_defines.vh"

module decoder (
    input  wire [31:0] instruction,  // 32-bit instruction from memory

    // Extracted instruction fields
    output wire [6:0]  opcode,       // Instruction opcode [6:0]
    output wire [2:0]  funct3,       // Function 3 [14:12]
    output wire [6:0]  funct7,       // Function 7 [31:25]
    output wire [4:0]  rs1_addr,     // Source register 1 [19:15]
    output wire [4:0]  rs2_addr,     // Source register 2 [24:20]
    output wire [4:0]  rd_addr,      // Destination register [11:7]
    output reg  [31:0] immediate,    // Decoded immediate value

    // Control signals
    output reg  [3:0]  alu_op,       // ALU operation
    output reg         alu_src_imm,  // ALU source: 0=rs2, 1=immediate
    output reg         mem_read,     // Memory read enable
    output reg         mem_write,    // Memory write enable
    output reg         reg_write,    // Register write enable
    output reg         is_branch,    // Is branch instruction
    output reg         is_jump,      // Is jump instruction (JAL/JALR)
    output reg         is_system     // Is system instruction (ECALL, etc.)
);

    //==========================================================================
    // Instruction Field Extraction
    //==========================================================================

    /**
     * All RISC-V instructions have these fields in the same positions:
     *
     * [31:25] = funct7 (for R-type)
     * [24:20] = rs2 (source register 2)
     * [19:15] = rs1 (source register 1)
     * [14:12] = funct3
     * [11:7]  = rd (destination register)
     * [6:0]   = opcode
     */

    assign opcode   = instruction[6:0];
    assign funct3   = instruction[14:12];
    assign funct7   = instruction[31:25];
    assign rs1_addr = instruction[19:15];
    assign rs2_addr = instruction[24:20];
    assign rd_addr  = instruction[11:7];

    //==========================================================================
    // Immediate Decoding
    //==========================================================================

    /**
     * TODO: Implement immediate decoding for each instruction type
     *
     * RISC-V has 6 immediate formats:
     *
     * I-type: [31:20] = imm[11:0]
     *   Used by: ADDI, SLTI, LW, JALR, etc.
     *   Sign-extend bit 31 to fill upper 20 bits
     *
     * S-type: [31:25] = imm[11:5], [11:7] = imm[4:0]
     *   Used by: SW, SH, SB
     *   Sign-extend bit 31
     *
     * B-type: [31] = imm[12], [30:25] = imm[10:5],
     *         [11:8] = imm[4:1], imm[0] = 0
     *   Used by: BEQ, BNE, BLT, BGE, BLTU, BGEU
     *   Sign-extend bit 31, always even (bit 0 = 0)
     *
     * U-type: [31:12] = imm[31:12], [11:0] = 0
     *   Used by: LUI, AUIPC
     *   Upper 20 bits, lower 12 bits are 0
     *
     * J-type: [31] = imm[20], [30:21] = imm[10:1],
     *         [20] = imm[11], [19:12] = imm[19:12], imm[0] = 0
     *   Used by: JAL
     *   Sign-extend bit 31, always even (bit 0 = 0)
     */

    always @(*) begin
        case (opcode)
            `OPCODE_OP_IMM, `OPCODE_LOAD, `OPCODE_JALR: begin
                // I-type immediate
                immediate = 32'h0;  // TODO: Implement
            end

            `OPCODE_STORE: begin
                // S-type immediate
                immediate = 32'h0;  // TODO: Implement
            end

            `OPCODE_BRANCH: begin
                // B-type immediate
                immediate = 32'h0;  // TODO: Implement
            end

            `OPCODE_LUI, `OPCODE_AUIPC: begin
                // U-type immediate
                immediate = 32'h0;  // TODO: Implement
            end

            `OPCODE_JAL: begin
                // J-type immediate
                immediate = 32'h0;  // TODO: Implement
            end

            default: begin
                immediate = 32'h0;
            end
        endcase
    end

    //==========================================================================
    // Control Signal Generation
    //==========================================================================

    /**
     * TODO: Implement control signal generation
     *
     * Based on opcode and funct3/funct7, generate:
     * - alu_op: Which ALU operation to perform
     * - alu_src_imm: Use immediate (1) or rs2 (0) as ALU operand
     * - mem_read: Load instruction (LW, LH, LB, etc.)
     * - mem_write: Store instruction (SW, SH, SB)
     * - reg_write: Write result to rd
     * - is_branch: Branch instruction (BEQ, BNE, etc.)
     * - is_jump: Jump instruction (JAL, JALR)
     * - is_system: System instruction (ECALL, EBREAK, CSR*)
     */

    always @(*) begin
        // Default values
        alu_op = `ALU_OP_ADD;
        alu_src_imm = 1'b0;
        mem_read = 1'b0;
        mem_write = 1'b0;
        reg_write = 1'b0;
        is_branch = 1'b0;
        is_jump = 1'b0;
        is_system = 1'b0;

        case (opcode)
            `OPCODE_OP_IMM: begin
                // I-type arithmetic (ADDI, SLTI, XORI, etc.)
                // TODO: Implement
            end

            `OPCODE_OP: begin
                // R-type arithmetic (ADD, SUB, AND, OR, etc.)
                // TODO: Implement
            end

            `OPCODE_LOAD: begin
                // Load instructions (LW, LH, LB, LHU, LBU)
                // TODO: Implement
            end

            `OPCODE_STORE: begin
                // Store instructions (SW, SH, SB)
                // TODO: Implement
            end

            `OPCODE_BRANCH: begin
                // Branch instructions (BEQ, BNE, BLT, BGE, BLTU, BGEU)
                // TODO: Implement
            end

            `OPCODE_JAL: begin
                // JAL (Jump and Link)
                // TODO: Implement
            end

            `OPCODE_JALR: begin
                // JALR (Jump and Link Register)
                // TODO: Implement
            end

            `OPCODE_LUI: begin
                // LUI (Load Upper Immediate)
                // TODO: Implement
            end

            `OPCODE_AUIPC: begin
                // AUIPC (Add Upper Immediate to PC)
                // TODO: Implement
            end

            `OPCODE_SYSTEM: begin
                // System instructions (ECALL, EBREAK, CSR*)
                // TODO: Implement
            end

            default: begin
                // Invalid opcode - do nothing
            end
        endcase
    end

    //==========================================================================
    // IMPLEMENTATION HINTS
    //==========================================================================

    /**
     * IMMEDIATE DECODING EXAMPLES:
     *
     * I-type:
     *   immediate = {{20{instruction[31]}}, instruction[31:20]};
     *
     * S-type:
     *   immediate = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};
     *
     * B-type:
     *   immediate = {{19{instruction[31]}}, instruction[31], instruction[7],
     *                instruction[30:25], instruction[11:8], 1'b0};
     *
     * U-type:
     *   immediate = {instruction[31:12], 12'h0};
     *
     * J-type:
     *   immediate = {{11{instruction[31]}}, instruction[31], instruction[19:12],
     *                instruction[20], instruction[30:21], 1'b0};
     */

    /**
     * CONTROL SIGNAL EXAMPLES:
     *
     * ADDI (I-type):
     *   alu_op = `ALU_OP_ADD;
     *   alu_src_imm = 1'b1;  // Use immediate
     *   reg_write = 1'b1;    // Write to rd
     *
     * ADD (R-type):
     *   alu_op = `ALU_OP_ADD;
     *   alu_src_imm = 1'b0;  // Use rs2
     *   reg_write = 1'b1;    // Write to rd
     *
     * LW (Load Word):
     *   alu_op = `ALU_OP_ADD;  // Calculate address = rs1 + imm
     *   alu_src_imm = 1'b1;
     *   mem_read = 1'b1;
     *   reg_write = 1'b1;
     *
     * SW (Store Word):
     *   alu_op = `ALU_OP_ADD;  // Calculate address = rs1 + imm
     *   alu_src_imm = 1'b1;
     *   mem_write = 1'b1;
     *   reg_write = 1'b0;  // Don't write to register
     *
     * BEQ (Branch if Equal):
     *   alu_op = `ALU_OP_SUB;  // Compare by subtraction
     *   is_branch = 1'b1;
     *   reg_write = 1'b0;  // Branches don't write registers
     */

endmodule
