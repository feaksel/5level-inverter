# Modular Architecture: Universal Power Stage + 3 Control Boards

**Document Version:** 2.0
**Created:** 2025-11-29
**Purpose:** Clarified modular architecture with universal power/sensing stage

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Universal Power Stage PCB](#universal-power-stage-pcb)
3. [Stage 1: STM32 Only](#stage-1-stm32-only)
4. [Stage 2: STM32 + FPGA Acceleration](#stage-2-stm32--fpga-acceleration)
5. [Stage 3: ASIC RISC-V](#stage-3-asic-riscv)
6. [Interface Specification](#interface-specification)
7. [Complete Bill of Materials](#complete-bill-of-materials)
8. [PCB Design Guidelines](#pcb-design-guidelines)

---

## Architecture Overview

### ✅ Correct Project Stages:

| Stage | Control Platform | ADC Location | Control/PWM | Power Stage |
|-------|-----------------|--------------|-------------|-------------|
| **Stage 1** | STM32F303RE only | STM32 internal ADC | STM32 | **Universal PCB** |
| **Stage 2** | STM32 + FPGA acceleration | STM32 internal ADC | FPGA | **Universal PCB** |
| **Stage 3** | ASIC RISC-V | ASIC integrated ADC | ASIC | **Universal PCB** |

### 🎯 Key Design Principle:

**"Build ONE power stage PCB, swap control boards for each stage"**

```
┌─────────────────────────────────────────────────────────────┐
│         UNIVERSAL POWER STAGE PCB (Build Once!)             │
│                                                             │
│  ┌──────────────┐  ┌──────────────┐                        │
│  │  H-Bridge 1  │  │  H-Bridge 2  │  Power Stage           │
│  │  (4 switches)│  │  (4 switches)│  (8 IGBTs/MOSFETs)     │
│  └──────────────┘  └──────────────┘                        │
│         │                  │                                │
│  ┌──────┴──────────────────┴──────┐                        │
│  │  Isolated Voltage Sensors ×3   │  Sensing Circuitry     │
│  │  Isolated Current Sensor ×1    │  (AMC1301 + ACS724)    │
│  │  → Pre-scaled to 0-3.3V        │  Outputs: 0-3.3V       │
│  └────────────┬───────────────────┘                        │
│               │                                             │
│    ┌──────────▼──────────────┐                             │
│    │  Standard Connector     │  Interface                  │
│    │  - 4× Analog (0-3.3V)   │  (Same for all stages!)     │
│    │  - 8× PWM inputs        │                             │
│    │  - Power, GND           │                             │
│    └──────────┬──────────────┘                             │
└───────────────┼─────────────────────────────────────────────┘
                │
                │  Plug in different control boards:
                │
       ┌────────┴─────────┬──────────────┬────────────────┐
       │                  │              │                │
       ▼                  ▼              ▼                │
 ┌──────────┐      ┌─────────────┐  ┌──────────────┐    │
 │  STM32   │      │ STM32+FPGA  │  │ ASIC RISC-V  │    │
 │  Board   │      │   Board     │  │    Board     │    │
 │ (Stage 1)│      │  (Stage 2)  │  │  (Stage 3)   │    │
 └──────────┘      └─────────────┘  └──────────────┘    │
```

---

## Universal Power Stage PCB

### Purpose

**This PCB is built ONCE and used for ALL three stages.**

It contains:
1. ✅ 2× H-bridges (8 power switches)
2. ✅ Gate drivers (8 channels)
3. ✅ Isolated voltage sensors (3× AMC1301)
4. ✅ Isolated current sensor (1× ACS724)
5. ✅ Isolated DC-DC power supplies (for isolation circuits)
6. ✅ Standard connector to control board

### Block Diagram

```
HIGH VOLTAGE SIDE (50-100V)                    LOW VOLTAGE SIDE (0-3.3V)
┌─────────────────────────────────┐           ┌──────────────────────────┐
│                                 │           │                          │
│  DC Source 1 (+50V) ────┐      │           │  ┌─────────────────────┐ │
│                         │      │           │  │ Isolated Amplifiers │ │
│  ┌──────────────────────┴───┐  │           │  │                     │ │
│  │   H-Bridge 1             │  │           │  │ AMC1301 #1          │ │
│  │   S1  S2                 │  │  ══════>  │  │   VIN: ±250mV       │ │
│  │   │    │                 │  │  Voltage  │  │   VOUT: 0-2.048V    │ │
│  │   S3  S4                 │  │  Sensing  │  │   Gain: 8.2×        │ │──┐
│  │   Output → AC Node A     │  │           │  │   Isolation: 7070V  │ │  │
│  └──────────────────────────┘  │           │  └─────────────────────┘ │  │
│                                 │           │                          │  │
│  DC Source 2 (+50V) ────┐      │           │  ┌─────────────────────┐ │  │
│                         │      │           │  │ AMC1301 #2          │ │  │
│  ┌──────────────────────┴───┐  │           │  │   (Same as above)   │ │──┤
│  │   H-Bridge 2             │  │  ══════>  │  └─────────────────────┘ │  │
│  │   S5  S6                 │  │           │                          │  │
│  │   │    │                 │  │           │  ┌─────────────────────┐ │  │
│  │   S7  S8                 │  │           │  │ AMC1301 #3          │ │  │
│  │   Output → AC Node B     │  │  ══════>  │  │   (Same as above)   │ │──┤
│  └──────────────────────────┘  │           │  └─────────────────────┘ │  │
│                                 │           │                          │  │
│  AC Output (Node A + Node B)   │           │  ┌─────────────────────┐ │  │
│  │                              │           │  │ ACS724 Current      │ │  │
│  └─────[ Current Path ]─────    │  ══════>  │  │   Range: ±10A       │ │──┤
│         (through sensor)        │  Current  │  │   Output: 0.5-4.5V  │ │  │
│                                 │  Sensing  │  │   Isolation: 2100V  │ │  │
└─────────────────────────────────┘           │  └─────────────────────┘ │  │
                                              │                          │  │
        Isolation Barrier                    │  ┌─────────────────────┐ │  │
        (1500-7070V)                         │  │ B0505S Isolated     │ │  │
                                              │  │ DC-DC Converters    │ │  │
                                              │  │ (3× for AMC1301)    │ │  │
                                              │  └─────────────────────┘ │  │
                                              │                          │  │
                                              │  ┌─────────────────────┐ │  │
                                              │  │ Output Connector    │ │  │
                                              │  │ to Control Board:   │◄─┴──┘
                                              │  │                     │
                                              │  │ Pin 1: DC Bus 1 V   │ 0-2.048V
                                              │  │ Pin 2: DC Bus 2 V   │ 0-2.048V
                                              │  │ Pin 3: AC Output V  │ 0-2.048V
                                              │  │ Pin 4: AC Current   │ 0.5-4.5V
                                              │  │ Pin 5: GND          │
                                              │  │ Pin 6: +3.3V        │ (optional)
                                              │  │                     │
                                              │  │ Pin 7-14: PWM In    │ From control
                                              │  │   (8 channels)      │ board
                                              │  │                     │
                                              │  │ Pin 15-16: Pwr/GND  │
                                              │  └─────────────────────┘
                                              └──────────────────────────┘
```

### Sensor Outputs (Pre-scaled for 0-3.3V ADC)

**All control boards will read these analog signals directly:**

| Signal | Source | Range | Scaling | Connector Pin |
|--------|--------|-------|---------|---------------|
| **DC Bus 1 Voltage** | AMC1301 #1 | 0-2.048V | 50V → 2.09V (via 196:1 divider + 8.2× gain) | Pin 1 |
| **DC Bus 2 Voltage** | AMC1301 #2 | 0-2.048V | 50V → 2.09V | Pin 2 |
| **AC Output Voltage** | AMC1301 #3 | 0-2.048V | 141V pk → 2.04V | Pin 3 |
| **AC Output Current** | ACS724 | 0.5-4.5V | 2.5V @ 0A, ±10A → 0.5-4.5V (200mV/A) | Pin 4 |

**Key Point:** These outputs are:
- ✅ **Already isolated** (no additional isolation needed in control board)
- ✅ **Pre-scaled to ADC range** (0-3.3V safe for any ADC)
- ✅ **Identical for all stages** (universal interface)

### PWM Inputs (From Control Board)

The power stage expects **8 PWM signals** from the control board:

| PWM Signal | H-Bridge | Switch | Polarity | Connector Pin |
|------------|----------|--------|----------|---------------|
| PWM1 | H-Bridge 1 | S1 (high-side) | Active high | Pin 7 |
| PWM2 | H-Bridge 1 | S2 (high-side) | Active high | Pin 8 |
| PWM3 | H-Bridge 1 | S3 (low-side) | Active high | Pin 9 |
| PWM4 | H-Bridge 1 | S4 (low-side) | Active high | Pin 10 |
| PWM5 | H-Bridge 2 | S5 (high-side) | Active high | Pin 11 |
| PWM6 | H-Bridge 2 | S6 (high-side) | Active high | Pin 12 |
| PWM7 | H-Bridge 2 | S7 (low-side) | Active high | Pin 13 |
| PWM8 | H-Bridge 2 | S8 (low-side) | Active high | Pin 14 |

**Logic levels:** 3.3V or 5V compatible (gate driver inputs)

### Power Stage PCB Components

| Component | Quantity | Part Number | Purpose | Unit Price | Total |
|-----------|----------|-------------|---------|------------|-------|
| **Power Switches** | 8 | IRGP4063D or similar | IGBTs (600V, 48A) | $5 | $40 |
| **Gate Drivers** | 4 | IR2110 or UCC27211 | Half-bridge drivers | $3 | $12 |
| **Isolated Amplifiers** | 3 | AMC1301 module | Voltage sensing | $15 | $45 |
| **Current Sensor** | 1 | ACS724LLCTR-10AB | Current sensing | $6 | $6 |
| **Isolated DC-DC** | 3 | B0505S-1W | Power isolation | $3 | $9 |
| **Resistors 0.1%** | 20 | Various (1MΩ, 5.1kΩ) | Voltage dividers | $0.60 | $12 |
| **Capacitors** | 30 | Various | Filtering, DC link | $0.30 | $9 |
| **Connectors** | 1 | 16-pin header | Control interface | $2 | $2 |
| **PCB** | 1 | Custom 15×20cm | Power stage layout | $25 | $25 |
| **Heatsink** | 1 | - | IGBT cooling | $10 | $10 |
| **Misc** | - | Wire, screws, etc. | Assembly | - | $10 |
| | | | | **TOTAL** | **$180** |

**This PCB is built ONCE and used for all 3 stages!**

---

## Stage 1: STM32 Only

### Architecture

**All functions in STM32F303RE:**
- ✅ ADC: Internal 12-bit SAR ADCs (ADC1, ADC2)
- ✅ Control: PR current + PI voltage control
- ✅ PWM: Timer1 (4 ch) + Timer8 (4 ch) = 8 PWM outputs
- ✅ Communication: UART for debug

### Block Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                  UNIVERSAL POWER STAGE PCB                  │
│                                                             │
│  4× Analog Outputs (0-2.5V / 0-4.5V) ──────────────┐       │
│  8× PWM Inputs (3.3V logic) <──────────────────────┼───┐   │
└────────────────────────────────────────────────────┼───┼───┘
                                                     │   │
                    16-pin connector                 │   │
                                                     │   │
┌────────────────────────────────────────────────────┼───┼───┐
│                 STM32F303RE NUCLEO BOARD           │   │   │
│                                                    │   │   │
│  ┌──────────────────────────────────────────────┐ │   │   │
│  │  ADC1 (12-bit SAR)                           │ │   │   │
│  │   - PA0 (ADC1_IN1): DC Bus 1 ◄──────────────┼─┘   │   │
│  │   - PA1 (ADC1_IN2): DC Bus 2 ◄──────────────┼─────┘   │
│  │                                              │         │
│  │  ADC2 (12-bit SAR)                           │         │
│  │   - PA4 (ADC2_IN1): AC Voltage ◄────────────┼─────────┘
│  │   - PA5 (ADC2_IN2): AC Current ◄────────────┼─────────┐
│  │                                              │         │
│  │  DMA: Transfer ADC results to memory        │         │
│  └──────────────────────────────────────────────┘         │
│                          ↓                                 │
│  ┌──────────────────────────────────────────────┐         │
│  │  CONTROL ALGORITHM (C code)                  │         │
│  │   - PR current controller                    │         │
│  │   - PI voltage controller                    │         │
│  │   - Level-shifted carrier modulation         │         │
│  │   - Calculate 8× duty cycles                 │         │
│  └──────────────────────────────────────────────┘         │
│                          ↓                                 │
│  ┌──────────────────────────────────────────────┐         │
│  │  PWM GENERATION                              │         │
│  │   Timer1: 4× PWM (H-Bridge 1)                │         │
│  │   Timer8: 4× PWM (H-Bridge 2)                │         │
│  │   Frequency: 10 kHz                          │         │
│  │   Dead-time: 1 µs                            │         │
│  └──────────────────────────────────────────────┘         │
│                          ↓                                 │
│  8× PWM Outputs ─────────────────────────────────────────>│
│    - PE8-PE15 (example pins)                              │
│                                                            │
│  UART2: Debug output to PC                                │
└────────────────────────────────────────────────────────────┘
```

### ADC Configuration (STM32F303RE)

**Reading Sensors from Universal Power Stage:**

```c
// ADC channels (connected to power stage via 16-pin connector)
// All inputs are 0-3.3V (pre-isolated and pre-scaled)

void ADC_Init(void) {
    // Configure ADC1: DC bus voltages
    hadc1.Instance = ADC1;
    hadc1.Init.Resolution = ADC_RESOLUTION_12B;
    hadc1.Init.ScanConvMode = ADC_SCAN_ENABLE;
    hadc1.Init.ContinuousConvMode = DISABLE;
    hadc1.Init.ExternalTrigConv = ADC_EXTERNALTRIGCONV_T1_TRGO;  // Sync with PWM
    hadc1.Init.DMAContinuousRequests = ENABLE;
    HAL_ADC_Init(&hadc1);

    // Channel 1: DC Bus 1 (PA0)
    ADC_ChannelConfTypeDef sConfig = {0};
    sConfig.Channel = ADC_CHANNEL_1;
    sConfig.Rank = ADC_REGULAR_RANK_1;
    sConfig.SamplingTime = ADC_SAMPLETIME_19CYCLES_5;
    HAL_ADC_ConfigChannel(&hadc1, &sConfig);

    // Channel 2: DC Bus 2 (PA1)
    sConfig.Channel = ADC_CHANNEL_2;
    sConfig.Rank = ADC_REGULAR_RANK_2;
    HAL_ADC_ConfigChannel(&hadc1, &sConfig);

    // Configure ADC2: AC voltage and current
    hadc2.Instance = ADC2;
    hadc2.Init.Resolution = ADC_RESOLUTION_12B;
    hadc2.Init.ScanConvMode = ADC_SCAN_ENABLE;
    hadc2.Init.ExternalTrigConv = ADC_EXTERNALTRIGCONV_T1_TRGO;  // Simultaneous with ADC1
    hadc2.Init.DMAContinuousRequests = ENABLE;
    HAL_ADC_Init(&hadc2);

    // Channel 1: AC Output Voltage (PA4)
    sConfig.Channel = ADC_CHANNEL_1;
    sConfig.Rank = ADC_REGULAR_RANK_1;
    HAL_ADC_ConfigChannel(&hadc2, &sConfig);

    // Channel 2: AC Output Current (PA5)
    sConfig.Channel = ADC_CHANNEL_2;
    sConfig.Rank = ADC_REGULAR_RANK_2;
    HAL_ADC_ConfigChannel(&hadc2, &sConfig);
}

// DMA buffer for ADC results (automatically updated at 10 kHz)
uint16_t adc_buffer[4];  // [DC1, DC2, AC_V, AC_I]

// Convert ADC counts to real values
float get_dc_bus1_voltage(void) {
    float vout_adc = (float)adc_buffer[0] * 3.3f / 4095.0f;  // ADC to voltage
    float vout_amc1301 = vout_adc;                           // AMC1301 output
    float vin_amc1301 = vout_amc1301 / 8.2f;                 // AMC1301 gain
    float vin_actual = vin_amc1301 * 196.0f;                 // Voltage divider ratio
    return vin_actual;
}

float get_ac_current(void) {
    float vout_adc = (float)adc_buffer[3] * 3.3f / 4095.0f;  // ADC to voltage
    float current = (vout_adc - 2.5f) / 0.2f;                // ACS724: 200mV/A, 2.5V @ 0A
    return current;
}
```

### Stage 1 Additional Components

| Component | Quantity | Part Number | Purpose | Unit Price | Total |
|-----------|----------|-------------|---------|------------|-------|
| **STM32F303RE Nucleo** | 1 | NUCLEO-F303RE | Microcontroller | $12 | $12 |
| **Adapter PCB** | 1 | Custom 5×5cm | Nucleo to power stage | $5 | $5 |
| **Connectors/Wire** | - | Various | Interface | - | $3 |
| | | | | **TOTAL** | **$20** |

**Stage 1 Total Cost:** $180 (power stage) + $20 (control) = **$200**

---

## Stage 2: STM32 + FPGA Acceleration

### Architecture

**Hybrid system:**
- ✅ STM32: ADC sampling, preprocessing, communication
- ✅ FPGA: Control algorithm, PWM generation
- ✅ Communication: SPI or parallel bus (STM32 → FPGA)

### Why This Architecture?

**STM32 does what it's good at:**
- Fast ADC sampling (5 MSPS)
- Easy analog interface (built-in ADCs)
- USB/UART communication to PC

**FPGA does what it's good at:**
- Parallel processing (control loops)
- Deterministic PWM generation
- Low latency (<100 ns)

### Block Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                  UNIVERSAL POWER STAGE PCB                  │
│  4× Analog Outputs ────────────────────┐                    │
│  8× PWM Inputs <───────────────────────┼────────────────┐   │
└────────────────────────────────────────┼────────────────┼───┘
                                         │                │
┌────────────────────────────────────────┼────────────────┼───┐
│         STM32 + FPGA CONTROL BOARD     │                │   │
│                                        │                │   │
│  ┌──────────────────────────────┐     │                │   │
│  │  STM32F303RE                 │     │                │   │
│  │   ADC1 + ADC2 ◄──────────────┼─────┘                │   │
│  │   (4 channels @ 10 kHz)      │                      │   │
│  │                              │                      │   │
│  │   SPI Master ────────┐       │                      │   │
│  │   (Send ADC data)    │       │                      │   │
│  │                      │       │                      │   │
│  │   UART: PC comms     │       │                      │   │
│  └──────────────────────┼───────┘                      │   │
│                         │                              │   │
│                         ↓ SPI (1 MHz)                  │   │
│  ┌──────────────────────┼──────────────────────────┐   │   │
│  │  FPGA (Artix-7)      │                          │   │   │
│  │                      │                          │   │   │
│  │   ┌──────────────────▼────────┐                │   │   │
│  │   │ SPI Slave Receiver        │                │   │   │
│  │   │ (4× ADC values)           │                │   │   │
│  │   └──────────────┬────────────┘                │   │   │
│  │                  ↓                              │   │   │
│  │   ┌──────────────────────────────┐             │   │   │
│  │   │ CONTROL ALGORITHM (Verilog)  │             │   │   │
│  │   │  - PR current controller     │             │   │   │
│  │   │  - PI voltage controller     │             │   │   │
│  │   │  - Modulation                │             │   │   │
│  │   └──────────────┬───────────────┘             │   │   │
│  │                  ↓                              │   │   │
│  │   ┌──────────────────────────────┐             │   │   │
│  │   │ PWM GENERATOR (8 channels)   │             │   │   │
│  │   │  - 10 kHz frequency          │             │   │   │
│  │   │  - Dead-time insertion       │             │   │   │
│  │   │  - Level-shifted carriers    │             │   │   │
│  │   └──────────────┬───────────────┘             │   │   │
│  │                  │                              │   │   │
│  │   8× PWM Outputs ├──────────────────────────────┼───┼───>
│  │                                                 │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### Interface: STM32 → FPGA (SPI)

**Protocol:**

```c
// STM32 sends 4× 16-bit ADC values via SPI
void send_adc_to_fpga(uint16_t* adc_values) {
    uint8_t tx_buffer[8];

    // Pack 4× 16-bit values into 8 bytes
    tx_buffer[0] = (adc_values[0] >> 8) & 0xFF;  // DC Bus 1 MSB
    tx_buffer[1] = adc_values[0] & 0xFF;         // DC Bus 1 LSB
    tx_buffer[2] = (adc_values[1] >> 8) & 0xFF;  // DC Bus 2 MSB
    tx_buffer[3] = adc_values[1] & 0xFF;         // DC Bus 2 LSB
    tx_buffer[4] = (adc_values[2] >> 8) & 0xFF;  // AC Voltage MSB
    tx_buffer[5] = adc_values[2] & 0xFF;         // AC Voltage LSB
    tx_buffer[6] = (adc_values[3] >> 8) & 0xFF;  // AC Current MSB
    tx_buffer[7] = adc_values[3] & 0xFF;         // AC Current LSB

    // Transmit via SPI
    HAL_SPI_Transmit(&hspi1, tx_buffer, 8, 100);
}

// Called at 10 kHz (from ADC DMA complete interrupt)
void HAL_ADC_ConvCpltCallback(ADC_HandleTypeDef* hadc) {
    send_adc_to_fpga(adc_buffer);
}
```

**Verilog SPI Receiver:**

```verilog
module spi_slave_adc_receiver (
    input wire clk,
    input wire rst,

    // SPI interface
    input wire spi_sclk,
    input wire spi_mosi,
    input wire spi_cs,

    // ADC data outputs
    output reg [15:0] adc_dc_bus1,
    output reg [15:0] adc_dc_bus2,
    output reg [15:0] adc_ac_voltage,
    output reg [15:0] adc_ac_current,
    output reg data_valid
);

    reg [7:0] rx_buffer [0:7];
    reg [2:0] byte_count;
    reg [2:0] bit_count;

    // SPI receiver (Mode 0: CPOL=0, CPHA=0)
    always @(posedge spi_sclk or posedge spi_cs) begin
        if (spi_cs) begin
            byte_count <= 0;
            bit_count <= 0;
            data_valid <= 0;
        end else begin
            // Shift in MOSI bit
            rx_buffer[byte_count][7 - bit_count] <= spi_mosi;
            bit_count <= bit_count + 1;

            if (bit_count == 7) begin
                bit_count <= 0;
                byte_count <= byte_count + 1;

                if (byte_count == 7) begin
                    // All 8 bytes received, parse ADC values
                    adc_dc_bus1    <= {rx_buffer[0], rx_buffer[1]};
                    adc_dc_bus2    <= {rx_buffer[2], rx_buffer[3]};
                    adc_ac_voltage <= {rx_buffer[4], rx_buffer[5]};
                    adc_ac_current <= {rx_buffer[6], rx_buffer[7]};
                    data_valid <= 1;
                    byte_count <= 0;
                end
            end
        end
    end

endmodule
```

### Alternative: FPGA Does ADC Directly (Sigma-Delta)

**If you want FPGA to read sensors directly:**

Use the Sigma-Delta ADC design from the addendum document:
- FPGA implements 4× Sigma-Delta ADCs in Verilog
- External comparators (LM339) interface sensors to FPGA
- STM32 is NOT needed for ADC (only for USB/UART comms)

**Trade-offs:**

| Approach | Pros | Cons |
|----------|------|------|
| **STM32 ADC → FPGA** | ✅ Fast (5 MSPS)<br>✅ Simple analog interface<br>✅ Proven SAR ADC | ⚠️ Extra chip (STM32)<br>⚠️ SPI overhead |
| **FPGA Sigma-Delta ADC** | ✅ No STM32 ADC needed<br>✅ Custom ADC design<br>✅ Educational | ⚠️ External comparators<br>⚠️ More complex design |

**Recommendation:** Use STM32 ADC for simplicity in Stage 2.

### Stage 2 Additional Components

| Component | Quantity | Part Number | Purpose | Unit Price | Total |
|-----------|----------|-------------|---------|------------|-------|
| **STM32F303RE Nucleo** | 1 | NUCLEO-F303RE | ADC + comms | $12 | $12 |
| **FPGA Dev Board** | 1 | Basys 3 (Artix-7) | Control + PWM | $150 | $150 |
| **Hybrid PCB** | 1 | Custom 10×10cm | STM32+FPGA interface | $10 | $10 |
| **Connectors/Wire** | - | Various | Interfaces | - | $8 |
| | | | | **TOTAL** | **$180** |

**Stage 2 Total Cost:** $180 (power stage) + $180 (control) = **$360**

---

## Stage 3: ASIC RISC-V

### Architecture

**Custom ASIC with integrated peripherals:**
- ✅ RISC-V CPU core (synthesized)
- ✅ Integrated ADC (SAR or Sigma-Delta)
- ✅ PWM peripheral (8 channels)
- ✅ Memory (SRAM, Flash)
- ✅ Communication (UART, SPI)

**This is a full "system-on-chip" (SoC) implementation.**

### Block Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                  UNIVERSAL POWER STAGE PCB                  │
│  4× Analog Outputs ────────────────────┐                    │
│  8× PWM Inputs <───────────────────────┼────────────────┐   │
└────────────────────────────────────────┼────────────────┼───┘
                                         │                │
┌────────────────────────────────────────┼────────────────┼───┐
│              ASIC RISC-V CHIP          │                │   │
│              (Custom Silicon)          │                │   │
│                                        │                │   │
│  ┌──────────────────────────────────────────────────┐  │   │
│  │  Analog Pins (4× inputs) ◄──────────┼────────────┼──┘   │
│  │  (0-3.3V range)                     │            │      │
│  └──────────────┬───────────────────────┘            │      │
│                 ↓                                    │      │
│  ┌──────────────────────────────────┐               │      │
│  │  INTEGRATED ADC PERIPHERAL       │               │      │
│  │  (SAR or Sigma-Delta)            │               │      │
│  │   - 4 channels                   │               │      │
│  │   - 12-bit resolution            │               │      │
│  │   - 10 kHz sampling              │               │      │
│  │   - DMA to memory                │               │      │
│  └──────────────┬───────────────────┘               │      │
│                 ↓                                    │      │
│  ┌──────────────────────────────────┐               │      │
│  │  RISC-V CPU CORE                 │               │      │
│  │  (RV32I or RV32IM)               │               │      │
│  │   - Control algorithm in C       │               │      │
│  │   - Reads ADC via registers      │               │      │
│  │   - Writes PWM via registers     │               │      │
│  └──────────────┬───────────────────┘               │      │
│                 ↓                                    │      │
│  ┌──────────────────────────────────┐               │      │
│  │  PWM PERIPHERAL                  │               │      │
│  │   - 8 channels                   │               │      │
│  │   - 10 kHz frequency             │               │      │
│  │   - Dead-time insertion          │               │      │
│  │   - Hardware modulation          │               │      │
│  └──────────────┬───────────────────┘               │      │
│                 │                                    │      │
│  8× PWM Output Pins ────────────────────────────────┼──────┼──>
│                                                      │      │
│  ┌──────────────────────────────────┐               │      │
│  │  OTHER PERIPHERALS               │               │      │
│  │   - UART (debug/comms)           │               │      │
│  │   - SPI (expansion)              │               │      │
│  │   - GPIO (status LEDs)           │               │      │
│  │   - Watchdog timer               │               │      │
│  └──────────────────────────────────┘               │      │
│                                                      │      │
│  ┌──────────────────────────────────┐               │      │
│  │  MEMORY                          │               │      │
│  │   - 32 KB SRAM                   │               │      │
│  │   - 128 KB Flash (program)       │               │      │
│  └──────────────────────────────────┘               │      │
│                                                      │      │
└──────────────────────────────────────────────────────┘      │
```

### ASIC ADC Options

**Option A: SAR ADC (like STM32)**

Synthesize a SAR ADC controller with external:
- Resistor ladder (R-2R DAC)
- Comparator
- Sample-and-hold

**Pros:** Fast (100 kSPS+), deterministic
**Cons:** Requires precision external components

**Option B: Sigma-Delta ADC**

Integrate Sigma-Delta modulator + decimation filter:
- External comparator only
- Digital filtering in ASIC
- Lower external component count

**Pros:** Few external parts, good noise rejection
**Cons:** Higher latency (100 µs)

**Recommendation for ASIC:** **Sigma-Delta ADC** (fewer external components, easier integration)

### ASIC Design Flow

**This is Stage 3, far in the future. High-level plan:**

1. **RTL Design (Verilog/VHDL):**
   - RISC-V core (use open-source: NEORV32, Ibex, PicoRV32)
   - ADC peripheral (Sigma-Delta modulator + CIC filter)
   - PWM peripheral (8-channel timer)
   - UART, SPI, GPIO peripherals
   - Memory controller

2. **Verification:**
   - Simulate in ModelSim/Verilator
   - Test on FPGA first (Stage 2 prototyping!)

3. **Synthesis:**
   - Use Synopsys Design Compiler or Cadence Genus
   - Target standard cell library (e.g., SkyWater 130nm, TSMC 180nm)

4. **Layout:**
   - Place & Route (Cadence Innovus)
   - DRC/LVS checks
   - GDS-II generation

5. **Fabrication:**
   - Submit to foundry (SkyWater via Google's OpenMPW program, or commercial)
   - Cost: $10k-100k+ depending on technology node

**For educational/thesis:** Consider using **SkyWater SKY130 PDK** (free 130nm process via Google's Open MPW shuttle)

### Stage 3 Components

| Component | Quantity | Part Number | Purpose | Unit Price | Total |
|-----------|----------|-------------|---------|------------|-------|
| **ASIC Chip** | 1 | Custom RISC-V SoC | Control + ADC + PWM | $50-100+ | $75 (estimate) |
| **Support Components** | - | Caps, resistors, crystal | ASIC support circuitry | - | $10 |
| **PCB** | 1 | Custom 8×8cm | ASIC breakout board | $10 | $10 |
| **Programming** | 1 | JTAG adapter | ASIC debug/program | $20 | $20 |
| | | | | **TOTAL** | **$115** |

**Stage 3 Total Cost:** $180 (power stage) + $115 (ASIC) = **$295**

**Note:** ASIC fabrication cost ($10k-100k) not included - assume using MPW shuttle or university fab access.

---

## Interface Specification

### Standard 16-Pin Connector

**Purpose:** Universal interface between power stage and all control boards.

**Pinout:**

| Pin | Signal | Direction | Type | Voltage Range | Description |
|-----|--------|-----------|------|---------------|-------------|
| 1 | DC_BUS1_SENSE | Power → Control | Analog | 0-2.048V | DC Bus 1 voltage (pre-scaled) |
| 2 | DC_BUS2_SENSE | Power → Control | Analog | 0-2.048V | DC Bus 2 voltage (pre-scaled) |
| 3 | AC_VOLTAGE_SENSE | Power → Control | Analog | 0-2.048V | AC output voltage (pre-scaled) |
| 4 | AC_CURRENT_SENSE | Power → Control | Analog | 0.5-4.5V | AC output current (ACS724) |
| 5 | ANALOG_GND | - | Ground | 0V | Analog ground reference |
| 6 | +3.3V_AUX | Power → Control | Power | 3.3V | Auxiliary power (optional) |
| 7 | PWM1_H1S1 | Control → Power | Digital | 0-5V | H-Bridge 1, Switch 1 (high-side) |
| 8 | PWM2_H1S2 | Control → Power | Digital | 0-5V | H-Bridge 1, Switch 2 (high-side) |
| 9 | PWM3_H1S3 | Control → Power | Digital | 0-5V | H-Bridge 1, Switch 3 (low-side) |
| 10 | PWM4_H1S4 | Control → Power | Digital | 0-5V | H-Bridge 1, Switch 4 (low-side) |
| 11 | PWM5_H2S5 | Control → Power | Digital | 0-5V | H-Bridge 2, Switch 5 (high-side) |
| 12 | PWM6_H2S6 | Control → Power | Digital | 0-5V | H-Bridge 2, Switch 6 (high-side) |
| 13 | PWM7_H2S7 | Control → Power | Digital | 0-5V | H-Bridge 2, Switch 7 (low-side) |
| 14 | PWM8_H2S8 | Control → Power | Digital | 0-5V | H-Bridge 2, Switch 8 (low-side) |
| 15 | +5V_POWER | Power → Control | Power | 5V | Main power supply |
| 16 | POWER_GND | - | Ground | 0V | Power ground |

**Connector Type:** 2×8 pin header (2.54mm pitch) or equivalent

**Cable:** 16-wire ribbon cable, max length 30cm

---

## Complete Bill of Materials

### Universal Power Stage PCB (Build Once!)

| Component | Quantity | Part Number | Unit Price | Total | Source |
|-----------|----------|-------------|------------|-------|--------|
| Power Switches (IGBTs) | 8 | IRGP4063D | $5 | $40 | Direnc.net, AliExpress |
| Gate Drivers | 4 | IR2110 | $3 | $12 | Direnc.net, AliExpress |
| AMC1301 Modules | 3 | AMC1301 breakout | $15 | $45 | AliExpress |
| ACS724 Sensor | 1 | ACS724LLCTR-10AB | $6 | $6 | AliExpress |
| Isolated DC-DC | 3 | B0505S-1W | $3 | $9 | AliExpress |
| Resistors 0.1% (voltage dividers) | 20 | Various | $0.60 | $12 | Direnc.net |
| Capacitors | 30 | Various | $0.30 | $9 | Direnc.net |
| 16-pin connector | 1 | Header + cable | $3 | $3 | Direnc.net |
| PCB (15×20cm) | 1 | Custom | $25 | $25 | JLCPCB |
| Heatsink | 1 | - | $10 | $10 | Direnc.net |
| Misc (wire, screws) | - | - | - | $10 | Direnc.net |
| | | | **TOTAL** | **$181** | |

### Stage 1: STM32 Only (+ Universal Power Stage)

| Component | Quantity | Part Number | Unit Price | Total |
|-----------|----------|-------------|------------|-------|
| **Universal Power Stage** | 1 | (see above) | $181 | $181 |
| STM32F303RE Nucleo | 1 | NUCLEO-F303RE | $12 | $12 |
| Adapter PCB (5×5cm) | 1 | Custom | $5 | $5 |
| Connectors/Wire | - | Various | - | $3 |
| | | | **TOTAL** | **$201** |

### Stage 2: STM32 + FPGA (+ Universal Power Stage)

| Component | Quantity | Part Number | Unit Price | Total |
|-----------|----------|-------------|------------|-------|
| **Universal Power Stage** | 1 | (see above) | $181 | $181 |
| STM32F303RE Nucleo | 1 | NUCLEO-F303RE | $12 | $12 |
| FPGA Dev Board | 1 | Basys 3 (Artix-7) | $150 | $150 |
| Hybrid PCB (10×10cm) | 1 | Custom | $10 | $10 |
| Connectors/Wire | - | Various | - | $8 |
| | | | **TOTAL** | **$361** |

### Stage 3: ASIC RISC-V (+ Universal Power Stage)

| Component | Quantity | Part Number | Unit Price | Total |
|-----------|----------|-------------|------------|-------|
| **Universal Power Stage** | 1 | (see above) | $181 | $181 |
| ASIC Chip | 1 | Custom RISC-V SoC | $75 | $75 |
| Support Components | - | Caps, resistors, crystal | - | $10 |
| ASIC PCB (8×8cm) | 1 | Custom | $10 | $10 |
| JTAG Adapter | 1 | Generic | $20 | $20 |
| | | | **TOTAL** | **$296** |

### Grand Total (All 3 Stages)

**If building all 3 stages with shared power stage:**

- Universal Power Stage: $181 (build once)
- Stage 1 control board: $20
- Stage 2 control board: $180
- Stage 3 control board: $115

**Total: $496**

(vs. $613 in original document - **$117 savings** with modular approach!)

---

## PCB Design Guidelines

### Universal Power Stage PCB

**Size:** 15cm × 20cm (fits standard enclosure)

**Layers:** 4-layer recommended
- Layer 1 (Top): High-voltage traces, power switches
- Layer 2 (Inner): Ground plane
- Layer 3 (Inner): Power plane (isolated sections)
- Layer 4 (Bottom): Low-voltage control, sensors

**Key Design Rules:**

1. **Isolation Clearances:**
   - High-voltage to low-voltage: 8mm creepage, 4mm clearance
   - PCB slot/cutout across isolation barrier
   - Follow IEC 60664-1 standards

2. **Power Stage:**
   - Wide traces for high current (5mm+ for 10A)
   - Short gate driver traces (<5cm)
   - Star grounding for power ground

3. **Sensor Circuitry:**
   - Separate analog ground plane
   - Guard rings around isolated amplifiers
   - Shield sensitive traces

4. **Connector Placement:**
   - 16-pin connector at board edge
   - Clear labeling (silk screen)
   - Strain relief for cable

**Example Layout:**

```
┌──────────────────────────────────────────────┐
│                                              │
│  High Voltage Section (Top half)             │
│  ┌────────┐         ┌────────┐              │
│  │H-Bridge│         │H-Bridge│              │
│  │   1    │         │   2    │              │
│  └────────┘         └────────┘              │
│      │                  │                    │
│  ┌───┴──────────────────┴───┐               │
│  │  Gate Drivers (4×)       │               │
│  └──────────────────────────┘               │
│                                              │
│  ═══════════════════════════════════════     │ <- PCB Slot
│  ════ Isolation Barrier (8mm) ═══════        │    (Reinforced
│  ═══════════════════════════════════════     │     Isolation)
│                                              │
│  Low Voltage Section (Bottom half)           │
│  ┌──────────────────────────────────┐       │
│  │ AMC1301  AMC1301  AMC1301  ACS724│       │
│  │   #1       #2       #3      Sensor│      │
│  └──────────────────────────────────┘       │
│                                              │
│  ┌──────────────────────────────────┐       │
│  │  B0505S  B0505S  B0505S          │       │
│  │  DC-DC   DC-DC   DC-DC           │       │
│  └──────────────────────────────────┘       │
│                                              │
│  ┌────────────────┐                         │
│  │   16-Pin       │                         │
│  │   Connector    │◄─ To Control Board      │
│  └────────────────┘                         │
│                                              │
└──────────────────────────────────────────────┘
```

### Control Board PCBs

**Stage 1:** Simple adapter (5×5cm)
- Just routes Nucleo pins to 16-pin connector
- Can use protoboard or custom PCB

**Stage 2:** Hybrid board (10×10cm)
- STM32 Nucleo socket
- FPGA dev board socket (or direct FPGA if custom)
- SPI interface traces
- 16-pin connector to power stage

**Stage 3:** ASIC breakout (8×8cm)
- ASIC chip (QFN/QFP package)
- Support circuitry (caps, crystal, etc.)
- JTAG header for programming
- 16-pin connector to power stage

---

## Summary

### ✅ Modular Architecture Benefits:

1. **One Power Stage for All:** Build the expensive part ($181) once, reuse forever
2. **Identical Sensing:** All stages read same 0-3.3V pre-isolated signals
3. **Standard Interface:** 16-pin connector (4× analog in, 8× PWM out, power/GND)
4. **Cost Savings:** $496 total vs. $613 (save $117)
5. **Easy Demonstration:** Quickly swap control boards to show different implementations

### 📊 Stage Comparison:

| Feature | Stage 1: STM32 | Stage 2: STM32+FPGA | Stage 3: ASIC RISC-V |
|---------|---------------|---------------------|---------------------|
| **ADC** | STM32 internal SAR | STM32 SAR | ASIC integrated Σ-Δ |
| **Control** | STM32 C code | FPGA Verilog | ASIC RISC-V C code |
| **PWM** | STM32 timers | FPGA logic | ASIC PWM peripheral |
| **Cost** | $201 | $361 | $296 |
| **Complexity** | Low | Medium | High |
| **Performance** | Good | Excellent | Excellent |
| **Educational Value** | Medium | High | Very High |

### 🎯 Recommended Implementation Order:

1. **First:** Design and build **Universal Power Stage PCB** (test with dummy load)
2. **Second:** Build **Stage 1 (STM32)** - validate control algorithm
3. **Third:** Build **Stage 2 (STM32+FPGA)** - port algorithm to FPGA, optimize
4. **Fourth:** Design **Stage 3 (ASIC)** - synthesize FPGA design to ASIC

---

**This modular approach is perfect for a thesis demonstration where you want to show progressive implementation across multiple platforms!**
