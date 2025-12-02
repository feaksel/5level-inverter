# STM32F401RE + FPGA Pin Mapping and Integration Guide

**Date:** 2025-12-02
**Target:** STM32F401RE + Xilinx Artix-7 (Basys 3 or similar)

---

## STM32F401RE Pin Mapping

### SPI1 (FPGA Communication)

| STM32 Pin | Function | Direction | FPGA Connection | Notes |
|-----------|----------|-----------|-----------------|-------|
| PA5 | SPI1_SCK | Output | FPGA SPI_SCK | 10 MHz max |
| PA6 | SPI1_MISO | Input | FPGA SPI_MISO | Pull-up recommended |
| PA7 | SPI1_MOSI | Output | FPGA SPI_MOSI | |
| PA4 | GPIO (CS) | Output | FPGA SPI_CS_N | Manual CS control |

**Configuration:**
```c
// SPI1 GPIO Configuration
GPIO_InitTypeDef GPIO_InitStruct = {0};

// SPI1 SCK, MOSI, MISO
GPIO_InitStruct.Pin = GPIO_PIN_5 | GPIO_PIN_6 | GPIO_PIN_7;
GPIO_InitStruct.Mode = GPIO_MODE_AF_PP;
GPIO_InitStruct.Pull = GPIO_NOPULL;
GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_VERY_HIGH;
GPIO_InitStruct.Alternate = GPIO_AF5_SPI1;
HAL_GPIO_Init(GPIOA, &GPIO_InitStruct);

// CS (manual control)
GPIO_InitStruct.Pin = GPIO_PIN_4;
GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP;
GPIO_InitStruct.Pull = GPIO_NOPULL;
GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_VERY_HIGH;
HAL_GPIO_Init(GPIOA, &GPIO_InitStruct);
```

### TIM1 (PWM - H-Bridge 1)

| STM32 Pin | Function | Direction | Connection | Notes |
|-----------|----------|-----------|------------|-------|
| PA8 | TIM1_CH1 | Output | H1_S1 (high-side) | Complementary pair |
| PB13 | TIM1_CH1N | Output | H1_S2 (low-side) | |
| PA9 | TIM1_CH2 | Output | H1_S3 (high-side) | Complementary pair |
| PB14 | TIM1_CH2N | Output | H1_S4 (low-side) | |

### TIM8 (PWM - H-Bridge 2) - *If Available*

| STM32 Pin | Function | Direction | Connection | Notes |
|-----------|----------|-----------|------------|-------|
| PC6 | TIM8_CH1 | Output | H2_S5 (high-side) | Complementary pair |
| PA7 | TIM8_CH1N | Output | H2_S6 (low-side) | **Conflict with SPI MOSI!** |
| PC7 | TIM8_CH2 | Output | H2_S7 (high-side) | Complementary pair |
| PB0 | TIM8_CH2N | Output | H2_S8 (low-side) | |

**⚠️ WARNING:** STM32F401RE has pin conflicts with TIM8. Consider using:
- TIM3 or TIM4 for H-Bridge 2 (no complementary outputs)
- External gate driver with dead-time insertion
- Larger STM32 (e.g., STM32F407) with more pins

### USART2 (Debug/Communication)

| STM32 Pin | Function | Direction | Connection | Notes |
|-----------|----------|-----------|------------|-------|
| PA2 | USART2_TX | Output | USB-Serial TX | ST-Link virtual COM |
| PA3 | USART2_RX | Input | USB-Serial RX | |

### Protection Inputs

| STM32 Pin | Function | Direction | Connection | Notes |
|-----------|----------|-----------|------------|-------|
| PB0 | GPIO_Input | Input | OCP (Overcurrent) | Active high |
| PB1 | GPIO_Input | Input | OVP (Overvoltage) | Active high |
| PC13 | GPIO_Input | Input | E-STOP | Active low (button) |

### Status LEDs

| STM32 Pin | Function | Direction | Connection | Notes |
|-----------|----------|-----------|------------|-------|
| PA10 | GPIO_Output | Output | LED_STATUS | Power indicator |
| PB3 | GPIO_Output | Output | LED_FAULT | Fault indicator |
| PB4 | GPIO_Output | Output | LED_PWM | PWM active |
| PB5 | GPIO_Output | Output | LED_COMM | SPI activity |

---

## FPGA Pin Mapping (Xilinx Artix-7 / Basys 3)

### Comparator Interface (from LM339)

| FPGA Pin | Function | Direction | Connection | Notes |
|----------|----------|-----------|------------|-------|
| J1 (V11) | comp_in[0] | Input | LM339 OUT1 (CH0) | DC Bus 1 |
| J2 (V12) | comp_in[1] | Input | LM339 OUT2 (CH1) | DC Bus 2 |
| J3 (V13) | comp_in[2] | Input | LM339 OUT3 (CH2) | AC Voltage |
| J4 (V14) | comp_in[3] | Input | LM339 OUT4 (CH3) | AC Current |

