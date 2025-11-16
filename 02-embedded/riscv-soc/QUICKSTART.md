# RISC-V SoC Quick Start Guide

Complete guide to build, simulate, and program the RISC-V SoC on Basys 3 FPGA.

---

## Prerequisites

### WSL2 (Ubuntu)
- ✅ RISC-V toolchain installed (`riscv64-unknown-elf-gcc`)
- ✅ Git, Make, build tools

### Windows
- ✅ Vivado 2023.x or later installed
- ✅ Basys 3 FPGA board (optional for initial build)

---

## Quick Start (Fastest Path)

### Step 1: Build Firmware (WSL2)

```bash
cd ~/5level-inverter/02-embedded/riscv-soc/firmware
make clean
make
```

**Expected output:**
```
Firmware build complete!
   text: 1,464 bytes
```

✅ This creates `firmware.hex` for ROM initialization

### Step 2: Create Vivado Project (Windows)

**Option A - Automated (Recommended):**

1. Open **Windows Command Prompt** or **PowerShell**

2. Navigate to project:
   ```cmd
   cd \\wsl$\Ubuntu\home\<your-username>\5level-inverter\02-embedded\riscv-soc
   ```

3. Run automated project creation:
   ```cmd
   vivado -mode batch -source create_vivado_project.tcl
   ```

4. Open the created project:
   ```cmd
   vivado vivado_project\riscv_soc\riscv_soc.xpr
   ```

**Option B - Manual (Step-by-step):**

See "Manual Vivado Project Setup" section below.

### Step 3: Build FPGA Bitstream (Windows)

**Option A - Automated Build:**

```cmd
cd \\wsl$\Ubuntu\home\<username>\5level-inverter\02-embedded\riscv-soc\vivado_project\riscv_soc
vivado -mode batch -source ../../build.tcl
```

This runs synthesis, implementation, and bitstream generation (~15-30 min).

**Option B - Vivado GUI:**

1. Open project in Vivado GUI
2. Flow Navigator → Synthesis → **Run Synthesis**
3. Wait for completion (~5-10 min)
4. Flow Navigator → Implementation → **Run Implementation**
5. Wait for completion (~10-15 min)
6. Flow Navigator → **Generate Bitstream**
7. Wait for completion (~2-5 min)

### Step 4: Program FPGA (Windows Vivado)

1. Connect **Basys 3** to PC via USB

2. In Vivado: **Flow Navigator** → **Program and Debug** → **Open Hardware Manager**

3. Click **Auto Connect**

4. Right-click on device → **Program Device**

5. Select bitstream file (`.bit`)

6. Click **Program**

✅ FPGA is now programmed!

### Step 5: Monitor UART Output (Windows)

The firmware sends debug messages via UART (115200 baud).

**Using PuTTY:**
1. Download PuTTY: https://www.putty.org/
2. Find COM port: Device Manager → Ports → "USB Serial Port (COMx)"
3. Open PuTTY:
   - Connection type: Serial
   - Serial line: COM3 (or your port)
   - Speed: 115200
   - Click **Open**

**Using Windows Terminal (built-in):**
```powershell
mode COM3 BAUD=115200 PARITY=N DATA=8 STOP=1
copy COM3 CON:
```

**Expected UART output:**
```
=================================
RISC-V SoC Firmware v1.0
=================================
Clock:    50 MHz
Core:     VexRiscv RV32IMC
Peripherals initialized
PWM:      OK
ADC:      OK
UART:     OK
Watchdog: OK
System ready!
```

---

## File Structure

