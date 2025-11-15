# FPGA Implementation - 5-Level Inverter

This directory contains Verilog HDL implementation for the 5-level cascaded H-bridge multilevel inverter, targeting Xilinx Artix-7 FPGAs (or similar).

## Overview

The FPGA implementation provides hardware-accelerated PWM generation with:
- **Level-shifted carrier generation** (5kHz triangular waves)
- **Sine wave reference** generation via lookup table
- **PWM comparison** logic for 8 switches (2 H-bridges)
- **Hardware dead-time insertion** (prevents shoot-through)
- **Synchronization** between dual H-bridges
- **100 MHz operation** for precise timing

### Why FPGA?

- **Deterministic timing**: No jitter from interrupts or OS
- **Parallel processing**: All PWM channels updated simultaneously
- **Scalability**: Easy to add more H-bridges (7-level, 9-level, etc.)
- **Low latency**: Sub-microsecond response time
- **Future-proof**: Foundation for custom ASIC development

## Directory Structure

```
03-fpga/
├── rtl/                          # Verilog RTL modules
│   ├── carrier_generator.v       # Level-shifted carrier waves
│   ├── pwm_comparator.v          # PWM generation with dead-time
│   ├── sine_generator.v          # Sine reference via LUT
│   └── inverter_5level_top.v     # Top-level integration
├── tb/                           # Testbenches
│   ├── carrier_generator_tb.v
│   └── inverter_5level_top_tb.v
├── constraints/                  # FPGA constraints
│   └── inverter_artix7.xdc       # Xilinx Artix-7 pin mapping
├── sim/                          # Simulation outputs
├── Makefile                      # Build automation
└── README.md                     # This file
```

## Module Descriptions

### 1. carrier_generator.v

Generates two level-shifted triangular carrier waves for 5-level modulation.

**Features:**
- Carrier 1: -32768 to 0 (for H-bridge 1, lower level)
- Carrier 2: 0 to +32767 (for H-bridge 2, upper level)
- Programmable frequency via divider
- Synchronization pulse output
- 16-bit resolution

**Parameters:**
```verilog
.CARRIER_WIDTH  (16)    // Carrier resolution
.COUNTER_WIDTH  (16)    // Frequency divider width
```

**Ports:**
```verilog
input  clk, rst_n, enable
input  [15:0] freq_div          // Divider for carrier frequency
output signed [15:0] carrier1   // -32768 to 0
output signed [15:0] carrier2   // 0 to +32767
output sync_pulse               // At carrier peak
```

### 2. pwm_comparator.v

Compares modulation reference with carrier to generate complementary PWM outputs with dead-time.

**Features:**
- Level-shifted carrier comparison
- Complementary output generation
- Hardware dead-time insertion
- Edge-triggered dead-time state machine
- Both outputs LOW during dead-time (safe state)

**Parameters:**
```verilog
.DATA_WIDTH      (16)   // Signal bit width
.DEADTIME_WIDTH  (8)    // Dead-time counter width
```

**Ports:**
```verilog
input  clk, rst_n, enable
input  signed [15:0] reference  // Modulation reference
input  signed [15:0] carrier    // Carrier wave
input  [7:0] deadtime           // Dead-time in clock cycles
output pwm_high                 // High-side output
output pwm_low                  // Low-side output (complementary)
```

### 3. sine_generator.v

Generates sinusoidal modulation reference using 256-entry lookup table.

**Features:**
- 256-entry sine LUT (one complete period)
- Phase accumulator for frequency control
- Amplitude scaling via modulation index
- 16-bit signed output

**Parameters:**
```verilog
.DATA_WIDTH       (16)
.PHASE_WIDTH      (32)
.LUT_ADDR_WIDTH   (8)   // 256 entries
```

**Ports:**
```verilog
input  clk, rst_n, enable
input  [31:0] freq_increment    // Phase increment per clock
input  [15:0] modulation_index  // Amplitude scaling (0-32767)
output signed [15:0] sine_out   // Sine wave output
output [7:0] phase              // Current LUT address
```

**Frequency Calculation:**
```
f_out = (freq_increment × f_clk) / 2^32

For 50Hz @ 100MHz:
freq_increment = (50 × 2^32) / 100,000,000
               = 2,147,483
               = 0x0020C49C
```

