/**
 * @file regfile.v
 * @brief RISC-V Register File (32 registers, x0 = 0)
 *
 * The register file provides:
 * - 32 general-purpose registers (x0-x31)
 * - x0 is hardwired to 0 (reads always return 0, writes are ignored)
 * - Two read ports (for rs1, rs2)
 * - One write port (for rd)
 * - Synchronous writes, combinational reads
 *
 * This is typically the FIRST module you implement because:
 * - It's simple and self-contained
 * - Easy to test
 * - No dependencies on other modules
 * - Required by almost every instruction
 *
 * @author Custom RISC-V Core Team
 * @date 2025-12-03
 */

module regfile (
    input  wire        clk,
    input  wire        rst_n,

    // Read port 1 (rs1)
    input  wire [4:0]  rs1_addr,   // Register address to read
    output wire [31:0] rs1_data,   // Data read from register

    // Read port 2 (rs2)
    input  wire [4:0]  rs2_addr,   // Register address to read
    output wire [31:0] rs2_data,   // Data read from register

    // Write port (rd)
    input  wire [4:0]  rd_addr,    // Register address to write
    input  wire [31:0] rd_data,    // Data to write
    input  wire        rd_wen      // Write enable (1=write, 0=no write)
);

    //==========================================================================
    // Register Array
    //==========================================================================

    /**
     * Array of 32 registers (x0-x31)
     *
     * IMPORTANT: x0 is special!
     * - Always reads as 0
     * - Writes to x0 are ignored
     *
     * We only need to store x1-x31 (31 registers)
     * x0 is handled specially in the read logic
     */

    reg [31:0] registers [1:31];  // x1 to x31 (x0 not stored)

    //==========================================================================
    // Write Logic (Synchronous)
    //==========================================================================

    /**
     * TODO: Implement write logic
     *
     * On rising edge of clk:
     * - If rd_wen is 1 and rd_addr != 0:
     *   * Write rd_data to registers[rd_addr]
     * - If rd_addr == 0:
     *   * Ignore write (x0 is always 0)
     */

    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset all registers to 0
            for (i = 1; i < 32; i = i + 1) begin
                registers[i] <= 32'h0;
            end
        end else begin
            // TODO: Implement write logic here
            // Hint: Check rd_wen and rd_addr
        end
    end

    //==========================================================================
    // Read Logic (Combinational)
    //==========================================================================

    /**
     * TODO: Implement read logic
     *
     * rs1_data should be:
     * - 0 if rs1_addr == 0
     * - registers[rs1_addr] otherwise
     *
     * Same for rs2_data
     */

    assign rs1_data = 32'h0;  // TODO: Implement
    assign rs2_data = 32'h0;  // TODO: Implement

    //==========================================================================
    // IMPLEMENTATION HINTS
    //==========================================================================

    /**
     * WRITE LOGIC HINT:
     *
     * always @(posedge clk or negedge rst_n) begin
     *     if (!rst_n) begin
     *         // Reset
     *     end else if (rd_wen && (rd_addr != 5'd0)) begin
     *         registers[rd_addr] <= rd_data;
     *     end
     * end
     */

    /**
     * READ LOGIC HINT:
     *
     * assign rs1_data = (rs1_addr == 5'd0) ? 32'h0 : registers[rs1_addr];
     * assign rs2_data = (rs2_addr == 5'd0) ? 32'h0 : registers[rs2_addr];
     */

    /**
     * TESTING:
     *
     * 1. Write some values to different registers
     * 2. Read them back and verify
     * 3. Try writing to x0 and verify it stays 0
     * 4. Try reading x0 and verify it returns 0
     *
     * Example testbench:
     *   rd_addr = 5; rd_data = 32'hDEADBEEF; rd_wen = 1; // Write to x5
     *   @(posedge clk);
     *   rd_wen = 0;
     *   rs1_addr = 5; // Read x5
     *   // Verify rs1_data == 32'hDEADBEEF
     */

endmodule
