# RISC-V SoC Implementation Guide for Basys 3

**Document Type:** Implementation and Build Guide
**Project:** 5-Level Inverter RISC-V SoC
**Target Hardware:** Digilent Basys 3 (Artix-7 XC7A35T)
**Tools:** Vivado 2020.2+ (WebPACK), RISC-V GCC Toolchain
**Author:** 5-Level Inverter Project
**Date:** 2025-11-15
**Version:** 1.0

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Tool Installation](#tool-installation)
3. [Project Structure](#project-structure)
4. [Building the SoC](#building-the-soc)
5. [Simulation Workflow](#simulation-workflow)
6. [FPGA Implementation](#fpga-implementation)
7. [Hardware Testing](#hardware-testing)
8. [Debugging Guide](#debugging-guide)
9. [ASIC Flow (Future)](#asic-flow-future)
10. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Hardware Requirements

**Essential:**
- **Digilent Basys 3 Board** (Artix-7 XC7A35T-1CPG236C)
- USB cable (for programming and power)
- Host computer (Windows, Linux, or macOS)

**For Full System Testing:**
- Gate driver board (IR2110 × 4)
- Power MOSFETs (8×)
- Power supplies (50V DC × 2)
- Oscilloscope (≥ 2 channels, 100 MHz)
- Logic analyzer (optional, for debugging)

**Recommended:**
- PMOD cables for clean connections
- USB-UART adapter (for debug output)
- Bench power supply (for low-voltage testing)

---

### Software Requirements

**Required:**
1. **Vivado ML Edition 2020.2 or later** (WebPACK is free)
   - Download: https://www.xilinx.com/support/download.html
   - Size: ~35 GB installed
   - License: Free WebPACK (includes Artix-7 support)

2. **RISC-V GCC Toolchain**
   - For compiling firmware
   - Install instructions below

3. **Git** (for version control)

**Optional but Recommended:**
4. **GTKWave** (waveform viewer)
5. **VS Code** or text editor with Verilog support
6. **PuTTY** or `screen` (for UART terminal)

---

## Tool Installation

### 1. Installing Vivado (Linux)

```bash
# Download Vivado from Xilinx website (35 GB)
wget https://www.xilinx.com/member/forms/download/xef.html?filename=Xilinx_Unified_2023.2_1013_2256_Lin64.bin

# Make executable and run installer
chmod +x Xilinx_Unified_2023.2_1013_2256_Lin64.bin
./Xilinx_Unified_2023.2_1013_2256_Lin64.bin

# During installation:
# - Select "Vivado ML Enterprise" or "Vivado ML Standard" (WebPACK)
# - Include Artix-7 device support
# - Install to /tools/Xilinx (default)

# Add to PATH (add to ~/.bashrc)
export PATH="/tools/Xilinx/Vivado/2023.2/bin:$PATH"
source /tools/Xilinx/Vivado/2023.2/settings64.sh
```

**Windows Installation:**
- Run installer executable
- Follow GUI wizard
- Select WebPACK edition
- Install cable drivers when prompted

---

### 2. Installing RISC-V GCC Toolchain

**Pre-built Binaries (Easiest):**

```bash
# Ubuntu/Debian
sudo apt install gcc-riscv64-unknown-elf

# Or download SiFive prebuilt toolchain
wget https://github.com/sifive/freedom-tools/releases/download/v2020.12.0/riscv64-unknown-elf-toolchain-10.2.0-2020.12.8-x86_64-linux-ubuntu14.tar.gz
tar -xzf riscv64-unknown-elf-toolchain-10.2.0-2020.12.8-x86_64-linux-ubuntu14.tar.gz
export PATH="$PWD/riscv64-unknown-elf-toolchain-10.2.0-2020.12.8-x86_64-linux-ubuntu14/bin:$PATH"
```

**Building from Source (Alternative):**

```bash
git clone https://github.com/riscv/riscv-gnu-toolchain
cd riscv-gnu-toolchain
./configure --prefix=/opt/riscv --with-arch=rv32imc --with-abi=ilp32
make -j$(nproc)
export PATH="/opt/riscv/bin:$PATH"
```

**Verify Installation:**
```bash
riscv64-unknown-elf-gcc --version
# Should show: gcc (GCC) 10.2.0 or similar
```

---

### 3. Installing Supporting Tools

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install -y \
    make \
    git \
    gtkwave \
    picocom \
    python3 \
    python3-pip

# Optional: Icarus Verilog (for open-source simulation)
sudo apt install iverilog

# Optional: Verilator (for fast simulation)
sudo apt install verilator
```

---

## Project Structure

```
02-embedded/riscv-soc/
│
├── 00-RISCV-SOC-ARCHITECTURE.md    # Architecture specification
├── 01-IMPLEMENTATION-GUIDE.md       # This file
│
├── rtl/                             # Verilog RTL source code
│   ├── soc_top.v                   # Top-level SoC
│   ├── vexriscv_wrapper.v          # VexRiscv integration
│   ├── memory/
│   │   ├── rom_32kb.v              # Firmware ROM
│   │   └── ram_64kb.v              # Data RAM
│   ├── peripherals/
│   │   ├── pwm_accelerator.v       # PWM peripheral
│   │   ├── adc_interface.v         # ADC peripheral
│   │   ├── protection.v            # Fault protection
│   │   ├── uart.v                  # Debug UART
│   │   ├── timer.v                 # System timer
│   │   └── gpio.v                  # GPIO controller
│   ├── bus/
│   │   └── wishbone_interconnect.v # Bus arbiter
│   └── utils/
│       ├── carrier_generator.v      # From Track 2
│       ├── pwm_comparator.v         # From Track 2
│       └── sine_generator.v         # From Track 2
│
├── tb/                              # Testbenches
│   ├── soc_tb.v                    # Full SoC testbench
│   ├── pwm_accelerator_tb.v
│   ├── adc_interface_tb.v
│   └── ...
│
├── constraints/
│   └── basys3.xdc                  # Basys 3 pin constraints
│
├── vivado/                          # Vivado-specific files
│   ├── create_project.tcl          # Project creation script
│   ├── build.tcl                   # Synthesis & implementation
│   ├── sim.tcl                     # Simulation script
│   └── program.tcl                 # FPGA programming
│
├── sim/                             # Open-source simulation
│   ├── Makefile                    # Icarus Verilog build
│   └── run_sim.sh                  # Simulation runner
│
├── firmware/                        # RISC-V firmware (C code)
│   ├── src/
│   │   ├── main.c                  # Entry point
│   │   ├── startup.S               # Assembly startup
│   │   ├── peripherals.c           # Hardware drivers
│   │   ├── pr_controller.c         # Control algorithm
│   │   └── ...
│   ├── include/
│   │   ├── soc.h                   # Register definitions
│   │   ├── peripherals.h
│   │   └── ...
│   ├── linker.ld                   # Linker script
│   ├── Makefile                    # Firmware build
│   └── firmware.hex                # Compiled hex file
│
├── prebuilt/
│   └── VexRiscv.v                  # Pre-generated RISC-V core
│
├── scripts/
│   ├── generate_rom.py             # Convert .hex to ROM init
│   └── uart_monitor.py             # UART debug monitor
│
├── docs/
│   ├── register_map.md             # Peripheral registers
│   └── memory_map.md               # Address space
│
└── Makefile                         # Top-level build system
```

---

## Building the SoC

### Quick Start (TL;DR)

```bash
# 1. Clone and enter project
cd 02-embedded/riscv-soc

# 2. Build firmware
cd firmware
make clean all
cd ..

# 3. Create Vivado project
make vivado-project

# 4. Synthesize and implement
make vivado-build

# 5. Program FPGA
make vivado-program

# 6. Monitor UART output
make uart-monitor
```

---

### Step-by-Step Build Process

#### Step 1: Compile Firmware

The firmware must be compiled FIRST because it's embedded in the ROM during synthesis.

```bash
cd firmware/

# Clean previous builds
make clean

# Compile firmware
make all

# This creates:
# - firmware.elf  (ELF executable)
# - firmware.bin  (raw binary)
# - firmware.hex  (hex format for ROM initialization)
# - firmware.dis  (disassembly for debugging)

# Verify hex file was created
ls -lh firmware.hex
# Should be ~32KB
```

**Firmware Build Flags:**
```makefile
ARCH = rv32imc          # RISC-V architecture
ABI = ilp32             # Integer calling convention
CFLAGS = -O2 -g         # Optimize, include debug symbols
LDFLAGS = -T linker.ld  # Use custom linker script
```

---

#### Step 2: Create Vivado Project

```bash
cd ..  # Back to riscv-soc/

# Option A: Using Makefile (easiest)
make vivado-project

# Option B: Manual Vivado TCL
vivado -mode batch -source vivado/create_project.tcl

# This creates:
# - vivado/inverter_soc/inverter_soc.xpr (Vivado project)
# - Adds all RTL sources
# - Sets top-level to soc_top
# - Configures for Basys 3 (xc7a35tcpg236-1)
```

**What the script does:**
```tcl
# vivado/create_project.tcl
create_project inverter_soc ./vivado/inverter_soc -part xc7a35tcpg236-1 -force

# Add RTL sources
add_files [glob rtl/*.v rtl/**/*.v]
add_files prebuilt/VexRiscv.v

# Add constraints
add_files -fileset constrs_1 constraints/basys3.xdc

# Add firmware (ROM initialization)
add_files -fileset sources_1 firmware/firmware.hex

# Set top module
set_property top soc_top [current_fileset]
```

---

#### Step 3: Run Synthesis

**Synthesis** converts Verilog to FPGA primitives (LUTs, FFs, BRAMs).

```bash
# Option A: Using Makefile
make vivado-synth

# Option B: Manual Vivado
vivado -mode batch -source vivado/build.tcl -tclargs synth

# Option C: Vivado GUI
vivado vivado/inverter_soc/inverter_soc.xpr
# Then: Flow Navigator → Synthesis → Run Synthesis
```

**Synthesis Output:**
```
Utilization Report:
  LUT:      4,287 / 20,800  (20%)
  FF:       2,134 / 41,600  (5%)
  BRAM:     21 / 50         (42%)
  DSP:      0 / 90          (0%)
```

**Check for Errors:**
- No critical warnings about undefined nets
- No timing issues (at this stage)
- Resource usage < 80% (you're way under!)

---

#### Step 4: Run Implementation

**Implementation** = Place & Route + Timing analysis.

```bash
# Option A: Makefile
make vivado-impl

# Option B: Vivado GUI
# Flow Navigator → Implementation → Run Implementation
```

**Timing Report (CRITICAL!):**
```
WNS (Worst Negative Slack): 2.345 ns   ← Must be POSITIVE
TNS (Total Negative Slack):  0.000 ns   ← Must be ZERO
WHS (Worst Hold Slack):      0.123 ns   ← Must be POSITIVE
```

**If timing fails:**
- Reduce clock frequency (change constraint to 40 MHz)
- Add pipeline stages
- Check long combinational paths

---

#### Step 5: Generate Bitstream

```bash
# Makefile
make vivado-bitstream

# Manual
vivado -mode batch -source vivado/build.tcl -tclargs bitstream

# Output: vivado/inverter_soc/inverter_soc.runs/impl_1/soc_top.bit
```

---

#### Step 6: Program Basys 3

**Connect Basys 3:**
1. Plug USB cable into Basys 3
2. Turn on power switch
3. LED LD17 should light up (FPGA powered)

**Program via Vivado:**
```bash
# Makefile (auto-detects board)
make vivado-program

# Manual
vivado -mode batch -source vivado/program.tcl
```

**Vivado Hardware Manager:**
```tcl
open_hw_manager
connect_hw_server
open_hw_target
current_hw_device [get_hw_devices xc7a35t_0]
set_property PROGRAM.FILE {soc_top.bit} [get_hw_devices xc7a35t_0]
program_hw_devices [get_hw_devices xc7a35t_0]
close_hw_manager
```

**Success Indicators:**
- "Programming successful" message
- DONE LED on Basys 3 lights up
- Your design is now running!

---

## Simulation Workflow

### Vivado Simulation (Behavioral)

**Test Individual Modules:**

```bash
# Simulate PWM accelerator
cd tb/
vivado -mode batch -source ../vivado/sim.tcl -tclargs pwm_accelerator_tb

# Or use GUI
vivado
# Add Sources → Add Simulation Sources → pwm_accelerator_tb.v
# Run → Run Simulation → Run Behavioral Simulation
```

**View Waveforms:**
- Vivado opens waveform viewer automatically
- Add signals to watch
- Zoom in/out with mouse wheel
- Measure timing with cursors

**Test Full SoC:**

```bash
# This simulates the entire SoC running firmware
vivado -mode batch -source vivado/sim.tcl -tclargs soc_tb

# Runtime: ~10 seconds of simulated time (can be slow!)
```

---

### Icarus Verilog Simulation (Faster, for ASIC)

```bash
cd sim/

# Compile and run
make sim MODULE=pwm_accelerator

# View waveforms
gtkwave pwm_accelerator.vcd &

# Full SoC simulation
make sim MODULE=soc_top
```

**Icarus Makefile:**
```makefile
iverilog -o $(MODULE).vvp \
    -I../rtl \
    ../tb/$(MODULE)_tb.v \
    ../rtl/**/*.v \
    ../prebuilt/VexRiscv.v

vvp $(MODULE).vvp
```

---

## FPGA Implementation

### Pin Mapping (Basys 3)

**Critical Connections:**

| SoC Signal | Basys 3 Pin | Component | Notes |
|------------|-------------|-----------|-------|
| `clk` | W5 | 100 MHz Clock | Onboard oscillator |
| `rst_n` | U18 | BTNU (button) | Active-low reset |
| `pwm_out[0]` | J1 | PMOD JA1 | To gate driver 1 HIN |
| `pwm_out[1]` | L2 | PMOD JA2 | To gate driver 1 LIN |
| `pwm_out[2]` | J2 | PMOD JA3 | To gate driver 2 HIN |
| `pwm_out[3]` | G2 | PMOD JA4 | To gate driver 2 LIN |
| `pwm_out[4]` | H1 | PMOD JA7 | To gate driver 3 HIN |
| `pwm_out[5]` | K2 | PMOD JA8 | To gate driver 3 LIN |
| `pwm_out[6]` | H2 | PMOD JA9 | To gate driver 4 HIN |
| `pwm_out[7]` | G3 | PMOD JA10 | To gate driver 4 LIN |
| `uart_tx` | A18 | USB-UART TX | Debug output |
| `uart_rx` | B18 | USB-UART RX | (optional) |
| `gpio_out[0]` | U16 | LED0 | Status LED |
| `gpio_out[1]` | E19 | LED1 | Fault LED |

**Constraint File:** `constraints/basys3.xdc`

---

### Clock Configuration

**Input:** 100 MHz onboard oscillator
**SoC Clock:** 50 MHz (divided by 2)

**In Verilog:**
```verilog
// Clock divider in soc_top.v
reg clk_50mhz;
always @(posedge clk_100mhz) begin
    clk_50mhz <= ~clk_50mhz;
end
```

**Or use Clocking Wizard IP:**
- Input: 100 MHz
- Output: 50 MHz (0° phase)
- Enables better timing performance

---

### Resource Optimization

**If you run out of resources:**

1. **Reduce ROM size:**
   - Change to 16 KB ROM
   - Optimize firmware (remove printf strings)

2. **Reduce RAM size:**
   - Change to 32 KB RAM
   - Sufficient for control loops

3. **Simplify peripherals:**
   - Remove UART if not needed
   - Use simpler PWM (no sine LUT)

4. **Use distributed RAM instead of BRAM:**
   ```verilog
   (* ram_style = "distributed" *) reg [31:0] ram_memory [0:4095];
   ```

---

## Hardware Testing

### Safety First!

**⚠️ WARNING: High voltage testing involves potentially lethal voltages!**

**Progressive Testing Strategy:**
1. FPGA-only testing (no power stage)
2. Gate driver testing (12V logic only)
3. Low-voltage power testing (12V DC bus)
4. Full-power testing (50V DC bus)

---

### Test 1: FPGA Validation (No External Hardware)

**Goal:** Verify FPGA programming and UART output

**Setup:**
1. Program Basys 3 with bitstream
2. Connect USB-UART adapter to PMOD pins
3. Open terminal (115200 baud)

**Expected Output:**
```
RISC-V Inverter Control v1.0
Initializing peripherals...
PWM: OK
ADC: OK
Protection: OK
Starting control loop...
[T=0.000s] MI=0.000, I=0.00A
[T=0.100s] MI=0.050, I=0.25A (soft-start)
[T=0.200s] MI=0.100, I=0.50A
...
```

**Commands:**
```bash
# Linux/Mac
screen /dev/ttyUSB0 115200

# Or use Python script
python3 scripts/uart_monitor.py /dev/ttyUSB0
```

---

### Test 2: PWM Output Verification

**Goal:** Verify 8× PWM signals with oscilloscope

**Setup:**
1. Connect oscilloscope probes to PMOD JA pins
2. GND to PMOD GND pin

**Measurements:**
- Channel 1: `pwm_out[0]` (H-bridge 1, S1 high-side)
- Channel 2: `pwm_out[1]` (H-bridge 1, S2 low-side)

**Expected Waveforms:**
- Frequency: 5 kHz (200 μs period)
- Duty cycle: Varies with sine reference
- Dead-time: ~1 μs gap between transitions
- Amplitude: 3.3V (FPGA logic level)

**Verification:**
```
✓ PWM frequency = 5 kHz ± 0.1%
✓ Dead-time ≥ 1 μs
✓ No overlap (both LOW during dead-time)
✓ Complementary signals (when one HIGH, other LOW)
```

---

### Test 3: Gate Driver Integration

**Setup:**
1. Build gate driver board (IR2110 × 4)
2. Connect FPGA PWM outputs to IR2110 inputs
3. Power IR2110 with +12V (Vcc) and +5V (Vdd)
4. **DO NOT connect MOSFETs yet**

**Measurements:**
- Measure IR2110 HO and LO outputs
- Should be 0-12V (not 0-3.3V anymore)

**Verification:**
```
✓ Gate driver outputs swing 0-12V
✓ Bootstrap capacitors charging properly
✓ Dead-time preserved through gate driver
```

---

### Test 4: Low-Voltage Power Stage Test

**Setup:**
1. Connect MOSFETs to gate drivers
2. Use **12V DC bus** (NOT 50V yet!)
3. Connect 10Ω / 25W resistive load
4. Current limit on bench PSU: 2A

**Measurements:**
- Output voltage with oscilloscope (AC coupled)
- Load current (should be < 2A)
- MOSFET temperatures (IR thermometer)

**Expected:**
- 5-level waveform visible
- Peak output voltage ≈ 12V
- No shoot-through (no current spikes)
- MOSFETs barely warm

---

### Test 5: Full-Power Test (50V DC bus)

**⚠️ EXTREME CAUTION REQUIRED!**

Only proceed after all previous tests pass.

**Setup:**
1. Use isolated 50V power supplies (Mean Well RSP-500-48 × 2)
2. Current limit: 5A per supply
3. Operator and observer present
4. E-stop button accessible

**Gradual Power-Up:**
1. Start at 20V DC bus → test → increase by 10V steps
2. Monitor temperatures continuously
3. Check for abnormal sounds or smells
4. Verify protection circuits functional

**Full-Power Test:**
- Output: 100V RMS AC, 50 Hz
- Load: 10Ω resistive (10A RMS)
- Measure THD with oscilloscope FFT
- Target: < 5% THD

---

## Debugging Guide

### Common Issues and Fixes

**Issue 1: FPGA won't program**
- **Symptom:** "Device not found" error
- **Fix:**
  - Check USB cable
  - Install Digilent Adept drivers
  - Try different USB port
  - Power-cycle Basys 3

**Issue 2: No UART output**
- **Symptom:** Terminal shows nothing
- **Fix:**
  - Check baud rate (must be 115200)
  - Verify TX/RX not swapped
  - Check pin constraints
  - Add LED toggle in firmware to verify CPU running

**Issue 3: PWM not toggling**
- **Symptom:** PWM pins stuck HIGH or LOW
- **Fix:**
  - Check enable bit in PWM peripheral
  - Verify clock is running (add counter LED)
  - Simulate in Vivado to check logic
  - Check for synthesis warnings

**Issue 4: Timing violations**
- **Symptom:** WNS negative in timing report
- **Fix:**
  - Reduce clock to 40 MHz
  - Add pipeline stages in critical paths
  - Check for combinational loops
  - Use timing constraints properly

**Issue 5: Shoot-through detected**
- **Symptom:** High current spikes, MOSFETs heating
- **Fix:**
  - Increase dead-time to 2 μs
  - Check gate driver logic
  - Verify complementary signals
  - Add hardware interlocks

---

### Debug Tools

**1. Internal Logic Analyzer (ILA):**

Add Vivado ILA IP to probe internal signals:

```tcl
# In Vivado
create_ip -name ila -vendor xilinx.com -library ip -version 6.2 -module_name ila_0

# Connect to signals you want to debug
# Re-synthesize and program FPGA
# Use Vivado Hardware Manager to view live signals
```

**2. UART Debug Prints:**

```c
// firmware/src/main.c
void debug_print_state(void) {
    uart_printf("PWM_CTRL: 0x%08X\n", PWM->CTRL);
    uart_printf("MI: %.3f\n", modulation_index);
    uart_printf("ADC[0]: %d\n", ADC->CH0_DATA);
}
```

**3. LED Indicators:**

```c
// Blink pattern for different states
GPIO->OUT = 0x0001;  // LED0: Running
GPIO->OUT = 0x0002;  // LED1: Fault
GPIO->OUT = 0x0003;  // LED0+1: Initializing
```

---

## ASIC Flow (Future)

Once you validate the design on FPGA, you can proceed to ASIC fabrication.

### Open-Source ASIC Flow

**Toolchain:**
1. **Yosys** - RTL synthesis
2. **OpenROAD** - Place & route
3. **Magic** - Layout viewer
4. **Netgen** - LVS (layout vs schematic)
5. **OpenLane** - Complete flow automation

**Process:**
```bash
# Install OpenLane (automated ASIC flow)
git clone https://github.com/The-OpenROAD-Project/OpenLane
cd OpenLane
make

# Prepare design
export PDK_ROOT=/path/to/skywater-pdk
export PDK=sky130A

# Run ASIC flow
make mount
flow.tcl -design inverter_soc -tag run1
```

**Timeline:**
- Synthesis: 1 hour
- Place & route: 4-8 hours
- Verification: 1-2 days
- Tape-out prep: 1-2 weeks

**Submission:**
- Efabless Open MPW shuttle (FREE, 2× per year)
- Or MOSIS/Europractice (university access, $1k-10k)

**Fabrication time:** 8-12 weeks
**Cost:** $0-10,000 depending on shuttle

---

## Troubleshooting

### Vivado Build Errors

**Error:** `[Synth 8-3295] timed out waiting for design to be available`
- **Cause:** Simulation lock file
- **Fix:** `File → Close Simulation`, then retry

**Error:** `[Place 30-494] The design is empty`
- **Cause:** Synthesis failed silently
- **Fix:** Check synthesis log for errors

**Error:** `[DRC NSTD-1] Unspecified I/O Standard`
- **Cause:** Missing IOSTANDARD in constraints
- **Fix:** Add `set_property IOSTANDARD LVCMOS33` to all I/O pins

---

### Firmware Issues

**Error:** `undefined reference to 'memset'`
- **Cause:** Missing C library functions
- **Fix:** Add newlib: `-lc -lm -lgcc` to linker flags

**Error:** Firmware too large for ROM
- **Cause:** Code + data > 32 KB
- **Fix:**
  - Enable optimization: `-O2` or `-Os`
  - Remove unused functions
  - Reduce string constants

**Error:** CPU not executing (stuck in reset)
- **Cause:** Bad linker script or reset vector
- **Fix:**
  - Check reset vector points to ROM (0x00000000)
  - Verify startup code loads correctly

---

## Performance Benchmarks

**Expected Results (Basys 3 @ 50 MHz):**

| Metric | Value |
|--------|-------|
| Control loop frequency | 10 kHz |
| PWM frequency | 5 kHz |
| ADC sampling rate | 10 kHz |
| CPU utilization | 40-60% |
| Worst-case interrupt latency | < 2 μs |
| UART throughput | ~11 KB/s |
| Power consumption (FPGA) | ~500 mW |

**Timing Performance:**

| Path | Requirement | Achieved |
|------|-------------|----------|
| Setup (WNS) | > 0 ns | +2.5 ns |
| Hold (WHS) | > 0 ns | +0.3 ns |
| Max frequency | 50 MHz | 52 MHz |

---

## Next Steps

After successful FPGA implementation:

1. **Validate Control Performance:**
   - Measure THD of AC output
   - Test step response
   - Verify current tracking

2. **Optimize Firmware:**
   - Profile CPU usage
   - Optimize PR controller
   - Add data logging

3. **Prepare for ASIC:**
   - Remove FPGA-specific constructs
   - Add scan chains (DFT)
   - Timing closure for target node

4. **Tape-Out:**
   - Submit to Efabless shuttle
   - Wait for fabrication
   - Test silicon!

---

## Appendix: Makefile Reference

**Top-level Makefile commands:**

```bash
# Firmware
make firmware-clean
make firmware-build
make firmware-disasm       # View assembly

# Vivado
make vivado-project        # Create project
make vivado-synth          # Synthesize
make vivado-impl           # Implement
make vivado-bitstream      # Generate bitstream
make vivado-program        # Program FPGA
make vivado-gui            # Open in GUI

# Simulation
make sim-vivado MODULE=pwm_accelerator
make sim-iverilog MODULE=soc_top

# UART monitoring
make uart-monitor PORT=/dev/ttyUSB0

# Clean
make clean                 # Clean all
make clean-vivado
make clean-firmware
```

---

## Support and Resources

**Documentation:**
- VexRiscv GitHub: https://github.com/SpinalHDL/VexRiscv
- RISC-V ISA: https://riscv.org/technical/specifications/
- Basys 3 Reference: https://digilent.com/reference/programmable-logic/basys-3
- Vivado User Guide: https://www.xilinx.com/support/documentation-navigation/design-hubs/dh0058-vivado-synthesis-hub.html

**Community:**
- RISC-V Discord
- FPGAs subreddit
- Efabless Slack (for ASIC questions)

---

**Document Version:** 1.0
**Last Updated:** 2025-11-15
**Status:** Ready for implementation

**Start building your custom chip!** 🚀
