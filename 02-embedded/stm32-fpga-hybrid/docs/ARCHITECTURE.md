# STM32F401RE + FPGA Hybrid Architecture

**Date:** 2025-12-02
**Status:** Design Complete
**Target Platform:** STM32F401RE + Xilinx Artix-7 (or similar)

---

## Overview

This document describes the hybrid STM32+FPGA architecture for the 5-level cascaded H-bridge inverter control system.

### System Architecture

```
┌────────────────────────────────────────────────────────────────────┐
│                    Universal Power Stage PCB                        │
│  Sensors: AMC1301 (3×) + ACS724 (1×)                               │
│  Output: 4× Pre-isolated analog (0-3.3V)                           │
└───────────────────┬────────────────────────────────────────────────┘
                    │ Standard 16-pin connector
                    ↓
┌────────────────────────────────────────────────────────────────────┐
│              Comparator Board (LM339 quad)                          │
│  ┌────────┐  ┌────────┐  ┌────────┐  ┌────────┐                  │
│  │ CH0    │  │ CH1    │  │ CH2    │  │ CH3    │                  │
│  │ RC Flt │  │ RC Flt │  │ RC Flt │  │ RC Flt │                  │
│  │ Comp   │  │ Comp   │  │ Comp   │  │ Comp   │                  │
│  └───┬────┘  └───┬────┘  └───┬────┘  └───┬────┘                  │
│      │ 1-bit     │ 1-bit     │ 1-bit     │ 1-bit                 │
└──────┼───────────┼───────────┼───────────┼───────────────────────┘
       │           │           │           │
       ↓           ↓           ↓           ↓
┌────────────────────────────────────────────────────────────────────┐
│                    FPGA (Artix-7 or similar)                        │
│                                                                     │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │         Sigma-Delta ADC (4 channels)                          │ │
│  │                                                               │ │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐    │ │
│  │  │ Σ-Δ Ch0  │  │ Σ-Δ Ch1  │  │ Σ-Δ Ch2  │  │ Σ-Δ Ch3  │    │ │
│  │  │ Mod+CIC  │  │ Mod+CIC  │  │ Mod+CIC  │  │ Mod+CIC  │    │ │
│  │  │ 16-bit   │  │ 16-bit   │  │ 16-bit   │  │ 16-bit   │    │ │
│  │  │ @ 10kHz  │  │ @ 10kHz  │  │ @ 10kHz  │  │ @ 10kHz  │    │ │
│  │  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘    │ │
│  │       └─────────────┴──────────────┴──────────────┘         │ │
│  └───────────────────────────┬──────────────────────────────────┘ │
│                               │                                    │
│  ┌────────────────────────────▼──────────────────────────────────┐ │
│  │         SPI Slave Interface (Register-based)                  │ │
│  │         - Read ADC channels via SPI                           │ │
│  │         - Up to 10 MHz SPI clock                              │ │
│  └────────────────────────────┬──────────────────────────────────┘ │
│                                │ SPI                                │
└────────────────────────────────┼────────────────────────────────────┘
                                 │
                  ┌──────────────┴──────────────┐
                  │         SPI (Master)        │
                  │    ┌────────────────────┐   │
                  │    │   STM32F401RE      │   │
                  │    │                    │   │
                  │    │  ┌──────────────┐  │   │
                  │    │  │ Control Loop │  │   │
                  │    │  │ PR + PI      │  │   │
                  │    │  │ @ 10 kHz     │  │   │
                  │    │  └──────┬───────┘  │   │
                  │    │         │          │   │
                  │    │  ┌──────▼───────┐  │   │
                  │    │  │ PWM Gen      │  │   │
                  │    │  │ TIM1+TIM8    │  │   │
                  │    │  │ 8 channels   │  │   │
                  │    │  └──────┬───────┘  │   │
                  │    └─────────┼──────────┘   │
                  └──────────────┼──────────────┘
                                 │ PWM (8 channels)
                                 ↓
                  ┌──────────────────────────────┐
                  │   H-Bridge Gate Drivers      │
                  │   (IR2110 or similar)        │
                  └──────────────────────────────┘
```

---

## Design Rationale

### Why Hybrid STM32+FPGA?

| Aspect | STM32 Alone | FPGA Alone | **Hybrid (Best)** |
|--------|-------------|------------|-------------------|
| **Sensing** | Internal ADC (fast enough) | Custom Σ-Δ ADC (flexible) | **FPGA Σ-Δ ADC (ASIC-ready)** |
| **Control** | Excellent (C code, FPU) | Complex (FSM/DSP) | **STM32 (easy development)** |
| **PWM** | Hardware timers (excellent) | Easy RTL | **STM32 (proven)** |
| **Cost** | Low ($5) | Medium ($20-40) | **Medium ($25-45)** |
| **ASIC Path** | Limited | Excellent | **Excellent (FPGA proves ADC)** |
| **Development** | Fast | Slow | **Moderate** |