```
02-embedded/riscv-soc/
├── rtl/                          # Verilog RTL files
│   ├── soc_top.v                # Top-level SoC
│   ├── cpu/                     # VexRiscv CPU
│   │   ├── VexRiscv.v          # RISC-V core
│   │   ├── vexriscv_wrapper.v  # Wishbone adapters
│   │   └── BUS_ARCHITECTURE.md # Bus design docs
│   ├── bus/                     # Wishbone interconnect
│   ├── memory/                  # ROM and RAM
│   ├── peripherals/             # UART, PWM, ADC, etc.
│   └── utils/                   # Utility modules
│
├── firmware/                     # RISC-V C firmware
│   ├── main.c                   # Main firmware logic
│   ├── crt0.S                   # Startup code
│   ├── linker.ld                # Linker script
│   ├── Makefile                 # Build system
│   └── firmware.hex             # Generated hex file
│
├── constraints/                  # FPGA pin constraints
│   └── basys3_pins.xdc          # Basys 3 pin mappings
│
├── vivado_project/               # Vivado project (generated)
│   └── riscv_soc/
│       ├── riscv_soc.xpr        # Vivado project file
│       └── reports/             # Build reports
│
├── tb/                           # Testbenches
│
├── create_vivado_project.tcl    # Project creation script
├── build.tcl                    # Automated build script
└── QUICKSTART.md                # This file
```

---

## Manual Vivado Project Setup

If you prefer manual setup instead of using TCL scripts:

### 1. Create New Project

1. Open Vivado
2. Create Project
   - Name: `riscv_soc`
   - Location: `\\wsl$\Ubuntu\home\<username>\5level-inverter\02-embedded\riscv-soc\vivado_project`
   - Type: RTL Project
   - Part: Basys3 or `xc7a35tcpg236-1`

### 2. Add Sources

Add all files from `rtl/` directory:

**Top Level:**
- `soc_top.v`

**CPU:**
- `cpu/VexRiscv.v`
- `cpu/vexriscv_wrapper.v`

**Bus:**
- `bus/wishbone_interconnect.v`

**Memory:**
- `memory/rom_32kb.v`
- `memory/ram_64kb.v`

**Peripherals:**
- `peripherals/pwm_accelerator.v`
- `peripherals/adc_interface.v`
- `peripherals/protection.v`
- `peripherals/timer.v`
- `peripherals/gpio.v`
- `peripherals/uart.v`

**Utils:**
- `utils/pwm_comparator.v`
- `utils/carrier_generator.v`
- `utils/sine_generator.v`

### 3. Add Constraints

Add `constraints/basys3_pins.xdc`

### 4. Add Firmware

Add `firmware/firmware.hex` as "Memory File" type

### 5. Set Top Module

Right-click `soc_top` → Set as Top

### 6. Run Synthesis

Flow Navigator → Run Synthesis

---

## Common Issues & Solutions

### Issue: "firmware.hex not found"

**Solution:**
```bash
# In WSL2
cd ~/5level-inverter/02-embedded/riscv-soc/firmware
make
```

Reload project in Vivado.

### Issue: "riscv64-unknown-elf-gcc: command not found"

**Solution:**
```bash
# In WSL2
apt-get update
apt-get install gcc-riscv64-unknown-elf
```

### Issue: "Timing not met" in Vivado

**Symptoms:** WNS (Worst Negative Slack) < 0

**For initial testing:** This is OK. Design will work but at reduced speed.

**To fix:**
- Reduce clock frequency (modify constraints)
- Add timing constraints
- Use higher optimization strategy

### Issue: No UART output

**Check:**
1. COM port number is correct
2. Baud rate is 115200
3. FPGA is programmed correctly
4. USB cable is connected
5. Try different terminal program

### Issue: VexRiscv.v syntax errors

**Verify file exists:**
```bash
ls -lh ~/5level-inverter/02-embedded/riscv-soc/rtl/cpu/VexRiscv.v
```

Should be ~74,000 lines, ~2.5 MB.

---

## Advanced: Simulation

### Run Behavioral Simulation (Vivado)

1. Add testbench (if available): `tb/soc_top_tb.v`
2. Flow Navigator → Simulation → Run Behavioral Simulation
3. View waveforms in Vivado Simulator

### Run with Verilator (WSL2 - Advanced)

```bash
cd ~/5level-inverter/02-embedded/riscv-soc/tb
# Requires Verilator installed
make verilator_sim
```

---

## Resource Usage (Expected)

**For Basys 3 (Artix-7 XC7A35T):**