### 1-bit DAC Outputs (to RC Filters)

| FPGA Pin | Function | Direction | Connection | Notes |
|----------|----------|-----------|------------|-------|
| K1 (W11) | dac_out[0] | Output | RC Filter → LM339 IN- (CH0) | 1 MHz toggle |
| K2 (W12) | dac_out[1] | Output | RC Filter → LM339 IN- (CH1) | |
| K3 (W13) | dac_out[2] | Output | RC Filter → LM339 IN- (CH2) | |
| K4 (W14) | dac_out[3] | Output | RC Filter → LM339 IN- (CH3) | |

### SPI Interface (to STM32)

| FPGA Pin | Function | Direction | Connection | Notes |
|----------|----------|-----------|------------|-------|
| L1 (U11) | spi_sck | Input | STM32 PA5 (SPI1_SCK) | 10 MHz max |
| L2 (U12) | spi_mosi | Input | STM32 PA7 (SPI1_MOSI) | |
| L3 (U13) | spi_miso | Output | STM32 PA6 (SPI1_MISO) | |
| L4 (U14) | spi_cs_n | Input | STM32 PA4 (CS) | Active low |

### Clock and Reset

| FPGA Pin | Function | Direction | Connection | Notes |
|----------|----------|-----------|------------|-------|
| W5 | clk_50mhz | Input | 50 MHz oscillator | On-board oscillator |
| T18 | rst_n | Input | Reset button | Active low, debounced |

### Status LEDs (on Basys 3 board)

| FPGA Pin | Function | Direction | Connection | Notes |
|----------|----------|-----------|------------|-------|
| U16 | led[0] | Output | LD0 | Power indicator |
| E19 | led[1] | Output | LD1 | ADC data ready |
| U19 | led[2] | Output | LD2 | SPI active |
| V19 | led[3] | Output | LD3 | Data read from STM32 |

---

## Constraints File (Xilinx XDC)

### fpga_sensing_top.xdc

```tcl
## Clock
create_clock -period 20.000 -name clk_50mhz -waveform {0.000 10.000} [get_ports clk_50mhz]
set_property -dict {PACKAGE_PIN W5 IOSTANDARD LVCMOS33} [get_ports clk_50mhz]

## Reset
set_property -dict {PACKAGE_PIN T18 IOSTANDARD LVCMOS33} [get_ports rst_n]

## Comparator Inputs (from LM339)
set_property -dict {PACKAGE_PIN V11 IOSTANDARD LVCMOS33} [get_ports {comp_in[0]}]
set_property -dict {PACKAGE_PIN V12 IOSTANDARD LVCMOS33} [get_ports {comp_in[1]}]
set_property -dict {PACKAGE_PIN V13 IOSTANDARD LVCMOS33} [get_ports {comp_in[2]}]
set_property -dict {PACKAGE_PIN V14 IOSTANDARD LVCMOS33} [get_ports {comp_in[3]}]

## DAC Outputs (to RC Filters)
set_property -dict {PACKAGE_PIN W11 IOSTANDARD LVCMOS33} [get_ports {dac_out[0]}]
set_property -dict {PACKAGE_PIN W12 IOSTANDARD LVCMOS33} [get_ports {dac_out[1]}]
set_property -dict {PACKAGE_PIN W13 IOSTANDARD LVCMOS33} [get_ports {dac_out[2]}]
set_property -dict {PACKAGE_PIN W14 IOSTANDARD LVCMOS33} [get_ports {dac_out[3]}]

## SPI Interface (to STM32)
set_property -dict {PACKAGE_PIN U11 IOSTANDARD LVCMOS33} [get_ports spi_sck]
set_property -dict {PACKAGE_PIN U12 IOSTANDARD LVCMOS33} [get_ports spi_mosi]
set_property -dict {PACKAGE_PIN U13 IOSTANDARD LVCMOS33} [get_ports spi_miso]
set_property -dict {PACKAGE_PIN U14 IOSTANDARD LVCMOS33} [get_ports spi_cs_n]

## Status LEDs
set_property -dict {PACKAGE_PIN U16 IOSTANDARD LVCMOS33} [get_ports {led[0]}]
set_property -dict {PACKAGE_PIN E19 IOSTANDARD LVCMOS33} [get_ports {led[1]}]
set_property -dict {PACKAGE_PIN U19 IOSTANDARD LVCMOS33} [get_ports {led[2]}]
set_property -dict {PACKAGE_PIN V19 IOSTANDARD LVCMOS33} [get_ports {led[3]}]

## Timing Constraints
set_input_delay -clock clk_50mhz -min 2.000 [get_ports {comp_in[*]}]
set_input_delay -clock clk_50mhz -max 5.000 [get_ports {comp_in[*]}]
set_output_delay -clock clk_50mhz -min 1.000 [get_ports {dac_out[*]}]
set_output_delay -clock clk_50mhz -max 3.000 [get_ports {dac_out[*]}]
```