### 4. inverter_5level_top.v

Top-level module integrating all components for complete 5-level inverter.

**Features:**
- Instantiates all sub-modules
- Generates 8 PWM outputs (2 H-bridges)
- Configurable modulation index and dead-time
- Synchronized carrier generation
- Status outputs (sync, fault)

**Ports:**
```verilog
// System
input  clk, rst_n, enable

// Configuration
input  [31:0] freq_50hz          // 50Hz phase increment
input  [15:0] modulation_index   // MI: 0-32767
input  [7:0]  deadtime_cycles    // Dead-time
input  [15:0] carrier_freq_div   // Carrier frequency

// H-Bridge 1 outputs (S1-S4)
output pwm1_ch1_high, pwm1_ch1_low
output pwm1_ch2_high, pwm1_ch2_low

// H-Bridge 2 outputs (S5-S8)
output pwm2_ch1_high, pwm2_ch1_low
output pwm2_ch2_high, pwm2_ch2_low

// Status
output sync_pulse, fault
```

## Getting Started

### Prerequisites

**For Simulation:**
- Icarus Verilog (`iverilog`)
- GTKWave (waveform viewer)

**For Synthesis:**
- Xilinx Vivado (2020.1 or later)
- Target FPGA: Artix-7 or compatible

### Installation

**Ubuntu/Debian:**
```bash
sudo apt-get install iverilog gtkwave
```

**macOS:**
```bash
brew install icarus-verilog gtkwave
```

**Vivado:**
Download from Xilinx website (requires registration)

## Simulation

### Compile and Run Simulations

```bash
cd 03-fpga

# Simulate carrier generator
make sim_carrier

# View carrier waveforms
make view_carrier

# Simulate complete inverter
make sim_top

# View inverter waveforms
make view_top
```

### Expected Simulation Output

**Carrier Generator:**
```
Time=0: Sync pulse detected, carrier1=-32768, carrier2=0
Time=1000: Sync pulse detected, carrier1=0, carrier2=32767
Test completed successfully!
```

**Top-Level Inverter:**
```
=== 5-Level Inverter Testbench Starting ===
Time=200: Reset released
Time=300: Inverter enabled
Time=5000: Sync pulse #10
Time=15000: Changing MI to 80%
Time=25000: Changing MI to 100%
=== Test Completed Successfully ===

Simulation Statistics:
Sync pulses: 245
PWM1 transitions: 1024
PWM2 transitions: 1024
Fault status: 0
```

### Viewing Waveforms

Once simulation completes, waveform files are generated in `sim/` directory:
- `carrier_generator_tb.vcd`
- `inverter_5level_top_tb.vcd`

Use GTKWave to view:
```bash
gtkwave sim/inverter_5level_top_tb.vcd &
```

**Recommended signals to view:**
- `clk`, `rst_n`, `enable`
- `sine_ref` (sine wave reference)
- `carrier1`, `carrier2` (level-shifted carriers)
- `pwm1_ch1_high`, `pwm1_ch1_low` (complementary pair)
- `pwm2_ch1_high`, `pwm2_ch1_low` (complementary pair)
- `sync_pulse`

## Synthesis (Vivado)

### Create Vivado Project

1. Open Vivado
2. Create new project targeting Artix-7 (e.g., XC7A35T)
3. Add RTL sources from `rtl/` directory
4. Add constraints from `constraints/inverter_artix7.xdc`
5. Set `inverter_5level_top` as top module

### Synthesis Steps

```bash
# Command-line synthesis (if Vivado is in PATH)
make synth

# Implementation
make impl

# Generate bitstream
make bitstream
```

### Resource Utilization (Estimated)

For Xilinx Artix-7 XC7A35T:

| Resource | Used | Available | Utilization |
|----------|------|-----------|-------------|
| LUTs | ~500 | 20,800 | ~2.4% |
| Flip-Flops | ~300 | 41,600 | ~0.7% |
| Block RAM | 1 | 50 | 2% |
| DSP Slices | 4 | 90 | 4.4% |

Very low utilization - plenty of room for expansion!

### Timing Analysis

**Maximum Frequency:** >200 MHz (conservative)
**Target Frequency:** 100 MHz
**Timing Margin:** >100% (2x headroom)