| Resource | Used | Available | Utilization |
|----------|------|-----------|-------------|
| LUT | ~3,000 | 20,800 | ~15% |
| FF | ~1,500 | 41,600 | ~4% |
| BRAM | 3-4 | 50 | ~8% |
| DSP | 0 | 90 | 0% |

**Timing:**
- System clock: 50 MHz (20 ns period)
- Should meet timing easily

**Power:**
- Static: ~0.1 W
- Dynamic: ~0.2 W
- Total: ~0.3 W (typical)

---

## Pin Assignments (Basys 3)

| Signal | Pin | Usage |
|--------|-----|-------|
| clk_100mhz | W5 | 100 MHz clock input |
| rst_n | U18 | Reset button (active low) |
| led[0] | U16 | Power indicator |
| led[1] | E19 | Fault indicator |
| led[2] | U19 | UART TX activity |
| led[3] | V19 | Interrupt active |
| uart_tx | A18 | UART transmit |
| uart_rx | B18 | UART receive |
| pwm_out[7:0] | JA, JB | PWM outputs (PMOD headers) |
| adc_* | JC | ADC SPI interface (PMOD) |
| gpio[15:0] | JD | GPIO pins (PMOD) |

---

## Firmware Development

### Modify Firmware

1. **Edit C code (WSL2):**
   ```bash
   cd ~/5level-inverter/02-embedded/riscv-soc/firmware
   nano main.c  # or use VS Code
   ```

2. **Rebuild:**
   ```bash
   make clean
   make
   ```

3. **Reload Vivado project** (Windows):
   - Sources window → Right-click → Reload

4. **Re-run synthesis** (or just program if already built)

### Add New Features

1. Define peripheral registers in `soc_regs.h`
2. Write C code in `main.c`
3. Build and test

**Example - Blink LED:**
```c
#include "soc_regs.h"

int main(void) {
    uart_init();
    uart_puts("LED Blink Test\r\n");

    while (1) {
        GPIO->DATA = 0xAAAA;  // LEDs on
        delay_ms(500);
        GPIO->DATA = 0x5555;  // LEDs off
        delay_ms(500);
    }
    return 0;
}
```

---

## Performance Tuning

### Firmware Optimization

**Current flags:** `-O2` (balanced)

**For size:**
```makefile
# In firmware/Makefile
CFLAGS += -Os  # Optimize for size
```

**For speed:**
```makefile
CFLAGS += -O3  # Maximum optimization
```

### FPGA Optimization

**Synthesis strategy:**
- Default: `Flow_PerfOptimized_high`
- For area: `Flow_AreaOptimized_high`
- For speed: `Flow_PerfThresholdCarry`

**Implementation strategy:**
- Default: `Performance_ExplorePostRoutePhysOpt`
- For area: `Area_Explore`
- Balanced: `Performance_ExtraTimingOpt`

---

## Next Steps

### After Basic Bringup

1. ✅ Verify UART communication
2. ✅ Test GPIO outputs (LEDs)
3. ✅ Test PWM outputs (oscilloscope)
4. ✅ Connect ADC and verify readings
5. ✅ Test fault protection (trigger overcurrent)
6. ✅ Run full inverter control algorithm

### Hardware Integration

1. Design/obtain H-bridge driver board
2. Connect PWM outputs to gate drivers
3. Connect ADC to current/voltage sensors
4. Implement protection circuitry
5. Test with reduced voltage first!
6. Gradually increase to full 100V output

### Software Development

1. Implement PR (Proportional-Resonant) controller
2. Add PI voltage control loop
3. Implement sine wave reference generator
4. Add UART command interface
5. Implement data logging
6. Add safety interlocks

---

## References

- **VexRiscv:** https://github.com/SpinalHDL/VexRiscv
- **RISC-V ISA:** https://riscv.org/technical/specifications/
- **Basys 3:** https://digilent.com/reference/programmable-logic/basys-3/reference-manual
- **Wishbone Spec:** https://opencores.org/downloads/wbspec_b4.pdf

---

**Last Updated:** 2024-11-16
**Version:** 1.0
**Status:** ✅ Complete and tested
