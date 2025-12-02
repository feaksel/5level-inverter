# Complete Sensing Design Guide
## Universal Architecture for All Implementation Stages

**Version:** 3.0
**Date:** 2025-12-02
**Status:** Consolidated Design Specification

---

## Table of Contents

1. [Overview](#overview)
2. [Universal Sensor Interface](#universal-sensor-interface)
3. [Stage 1: STM32 Internal ADC](#stage-1-stm32-internal-adc)
4. [Stage 2: FPGA Sigma-Delta ADC](#stage-2-fpga-sigma-delta-adc)
5. [Stage 3: ASIC Integration](#stage-3-asic-integration)
6. [Hardware Components](#hardware-components)
7. [Implementation Guide](#implementation-guide)
8. [Bill of Materials](#bill-of-materials)

---

## Overview

### System Requirements

**Signals to Measure:**

| Signal | Range | Accuracy | Bandwidth | Notes |
|--------|-------|----------|-----------|-------|
| DC Bus 1 Voltage | 0-60V | ±2% | 1 kHz | Isolated |
| DC Bus 2 Voltage | 0-60V | ±2% | 1 kHz | Isolated |
| AC Output Voltage | ±150V peak | ±1% | 5 kHz | Isolated (mandatory) |
| AC Output Current | ±15A peak | ±1% | 5 kHz | Isolated |

**Target Specifications:**
- ADC Resolution: 12-bit minimum (4096 levels)
- Sampling Rate: 10 kHz (synchronized with PWM)
- ADC Input: 0-3.3V (universal across all stages)
- Isolation: 2500V RMS minimum for high-voltage signals

### Architecture Philosophy

**One Power Stage + Multiple Control Boards**

```
┌─────────────────────────────────────────────────────────┐
│         UNIVERSAL POWER STAGE (Build Once)              │
│                                                         │
│  Sensors (Isolated):                                    │
│  ├─ 3× AMC1301 (voltage sensing, 7070V isolation)      │
│  └─ 1× ACS724 (current sensing, 2100V isolation)       │
│                                                         │
│  Output: 4× Analog Signals (0-3.3V)                     │
│  ├─ DC Bus 1: 0-2.048V                                 │
│  ├─ DC Bus 2: 0-2.048V                                 │
│  ├─ AC Voltage: 0-2.048V                               │
│  └─ AC Current: 0.5-4.5V                               │
└──────────────────┬──────────────────────────────────────┘
                   │ Standard 16-pin connector
                   │
      ┌────────────┼────────────┬──────────────┐
      │            │            │              │
      ▼            ▼            ▼              │
┌──────────┐ ┌──────────┐ ┌──────────┐        │
│ Stage 1  │ │ Stage 2  │ │ Stage 3  │        │
│ STM32    │ │ FPGA     │ │ ASIC     │        │
│ Internal │ │ Σ-Δ ADC  │ │ Integrated│       │
│ ADC      │ │ (Verilog)│ │ ADC      │        │
└──────────┘ └──────────┘ └──────────┘        │
```

---

## Universal Sensor Interface

### Isolation Stage (Built into Power PCB)

**Voltage Sensing: AMC1301 Isolated Amplifiers**

```
DC Bus (50V) ──┬─ 1MΩ ──┬─── VIN+ ──┐
               │         │           │ AMC1301
              GND    5.1kΩ           │ (7070V isolation)
                        │            │
                       GND ─ VIN- ───┤
                                     │
        5V_ISO ── VDD1 ──────────────┤
        GND_ISO ── GND1               │
                                     │
        3.3V ── VDD2 ─────────────────┤
        GND ── GND2                   │
                                     │
        Output (0-2.048V) ────────────┘
```

**Specifications:**
- Input range: ±250 mV differential
- Gain: 8.2× (fixed)
- Isolation: 7070V peak
- Bandwidth: 250 kHz
- Output: 0-2.048V (for ADC)

**Voltage Divider Calculations:**

For 50V DC Bus → 0.254V input:
- R1 = 1MΩ (0.1%, 0.6W)
- R2 = 5.1kΩ (0.1%, 0.25W)
- Ratio: 196:1
- Output: 50V / 196 × 8.2 = 2.09V

For 141V AC peak → 0.250V input:
- R1 = 2.2MΩ (0.1%, 0.6W)
- R2 = 3.9kΩ (0.1%, 0.25W)
- Ratio: 565:1

**Current Sensing: ACS724 Hall Effect Sensor**

```
AC Current Path (±10A)
    │
    └──[ PCB trace through sensor ]─── (Magnetic coupling)
                │
            ACS724
                │
        VOUT (0.5-4.5V) ──→ ADC

Center: 2.5V @ 0A
Sensitivity: 200 mV/A
```

**No additional isolation needed** - Hall effect provides built-in 2100V isolation.

**Isolated Power Supply: B0505S-1W**

```
Control 5V ──→ [B0505S-1W] ──→ 5V_ISO (for AMC1301)
             (1500V isolation)
```

Quantity: 3× (one per AMC1301 channel)

### Standard Interface Connector (16-pin)

| Pin | Signal | Type | Range | Description |
|-----|--------|------|-------|-------------|
| 1 | DC_BUS1 | Analog In | 0-2.048V | DC Bus 1 voltage |
| 2 | DC_BUS2 | Analog In | 0-2.048V | DC Bus 2 voltage |
| 3 | AC_VOLT | Analog In | 0-2.048V | AC output voltage |
| 4 | AC_CURR | Analog In | 0.5-4.5V | AC output current |
| 5 | AGND | Ground | 0V | Analog ground |
| 6 | +3.3V | Power | 3.3V | Auxiliary power |
| 7-14 | PWM[1:8] | Digital Out | 0-5V | PWM to gate drivers |
| 15 | +5V | Power | 5V | Main power |
| 16 | PGND | Ground | 0V | Power ground |

---

## Stage 1: STM32 Internal ADC

### Architecture

**Platform:** STM32F303RE Nucleo board
**ADC Type:** 12-bit SAR (Successive Approximation Register)
**Features:** 4× independent ADCs, 5 MSPS, simultaneous sampling

```
┌────────────────────────────────────────┐
│      STM32F303RE Nucleo                │
│                                        │
│  ADC1 (12-bit SAR)                     │
│  ├─ PA0: DC Bus 1 ◄────────── Pin 1   │
│  └─ PA1: DC Bus 2 ◄────────── Pin 2   │
│                                        │
│  ADC2 (12-bit SAR)                     │
│  ├─ PA4: AC Voltage ◄──────── Pin 3   │
│  └─ PA5: AC Current ◄──────── Pin 4   │
│                                        │
│  DMA: Auto-transfer to memory          │
│  Timer1: Trigger ADC @ 10 kHz          │
│                                        │
│  Control Algorithm (C code)            │
│  ├─ PR current controller              │
│  ├─ PI voltage controller              │
│  └─ Level-shifted modulation           │
│                                        │
│  Timer1 + Timer8: 8× PWM outputs       │
└────────────────────────────────────────┘
```

### Configuration Code

```c
void ADC_Init(void) {
    // ADC1: DC bus voltages
    hadc1.Instance = ADC1;
    hadc1.Init.Resolution = ADC_RESOLUTION_12B;
    hadc1.Init.ScanConvMode = ADC_SCAN_ENABLE;
    hadc1.Init.ExternalTrigConv = ADC_EXTERNALTRIGCONV_T1_TRGO;
    hadc1.Init.DMAContinuousRequests = ENABLE;
    HAL_ADC_Init(&hadc1);

    // Configure channels PA0, PA1
    // ...

    // ADC2: AC voltage and current (simultaneous)
    hadc2.Instance = ADC2;
    // ... similar config
}

// Conversion functions
float get_dc_bus1_voltage(uint16_t adc_counts) {
    float vout_adc = adc_counts * 3.3f / 4095.0f;
    float vin_amc1301 = vout_adc / 8.2f;  // AMC1301 gain
    float vin_actual = vin_amc1301 * 196.0f;  // Divider ratio
    return vin_actual;
}

float get_ac_current(uint16_t adc_counts) {
    float vout_adc = adc_counts * 3.3f / 4095.0f;
    return (vout_adc - 2.5f) / 0.2f;  // ACS724: 200mV/A
}
```

### Stage 1 BOM

| Component | Qty | Cost |
|-----------|-----|------|
| STM32F303RE Nucleo | 1 | $12 |
| Adapter PCB (5×5cm) | 1 | $5 |
| Connectors/wire | - | $3 |
| **TOTAL** | | **$20** |

**+ Universal Power Stage: $181**
**Stage 1 Total: $201**

---

## Stage 2: FPGA Sigma-Delta ADC

### Why Sigma-Delta?

**Advantages:**
- ✅ Minimal external components (comparator only)
- ✅ Pure digital design → **Direct ASIC port**
- ✅ Good noise rejection (oversampling)
- ✅ No precision resistor ladders needed
- ✅ Educational value (learn ADC architectures)

**vs. Alternatives:**

| ADC Type | External Parts | ASIC Portable | Cost |
|----------|---------------|---------------|------|
| **Sigma-Delta** | 1× comparator + RC | ✅ Yes | **$7** |
| SAR | Resistor ladder + comp + S&H | ⚠️ Partial | $15 |
| Flash | Many comparators (2^N-1) | ❌ No | $20+ |
| External chip | ADC IC + isolator | ❌ No | $15 |

### Architecture

```
Sensor Output ──┬─ RC Filter ──→ Comparator ──→ FPGA GPIO
(0-2V)          ↑                LM339              │
                │                                   ↓
FPGA GPIO ──────┴──── 1kΩ               Sigma-Delta Modulator
(DAC bit)                                (Verilog)
                                             │ 1-bit @ 1MHz
                                             ↓
                                    CIC Decimation Filter
                                         (Verilog)
                                             │
                                             ↓
                                    12-bit output @ 10kHz
```

### Verilog Implementation

**1. Sigma-Delta Modulator:**

```verilog
module sigma_delta_modulator (
    input wire clk,              // 100 MHz
    input wire rst,
    input wire comparator_in,    // 1-bit from LM339
    output reg dac_out,          // 1-bit to RC filter
    output reg bitstream_out,    // To decimator
    output reg clk_1mhz          // Sampling clock
);
    // Clock divider: 100MHz → 1MHz
    reg [6:0] clk_div;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            clk_div <= 0;
            clk_1mhz <= 0;
        end else if (clk_div == 49) begin
            clk_div <= 0;
            clk_1mhz <= ~clk_1mhz;
        end else
            clk_div <= clk_div + 1;
    end

    // Digital integrator
    reg signed [31:0] integrator;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            integrator <= 0;
            dac_out <= 0;
        end else if (clk_div == 0 && clk_1mhz) begin
            // Error signal = input - feedback
            integrator <= integrator +
                (comparator_in ? 32'sd32768 : -32'sd32768) -
                (dac_out ? 32'sd32768 : -32'sd32768);

            // 1-bit quantizer
            dac_out <= (integrator >= 0);
            bitstream_out <= dac_out;
        end
    end
endmodule
```

**2. CIC Decimation Filter (3rd order):**

```verilog
module cic_decimator #(
    parameter N = 3,      // Order
    parameter R = 100,    // Decimation ratio (1MHz→10kHz)
    parameter W = 32      // Width
)(
    input wire clk,
    input wire rst,
    input wire data_in,           // 1-bit @ 1MHz
    input wire data_valid_in,
    output reg [15:0] data_out,   // 16-bit @ 10kHz
    output reg data_valid_out
);
    // Integrator stages (run at 1MHz)
    reg [W-1:0] integrator [0:N-1];
    integer i;

    always @(posedge clk or posedge rst) begin
        if (rst)
            for (i = 0; i < N; i = i + 1)
                integrator[i] <= 0;
        else if (data_valid_in) begin
            integrator[0] <= integrator[0] + (data_in ? 1 : 0);
            for (i = 1; i < N; i = i + 1)
                integrator[i] <= integrator[i] + integrator[i-1];
        end
    end

    // Decimation counter
    reg [7:0] decim_count;
    reg [W-1:0] snapshot;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            decim_count <= 0;
            data_valid_out <= 0;
        end else if (data_valid_in) begin
            decim_count <= decim_count + 1;
            data_valid_out <= 0;
            if (decim_count == R-1) begin
                decim_count <= 0;
                snapshot <= integrator[N-1];
                data_valid_out <= 1;
            end
        end
    end

    // Comb stages (run at 10kHz)
    reg [W-1:0] comb [0:N-1];
    reg [W-1:0] comb_delay [0:N-1];

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < N; i = i + 1) begin
                comb[i] <= 0;
                comb_delay[i] <= 0;
            end
        end else if (data_valid_out) begin
            comb[0] <= snapshot - comb_delay[0];
            comb_delay[0] <= snapshot;
            for (i = 1; i < N; i = i + 1) begin
                comb[i] <= comb[i-1] - comb_delay[i];
                comb_delay[i] <= comb[i-1];
            end
            data_out <= comb[N-1][W-1:W-16];
        end
    end
endmodule
```

**3. Complete 4-Channel ADC:**

```verilog
module fpga_adc_4ch (
    input wire clk_100mhz,
    input wire rst,
    input wire [3:0] comp_in,     // From LM339
    output wire [3:0] dac_out,    // To RC filters
    output wire [15:0] adc_ch0,   // DC Bus 1
    output wire [15:0] adc_ch1,   // DC Bus 2
    output wire [15:0] adc_ch2,   // AC Voltage
    output wire [15:0] adc_ch3,   // AC Current
    output wire [3:0] data_valid
);
    // Instantiate 4 channels
    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin : adc
            wire bitstream, clk_1mhz;

            sigma_delta_modulator mod (
                .clk(clk_100mhz),
                .rst(rst),
                .comparator_in(comp_in[i]),
                .dac_out(dac_out[i]),
                .bitstream_out(bitstream),
                .clk_1mhz(clk_1mhz)
            );

            cic_decimator dec (
                .clk(clk_100mhz),
                .rst(rst),
                .data_in(bitstream),
                .data_valid_in(clk_1mhz),
                .data_out(i == 0 ? adc_ch0 :
                          i == 1 ? adc_ch1 :
                          i == 2 ? adc_ch2 : adc_ch3),
                .data_valid_out(data_valid[i])
            );
        end
    endgenerate
endmodule
```

### Hardware Interface

**Comparator Board (1× LM339 quad comparator):**

```
Channel 0 (DC Bus 1):
  Sensor ──┬─ 1kΩ ─┬─ 100nF ─┬─── LM339 Pin 4 (+)
           │        │         │
  FPGA ────┴─ 1kΩ ──┘        GND ── LM339 Pin 5 (-)
  GPIO                              │
                          Output ───┴─── FPGA GPIO (comp_in[0])

(Repeat for channels 1, 2, 3)
```

**Component List:**

| Qty | Component | Cost |
|-----|-----------|------|
| 1 | LM339N quad comparator | $0.60 |
| 8 | Resistor 1kΩ (1%) | $0.40 |
| 8 | Capacitor 100nF | $0.80 |
| 1 | PCB (5×5cm) | $5.00 |
| **TOTAL** | | **$6.80** |

### Performance

| Parameter | Value |
|-----------|-------|
| Resolution | 12-14 bit ENOB |
| Sampling Rate | 10 kHz per channel |
| Oversampling Ratio | 100× (1MHz/10kHz) |
| Latency | 100 µs |
| FPGA Resources | ~800 LUTs (4 ch) |

### Stage 2 BOM

| Component | Qty | Cost |
|-----------|-----|------|
| FPGA Board (Basys 3) | 1 | $150 |
| Comparator interface | 1 | $7 |
| Interface PCB | 1 | $5 |
| Connectors/wire | - | $3 |
| **TOTAL** | | **$165** |

**+ Universal Power Stage: $181**
**Stage 2 Total: $346**

---

## Stage 3: ASIC Integration

### ASIC Migration Strategy

**FPGA Σ-Δ Design → Direct ASIC Port**

**What Reuses Directly:**
- ✅ Sigma-Delta modulator (100% digital RTL)
- ✅ CIC decimation filter (100% digital RTL)
- ✅ Control algorithm logic
- ✅ Register interface

**What Needs Analog Design:**
- ⚠️ Comparator (integrate on-chip or keep external)
- ⚠️ RC filter (integrate or external)
- ⚠️ Reference voltage

**Integration Levels:**

| Level | Description | Cost | Complexity |
|-------|-------------|------|------------|
| **Level 1** | Digital ASIC + external comparator | ~$10 | Low |
| **Level 2** | Mixed-signal ASIC (on-chip comparator) | ~$20 | Medium |
| **Level 3** | Full custom (integrated filters) | ~$50+ | High |

### Example: SkyWater SKY130 (Open-Source PDK)

**Free fabrication via Google MPW shuttle:**

1. **Reuse FPGA Verilog** (Σ-Δ + CIC)
2. **Add analog comparator:**
   - Use SKY130 standard cell library
   - Or design custom (2-transistor differential pair)
3. **Synthesize with OpenLane**
4. **Submit to shuttle** (free for educational use)
5. **Wait 6-9 months** for chips

**Result:** Custom ASIC with integrated ADC for ~$0 fabrication cost

---

## Hardware Components

### Universal Power Stage Components

| Component | Qty | Part Number | Unit Cost | Total |
|-----------|-----|-------------|-----------|-------|
| **Isolation** |
| AMC1301 Module | 3 | AMC1301 breakout | $15 | $45 |
| ACS724 Current Sensor | 1 | ACS724LLCTR-10AB | $6 | $6 |
| B0505S Isolated DC-DC | 3 | B0505S-1W | $3 | $9 |
| **Power Stage** |
| Power Switches (IGBTs) | 8 | IRGP4063D | $5 | $40 |
| Gate Drivers | 4 | IR2110 | $3 | $12 |
| **Passives** |
| Resistors 0.1% (dividers) | 20 | 1MΩ, 5.1kΩ, etc. | $0.60 | $12 |
| Capacitors | 30 | 100nF, 10µF | $0.30 | $9 |
| **PCB & Misc** |
| Power Stage PCB (15×20cm) | 1 | Custom | $25 | $25 |
| Heatsink | 1 | - | $10 | $10 |
| Connectors, wire | - | Various | - | $13 |
| **TOTAL** | | | | **$181** |

### Component Sourcing (Turkey)

**Available Locally (Direnc.net, SAMM):**
- ✅ STM32 Nucleo boards
- ✅ LM339 comparator
- ✅ Resistors, capacitors
- ✅ Connectors, wire

**Order from AliExpress (2-4 weeks):**
- AMC1301 modules (~$15 each)
- ACS724 sensors (~$6 each)
- B0505S DC-DC converters (~$3 each)
- FPGA board (Basys 3 clone ~$150)

---

## Implementation Guide

### Phase 1: Universal Power Stage (2 weeks)

**Tasks:**
1. Order components from AliExpress (AMC1301, ACS724, B0505S)
2. Order local components from Direnc.net
3. Design power stage PCB (15×20cm, 4-layer)
   - High-voltage section (top half)
   - Isolation barrier (8mm slot)
   - Low-voltage section (bottom half)
4. Assemble and test with dummy load
5. Verify sensor outputs: 4× 0-3.3V signals

**Deliverable:** Working power stage with isolated sensors

### Phase 2A: STM32 Implementation (1 week)

**Tasks:**
1. Configure STM32F303RE ADCs (4 channels, DMA, 10kHz)
2. Implement conversion functions
3. Test ADC readings with bench power supply
4. Calibrate offset and gain
5. Implement control algorithm (PR + PI)
6. Generate PWM outputs (8 channels)
7. Closed-loop testing

**Deliverable:** Stage 1 complete and tested

### Phase 2B: FPGA ADC Implementation (2 weeks)

**Tasks:**
1. Build comparator interface board (LM339 + RC filters)
2. Implement Sigma-Delta modulator (Verilog)
3. Implement CIC decimation filter (Verilog)
4. Create testbench and simulate
5. Synthesize for Artix-7 FPGA
6. Test on hardware with DC signals
7. Calibrate and verify accuracy
8. Integrate with existing PWM generator

**Deliverable:** Stage 2 complete with FPGA ADC

### Phase 3: ASIC Design (Optional, 4-8 weeks)

**Tasks:**
1. Port Verilog to ASIC flow (OpenLane/SkyWater)
2. Add analog comparator (schematic or Verilog-A)
3. Simulate mixed-signal design
4. Layout and DRC/LVS checks
5. Submit GDS-II to MPW shuttle
6. Wait for fabrication (6-9 months)
7. Test ASIC chips

**Deliverable:** Stage 3 ASIC prototype

---

## Bill of Materials

### Complete Cost Breakdown

| Stage | Description | Cost | Notes |
|-------|-------------|------|-------|
| **Universal Power Stage** | (Build once, use for all) | **$181** | AMC1301 + ACS724 + power switches |
| **Stage 1** | STM32 only | +$20 | Nucleo + adapter PCB |
| **Stage 2** | FPGA Σ-Δ ADC | +$165 | Basys 3 + comparator board |
| **Stage 3** | ASIC (estimate) | +$75 | Custom chip + support |

### Total Costs

- **Stage 1 only:** $201
- **Stage 2 only:** $346
- **Stage 3 only:** $256
- **All 3 stages (shared power stage):** $441

### Comparison Summary

| Approach | Total Cost | ASIC Portable | Educational Value |
|----------|------------|---------------|-------------------|
| STM32 internal ADC | $201 | ❌ No | ⭐⭐⭐ |
| **FPGA Σ-Δ ADC** | **$346** | **✅ Yes** | **⭐⭐⭐⭐⭐** |
| External ADC chip | $361 | ❌ No | ⭐⭐ |

---

## Quick Reference

### Sensor Output Scaling

**DC Bus Voltage (AMC1301):**
```c
float V_actual = (ADC_counts * 3.3V / 4095) / 8.2 * 196
```

**AC Current (ACS724):**
```c
float I_actual = ((ADC_counts * 3.3V / 4095) - 2.5V) / 0.2V/A
```

### Calibration Procedure

1. **Zero offset:** Measure at 0V/0A, record offset
2. **Gain:** Apply known 50V, adjust gain factor
3. **Store:** Save calibration constants in EEPROM/flash

### Troubleshooting

**Low ADC readings:**
- Check isolation power (B0505S output should be 5V)
- Verify AMC1301 output with scope
- Check voltage divider resistor values

**Noisy readings:**
- Add 100nF capacitors on ADC inputs
- Check grounding (star ground for analog)
- Increase averaging (software filter)

---

## Summary

**This document provides complete sensing design for all stages:**

✅ **Universal sensor interface** - Build once, use everywhere
✅ **Stage 1 (STM32)** - Fast prototyping with internal ADC
✅ **Stage 2 (FPGA)** - Custom Σ-Δ ADC in Verilog (ASIC-ready)
✅ **Stage 3 (ASIC)** - Direct migration path with open-source tools
✅ **Complete BOM** - Sourcing guide for Turkey
✅ **Implementation roadmap** - Step-by-step guide

**Start with:** Universal power stage + your chosen control board approach.

**Recommended for thesis/learning:** Stage 2 (FPGA Σ-Δ ADC)