---

## LM339 Comparator Board Connections

### Input Side (from Universal Power Stage)

| Comparator | Input+ | Input- | Function |
|------------|--------|--------|----------|
| LM339 #1 | Sensor CH0 | DAC0 (via RC) | DC Bus 1 |
| LM339 #2 | Sensor CH1 | DAC1 (via RC) | DC Bus 2 |
| LM339 #3 | Sensor CH2 | DAC2 (via RC) | AC Voltage |
| LM339 #4 | Sensor CH3 | DAC3 (via RC) | AC Current |

### Output Side (to FPGA)

| Comparator | Output | Pull-up | To FPGA |
|------------|--------|---------|---------|
| LM339 #1 OUT | Open-drain | 10kΩ to 3.3V | comp_in[0] |
| LM339 #2 OUT | Open-drain | 10kΩ to 3.3V | comp_in[1] |
| LM339 #3 OUT | Open-drain | 10kΩ to 3.3V | comp_in[2] |
| LM339 #4 OUT | Open-drain | 10kΩ to 3.3V | comp_in[3] |

### RC Filter (DAC to Comparator IN-)

```
FPGA dac_out[i] ──┬── 1kΩ ──┬── LM339 IN-
                  │          │
                  └── 100nF ─┴── GND

Cutoff frequency: fc = 1 / (2π × 1kΩ × 100nF) ≈ 1.6 kHz
```

---

## Wiring Diagram

### Complete System Connections

```
┌─────────────────────────────────────────────────────────────────┐
│                  Universal Power Stage PCB                       │
│  (AMC1301 ×3, ACS724 ×1, Isolation, Voltage Dividers)          │
└──────┬──────┬──────┬──────┬───────────────────────────────────┘
       │      │      │      │
       CH0    CH1    CH2    CH3
       │      │      │      │
┌──────▼──────▼──────▼──────▼──────────────────────────────────┐
│            LM339 Comparator Board (5×5 cm)                    │
│                                                               │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐        │
│  │ RC+Comp │  │ RC+Comp │  │ RC+Comp │  │ RC+Comp │        │
│  │   CH0   │  │   CH1   │  │   CH2   │  │   CH3   │        │
│  └─┬───┬───┘  └─┬───┬───┘  └─┬───┬───┘  └─┬───┬───┘        │
│    │   │        │   │        │   │        │   │            │
│    │   │        │   │        │   │        │   │            │
└────┼───┼────────┼───┼────────┼───┼────────┼───┼────────────┘
     │   │        │   │        │   │        │   │
     │   │        │   │        │   │        │   │
     ↓   ↑        ↓   ↑        ↓   ↑        ↓   ↑
   COMP DAC     COMP DAC     COMP DAC     COMP DAC
     │   │        │   │        │   │        │   │
┌────┼───┼────────┼───┼────────┼───┼────────┼───┼────────────┐
│    │   │        │   │        │   │        │   │   FPGA     │
│    ▼   └────────┴───┴────────┴───┴────────┴───┴─ dac_out   │
│  comp_in[3:0]                                               │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Sigma-Delta ADC (4 channels)                        │  │
│  └──────────────────┬───────────────────────────────────┘  │
│                     │                                       │
│  ┌──────────────────▼───────────────────────────────────┐  │
│  │  SPI Slave Interface                                 │  │
│  └──────────────────┬───────────────────────────────────┘  │
│                     │ SPI (SCK,MOSI,MISO,CS)              │
└─────────────────────┼─────────────────────────────────────┘
                      │
             ┌────────▼────────┐
             │   STM32F401RE   │
             │                 │
             │  SPI1 Master    │
             │  (PA4-PA7)      │
             │                 │
             │  Control Loop   │
             │  PR + PI        │
             │  @ 10 kHz       │
             │                 │
             │  PWM Gen        │
             │  TIM1 (PA8-PB14)│
             └────────┬────────┘
                      │ PWM (8 channels)
             ┌────────▼────────┐
             │  Gate Drivers   │
             │  (IR2110, etc.) │
             └────────┬────────┘
                      │
             ┌────────▼────────┐
             │   H-Bridges     │
             │   (IGBTs/MOSFETs)│
             └─────────────────┘
```

---

## Cable and Connector Specifications

### Universal Power Stage → Comparator Board

**Connector:** 16-pin IDC ribbon cable or 0.1" header

