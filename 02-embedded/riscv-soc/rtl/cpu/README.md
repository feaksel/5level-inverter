# VexRiscv CPU Integration

This directory contains the wrapper for the **VexRiscv RISC-V CPU core**.

## ⚠️ Important: VexRiscv Core Not Included

The VexRiscv core itself is **not included** in this repository. You must obtain it separately.

---

## What is VexRiscv?

**VexRiscv** is an open-source RISC-V CPU core written in SpinalHDL (Scala-based HDL).

**Key Features:**
- **ISA**: RV32I/M/C (configurable)
- **Pipeline**: 5-stage (Fetch, Decode, Execute, Memory, Writeback)
- **Size**: ~1,500 LUTs (FPGA), ~20K gates (ASIC)
- **Performance**: 1.5 DMIPS/MHz
- **Bus**: Wishbone, AXI4, or Avalon
- **License**: MIT (fully open-source)
- **ASIC-proven**: Successfully taped out in multiple projects

**Repository**: https://github.com/SpinalHDL/VexRiscv

---

## How to Obtain VexRiscv

### Option 1: Download Pre-built Core (Easiest)

1. Go to VexRiscv GitHub releases: https://github.com/SpinalHDL/VexRiscv/releases
2. Download a pre-built Verilog file (e.g., `VexRiscv.v`)
3. Copy to this directory:
   ```bash
   cp /path/to/VexRiscv.v 02-embedded/riscv-soc/rtl/cpu/
   ```

### Option 2: Generate Custom Core (Recommended)

**Requirements:**
- Java 8 or later
- SBT (Scala Build Tool)
- Git

**Steps:**

1. **Install SpinalHDL**:
   ```bash
   # Install SBT (Scala Build Tool)
   # On Ubuntu/Debian:
   sudo apt-get install sbt

   # On macOS:
   brew install sbt
   ```

2. **Clone VexRiscv repository**:
   ```bash
   cd /tmp
   git clone https://github.com/SpinalHDL/VexRiscv.git
   cd VexRiscv
   ```

3. **Generate the core** (choose one):

   **A) Smallest configuration** (minimal features):
   ```bash
   sbt "runMain vexriscv.demo.GenSmallest"
   ```

   **B) RV32IMC configuration** (recommended for this project):
   ```bash
   sbt "runMain vexriscv.demo.GenCustom --iCacheSize=4096 --dCacheSize=4096 --mulDiv=true --singleCycleMulDiv=false --bypass=true --prediction=dynamic --outputFile=VexRiscv_IMC.v"
   ```

   **C) Full-featured configuration**:
   ```bash
   sbt "runMain vexriscv.demo.GenFull"
   ```

4. **Copy generated Verilog**:
   ```bash
   cp VexRiscv*.v /path/to/5level-inverter/02-embedded/riscv-soc/rtl/cpu/
   ```

---

## Recommended Configuration for This SoC

For the 5-level inverter control system, use:

**ISA**: RV32IMC
- **I**: Integer base instruction set
- **M**: Multiply/divide extension (for control algorithms)
- **C**: Compressed instructions (reduces code size by ~30%)

**Bus**: Wishbone
- Required for integration with our SoC

**Features**:
- Instruction cache: 4 KB
- Data cache: 4 KB (optional)
- Hardware multiply/divide
- External interrupt support
- 5-stage pipeline

**Generation command**:
```bash
sbt "runMain vexriscv.demo.GenCustom \
  --iCacheSize=4096 \
  --dCacheSize=0 \
  --mulDiv=true \
  --singleCycleMulDiv=false \
  --bypass=true \
  --prediction=dynamic \
  --outputFile=VexRiscv_IMC_WB.v"
```

---

## Integration Steps

Once you have `VexRiscv.v`:

1. **Copy to this directory**:
   ```bash
   cp VexRiscv.v 02-embedded/riscv-soc/rtl/cpu/
   ```

2. **Edit `vexriscv_wrapper.v`**:
   - Open `vexriscv_wrapper.v`
   - Replace the stub implementation with actual VexRiscv instantiation
   - Match port names to your generated core (check VexRiscv.v)

