/**
 * @file custom_core_wrapper.v
 * @brief Wrapper for Custom RV32IM Core - DROP-IN Replacement for VexRiscv
 *
 * This module wraps the custom RISC-V core to provide the EXACT SAME
 * Wishbone interface as vexriscv_wrapper.v, making it a drop-in replacement.
 *
 * IMPLEMENTATION STATUS: TEMPLATE/PLACEHOLDER
 *
 * TODO: Implement this module according to DROP_IN_REPLACEMENT_GUIDE.md
 *
 * The wrapper connects your custom core (which can use cmd/rsp or native
 * Wishbone) to the SoC's Wishbone buses. All peripherals, memory, and
 * firmware will work unchanged once you implement this wrapper.
 *
 * See: docs/DROP_IN_REPLACEMENT_GUIDE.md for complete implementation details
 *
 * @author Custom RISC-V Core Team
 * @date 2025-12-03
 * @version 0.1 - Template/Placeholder
 */

module custom_core_wrapper (
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
    // PLACEHOLDER IMPLEMENTATION
    //==========================================================================

    /**
     * This is a PLACEHOLDER to allow the SoC to compile.
     *
     * TO IMPLEMENT YOUR CUSTOM CORE:
     *
     * 1. Review docs/DROP_IN_REPLACEMENT_GUIDE.md
     * 2. Decide on approach:
     *    - Approach 1: Core with cmd/rsp interface (match VexRiscv exactly)
     *    - Approach 2: Core with native Wishbone (cleaner design)
     * 3. Implement custom_riscv_core.v (in this directory)
     * 4. Replace this placeholder with real wrapper (see guide for template)
     * 5. Add Zpec custom instructions to your core
     * 6. Test with existing peripherals and firmware
     *
     * The guide provides:
     * - Complete VexRiscv interface analysis
     * - Full wrapper template with examples
     * - Zpec instruction specifications
     * - Week-by-week implementation roadmap
     * - Testing strategies
     */

    // For now, tie off outputs to prevent synthesis errors
    assign ibus_addr = 32'h0;
    assign ibus_cyc = 1'b0;
    assign ibus_stb = 1'b0;

    assign dbus_addr = 32'h0;
    assign dbus_dat_o = 32'h0;
    assign dbus_we = 1'b0;
    assign dbus_sel = 4'h0;
    assign dbus_cyc = 1'b0;
    assign dbus_stb = 1'b0;

    // Synthesis-time warning
    // synthesis translate_off
    initial begin
        $display("");
        $display("=================================================================");
        $display("WARNING: custom_core_wrapper is a PLACEHOLDER!");
        $display("=================================================================");
        $display("This module needs to be implemented with your custom RV32IM core.");
        $display("");
        $display("See: 02-embedded/riscv/docs/DROP_IN_REPLACEMENT_GUIDE.md");
        $display("     for complete implementation instructions.");
        $display("");
        $display("The guide includes:");
        $display("  - VexRiscv interface specification");
        $display("  - Complete wrapper template");
        $display("  - Zpec custom instruction designs");
        $display("  - Step-by-step implementation roadmap");
        $display("=================================================================");
        $display("");
    end
    // synthesis translate_on

    //==========================================================================
    // UNCOMMENT WHEN IMPLEMENTING:
    //==========================================================================

    /*
    // Reset polarity conversion
    wire reset = !rst_n;

    // Custom core native signals
    wire        core_ibus_cmd_valid;
    wire        core_ibus_cmd_ready;
    wire [31:0] core_ibus_cmd_payload_pc;
    wire        core_ibus_rsp_valid;
    wire        core_ibus_rsp_payload_error;
    wire [31:0] core_ibus_rsp_payload_inst;

    wire        core_dbus_cmd_valid;
    wire        core_dbus_cmd_ready;
    wire        core_dbus_cmd_payload_wr;
    wire [3:0]  core_dbus_cmd_payload_mask;
    wire [31:0] core_dbus_cmd_payload_address;
    wire [31:0] core_dbus_cmd_payload_data;
    wire [1:0]  core_dbus_cmd_payload_size;
    wire        core_dbus_rsp_ready;
    wire        core_dbus_rsp_error;
    wire [31:0] core_dbus_rsp_data;

    // Custom core instantiation
    custom_riscv_core #(
        .RESET_VECTOR(32'h00000000)
    ) cpu (
        .clk(clk),
        .reset(reset),

        // Instruction bus (cmd/rsp)
        .iBus_cmd_valid(core_ibus_cmd_valid),
        .iBus_cmd_ready(core_ibus_cmd_ready),
        .iBus_cmd_payload_pc(core_ibus_cmd_payload_pc),
        .iBus_rsp_valid(core_ibus_rsp_valid),
        .iBus_rsp_payload_error(core_ibus_rsp_payload_error),
        .iBus_rsp_payload_inst(core_ibus_rsp_payload_inst),

        // Data bus (cmd/rsp)
        .dBus_cmd_valid(core_dbus_cmd_valid),
        .dBus_cmd_ready(core_dbus_cmd_ready),
        .dBus_cmd_payload_wr(core_dbus_cmd_payload_wr),
        .dBus_cmd_payload_mask(core_dbus_cmd_payload_mask),
        .dBus_cmd_payload_address(core_dbus_cmd_payload_address),
        .dBus_cmd_payload_data(core_dbus_cmd_payload_data),
        .dBus_cmd_payload_size(core_dbus_cmd_payload_size),
        .dBus_rsp_ready(core_dbus_rsp_ready),
        .dBus_rsp_error(core_dbus_rsp_error),
        .dBus_rsp_data(core_dbus_rsp_data),

        // Interrupts
        .timerInterrupt(1'b0),
        .externalInterrupt(|external_interrupt),
        .softwareInterrupt(1'b0)
    );

    // cmd/rsp to Wishbone adapters
    // See DROP_IN_REPLACEMENT_GUIDE.md for complete implementation
    */

endmodule
