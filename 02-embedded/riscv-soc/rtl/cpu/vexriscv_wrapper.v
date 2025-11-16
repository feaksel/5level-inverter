/**
 * @file vexriscv_wrapper.v
 * @brief Wrapper for VexRiscv RISC-V Core
 *
 * This module wraps the VexRiscv RISC-V core and provides:
 * - Wishbone bus interface conversion
 * - Interrupt handling
 * - Reset management
 *
 * IMPORTANT: You must obtain the VexRiscv core separately!
 *
 * VexRiscv is a RISC-V core written in SpinalHDL (Scala).
 * To generate the Verilog for VexRiscv:
 *
 * 1. Install SpinalHDL (requires Java and SBT):
 *    https://github.com/SpinalHDL/SpinalHDL
 *
 * 2. Clone VexRiscv repository:
 *    git clone https://github.com/SpinalHDL/VexRiscv.git
 *
 * 3. Generate the core (recommended configuration):
 *    cd VexRiscv
 *    sbt "runMain vexriscv.demo.GenSmallest"
 *
 *    This generates: VexRiscv.v (or use GenCustom for specific config)
 *
 * 4. For this SoC, use configuration with:
 *    - RV32IMC (multiply, divide, compressed instructions)
 *    - Wishbone bus interface
 *    - External interrupt support
 *    - 5-stage pipeline
 *
 * 5. Copy generated VexRiscv.v to this directory:
 *    cp VexRiscv.v 02-embedded/riscv-soc/rtl/cpu/
 *
 * Alternative: Pre-built cores
 * - Download from VexRiscv releases (GitHub)
 * - Use community configurations
 *
 * Configuration Used:
 * ------------------
 * - ISA: RV32IMC
 * - Bus: Wishbone (instruction + data)
 * - Pipeline: 5-stage (Fetch, Decode, Execute, Memory, Writeback)
 * - Features: Hardware multiply/divide, compressed instructions
 * - Size: ~1,500 LUTs on FPGA
 * - Performance: ~1.5 DMIPS/MHz
 * - Interrupts: External interrupt input
 *
 * For ASIC: VexRiscv has been successfully taped out in multiple
 * projects. The core is proven in 180nm, 130nm, and advanced nodes.
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
    // VexRiscv Core Instantiation
    //==========================================================================

    /**
     * PLACEHOLDER: VexRiscv core instantiation
     *
     * Once you have generated VexRiscv.v, instantiate it here.
     * The exact port names depend on your VexRiscv configuration.
     *
     * Typical VexRiscv ports (Wishbone variant):
     *
     * VexRiscv cpu (
     *     .clk(clk),
     *     .reset(!rst_n),  // VexRiscv uses active-high reset
     *
     *     // Instruction bus
     *     .iBusWishbone_ADR(ibus_addr),
     *     .iBusWishbone_DAT_MISO(ibus_dat_i),
     *     .iBusWishbone_DAT_MOSI(),  // Not used for instruction fetch
     *     .iBusWishbone_SEL(4'hF),
     *     .iBusWishbone_CYC(ibus_cyc),
     *     .iBusWishbone_STB(ibus_stb),
     *     .iBusWishbone_ACK(ibus_ack),
     *     .iBusWishbone_WE(1'b0),    // Read-only
     *     .iBusWishbone_ERR(1'b0),
     *
     *     // Data bus
     *     .dBusWishbone_ADR(dbus_addr),
     *     .dBusWishbone_DAT_MISO(dbus_dat_i),
     *     .dBusWishbone_DAT_MOSI(dbus_dat_o),
     *     .dBusWishbone_SEL(dbus_sel),
     *     .dBusWishbone_CYC(dbus_cyc),
     *     .dBusWishbone_STB(dbus_stb),
     *     .dBusWishbone_ACK(dbus_ack),
     *     .dBusWishbone_WE(dbus_we),
     *     .dBusWishbone_ERR(dbus_err),
     *
     *     // Interrupts
     *     .externalInterrupt(|external_interrupt),
     *     .timerInterrupt(1'b0),      // Use external timer
     *     .softwareInterrupt(1'b0)
     * );
     */

    //==========================================================================
    // TEMPORARY: Stub Implementation for Synthesis
    //==========================================================================

    /**
     * This stub allows the SoC to synthesize without VexRiscv.
     * Replace this entire section once you have VexRiscv.v
     *
     * REMOVE THIS SECTION WHEN INTEGRATING ACTUAL VexRiscv!
     */

    // Instruction bus - just read from address 0
    assign ibus_addr = 32'h0000_0000;
    assign ibus_cyc  = 1'b1;
    assign ibus_stb  = 1'b1;

    // Data bus - idle
    assign dbus_addr   = 32'h0;
    assign dbus_dat_o  = 32'h0;
    assign dbus_we     = 1'b0;
    assign dbus_sel    = 4'h0;
    assign dbus_cyc    = 1'b0;
    assign dbus_stb    = 1'b0;

    /**
     * END OF STUB - REMOVE WHEN ADDING REAL VexRiscv
     */

endmodule