3. **Update Vivado project**:
   - Add `VexRiscv.v` to project sources
   - Re-run synthesis

4. **Test**:
   - Run simulation testbench
   - Verify firmware execution

---

## VexRiscv Port Names (Reference)

Port names vary by configuration. Common Wishbone ports:

**Instruction Bus (iBus)**:
- `iBusWishbone_ADR[31:0]` - Address
- `iBusWishbone_DAT_MISO[31:0]` - Data input
- `iBusWishbone_CYC` - Cycle
- `iBusWishbone_STB` - Strobe
- `iBusWishbone_ACK` - Acknowledge
- `iBusWishbone_WE` - Write enable (always 0 for instruction fetch)
- `iBusWishbone_SEL[3:0]` - Byte select

**Data Bus (dBus)**:
- `dBusWishbone_ADR[31:0]` - Address
- `dBusWishbone_DAT_MISO[31:0]` - Data input
- `dBusWishbone_DAT_MOSI[31:0]` - Data output
- `dBusWishbone_CYC` - Cycle
- `dBusWishbone_STB` - Strobe
- `dBusWishbone_ACK` - Acknowledge
- `dBusWishbone_WE` - Write enable
- `dBusWishbone_SEL[3:0]` - Byte select
- `dBusWishbone_ERR` - Error

**Other**:
- `clk` - Clock input
- `reset` - Reset (active HIGH)
- `externalInterrupt` - External interrupt input
- `timerInterrupt` - Timer interrupt
- `softwareInterrupt` - Software interrupt

---

## ASIC Considerations

VexRiscv is **ASIC-ready** and has been used in multiple tape-outs:

**Known Tape-outs**:
- SaxonSoC (open-source SoC)
- Various university projects
- Commercial products

**Technology Nodes**:
- 180nm: ~2.5 mm² die area
- 130nm: ~1.5 mm² die area
- 65nm and below: < 0.5 mm²

**Synthesis**:
- Works with standard cell libraries
- No FPGA-specific primitives (after proper configuration)
- Clean synthesis with Synopsys Design Compiler, Cadence Genus, Yosys

**Verification**:
- Extensive test suite included
- RISC-V compliance tests pass
- Formal verification support

**DFT** (Design for Test):
- Scan chain insertion supported
- Full DFT flow compatible

---

## Troubleshooting

### Issue: SBT fails to download dependencies

**Solution**: Check internet connection, configure proxy if needed:
```bash
export SBT_OPTS="-Dhttp.proxyHost=your.proxy.com -Dhttp.proxyPort=8080"
```

### Issue: Generated Verilog has syntax errors in Vivado

**Solution**:
- Ensure VexRiscv version is compatible
- Use `-D` flag for Verilog-2001 compatibility
- Check for SystemVerilog features (avoid if possible)

### Issue: Can't find VexRiscv ports in generated file

**Solution**:
- Open generated `VexRiscv.v` in text editor
- Search for `module VexRiscv`
- Port names are listed after module declaration
- Update `vexriscv_wrapper.v` accordingly

---

## Resources

- **VexRiscv GitHub**: https://github.com/SpinalHDL/VexRiscv
- **VexRiscv Documentation**: https://spinalhdl.github.io/VexRiscv/
- **SpinalHDL Documentation**: https://spinalhdl.github.io/SpinalDoc-RTD/
- **RISC-V Specification**: https://riscv.org/technical/specifications/

---

## Next Steps

After integrating VexRiscv:

1. **Compile firmware**: Write RISC-V C code in `firmware/` directory
2. **Generate hex file**: Use RISC-V GCC to compile firmware
3. **Initialize ROM**: Load firmware.hex into ROM module
4. **Simulate**: Run Vivado behavioral simulation
5. **Synthesize**: Build FPGA bitstream
6. **Test on hardware**: Program Basys 3 board

See `01-IMPLEMENTATION-GUIDE.md` for complete instructions.

---

**Last Updated**: 2025-11-16
**Status**: Awaiting VexRiscv integration
