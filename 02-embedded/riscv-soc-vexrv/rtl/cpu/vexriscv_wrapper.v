/**
 * @file vexriscv_wrapper.v
 * @brief Wrapper for VexRiscv RISC-V Core with Wishbone Bus Adapters
 *
 * This module wraps the VexRiscv RISC-V core and provides:
 * - VexRiscv cmd/rsp to Wishbone bus conversion (ibus + dbus)
 * - Interrupt handling
 * - Reset polarity conversion (active-low to active-high)
 *
 * VexRiscv Bus Protocol:
 * ----------------------
 * VexRiscv uses a simple cmd/rsp handshaking protocol, NOT Wishbone:
 *
 * Instruction Bus (iBus):
 *   - cmd: valid/ready handshake with PC address
 *   - rsp: valid signal with instruction data
 *
 * Data Bus (dBus):
 *   - cmd: valid/ready handshake with wr, mask, address, data
 *   - rsp: ready signal with response data and error
 *
 * This wrapper converts these to standard Wishbone B4 pipelined protocol
 * for compatibility with the rest of the SoC.
 *
 * Bus Architecture Decision:
 * --------------------------
 * We use Wishbone throughout the SoC because:
 * 1. Industry standard, well-documented
 * 2. All peripherals already use Wishbone
 * 3. ASIC-ready and silicon-proven
 * 4. Easier portability for Stage 5-6 (RISC-V ASIC)
 *
 * VexRiscv Configuration:
 * -----------------------
 * - ISA: RV32IMC (multiply, divide, compressed instructions)
 * - Bus: Simple cmd/rsp (converted to Wishbone here)
 * - Pipeline: 5-stage (Fetch, Decode, Execute, Memory, Writeback)
 * - Size: ~1,500 LUTs on FPGA
 * - Performance: ~1.5 DMIPS/MHz
 * - ASIC-proven: Taped out in 180nm, 130nm, and advanced nodes
 *
 * @author RISC-V SoC Team
 * @date 2024-11-16
 * @version 2.0 - Full VexRiscv integration with bus adapters
 */