**Key Benefits:**
1. **ASIC Development Path**: FPGA validates Sigma-Delta ADC design before ASIC tape-out
2. **Separation of Concerns**: STM32 handles control (what it's best at), FPGA handles sensing (custom ADC)
3. **Educational Value**: Learn both platforms and inter-chip communication
4. **Performance**: 10 kHz control loop maintained, proven ADC design
5. **Flexibility**: Can upgrade FPGA design without changing STM32 code

---

## Component Responsibilities

### FPGA Responsibilities

1. **Sigma-Delta ADC (4 channels)**
   - 1 MHz oversampling rate
   - 3rd-order CIC decimation (100:1)
   - 10 kHz output rate per channel
   - 12-14 bit ENOB

2. **SPI Slave Interface**
   - Register-based read interface
   - Up to 10 MHz SPI clock
   - 9 readable registers (status, ADC data, debug)

3. **Comparator Interface**
   - 4× 1-bit DAC outputs to RC filters
   - 4× comparator inputs from LM339

### STM32F401RE Responsibilities

1. **Control Algorithm**
   - PR (Proportional-Resonant) current controller
   - PI (Proportional-Integral) voltage controller
   - 10 kHz control loop rate
   - Floating-point math (Cortex-M4F FPU)

2. **PWM Generation**
   - TIM1 + TIM8 advanced timers
   - 8 complementary PWM channels
   - Dead-time insertion (1 µs)
   - Level-shifted carrier modulation

3. **Communication**
   - SPI master to FPGA (sensor reading)
   - UART debug output
   - CAN bus (future)

4. **Safety & Protection**
   - Overcurrent detection
   - Overvoltage detection
   - Emergency stop handling
   - Fault logging

---

## Communication Protocol (SPI)

### SPI Configuration

| Parameter | Value |
|-----------|-------|
| Mode | Master (STM32) / Slave (FPGA) |
| Clock Frequency | 10 MHz (max) |
| CPOL | 0 (idle low) |
| CPHA | 0 (sample on first edge) |
| Data Size | 8-bit |
| Bit Order | MSB first |

### SPI Transaction Format

**Read Register:**
```
Byte 0 (TX): Address (0x00-0x09)
Byte 1 (RX): Data
```

**Example: Read Channel 0**
```c
// Read CH0 high byte
CS = LOW;
SPI_TX(0x01);  // Address: ADC_CH0_H
uint8_t ch0_h = SPI_RX();
CS = HIGH;

// Read CH0 low byte
CS = LOW;
SPI_TX(0x02);  // Address: ADC_CH0_L
uint8_t ch0_l = SPI_RX();
CS = HIGH;

uint16_t ch0 = (ch0_h << 8) | ch0_l;
```

### FPGA Register Map

| Address | Register | Description |
|---------|----------|-------------|
| 0x00 | STATUS | Data valid flags [3:0] |
| 0x01 | ADC_CH0_H | Channel 0 high byte [15:8] |
| 0x02 | ADC_CH0_L | Channel 0 low byte [7:0] |
| 0x03 | ADC_CH1_H | Channel 1 high byte |
| 0x04 | ADC_CH1_L | Channel 1 low byte |
| 0x05 | ADC_CH2_H | Channel 2 high byte |
| 0x06 | ADC_CH2_L | Channel 2 low byte |
| 0x07 | ADC_CH3_H | Channel 3 high byte |
| 0x08 | ADC_CH3_L | Channel 3 low byte |
| 0x09 | SAMPLE_CNT | Sample counter (debug, low byte) |

---

## Timing and Performance

### Control Loop Timing (10 kHz)

```
┌─────── 100 µs Control Period ────────┐
│                                       │
├──┬──┬──┬──┬──────────────┬──────────┤
│1 │2 │3 │4 │   Control    │   PWM    │
│  │  │  │  │   Algorithm  │  Update  │
└──┴──┴──┴──┴──────────────┴──────────┘
 ↑  ↑  ↑  ↑
 Read Ch0-3 via SPI (~10 µs total)

Timing Budget:
- SPI reads (4 channels): ~10 µs
- Control algorithm: ~30 µs
- Safety checks: ~5 µs
- PWM update: ~1 µs
- Margin: ~54 µs
```

### SPI Read Timing

**Per Channel (16-bit):**
- CS setup: ~0.5 µs
- Address byte: ~0.8 µs (8 bits @ 10 MHz)
- Data high byte: ~0.8 µs
- CS hold: ~0.2 µs
- Repeat for low byte: ~2.3 µs
- **Total per channel: ~2.5 µs**

**All 4 Channels: ~10 µs**

---

## Resource Usage

### FPGA Resources (Xilinx Artix-7)

| Resource | Used | Available | Utilization |
|----------|------|-----------|-------------|
| LUTs | ~1500 | 20,800 | 7% |
| FFs | ~800 | 41,600 | 2% |
| BRAM | ~4 | 50 | 8% |
| DSP Slices | 0 | 90 | 0% |

**Very efficient design - leaves plenty of room for expansion!**

### STM32F401RE Resources

| Resource | Used | Available | Utilization |
|----------|------|-----------|-------------|
| Flash | ~20 KB | 512 KB | 4% |
| RAM | ~8 KB | 96 KB | 8% |
| Timers | 2 (TIM1, TIM8) | 11 | 18% |
| SPI | 1 (SPI1) | 3 | 33% |
| UART | 1 (USART2) | 3 | 33% |

---

## Power Consumption

| Component | Power | Notes |
|-----------|-------|-------|
| STM32F401RE | ~100 mW | @ 84 MHz, active |
| FPGA (Artix-7) | ~200 mW | Typical, low utilization |
| LM339 Comparator | ~5 mW | Quad comparator |
| RC Filters | ~1 mW | Passive |
| **Total** | **~306 mW** | Control & sensing only |

---

## Development Workflow

### FPGA Development

1. **Simulation**
   - Testbench for Sigma-Delta ADC
   - Verify CIC filter response
   - Test SPI slave interface

2. **Synthesis**
   - Xilinx Vivado (or open-source tools)
   - Constraints file for pin mapping
   - Timing analysis

3. **Programming**
   - JTAG programmer (Digilent, etc.)
   - Bitstream generation

### STM32 Development

1. **Firmware**
   - STM32CubeIDE or VSCode + PlatformIO
   - HAL library for peripherals
   - C code for control algorithm

2. **Testing**
   - Unit tests (PC-based)
   - Hardware-in-loop (with FPGA)
   - Oscilloscope verification

3. **Programming**
   - ST-Link v2 programmer
   - SWD interface

---

## Migration Path to ASIC

### Stage 1: STM32 + FPGA (Current)
- FPGA proves Sigma-Delta ADC design
- STM32 handles control
- **Cost:** ~$30 per unit (low volume)

### Stage 2: STM32 + Small ASIC
- Convert FPGA design to ASIC
- Keep STM32 for control flexibility
- **Cost:** ~$12-18 per unit (medium volume)

### Stage 3: Full ASIC
- Integrate everything on single chip
- Include RISC-V core + ADC + PWM
- **Cost:** ~$7-12 per unit (high volume)

**Key Point:** FPGA validation reduces ASIC risk significantly!

---

## Bill of Materials (BOM)

### Core Components

| Component | Part Number | Qty | Unit Price | Total |
|-----------|-------------|-----|------------|-------|
| STM32F401RE | STM32F401RET6 | 1 | $5.00 | $5.00 |
| FPGA | XC7A35T-CPG236 | 1 | $35.00 | $35.00 |
| Comparator | LM339N | 1 | $0.60 | $0.60 |
| Voltage Sensors | AMC1301 | 3 | $4.50 | $13.50 |
| Current Sensor | ACS724 | 1 | $8.00 | $8.00 |
| Passives | R, C | - | $2.00 | $2.00 |
| PCB (control) | Custom | 1 | $15.00 | $15.00 |
| **Subtotal** | | | | **$79.10** |

**Note:** This is for prototype quantities. Production costs significantly lower.

### Development Tools

| Tool | Cost |
|------|------|
| Basys 3 Board (Artix-7) | $149 |
| Nucleo-F401RE Board | $15 |
| ST-Link Programmer | $25 |
| **Total Dev Cost** | **$189** |

---

## Testing and Validation

### FPGA Tests

1. **ADC Accuracy**
   - Apply known voltages (bench PSU)
   - Measure ADC output
   - Verify 12-14 bit ENOB

2. **SPI Interface**
   - Logic analyzer capture
   - Verify timing (setup/hold)
   - Test all registers

3. **Throughput**
   - Verify 10 kHz sampling rate
   - Check data valid flags
   - Measure latency

### STM32 Tests

1. **SPI Communication**
   - Read all channels
   - Verify data integrity
   - Measure transaction time

2. **Control Loop**
   - Step response test
   - Frequency response
   - THD measurement

3. **PWM Generation**
   - Oscilloscope verification
   - Dead-time measurement
   - Duty cycle accuracy

---

## Known Limitations

1. **SPI Overhead**: ~10 µs per control loop for sensor reading (acceptable)
2. **FPGA Cost**: Higher than pure STM32 solution (justified for ASIC path)
3. **Complexity**: Two platforms to program and debug
4. **PCB Area**: Requires space for both chips

---

## Future Enhancements

1. **Parallel Interface**: Replace SPI with parallel bus for lower latency
2. **DMA**: Use STM32 DMA for SPI to reduce CPU load
3. **Higher OSR**: Increase to 256× for better ENOB (14-16 bit)
4. **CAN Bus**: Add CAN communication for system integration
5. **Ethernet**: Add Ethernet for remote monitoring

---

## References

- STM32F401RE Datasheet: [STM32F401xE](https://www.st.com/resource/en/datasheet/stm32f401re.pdf)
- Xilinx Artix-7 Guide: [7 Series FPGAs](https://www.xilinx.com/products/silicon-devices/fpga/artix-7.html)
- Sigma-Delta ADC Theory: `../../07-docs/SENSING-DESIGN-DEEP-DIVE.md`
- Universal Power Stage: `../../07-docs/SENSING-DESIGN.md`

---

**Document Version:** 1.0
**Last Updated:** 2025-12-02
**Status:** Ready for Implementation