| Pin | Signal | Type |
|-----|--------|------|
| 1 | CH0 (DC Bus 1) | Analog 0-3.3V |
| 2 | CH1 (DC Bus 2) | Analog 0-3.3V |
| 3 | CH2 (AC Voltage) | Analog 0-3.3V |
| 4 | CH3 (AC Current) | Analog 0-3.3V |
| 5-8 | GND | Ground |
| 9-12 | +3.3V | Power (optional) |
| 13-16 | NC | Reserved |

### Comparator Board → FPGA

**Connector:** 12-pin IDC ribbon cable or Pmod connector

| Pin | Signal | Type |
|-----|--------|------|
| 1 | comp_in[0] | Digital 3.3V |
| 2 | comp_in[1] | Digital 3.3V |
| 3 | comp_in[2] | Digital 3.3V |
| 4 | comp_in[3] | Digital 3.3V |
| 5 | dac_out[0] | Digital 3.3V |
| 6 | dac_out[1] | Digital 3.3V |
| 7 | dac_out[2] | Digital 3.3V |
| 8 | dac_out[3] | Digital 3.3V |
| 9-10 | GND | Ground |
| 11-12 | +3.3V | Power (optional) |

### FPGA → STM32

**Connector:** 6-pin SPI header (0.1" pitch)

| Pin | Signal | STM32 Pin | FPGA Pin |
|-----|--------|-----------|----------|
| 1 | SPI_SCK | PA5 | U11 |
| 2 | SPI_MISO | PA6 | U13 |
| 3 | SPI_MOSI | PA7 | U12 |
| 4 | SPI_CS_N | PA4 | U14 |
| 5 | GND | GND | GND |
| 6 | +3.3V | +3.3V | +3.3V |

---

## Power Supply Requirements

### STM32F401RE

- **Voltage:** 3.3V (regulated)
- **Current:** ~150 mA (typical), 200 mA (max)
- **Source:** USB (ST-Link) or external 3.3V regulator

### FPGA (Artix-7)

- **Voltage:**
  - VCCINT: 1.0V @ 200 mA
  - VCCO: 3.3V @ 100 mA
  - VCCAUX: 1.8V @ 50 mA
- **Source:** On-board regulators (Basys 3) or external supplies

### LM339 Comparator

- **Voltage:** 3.3V (single supply)
- **Current:** ~2 mA (all 4 channels)
- **Source:** FPGA 3.3V rail (ample margin)

### Total Power Budget

| Rail | Current | Source |
|------|---------|--------|
| 3.3V | ~450 mA | Main supply |
| 1.8V | ~50 mA | FPGA regulator |
| 1.0V | ~200 mA | FPGA regulator |

**Recommended Supply:** 5V @ 1A, with on-board regulators

---

## Testing Checklist

### Power-On Tests

- [ ] Verify 3.3V rail on all components
- [ ] Check FPGA configuration (LEDs blink)
- [ ] Verify STM32 boots (serial output)
- [ ] Test SPI communication (loopback test)

### FPGA Tests

- [ ] Comparator inputs respond to test signals
- [ ] DAC outputs toggle at 1 MHz
- [ ] SPI registers readable
- [ ] ADC data updates at 10 kHz

### STM32 Tests

- [ ] SPI master reads FPGA registers
- [ ] ADC data conversion correct
- [ ] Control loop runs at 10 kHz
- [ ] PWM outputs correct (oscilloscope)

### Integration Tests

- [ ] Apply known voltages, verify ADC readings
- [ ] Test overcurrent/overvoltage protection
- [ ] Verify end-to-end latency < 100 µs
- [ ] Full control loop operation

---

## Troubleshooting Guide

### SPI Communication Fails

**Symptoms:** All reads return 0xFF or 0x00

**Solutions:**
1. Check CS polarity (should be active low)
2. Verify SPI mode (CPOL=0, CPHA=0)
3. Reduce SPI clock frequency (try 1 MHz)
4. Check pull-ups/pull-downs on MISO
5. Use logic analyzer to verify waveforms

### ADC Readings Incorrect

**Symptoms:** ADC values stuck at 0 or 0xFFFF

**Solutions:**
1. Verify comparator power supply (3.3V)
2. Check RC filter values (1kΩ, 100nF)
3. Test comparator outputs with multimeter
4. Verify DAC outputs toggling (oscilloscope)
5. Check analog input connections

### Control Loop Too Slow

**Symptoms:** Cannot achieve 10 kHz rate

**Solutions:**
1. Use DMA for SPI transfers
2. Optimize control algorithm (avoid divisions)
3. Reduce SPI transaction overhead
4. Consider parallel interface instead of SPI
5. Profile code to find bottlenecks

---

## Revision History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2025-12-02 | Initial pin mapping and integration guide |

---

**Status:** Ready for Hardware Bring-Up
