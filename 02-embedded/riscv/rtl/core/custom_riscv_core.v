/**
 * @file custom_riscv_core.v
 * @brief Custom RV32IM RISC-V Core with Zpec Extension (Native Wishbone)
 *
 * This is the main processor core implementing:
 * - RV32I base integer instruction set (40 instructions)
 * - M extension: multiply/divide (8 instructions)
 * - Zpec extension: power electronics custom instructions (6 instructions)
 *
 * Architecture: 3-stage pipeline (Fetch, Decode/Execute, Writeback)
 * ISA: RV32IM + Zpec
 * Bus: Native Wishbone B4 (Approach 2 - Cleaner Design)
 *
 * IMPLEMENTATION APPROACH: Native Wishbone (Approach 2)
 * - Core uses standard Wishbone B4 protocol directly
 * - No cmd/rsp conversion needed
 * - Cleaner, more reusable design
 * - Wrapper is just a simple passthrough
 *
 * @author Custom RISC-V Core Team
 * @date 2025-12-03
 * @version 0.2 - Approach 2: Native Wishbone Template
 */

module custom_riscv_core #(
    parameter RESET_VECTOR = 32'h00000000  // Reset PC address
)(
    input  wire        clk,
    input  wire        rst_n,  // Active LOW reset (Wishbone standard)

    //==========================================================================
    // Instruction Wishbone Bus (Master)
    //==========================================================================

    output wire [31:0] iwb_adr_o,   // Instruction address
    input  wire [31:0] iwb_dat_i,   // Instruction data from memory
    output wire        iwb_cyc_o,   // Cycle active
    output wire        iwb_stb_o,   // Strobe
    input  wire        iwb_ack_i,   // Acknowledge

    //==========================================================================
    // Data Wishbone Bus (Master)
    //==========================================================================

    output wire [31:0] dwb_adr_o,   // Data address
    output wire [31:0] dwb_dat_o,   // Data to write
    input  wire [31:0] dwb_dat_i,   // Data read from memory/peripheral
    output wire        dwb_we_o,    // Write enable (1=write, 0=read)
    output wire [3:0]  dwb_sel_o,   // Byte select
    output wire        dwb_cyc_o,   // Cycle active
    output wire        dwb_stb_o,   // Strobe
    input  wire        dwb_ack_i,   // Acknowledge
    input  wire        dwb_err_i,   // Bus error

    //==========================================================================
    // Interrupts
    //==========================================================================

    input  wire [31:0] interrupts   // Interrupt inputs [31:0]
);

    //==========================================================================
    // IMPLEMENTATION GUIDE - Approach 2: Native Wishbone
    //==========================================================================

    /**
     * WISHBONE PROTOCOL BASICS:
     *
     * Read Cycle:
     *   1. Master asserts CYC, STB, ADR (and clears WE)
     *   2. Slave sees STB=1, prepares data
     *   3. Slave asserts ACK with valid data on DAT_I
     *   4. Master reads data, clears CYC/STB
     *
     * Write Cycle:
     *   1. Master asserts CYC, STB, ADR, DAT_O, WE, SEL
     *   2. Slave sees STB=1 and WE=1, writes data
     *   3. Slave asserts ACK
     *   4. Master clears CYC/STB
     *
     * IMPLEMENTATION STRATEGY:
     *
     * Stage 1: Fetch
     *   - Generate iwb_adr_o = PC
     *   - Assert iwb_cyc_o, iwb_stb_o
     *   - Wait for iwb_ack_i
     *   - Latch instruction from iwb_dat_i
     *   - Increment PC
     *
     * Stage 2: Decode/Execute
     *   - Decode instruction
     *   - Read register file
     *   - Execute ALU operation
     *   - For LOAD/STORE:
     *     * Assert dwb_cyc_o, dwb_stb_o
     *     * Set dwb_adr_o, dwb_we_o, dwb_sel_o
     *     * Wait for dwb_ack_i
     *   - For branches: update PC
     *
     * Stage 3: Writeback
     *   - Write result to register file
     *   - For LOAD: write dwb_dat_i to register
     *
     * START SIMPLE:
     *   1. Implement single-cycle (no pipeline) first
     *   2. Just fetch → decode → execute → writeback sequentially
     *   3. Add pipelining later for performance
     */

    //==========================================================================
    // Internal Signals
    //==========================================================================

    // Program Counter
    reg [31:0] pc;

    // Instruction register
    reg [31:0] instruction;

    // Register file signals
    wire [4:0]  rs1_addr, rs2_addr, rd_addr;
    wire [31:0] rs1_data, rs2_data, rd_data;
    wire        rd_wen;

    // Decode signals
    wire [6:0]  opcode;
    wire [2:0]  funct3;
    wire [6:0]  funct7;
    wire [31:0] immediate;

    // ALU signals
    wire [31:0] alu_operand_a, alu_operand_b;
    wire [3:0]  alu_op;
    wire [31:0] alu_result;
    wire        alu_zero;

    // Control signals
    wire        branch_taken;
    wire [31:0] branch_target;
    wire        is_load, is_store;
    wire        is_branch, is_jump;

    // State machine (for multi-cycle operations)
    reg [2:0] state;
    localparam STATE_FETCH     = 3'd0;
    localparam STATE_DECODE    = 3'd1;
    localparam STATE_EXECUTE   = 3'd2;
    localparam STATE_MEM       = 3'd3;
    localparam STATE_WRITEBACK = 3'd4;

    //==========================================================================
    // PLACEHOLDER IMPLEMENTATION
    //==========================================================================

    /**
     * This is a STARTER TEMPLATE for Native Wishbone implementation.
     *
     * RECOMMENDED IMPLEMENTATION ORDER:
     *
     * 1. Register File (simplest module)
     *    - Create rtl/core/regfile.v
     *    - 32 registers, x0 always 0
     *    - Synchronous write, combinational read
     *
     * 2. ALU (pure combinational logic)
     *    - Create rtl/core/alu.v
     *    - Implement all RV32I operations
     *    - Test with simple testbench
     *
     * 3. Instruction Decoder
     *    - Create rtl/core/decoder.v
     *    - Extract fields from instruction
     *    - Generate control signals
     *
     * 4. Simple State Machine (this file)
     *    - FETCH: Read instruction from iwb
     *    - DECODE: Decode and read registers
     *    - EXECUTE: Run ALU
     *    - WRITEBACK: Write to register file
     *
     * 5. Load/Store Support
     *    - Add MEM state for dwb access
     *    - Handle byte/half/word accesses
     *
     * 6. Branches and Jumps
     *    - Add branch comparison logic
     *    - Update PC on taken branches
     *
     * 7. M Extension (Multiply/Divide)
     *    - Create rtl/core/multiplier.v
     *    - Create rtl/core/divider.v
     *    - Add multi-cycle support
     *
     * 8. Interrupts and CSRs
     *    - Create rtl/core/csr_file.v
     *    - Implement trap handling
     *    - Add mstatus, mie, mtvec, etc.
     *
     * 9. Zpec Custom Instructions
     *    - Add custom instruction decoders
     *    - Implement accelerators
     *
     * See docs/IMPLEMENTATION_ROADMAP.md for detailed code examples!
     */

    // For now, tie off outputs to prevent synthesis errors
    assign iwb_adr_o = 32'h0;
    assign iwb_cyc_o = 1'b0;
    assign iwb_stb_o = 1'b0;

    assign dwb_adr_o = 32'h0;
    assign dwb_dat_o = 32'h0;
    assign dwb_we_o = 1'b0;
    assign dwb_sel_o = 4'h0;
    assign dwb_cyc_o = 1'b0;
    assign dwb_stb_o = 1'b0;

    // Initialize PC on reset
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc <= RESET_VECTOR;
            state <= STATE_FETCH;
        end else begin
            // TODO: Implement state machine
            // See implementation guide above
        end
    end

    // Synthesis-time warning
    // synthesis translate_off
    initial begin
        $display("");
        $display("=================================================================");
        $display("INFO: custom_riscv_core - Approach 2 (Native Wishbone)");
        $display("=================================================================");
        $display("This template uses NATIVE WISHBONE interface.");
        $display("");
        $display("Advantages:");
        $display("  - Standard protocol, widely used");
        $display("  - Simpler wrapper (just passthrough)");
        $display("  - More reusable design");
        $display("  - Easier to understand");
        $display("");
        $display("Implementation guides:");
        $display("  1. docs/DROP_IN_REPLACEMENT_GUIDE.md");
        $display("     Section: 'Approach 2: Native Wishbone Core'");
        $display("");
        $display("  2. docs/IMPLEMENTATION_ROADMAP.md");
        $display("     - Week-by-week implementation plan");
        $display("     - Complete code examples for each module");
        $display("");
        $display("Quick Start:");
        $display("  1. Implement regfile.v (register file)");
        $display("  2. Implement alu.v (arithmetic logic unit)");
        $display("  3. Implement decoder.v (instruction decoder)");
        $display("  4. Build simple state machine in this file");
        $display("  5. Test with simple programs!");
        $display("=================================================================");
        $display("");
    end
    // synthesis translate_on

    //==========================================================================
    // MODULE INSTANTIATIONS (uncomment as you implement each module)
    //==========================================================================

    /*
    // Register File
    regfile regfile_inst (
        .clk(clk),
        .rst_n(rst_n),
        .rs1_addr(rs1_addr),
        .rs2_addr(rs2_addr),
        .rd_addr(rd_addr),
        .rd_data(rd_data),
        .rd_wen(rd_wen),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data)
    );

    // ALU
    alu alu_inst (
        .operand_a(alu_operand_a),
        .operand_b(alu_operand_b),
        .alu_op(alu_op),
        .result(alu_result),
        .zero(alu_zero)
    );

    // Instruction Decoder
    decoder decoder_inst (
        .instruction(instruction),
        .opcode(opcode),
        .funct3(funct3),
        .funct7(funct7),
        .rs1_addr(rs1_addr),
        .rs2_addr(rs2_addr),
        .rd_addr(rd_addr),
        .immediate(immediate),
        // Control signals
        .alu_op(alu_op),
        .is_load(is_load),
        .is_store(is_store),
        .is_branch(is_branch),
        .is_jump(is_jump)
    );

    // Branch Unit
    branch_unit branch_inst (
        .rs1_data(rs1_data),
        .rs2_data(rs2_data),
        .funct3(funct3),
        .is_branch(is_branch),
        .is_jump(is_jump),
        .pc(pc),
        .immediate(immediate),
        .branch_taken(branch_taken),
        .branch_target(branch_target)
    );

    // Multiply/Divide Unit (M extension)
    mul_div mul_div_inst (
        .clk(clk),
        .rst_n(rst_n),
        .start(mul_div_start),
        .funct3(funct3),
        .operand_a(rs1_data),
        .operand_b(rs2_data),
        .result(mul_div_result),
        .done(mul_div_done)
    );

    // CSR File (for interrupts and system instructions)
    csr_file csr_inst (
        .clk(clk),
        .rst_n(rst_n),
        .csr_addr(instruction[31:20]),
        .csr_wdata(rs1_data),
        .csr_rdata(csr_rdata),
        .csr_we(csr_we),
        .interrupts(interrupts),
        .interrupt_taken(interrupt_taken),
        .trap_vector(trap_vector)
    );
    */

endmodule