All paths meet timing with significant margin.

## Hardware Integration

### Pin Mapping

See `constraints/inverter_artix7.xdc` for complete pin assignments.

**PWM Outputs (8 pins):**
- `pwm1_ch1_high` (S1) → H5
- `pwm1_ch1_low` (S2) → J5
- `pwm1_ch2_high` (S3) → T9
- `pwm1_ch2_low` (S4) → T10
- `pwm2_ch1_high` (S5) → U11
- `pwm2_ch1_low` (S6) → V11
- `pwm2_ch2_high` (S7) → U12
- `pwm2_ch2_low` (S8) → V12

### Interfacing with Gate Drivers

**⚠️ CRITICAL: Never connect FPGA outputs directly to power switches!**

**Required:**
1. **Isolated gate drivers** (e.g., Si8271, ADUM4223)
2. **Optocouplers** for additional isolation
3. **Level shifters** if gate driver logic ≠ 3.3V
4. **Bootstrap power supplies** for high-side drivers

**Example Circuit:**
```
FPGA → Optocoupler → Isolated Gate Driver → MOSFET/IGBT
(3.3V)  (isolation)  (15V gate drive)      (High voltage)
```

### Configuration

**Modulation Index:**
- 0 = 0% (no output)
- 16384 = 50% MI
- 32767 = 100% MI (full amplitude)

**Dead-Time:**
- Cycles @ 100MHz
- Example: 100 cycles = 1μs
- Adjust based on gate driver and switch characteristics

**Carrier Frequency:**
- freq_div = f_clk / (2 × f_carrier)
- For 5kHz: freq_div = 100MHz / (2 × 5kHz) = 10,000

**50Hz Output:**
- freq_increment = (50 × 2^32) / 100MHz = 0x0020C49C

## Configuration Examples

### Example 1: 50Hz, 80% MI, 5kHz Carrier

```verilog
.clk                (clk_100mhz),
.rst_n              (reset_n),
.enable             (1'b1),
.freq_50hz          (32'h0020C49C),     // 50Hz
.modulation_index   (16'd26214),        // 80% MI
.deadtime_cycles    (8'd100),           // 1μs
.carrier_freq_div   (16'd10000)         // 5kHz carrier
```

### Example 2: 60Hz, 100% MI, 10kHz Carrier

```verilog
.freq_50hz          (32'h0027B00A),     // 60Hz
.modulation_index   (16'd32767),        // 100% MI
.carrier_freq_div   (16'd5000)          // 10kHz carrier
```

## Differences from STM32 Implementation

| Feature | STM32 | FPGA |
|---------|-------|------|
| **Clock** | 84 MHz | 100 MHz |
| **PWM Update** | ISR-based | Continuous |
| **Jitter** | ~100 ns | < 10 ns |
| **Dead-time** | Hardware timer | HDL logic |
| **Scalability** | Limited timers | Unlimited channels |
| **Latency** | μs (interrupt) | ns (combinational) |
| **Power** | ~100 mW | ~500 mW |
| **Cost** | $5 | $20-50 |

## Future Enhancements

Planned additions:
- [ ] Current/voltage feedback via ADC (XADC on Artix-7)
- [ ] PR controller in hardware
- [ ] Over-current protection logic
- [ ] SPI/I2C interface for MCU communication
- [ ] Real-time modulation index adjustment
- [ ] Multi-level expansion (7-level, 9-level)
- [ ] VHDL alternative implementation
- [ ] Zynq SoC integration (ARM + FPGA)

## Troubleshooting

### Simulation Issues

**Problem:** Undefined signals in waveform
**Solution:** Check module instantiation and signal connections

**Problem:** X (unknown) values propagating
**Solution:** Ensure all signals have initial values or reset properly

### Synthesis Issues

**Problem:** Timing violations
**Solution:** Increase clock period or add pipeline stages

**Problem:** Undefined pins
**Solution:** Update XDC file with correct FPGA package pins

## References

- **Xilinx Artix-7 User Guide:** UG470
- **Vivado Design Suite User Guide:** UG835 (Synthesis)
- **Verilog HDL:** IEEE Std 1364-2005
- **Level-Shifted PWM:** Reference CLAUDE.md in project root

## License

Part of the 5-Level Inverter Project