module vexriscv_wrapper (
    input  wire        clk,
    input  wire        rst_n,

    // Wishbone Instruction Bus (master)
    output wire [31:0] ibus_addr,
    output wire        ibus_cyc,
    output wire        ibus_stb,
    input  wire        ibus_ack,
    input  wire [31:0] ibus_dat_i,

    // Wishbone Data Bus (master)
    output wire [31:0] dbus_addr,
    output wire [31:0] dbus_dat_o,
    input  wire [31:0] dbus_dat_i,
    output wire        dbus_we,
    output wire [3:0]  dbus_sel,
    output wire        dbus_cyc,
    output wire        dbus_stb,
    input  wire        dbus_ack,
    input  wire        dbus_err,

    // Interrupts
    input  wire [31:0] external_interrupt
);

    //==========================================================================
    // Reset Conversion
    //==========================================================================

    // VexRiscv uses active-high reset, we use active-low
    wire reset = !rst_n;

    //==========================================================================
    // VexRiscv Native Bus Signals
    //==========================================================================

    // Instruction Bus (cmd/rsp protocol)
    wire        vex_ibus_cmd_valid;
    wire        vex_ibus_cmd_ready;
    wire [31:0] vex_ibus_cmd_payload_pc;
    wire        vex_ibus_rsp_valid;
    wire        vex_ibus_rsp_payload_error;
    wire [31:0] vex_ibus_rsp_payload_inst;

    // Data Bus (cmd/rsp protocol)
    wire        vex_dbus_cmd_valid;
    wire        vex_dbus_cmd_ready;
    wire        vex_dbus_cmd_payload_wr;
    wire [3:0]  vex_dbus_cmd_payload_mask;
    wire [31:0] vex_dbus_cmd_payload_address;
    wire [31:0] vex_dbus_cmd_payload_data;
    wire [1:0]  vex_dbus_cmd_payload_size;
    wire        vex_dbus_rsp_ready;
    wire        vex_dbus_rsp_error;
    wire [31:0] vex_dbus_rsp_data;

    //==========================================================================
    // VexRiscv Core Instantiation
    //==========================================================================

    VexRiscv cpu (
        .clk(clk),
        .reset(reset),

        // Instruction bus (native cmd/rsp interface)
        .iBus_cmd_valid(vex_ibus_cmd_valid),
        .iBus_cmd_ready(vex_ibus_cmd_ready),
        .iBus_cmd_payload_pc(vex_ibus_cmd_payload_pc),
        .iBus_rsp_valid(vex_ibus_rsp_valid),
        .iBus_rsp_payload_error(vex_ibus_rsp_payload_error),
        .iBus_rsp_payload_inst(vex_ibus_rsp_payload_inst),

        // Data bus (native cmd/rsp interface)
        .dBus_cmd_valid(vex_dbus_cmd_valid),
        .dBus_cmd_ready(vex_dbus_cmd_ready),
        .dBus_cmd_payload_wr(vex_dbus_cmd_payload_wr),
        .dBus_cmd_payload_mask(vex_dbus_cmd_payload_mask),
        .dBus_cmd_payload_address(vex_dbus_cmd_payload_address),
        .dBus_cmd_payload_data(vex_dbus_cmd_payload_data),
        .dBus_cmd_payload_size(vex_dbus_cmd_payload_size),
        .dBus_rsp_ready(vex_dbus_rsp_ready),
        .dBus_rsp_error(vex_dbus_rsp_error),
        .dBus_rsp_data(vex_dbus_rsp_data),

        // Interrupts
        .timerInterrupt(1'b0),           // Use external timer peripheral
        .externalInterrupt(|external_interrupt),  // Any interrupt bit
        .softwareInterrupt(1'b0)          // Not used in this SoC
    );

    //==========================================================================
    // Instruction Bus: VexRiscv cmd/rsp to Wishbone Adapter
    //==========================================================================

    /**
     * VexRiscv iBus protocol:
     *   1. CPU asserts cmd_valid with PC
     *   2. Wait for cmd_ready (bus available)
     *   3. Bus responds with rsp_valid + instruction data
     *
     * Wishbone protocol:
     *   1. Master asserts CYC + STB with address
     *   2. Wait for ACK
     *   3. Data is valid when ACK is high
     *
     * Conversion: Simple state machine to bridge the two protocols
     */

    reg ibus_active;  // Wishbone transaction in progress

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            ibus_active <= 1'b0;
        end else begin
            if (vex_ibus_cmd_valid && !ibus_active) begin
                // Start new Wishbone transaction
                ibus_active <= 1'b1;
            end else if (ibus_ack) begin
                // Wishbone transaction complete
                ibus_active <= 1'b0;
            end
        end
    end

    // Wishbone outputs
    assign ibus_addr = vex_ibus_cmd_payload_pc;
    assign ibus_cyc  = ibus_active;
    assign ibus_stb  = ibus_active;

    // VexRiscv inputs
    assign vex_ibus_cmd_ready = !ibus_active;  // Ready when no transaction active
    assign vex_ibus_rsp_valid = ibus_ack;      // Response valid when ack
    assign vex_ibus_rsp_payload_inst = ibus_dat_i;
    assign vex_ibus_rsp_payload_error = 1'b0;  // No error support on ibus

    //==========================================================================
    // Data Bus: VexRiscv cmd/rsp to Wishbone Adapter
    //==========================================================================

    /**
     * VexRiscv dBus protocol:
     *   1. CPU asserts cmd_valid with wr, mask, address, data
     *   2. Wait for cmd_ready
     *   3. CPU asserts rsp_ready to accept response
     *   4. Bus provides rsp_data and rsp_error
     *
     * Wishbone protocol:
     *   1. Master asserts CYC + STB + WE with address, data, sel
     *   2. Wait for ACK
     *   3. Data/error valid when ACK is high
     *
     * Conversion: State machine for proper handshaking
     */

    reg dbus_active;  // Wishbone transaction in progress

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            dbus_active <= 1'b0;
        end else begin
            if (vex_dbus_cmd_valid && !dbus_active) begin
                // Start new Wishbone transaction
                dbus_active <= 1'b1;
            end else if (dbus_ack || dbus_err) begin
                // Wishbone transaction complete
                dbus_active <= 1'b0;
            end
        end
    end

    // Wishbone outputs
    assign dbus_addr   = vex_dbus_cmd_payload_address;
    assign dbus_dat_o  = vex_dbus_cmd_payload_data;
    assign dbus_we     = vex_dbus_cmd_payload_wr;
    assign dbus_sel    = vex_dbus_cmd_payload_mask;
    assign dbus_cyc    = dbus_active;
    assign dbus_stb    = dbus_active;

    // VexRiscv inputs
    assign vex_dbus_cmd_ready = !dbus_active;   // Ready when no transaction active
    assign vex_dbus_rsp_ready = dbus_ack || dbus_err;  // Response when ack or error
    assign vex_dbus_rsp_data  = dbus_dat_i;
    assign vex_dbus_rsp_error = dbus_err;

    //==========================================================================
    // Debug/Verification (optional, can be removed for production)
    //==========================================================================

    // Synthesis-time checks (removed by synthesis tools)
    // synthesis translate_off
    always @(posedge clk) begin
        if (ibus_cyc && ibus_ack) begin
//             $display("[IBUS] PC=0x%08x INST=0x%08x", ibus_addr, ibus_dat_i);
        end
        if (dbus_cyc && dbus_ack) begin
            if (dbus_we)
                $display("[DBUS] WRITE ADDR=0x%08x DATA=0x%08x SEL=%b",
                         dbus_addr, dbus_dat_o, dbus_sel);
            else
                $display("[DBUS] READ  ADDR=0x%08x DATA=0x%08x",
                         dbus_addr, dbus_dat_i);
        end
    end
    // synthesis translate_on

endmodule
