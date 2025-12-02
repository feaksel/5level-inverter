# ADC Selection and Isolation Guide for 5-Level Inverter Project

**Document Version:** 1.0
**Created:** 2025-11-29
**Target Application:** 5-Level Cascaded H-Bridge Multilevel Inverter (500W, 100V RMS)
**Deployment Location:** Turkey

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Isolation Requirements Analysis](#isolation-requirements-analysis)
3. [ADC Selection Criteria](#adc-selection-criteria)
4. [Solution 1: STM32F303RE Internal ADC (Stage 2)](#solution-1-stm32f303re-internal-adc-stage-2)
5. [Solution 2: Isolated SAR ADC for FPGA (Stage 3)](#solution-2-isolated-sar-adc-for-fpga-stage-3)
6. [Solution 3: Isolated SAR ADC for RISC-V (Stage 4)](#solution-3-isolated-sar-adc-for-risc-v-stage-4)
7. [Isolation Circuit Designs](#isolation-circuit-designs)
8. [Turkey Sourcing Guide](#turkey-sourcing-guide)
9. [Complete Bill of Materials](#complete-bill-of-materials)
10. [Implementation Roadmap](#implementation-roadmap)
11. [References](#references)

---

## Executive Summary

### Project Requirements Recap

Your 5-level inverter project requires sensing 4 analog signals:
- **3× Voltage measurements:** DC Bus 1 (50V), DC Bus 2 (50V), AC Output (141V peak)
- **1× Current measurement:** AC Output current (up to 10A)

All measurements must be **galvanically isolated** from the high-voltage power stage for safety.

### System Architecture (3 Simultaneous Demonstrations)

You are building **3 separate systems** running simultaneously:

1. **Stage 2:** STM32F303RE microcontroller implementation
2. **Stage 3:** FPGA-based implementation
3. **Stage 4:** RISC-V soft-core implementation

Each system will have its own dedicated ADC and sensing circuitry.

### Key Findings

| Stage | ADC Solution | Isolation Method | Estimated Cost | Availability in Turkey |
|-------|-------------|------------------|----------------|----------------------|
| Stage 2 (STM32) | **STM32F303RE Internal ADC** | Analog isolation amplifiers | **$40-60** | ✅ Good (Direnc.net, SAMM) |
| Stage 3 (FPGA) | **MCP3208 SAR ADC** | Analog isolation + digital isolation | **$50-70** | ⚠️ Partial (AliExpress) |
| Stage 4 (RISC-V) | **ADS1256 Module** | Pre-isolated module from AliExpress | **$35-50** | ✅ Good (AliExpress) |

### Critical Safety Requirement

⚠️ **ALL ADC inputs must be galvanically isolated from the high-voltage inverter** to protect:
- Low-voltage control circuitry (3.3V/5V)
- Microcontroller/FPGA
- Programmer/debugger
- **You (the operator)**

**Failure to isolate can result in:**
- Equipment destruction
- Electric shock
- Fire hazard

---

## Isolation Requirements Analysis

### Why Isolation is Mandatory

Your power inverter operates at dangerous voltages:
- DC bus: 50V (each cell)
- AC output: 100V RMS (141V peak)
- Total cascaded voltage: Up to 100V DC

**Ground reference problems:**
- The high-voltage power stage "ground" is NOT the same as your control board "ground"
- Voltage differences between grounds can reach 100V or more
- Direct connection = **immediate damage**

### Isolation Barrier Requirements

According to safety standards (IEC 61010-1, IEC 60664-1):

| Parameter | Minimum Requirement | Recommended |
|-----------|-------------------|-------------|
| **Isolation voltage** | 1000V DC | 2500V RMS or higher |
| **Creepage distance** | 4mm (Pollution Degree 2) | 8mm |
| **Clearance distance** | 2.5mm | 4mm |
| **Working voltage** | 150V DC | 100V DC (with margin) |

### What Needs Isolation

1. **Analog signal paths** (voltage/current measurements)
   - Use isolated amplifiers (AMC1301, ACPL-C87A, etc.)
   - OR use isolation amplifiers + isolated ADC

2. **Digital signal paths** (SPI/I2C from ADC to controller)
   - Use digital isolators (ISO7762, ADUM3201, 6N137, etc.)

3. **Power supplies** (ADC chip power on high-voltage side)
   - Use isolated DC-DC converters (B0505S-1W, MEE1S0505SC, etc.)

---

## ADC Selection Criteria

### Specifications Needed

| Parameter | Requirement | Reason |
|-----------|------------|--------|
| **Channels** | 4 minimum (3 voltage + 1 current) | Sensing requirements |
| **Resolution** | 12-bit minimum | 0.024% resolution (adequate for 5% THD target) |
| **Sampling rate** | 10 kSPS minimum | Control loop at 10 kHz |
| **Input range** | 0-3.3V or 0-5V | After voltage dividers/amplifiers |
| **Interface** | SPI or I2C | Common microcontroller interfaces |
| **Isolation** | 2500V RMS minimum | Safety requirement |

### SAR ADC Candidates

| ADC Chip | Channels | Resolution | Speed | Interface | Package | Available in Turkey? |
|----------|----------|------------|-------|-----------|---------|---------------------|
| **MCP3208** | 8 single-ended | 12-bit | 100 kSPS | SPI | DIP-16/SOIC-16 | ✅ Yes (Direnc.net, AliExpress) |
| **MCP3008** | 8 single-ended | 10-bit | 200 kSPS | SPI | DIP-16/SOIC-16 | ✅ Yes (very common) |
| **ADS7828** | 8 single-ended | 12-bit | 50 kSPS | I2C | TSSOP-16 | ⚠️ AliExpress only |
| **ADS1256** | 8 differential | 24-bit | 30 kSPS | SPI | TSSOP-28 | ✅ Module on AliExpress |

**Verdict:**
- **MCP3208**: Best choice for hobbyist (DIP package, easy to solder, adequate specs)
- **ADS1256**: Overkill resolution but available as ready-made module

---

## Solution 1: STM32F303RE Internal ADC (Stage 2)

### Why Use Internal ADC?

The **STM32F303RE** has exceptional ADC capabilities:
- **4× independent 12-bit ADCs**
- **5 MSPS sampling rate** (500× faster than needed!)
- **Simultaneous sampling mode** (critical for phase measurements)
- **DMA support** (zero CPU overhead)
- **No external ADC chip needed** (cost savings)

### System Block Diagram

```
HIGH VOLTAGE SIDE (ISOLATED)          ISOLATION BARRIER          LOW VOLTAGE SIDE (CONTROL)
┌─────────────────────────┐                                     ┌────────────────────────────┐
│ DC Bus 1 (50V)          │                                     │                            │
│   └─ Test point         │─────[ Voltage Divider ]────────────>│ Isolated Amplifier         │
│                         │      (50:1 scaling)                 │ (AMC1301 or ACPL-C87A)     │
│ DC Bus 2 (50V)          │                                     │   Output: 0-2.5V           │
│   └─ Test point         │─────[ Voltage Divider ]────────────>│ Isolated Amplifier         │─────>│ ADC1 CH1 (PA0)  │
│                         │      (50:1 scaling)                 │   Output: 0-2.5V           │      │                │
│ AC Output (141V pk)     │                                     │                            │      │ ADC1 CH2 (PA1)  │
│   └─ Test point         │─────[ Voltage Divider ]────────────>│ Isolated Amplifier         │─────>│                │
│                         │      (57:1 scaling)                 │   Output: 0-2.5V           │      │ ADC2 CH1 (PA4)  │
│ AC Current (10A)        │                                     │                            │      │                │
│   └─ Shunt resistor     │─────[ ACS724LLCTR-10AB ]───────────>│ (Built-in isolation!)      │─────>│ ADC2 CH2 (PA5)  │
│      or ACS724          │      Isolated Hall sensor           │   Output: 0.5-4.5V         │      │                │
│                         │                                     │                            │      └────────────────┘
└─────────────────────────┘                                     └────────────────────────────┘      STM32F303RE
                                                                                                     ADC Inputs
```

### Isolated Amplifier Options for Voltage Sensing

#### Option A: AMC1301 (Texas Instruments) - Recommended

**Specifications:**
- Input range: ±250mV differential
- Gain: 8.2× (fixed)
- Isolation: 7070V peak (reinforced)
- Bandwidth: 250 kHz
- Delay: 3 µs
- Package: SOIC-8 (wide body, DWV)

**Circuit:**

```
DC Bus 1 (50V) ──┬─ 1MΩ ──┬─── VIN+ (AMC1301) ───┐
                 │         │                       │ Isolated barrier (7070V)
                GND     100kΩ                      │
                         │                         │
                        GND ─ VIN- (AMC1301) ───   │
                                                    │
                        5V_ISO ── VDD1 (AMC1301)    │
                        GND_ISO ── GND1             │
                                                    │
        STM32 5V ────────────── VDD2 (AMC1301) ────┤
        STM32 GND ──────────── GND2                 │
                                                    │
        STM32 ADC ──────────── VOUT (AMC1301) ─────┘
                               (0-2.048V output)
```

**Voltage Divider Calculation:**
- DC Bus 1: 50V input
- Divider ratio: 50V / 0.25V = 200:1
- R1 = 1MΩ, R2 = 5.1kΩ → Ratio = 196:1 ✅
- Input to AMC1301: 50V / 196 = 0.255V (within ±250mV)
- Output from AMC1301: 0.255V × 8.2 = 2.09V (within ADC range)

**Availability:**
- ⚠️ **Not commonly stocked in Turkey**
- ✅ Available as **ready-made module on Amazon/AliExpress** (~$15-20)
  - Search: "AMC1301 module"
  - Example: [Amazon AMC1301 Module](https://www.amazon.com/EC-Buying-Isolation-Acquisition-Bandwidth/dp/B0BMPV9K42)

#### Option B: ACPL-C87A/C87B (Broadcom/Avago) - Easier to Source

**Specifications:**
- Input range: 0-2V single-ended
- Gain: 8× (fixed)
- Isolation: 5000V RMS (1 minute test)
- Bandwidth: 200 kHz
- Delay: 1.6 µs
- Package: SOIC-8 (stretched SO-8)

**Circuit:**

```
DC Bus 1 (50V) ──┬─ 1MΩ ──┬─── VIN+ (ACPL-C87A) ──┐
                 │         │                       │ Isolated barrier (5000V RMS)
                GND     20kΩ                       │
                         │                         │
                        GND ─ VIN- (GND)           │
                                                    │
                        5V_ISO ── VDD1              │
                        GND_ISO ── GND1             │
                                                    │
        STM32 5V ────────────── VDD2 ───────────────┤
        STM32 GND ──────────── GND2                 │
                                                    │
        STM32 ADC ──────────── VOUT ────────────────┘
                               (0-2.5V output)
```

**Voltage Divider Calculation:**
- DC Bus 1: 50V input
- Divider ratio: 50V / 2V = 25:1
- R1 = 1MΩ, R2 = 40kΩ → Ratio = 26:1 ✅
- Input to ACPL-C87A: 50V / 26 = 1.92V (within 0-2V)
- Output from ACPL-C87A: 1.92V × 1 = 1.92V (within ADC range)

**Availability:**
- ⚠️ Limited in Turkey (check Direnc.net)
- ✅ AliExpress: ~$5-10 per chip

#### Option C: Optocoupler-Based Linear Isolation (Budget Solution)

**Chip:** IL300 (Vishay) - Linear optocoupler

**Specifications:**
- Input: LED current 0-10mA
- Transfer ratio: 0.01% typical
- Isolation: 5000V RMS
- Linearity: ±0.05%
- Package: DIP-8

**Circuit:**

```
DC Bus 1 (50V) ──┬─ 10MΩ ──┬─── LED Anode (IL300) ──┐
                 │          │                        │ Optical coupling (5000V)
                GND      100kΩ                       │
                          │                          │
                         LED Cathode (GND1)          │
                                                     │
                         VCC (5V_ISO)                │
                         GND1                        │
                                                     │
        STM32 5V ──────── VCC2 ──────────────────────┤
        STM32 GND ─────── GND2                       │
                          Photodiode Cathode         │
                          │                          │
        STM32 ADC ────────┴─ 10kΩ ─── Photodiode Anode
                          │
                         GND
```

**Availability:**
- ⚠️ Limited availability
- ✅ Alternative: 4N35 + op-amp feedback (more complex)

### Current Sensor: ACS724LLCTR-10AB (Allegro) - Built-in Isolation!

**Specifications:**
- Sensing range: -10A to +10A (bidirectional)
- Isolation: 2100V RMS
- Technology: Hall effect (galvanic isolation built-in)
- Output: 0.5V to 4.5V (2.5V at 0A)
- Sensitivity: 200 mV/A
- Bandwidth: 120 kHz
- Package: SOIC-16

**Wiring:**

```
AC Output Current Path
    │
    └───[ PCB Trace Through ACS724 ]───
        (Magnetic coupling, no electrical connection!)
                    │
                    │ Isolated output
                    │
                    └──> VOUT (0.5-4.5V) ──> STM32 ADC

        VCC (5V from STM32) ──> ACS724 VCC
        GND (STM32 GND)     ──> ACS724 GND
```

**No additional isolation needed!** The Hall effect sensor provides built-in isolation.

**Availability:**
- ⚠️ Not commonly stocked in Turkey
- ✅ **AliExpress:** ~$4-6 per chip
- ⚠️ Watch for counterfeit chips!

**Alternative:** ACS712 (older, more common, lower bandwidth)

### Isolated Power Supply for High-Side Circuitry

**Why needed?**
- Isolated amplifiers (AMC1301/ACPL-C87A) need isolated 5V power on the high-voltage side
- Cannot share ground with control board

**Recommended Module:** B0505S-1W (Mornsun/Hi-Link/Generic)

**Specifications:**
- Input: 4.5-5.5V DC
- Output: 5V DC, 200mA (1W)
- Isolation: 1500V DC
- Efficiency: 80%
- Package: SIP-4

**Wiring:**

```
STM32 5V ──>  VIN (+)  [B0505S-1W]  VOUT (+)  ──> VDD_ISO (for AMC1301)
STM32 GND ──> VIN (-)              VOUT (-)  ──> GND_ISO

              ││││││││││││││││││││││││
              Isolation barrier (1500V)
```

**Quantity Needed:**
- 3× isolated power supplies (one per voltage channel)
- OR 1× higher-power isolated supply (2W or 5W) shared between channels

**Availability:**
- ⚠️ Not commonly stocked in Turkey
- ✅ **AliExpress:** ~$2-3 per module
- ✅ Search: "B0505S-1W" or "isolated DC-DC 5V"

### STM32F303RE ADC Configuration

**Pinout:**

| Signal | STM32 Pin | ADC Channel | Purpose |
|--------|-----------|-------------|---------|
| DC Bus 1 Voltage | PA0 | ADC1_IN1 | Isolated amplifier output |
| DC Bus 2 Voltage | PA1 | ADC1_IN2 | Isolated amplifier output |
| AC Output Voltage | PA4 | ADC2_IN1 | Isolated amplifier output |
| AC Output Current | PA5 | ADC2_IN2 | ACS724 output |

**Software Configuration (STM32 HAL):**

```c
// ADC initialization
ADC_HandleTypeDef hadc1;
ADC_HandleTypeDef hadc2;

void ADC_Init(void) {
    // Configure ADC1 (DC bus voltages)
    hadc1.Instance = ADC1;
    hadc1.Init.ClockPrescaler = ADC_CLOCK_ASYNC_DIV1;
    hadc1.Init.Resolution = ADC_RESOLUTION_12B;
    hadc1.Init.DataAlign = ADC_DATAALIGN_RIGHT;
    hadc1.Init.ScanConvMode = ADC_SCAN_ENABLE;  // Multi-channel
    hadc1.Init.ContinuousConvMode = DISABLE;
    hadc1.Init.DiscontinuousConvMode = DISABLE;
    hadc1.Init.ExternalTrigConv = ADC_EXTERNALTRIGCONV_T1_TRGO;  // Trigger from Timer 1
    hadc1.Init.ExternalTrigConvEdge = ADC_EXTERNALTRIGCONVEDGE_RISING;
    hadc1.Init.DMAContinuousRequests = ENABLE;
    HAL_ADC_Init(&hadc1);

    // Configure ADC1 channels
    ADC_ChannelConfTypeDef sConfig = {0};
    sConfig.Channel = ADC_CHANNEL_1;  // PA0 - DC Bus 1
    sConfig.Rank = ADC_REGULAR_RANK_1;
    sConfig.SamplingTime = ADC_SAMPLETIME_19CYCLES_5;
    HAL_ADC_ConfigChannel(&hadc1, &sConfig);

    sConfig.Channel = ADC_CHANNEL_2;  // PA1 - DC Bus 2
    sConfig.Rank = ADC_REGULAR_RANK_2;
    HAL_ADC_ConfigChannel(&hadc1, &sConfig);

    // Configure ADC2 (AC output voltage and current)
    hadc2.Instance = ADC2;
    hadc2.Init.ClockPrescaler = ADC_CLOCK_ASYNC_DIV1;
    hadc2.Init.Resolution = ADC_RESOLUTION_12B;
    hadc2.Init.DataAlign = ADC_DATAALIGN_RIGHT;
    hadc2.Init.ScanConvMode = ADC_SCAN_ENABLE;
    hadc2.Init.ContinuousConvMode = DISABLE;
    hadc2.Init.ExternalTrigConv = ADC_EXTERNALTRIGCONV_T1_TRGO;
    hadc2.Init.ExternalTrigConvEdge = ADC_EXTERNALTRIGCONVEDGE_RISING;
    hadc2.Init.DMAContinuousRequests = ENABLE;
    HAL_ADC_Init(&hadc2);

    // Configure ADC2 channels
    sConfig.Channel = ADC_CHANNEL_1;  // PA4 - AC Output Voltage
    sConfig.Rank = ADC_REGULAR_RANK_1;
    HAL_ADC_ConfigChannel(&hadc2, &sConfig);

    sConfig.Channel = ADC_CHANNEL_2;  // PA5 - AC Output Current
    sConfig.Rank = ADC_REGULAR_RANK_2;
    HAL_ADC_ConfigChannel(&hadc2, &sConfig);
}

// DMA buffer for ADC results
uint16_t adc_buffer[4];  // [DC1, DC2, AC_V, AC_I]

void ADC_Start_DMA(void) {
    // Start ADC1 with DMA
    HAL_ADC_Start_DMA(&hadc1, (uint32_t*)&adc_buffer[0], 2);

    // Start ADC2 with DMA (simultaneous with ADC1)
    HAL_ADC_Start_DMA(&hadc2, (uint32_t*)&adc_buffer[2], 2);
}

// Conversion from ADC counts to real units
float convert_dc_bus_voltage(uint16_t adc_counts) {
    // AMC1301 output: 0-2.048V for 0-250mV input
    // Input voltage divider: 196:1
    // Full scale: 250mV * 196 = 49V
    // ADC: 12-bit, Vref = 3.3V
    float vout = (float)adc_counts * 3.3f / 4095.0f;  // AMC1301 output voltage
    float vin_amp = vout / 8.2f;  // AMC1301 gain = 8.2
    float vin_divider = vin_amp * 196.0f;  // Voltage divider ratio
    return vin_divider;
}

float convert_ac_voltage(uint16_t adc_counts) {
    // Similar calculation with 57:1 divider
    float vout = (float)adc_counts * 3.3f / 4095.0f;
    float vin_amp = vout / 8.2f;
    float vin_divider = vin_amp * 196.0f;  // Adjust ratio for AC
    return vin_divider;
}

float convert_current(uint16_t adc_counts) {
    // ACS724: 200mV/A, centered at 2.5V
    // 0A → 2.5V, +10A → 4.5V, -10A → 0.5V
    float vout = (float)adc_counts * 3.3f / 4095.0f;
    float current = (vout - 2.5f) / 0.2f;  // 200mV/A sensitivity
    return current;
}
```

### Stage 2 Bill of Materials

| Component | Quantity | Part Number | Purpose | Unit Price | Total | Source |
|-----------|----------|-------------|---------|------------|-------|--------|
| STM32F303RE Nucleo | 1 | NUCLEO-F303RE | Microcontroller | $12 | $12 | Direnc.net, SAMM |
| Isolated Amplifier | 3 | AMC1301 module | Voltage sensing isolation | $15 | $45 | AliExpress |
| Current Sensor | 1 | ACS724LLCTR-10AB | Current sensing | $6 | $6 | AliExpress |
| Isolated DC-DC | 3 | B0505S-1W | Power isolation | $3 | $9 | AliExpress |
| Resistors 0.1% | 20 | Various | Voltage dividers | $0.50 | $10 | Direnc.net |
| Capacitors | 20 | 0.1µF, 10µF | Filtering | $0.20 | $4 | Direnc.net |
| PCB (control board) | 1 | Custom | Component mounting | $15 | $15 | JLCPCB / local |
| **TOTAL** | | | | | **$101** | |

**Note:** Prices are approximate and may vary.

---

## Solution 2: Isolated SAR ADC for FPGA (Stage 3)

### Why External ADC for FPGA?

FPGAs typically **do not have built-in ADCs** (except for Xilinx Zynq SoC or Intel SoC-FPGAs). You need an external ADC chip.

### Recommended ADC: MCP3208 (Microchip)

**Why MCP3208?**
- ✅ 12-bit resolution (adequate for control)
- ✅ 8 channels (you need 4)
- ✅ 100 kSPS sampling rate (10× faster than needed)
- ✅ SPI interface (easy to implement in FPGA)
- ✅ DIP-16 and SOIC-16 packages (easy to solder)
- ✅ Available in Turkey (Direnc.net) and AliExpress
- ✅ Hobbyist-friendly (~$5)

**Specifications:**

| Parameter | Value |
|-----------|-------|
| Resolution | 12-bit (4096 levels) |
| Channels | 8 single-ended OR 4 differential |
| Sampling rate | 100 kSPS (at 3.3V) |
| Input range | 0 - VREF (typ. 3.3V or 5V) |
| Interface | SPI (4-wire: CLK, MOSI, MISO, CS) |
| Supply voltage | 2.7V - 5.5V |
| Package | DIP-16, SOIC-16 |

### Isolation Architecture

Since MCP3208 is **NOT isolated**, you must isolate:
1. **Analog inputs** (voltage/current sensors) → Use isolated amplifiers
2. **Digital SPI signals** → Use digital isolators
3. **Power supply** → Use isolated DC-DC converter

**System Block Diagram:**

```
HIGH VOLTAGE SIDE (ISOLATED)          ISOLATION BARRIER          LOW VOLTAGE SIDE (CONTROL)
┌─────────────────────────┐                                     ┌────────────────────────────┐
│ DC Bus 1 (50V)          │                                     │ Isolated Amplifier         │
│   └─ Test point         │─────[ Voltage Divider ]────────────>│ (AMC1301 or ACPL-C87A)     │
│                         │      (50:1 scaling)                 │   Output: 0-2.5V           │─────>│ MCP3208 CH0    │
│ DC Bus 2 (50V)          │                                     │                            │      │                │
│   └─ Test point         │─────[ Voltage Divider ]────────────>│ Isolated Amplifier         │─────>│ MCP3208 CH1    │
│                         │      (50:1 scaling)                 │   Output: 0-2.5V           │      │                │
│ AC Output (141V pk)     │                                     │                            │      │ MCP3208 CH2    │
│   └─ Test point         │─────[ Voltage Divider ]────────────>│ Isolated Amplifier         │─────>│                │
│                         │      (57:1 scaling)                 │   Output: 0-2.5V           │      │ MCP3208 CH3    │
│ AC Current (10A)        │                                     │                            │      │                │
│   └─ ACS724             │─────[ Built-in isolation ]─────────>│   Output: 0.5-4.5V         │─────>│ (SPI ADC)      │
│                         │                                     │                            │      └────────────────┘
└─────────────────────────┘                                     └────────────────────────────┘             │
                                                                                                            │ SPI signals
                                                                    ┌────────────────────────────┐          │
                                                                    │ Digital Isolator           │<─────────┘
                                                                    │ (ISO7762 or ADUM3201)      │
                                                                    │   - CLK isolation          │
                                                                    │   - MOSI isolation         │
                                                                    │   - MISO isolation         │
                                                                    │   - CS isolation           │
                                                                    └────────────────────────────┘
                                                                                │
                                                                                └──> FPGA SPI Master
```

### Analog Isolation: Same as Stage 2

Use the same isolated amplifiers:
- **AMC1301 modules** (3×) for voltage sensing
- **ACS724** (1×) for current sensing
- **B0505S-1W** (3×) for isolated power supplies

See [Solution 1](#solution-1-stm32f303re-internal-adc-stage-2) for detailed circuits.

### Digital Isolation: SPI Signal Isolators

**Why needed?**
- MCP3208 SPI signals (CLK, MOSI, MISO, CS) connect to FPGA
- MCP3208 shares ground with analog isolation circuits (low-voltage side)
- FPGA may have different ground reference
- **Optional but recommended** for robust system

**Recommended Chip:** ISO7762 (Texas Instruments)

**Specifications:**
- 6 channels, bidirectional
- 2500V RMS isolation
- 150 Mbps data rate (way more than SPI needs)
- Wide supply: 2.25V - 5.5V both sides
- Package: SOIC-16

**Wiring:**

```
MCP3208 (Low-voltage side)              FPGA (Control side)

   CLK ──────>  IN1  [ISO7762]  OUT1  ──────> FPGA CLK
   MOSI ─────>  IN2            OUT2  ──────> FPGA MOSI
   MISO <─────  OUT3           IN3   <────── FPGA MISO
   CS ───────>  IN4            OUT4  ──────> FPGA CS

   VCC (3.3V)   VCC1            VCC2    FPGA 3.3V
   GND          GND1            GND2    FPGA GND

                ││││││││││││││││││││
                Isolation barrier (2500V)
```

**Alternative (Budget Option):** High-speed optocouplers

**Chip:** 6N137 (Vishay) - 10 Mbps optocoupler

You need 4× 6N137 chips (one per SPI signal: CLK, MOSI, MISO, CS).

**Wiring (per signal):**

```
MCP3208 Signal ──┬─ 220Ω ── LED Anode [6N137] Photodetector ── Pull-up 10kΩ ── FPGA 3.3V
                 │                                    │                │
                GND         LED Cathode              GND1             FPGA Signal

                            VCC (5V isolated)
                            GND1

                            ││││││││││││││
                            Optical isolation
```

**Availability:**
- ✅ **ISO7762:** AliExpress (~$3-5)
- ✅ **6N137:** Common, available at Direnc.net (~$1 each)

### MCP3208 SPI Interface (FPGA Implementation)

**SPI Timing:**
- Clock frequency: Up to 1 MHz (at 3.3V supply)
- Mode: SPI Mode 0 or 3 (CPOL=0, CPHA=0 or CPOL=1, CPHA=1)

**Verilog SPI Master Example:**

```verilog
module mcp3208_spi_master (
    input wire clk,              // FPGA clock (e.g., 50 MHz)
    input wire rst,              // Reset
    input wire [2:0] channel,    // ADC channel (0-7)
    input wire start,            // Start conversion
    output reg [11:0] adc_data,  // 12-bit result
    output reg done,             // Conversion complete

    // SPI signals
    output reg spi_clk,
    output reg spi_cs,
    output reg spi_mosi,
    input wire spi_miso
);

    // SPI clock divider (50 MHz → 1 MHz SPI clock)
    reg [5:0] clk_div;
    wire spi_clk_en = (clk_div == 0);

    always @(posedge clk or posedge rst) begin
        if (rst)
            clk_div <= 0;
        else if (clk_div == 49)
            clk_div <= 0;
        else
            clk_div <= clk_div + 1;
    end

    // State machine
    localparam IDLE = 0, START_BIT = 1, MODE_BIT = 2, CHANNEL_BITS = 3,
               DATA_BITS = 4, DONE_STATE = 5;
    reg [2:0] state;
    reg [4:0] bit_count;
    reg [15:0] shift_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            spi_cs <= 1;
            spi_clk <= 0;
            spi_mosi <= 0;
            done <= 0;
            bit_count <= 0;
        end else if (spi_clk_en) begin
            case (state)
                IDLE: begin
                    spi_cs <= 1;
                    spi_clk <= 0;
                    done <= 0;
                    if (start) begin
                        spi_cs <= 0;
                        state <= START_BIT;
                        shift_reg <= {5'b11000, channel, 8'b0};  // Command: start + single-ended + channel
                        bit_count <= 0;
                    end
                end

                START_BIT: begin
                    spi_mosi <= shift_reg[15];
                    shift_reg <= {shift_reg[14:0], 1'b0};
                    spi_clk <= ~spi_clk;
                    if (spi_clk) begin  // Rising edge
                        bit_count <= bit_count + 1;
                        if (bit_count == 4)
                            state <= DATA_BITS;
                    end
                end

                DATA_BITS: begin
                    spi_clk <= ~spi_clk;
                    if (~spi_clk) begin  // Falling edge - sample MISO
                        shift_reg <= {shift_reg[14:0], spi_miso};
                        bit_count <= bit_count + 1;
                        if (bit_count == 16) begin
                            adc_data <= shift_reg[11:0];
                            state <= DONE_STATE;
                        end
                    end
                end

                DONE_STATE: begin
                    spi_cs <= 1;
                    spi_clk <= 0;
                    done <= 1;
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule
```

**Using the module:**

```verilog
// Instantiate ADC controller
wire [11:0] dc_bus1_raw, dc_bus2_raw, ac_voltage_raw, current_raw;
wire adc_done;
reg adc_start;
reg [2:0] adc_channel;

mcp3208_spi_master adc_controller (
    .clk(clk_50mhz),
    .rst(reset),
    .channel(adc_channel),
    .start(adc_start),
    .adc_data(adc_data_out),
    .done(adc_done),
    .spi_clk(spi_clk),
    .spi_cs(spi_cs),
    .spi_mosi(spi_mosi),
    .spi_miso(spi_miso)
);

// Sequencer to read all 4 channels at 10 kHz
reg [1:0] channel_index;
always @(posedge clk_50mhz) begin
    if (adc_done) begin
        case (channel_index)
            0: dc_bus1_raw <= adc_data_out;
            1: dc_bus2_raw <= adc_data_out;
            2: ac_voltage_raw <= adc_data_out;
            3: current_raw <= adc_data_out;
        endcase
        channel_index <= channel_index + 1;
        if (channel_index == 3) begin
            // All channels read, trigger control loop
        end
    end

    // Trigger next conversion
    adc_start <= (channel_index < 4) && !adc_start && adc_done;
    adc_channel <= channel_index;
end
```

### Stage 3 Bill of Materials

| Component | Quantity | Part Number | Purpose | Unit Price | Total | Source |
|-----------|----------|-------------|---------|------------|-------|--------|
| FPGA Dev Board | 1 | Basys 3 (Artix-7) | FPGA platform | $150 | $150 | Direnc.net? / AliExpress |
| MCP3208 ADC | 1 | MCP3208-CI/P | 12-bit SAR ADC | $5 | $5 | Direnc.net, AliExpress |
| Isolated Amplifier | 3 | AMC1301 module | Voltage sensing | $15 | $45 | AliExpress |
| Current Sensor | 1 | ACS724LLCTR-10AB | Current sensing | $6 | $6 | AliExpress |
| Isolated DC-DC | 3 | B0505S-1W | Power isolation | $3 | $9 | AliExpress |
| Digital Isolator | 1 | ISO7762FDW | SPI isolation | $4 | $4 | AliExpress |
| Resistors 0.1% | 20 | Various | Voltage dividers | $0.50 | $10 | Direnc.net |
| Capacitors | 20 | 0.1µF, 10µF | Filtering | $0.20 | $4 | Direnc.net |
| PCB (ADC board) | 1 | Custom | Component mounting | $10 | $10 | JLCPCB / local |
| **TOTAL** | | | | | **$243** | |

---

## Solution 3: Isolated SAR ADC for RISC-V (Stage 4)

### Recommended: ADS1256 Module from AliExpress (Easiest!)

**Why ADS1256 Module?**
- ✅ **Ready-made module** with everything integrated
- ✅ **24-bit resolution** (extreme overkill, but available)
- ✅ **8 differential channels** (you need 4)
- ✅ **SPI interface** (easy to connect to RISC-V soft-core)
- ✅ **Available on AliExpress** (~$10-15)
- ⚠️ **NOT isolated** - still need analog isolation

**Alternative:** Use the same MCP3208 solution as Stage 3.

### ADS1256 Module Specifications

| Parameter | Value |
|-----------|-------|
| Resolution | 24-bit (16.7 million levels) |
| Channels | 8 differential or 8 single-ended |
| Sampling rate | Up to 30 kSPS |
| Input range | ±VREF (typically ±2.5V) |
| Interface | SPI (4-wire) |
| Supply voltage | 5V (module includes LDO regulator) |
| Built-in PGA | 1× to 64× programmable gain |

**Module Pinout (typical):**

```
ADS1256 Module
┌─────────────────┐
│ VCC (5V)        │
│ GND             │
│ SCLK (SPI CLK)  │
│ DIN (MOSI)      │
│ DOUT (MISO)     │
│ CS              │
│ DRDY (Data Ready)│
│ RESET           │
│                 │
│ AIN0            │─┐
│ AIN1            │ │ Differential
│ AIN2            │ │ inputs
│ AIN3            │ │
│ AIN4            │ │
│ AIN5            │ │
│ AIN6            │ │
│ AIN7            │ │
│ AINCOM (common) │─┘
└─────────────────┘
```

### Isolation Architecture (Same as Stage 3)

**System Block Diagram:**

```
HIGH VOLTAGE SIDE (ISOLATED)          ISOLATION BARRIER          LOW VOLTAGE SIDE (CONTROL)
┌─────────────────────────┐                                     ┌────────────────────────────┐
│ DC Bus 1 (50V)          │                                     │ Isolated Amplifier         │
│ DC Bus 2 (50V)          │─────[ Voltage Dividers ]───────────>│ (AMC1301 × 3)              │─────>│ ADS1256 Module │
│ AC Output (141V pk)     │      (50:1, 57:1)                   │   Outputs: 0-2.5V          │      │ AIN0, AIN1,    │
│ AC Current (10A)        │                                     │                            │      │ AIN2, AIN3     │
│   └─ ACS724             │─────[ Built-in isolation ]─────────>│   Output: 0.5-4.5V         │─────>│                │
└─────────────────────────┘                                     └────────────────────────────┘      └────────────────┘
                                                                                                            │
                                                                    ┌────────────────────────────┐          │ SPI
                                                                    │ Digital Isolator           │<─────────┘
                                                                    │ (ISO7762)                  │
                                                                    └────────────────────────────┘
                                                                                │
                                                                                └──> RISC-V SPI
```

### RISC-V SPI Driver (C Code)

**Assuming RISC-V soft-core on FPGA with SPI peripheral:**

```c
#include <stdint.h>

// ADS1256 register addresses
#define ADS1256_REG_STATUS   0x00
#define ADS1256_REG_MUX      0x01
#define ADS1256_REG_ADCON    0x02
#define ADS1256_REG_DRATE    0x03

// ADS1256 commands
#define ADS1256_CMD_WAKEUP   0x00
#define ADS1256_CMD_RDATA    0x01
#define ADS1256_CMD_RDATAC   0x03
#define ADS1256_CMD_SDATAC   0x0F
#define ADS1256_CMD_RREG     0x10
#define ADS1256_CMD_WREG     0x50
#define ADS1256_CMD_SELFCAL  0xF0
#define ADS1256_CMD_SYNC     0xFC
#define ADS1256_CMD_STANDBY  0xFD
#define ADS1256_CMD_RESET    0xFE

// SPI peripheral base address (adjust for your RISC-V system)
#define SPI_BASE 0x10040000
#define SPI_TXDATA   (*(volatile uint32_t*)(SPI_BASE + 0x48))
#define SPI_RXDATA   (*(volatile uint32_t*)(SPI_BASE + 0x4C))
#define SPI_CSMODE   (*(volatile uint32_t*)(SPI_BASE + 0x18))

// GPIO for CS and DRDY (adjust pins)
#define ADS1256_CS_PIN    10
#define ADS1256_DRDY_PIN  11

void spi_transfer(uint8_t tx_data, uint8_t* rx_data) {
    SPI_TXDATA = tx_data;
    while ((SPI_RXDATA & 0x80000000) == 0);  // Wait for RX ready
    if (rx_data)
        *rx_data = SPI_RXDATA & 0xFF;
}

void ads1256_write_reg(uint8_t reg, uint8_t value) {
    gpio_write(ADS1256_CS_PIN, 0);  // Assert CS
    spi_transfer(ADS1256_CMD_WREG | (reg & 0x0F), NULL);
    spi_transfer(0x00, NULL);  // Write 1 register
    spi_transfer(value, NULL);
    gpio_write(ADS1256_CS_PIN, 1);  // Deassert CS
}

uint8_t ads1256_read_reg(uint8_t reg) {
    uint8_t value;
    gpio_write(ADS1256_CS_PIN, 0);
    spi_transfer(ADS1256_CMD_RREG | (reg & 0x0F), NULL);
    spi_transfer(0x00, NULL);  // Read 1 register
    spi_transfer(0x00, &value);
    gpio_write(ADS1256_CS_PIN, 1);
    return value;
}

void ads1256_init(void) {
    // Reset ADS1256
    gpio_write(ADS1256_CS_PIN, 0);
    spi_transfer(ADS1256_CMD_RESET, NULL);
    delay_us(10);
    gpio_write(ADS1256_CS_PIN, 1);
    delay_ms(1);

    // Configure data rate (30 kSPS)
    ads1256_write_reg(ADS1256_REG_DRATE, 0xF0);

    // Configure ADCON (PGA gain = 1, buffer enable)
    ads1256_write_reg(ADS1256_REG_ADCON, 0x00);

    // Self-calibration
    gpio_write(ADS1256_CS_PIN, 0);
    spi_transfer(ADS1256_CMD_SELFCAL, NULL);
    gpio_write(ADS1256_CS_PIN, 1);
    delay_ms(10);
}

int32_t ads1256_read_channel(uint8_t channel) {
    // Set MUX to single-ended input (channel vs. AINCOM)
    uint8_t mux_value = (channel << 4) | 0x08;  // POS=channel, NEG=AINCOM
    ads1256_write_reg(ADS1256_REG_MUX, mux_value);

    // Sync and start conversion
    gpio_write(ADS1256_CS_PIN, 0);
    spi_transfer(ADS1256_CMD_SYNC, NULL);
    delay_us(5);
    spi_transfer(ADS1256_CMD_WAKEUP, NULL);
    gpio_write(ADS1256_CS_PIN, 1);

    // Wait for DRDY (data ready)
    while (gpio_read(ADS1256_DRDY_PIN) == 1);

    // Read 24-bit result
    uint8_t msb, mid, lsb;
    gpio_write(ADS1256_CS_PIN, 0);
    spi_transfer(ADS1256_CMD_RDATA, NULL);
    delay_us(10);
    spi_transfer(0x00, &msb);
    spi_transfer(0x00, &mid);
    spi_transfer(0x00, &lsb);
    gpio_write(ADS1256_CS_PIN, 1);

    // Combine bytes (24-bit signed, extend to 32-bit)
    int32_t result = ((int32_t)msb << 16) | ((int32_t)mid << 8) | lsb;
    if (result & 0x800000)  // Sign extend
        result |= 0xFF000000;

    return result;
}

// Read all 4 channels
void ads1256_read_all_channels(int32_t* data) {
    for (uint8_t ch = 0; ch < 4; ch++) {
        data[ch] = ads1256_read_channel(ch);
    }
}

// Convert ADC counts to voltages
float convert_ads1256_to_voltage(int32_t adc_counts, float vref) {
    // ADS1256: 24-bit, ±VREF range
    // Full scale: 2^23 = 8388608
    return (float)adc_counts * vref / 8388608.0f;
}
```

### Stage 4 Bill of Materials

| Component | Quantity | Part Number | Purpose | Unit Price | Total | Source |
|-----------|----------|-------------|---------|------------|-------|--------|
| FPGA Dev Board | 1 | Basys 3 (Artix-7) | RISC-V platform | $150 | $150 | AliExpress |
| ADS1256 Module | 1 | HX711 / ADS1256 | 24-bit ADC module | $12 | $12 | AliExpress |
| Isolated Amplifier | 3 | AMC1301 module | Voltage sensing | $15 | $45 | AliExpress |
| Current Sensor | 1 | ACS724LLCTR-10AB | Current sensing | $6 | $6 | AliExpress |
| Isolated DC-DC | 3 | B0505S-1W | Power isolation | $3 | $9 | AliExpress |
| Digital Isolator | 1 | ISO7762FDW | SPI isolation | $4 | $4 | AliExpress |
| Resistors 0.1% | 20 | Various | Voltage dividers | $0.50 | $10 | Direnc.net |
| Capacitors | 20 | 0.1µF, 10µF | Filtering | $0.20 | $4 | Direnc.net |
| PCB (ADC board) | 1 | Custom | Component mounting | $10 | $10 | JLCPCB / local |
| **TOTAL** | | | | | **$250** | |

---

## Isolation Circuit Designs

### Voltage Divider Design

**Purpose:** Scale high voltages (50V, 141V) to low voltages (0-2.5V) safe for isolated amplifiers.

**Design Constraints:**
- Input impedance: >100kΩ (minimize loading on power circuit)
- Tolerance: 0.1% or better (for accurate measurements)
- Power dissipation: <0.5W

**DC Bus Voltage Divider (50V → 0.25V):**

```
DC Bus (+50V) ──┬─── R1 (1MΩ, 0.1%, 0.6W) ───┬─── VOUT (0.255V) ──> Isolated Amplifier
                │                             │
               GND                          R2 (5.1kΩ, 0.1%, 0.25W)
                                              │
                                             GND
```

**Calculations:**
- Ratio: (R1 + R2) / R2 = (1,000,000 + 5,100) / 5,100 = 197
- Output voltage: 50V / 197 = 0.254V ✅ (within AMC1301 ±250mV range)
- Current: 50V / 1,005,100Ω = 49.7µA
- Power in R1: I² × R1 = (49.7µA)² × 1MΩ = 2.47mW ✅
- Power in R2: I² × R2 = (49.7µA)² × 5.1kΩ = 0.013mW ✅

**AC Output Voltage Divider (141V peak → 0.25V):**

```
AC Output (±141V) ──┬─── R1 (2.2MΩ, 0.1%, 0.6W) ───┬─── VOUT (0.25V) ──> Isolated Amplifier
                    │                               │
                   GND                            R2 (3.9kΩ, 0.1%, 0.25W)
                                                    │
                                                   GND
```

**Calculations:**
- Ratio: (2,200,000 + 3,900) / 3,900 = 565
- Output voltage: 141V / 565 = 0.250V ✅
- Current (at peak): 141V / 2,203,900Ω = 64µA
- Power in R1: (64µA)² × 2.2MΩ = 9mW (average over AC cycle: ~4.5mW) ✅

**Component Selection:**
- Use **metal film resistors** (low temperature coefficient)
- Tolerance: **0.1%** or better (Vishay Dale TNPW series recommended)
- Power rating: 2× calculated power (safety margin)
- Add **100nF ceramic capacitor** parallel to R2 for noise filtering

### Isolated Amplifier Circuit (AMC1301)

**Full schematic for one voltage channel:**

```
HIGH VOLTAGE SIDE (ISOLATED)                      LOW VOLTAGE SIDE (CONTROL)

VIN (50V) ──┬─ R1 (1MΩ) ──┬─── VIN+ ──┐           ┌─── VOUT ──> ADC input (0-2V)
            │              │           │           │
           GND          R2 (5.1kΩ)     │ AMC1301   │
                           │           │ (SOIC-8)  │
                          GND ─ VIN- ──┤ Isolation │
                                       │  Barrier  │
         5V_ISO (from B0505S) ── VDD1 ─┤ 7070V pk  │─ VDD2 ── 5V (from STM32/FPGA)
                                       │           │
         GND_ISO ────────────── GND1 ──┤           │─ GND2 ── GND (STM32/FPGA)
                                       └───────────┘

C1 (100nF) ─┬─ VDD1                  C3 (10µF)  ─┬─ VDD2
            │                                    │
          GND_ISO                               GND

C2 (10µF)  ─┘                        C4 (100nF) ─┘
```

**Component List (per channel):**
- 1× AMC1301 (or ACPL-C87A)
- 1× R1 (1MΩ, 0.1%, 0.6W, metal film)
- 1× R2 (5.1kΩ, 0.1%, 0.25W, metal film)
- 1× C1 (100nF ceramic, X7R, 50V)
- 1× C2 (10µF electrolytic, 25V)
- 1× C3 (10µF electrolytic, 16V)
- 1× C4 (100nF ceramic, X7R, 25V)

**PCB Layout Guidelines:**
- Maintain **8mm creepage** and **4mm clearance** across isolation barrier
- Use **PCB slot** or **cutout** between high/low voltage sides for reinforced isolation
- Keep high-voltage traces away from board edges
- Add **ground plane** on low-voltage side only

### Isolated Power Supply Circuit (B0505S-1W)

**Schematic:**

```
LOW VOLTAGE SIDE                    HIGH VOLTAGE SIDE (ISOLATED)

5V (from STM32/FPGA) ──┬─ C1 (10µF) ───┬─── VIN+ ──┐         ┌─── VOUT+ ──┬─ C3 (10µF) ─── 5V_ISO
                       │                │           │ B0505S  │            │
                      GND            C2 (100nF)     │  1W     │         C4 (100nF)
                                       │            │ Module  │            │
                      GND ───────────  VIN- ────────┤ (SIP-4) │──── VOUT- ┴─────────────── GND_ISO
                                                    │         │
                                                    │ 1500V   │
                                                    │Isolation│
                                                    └─────────┘
```

**Load Calculation:**
- AMC1301 supply current: ~5mA (typical)
- Total for 3 channels: 15mA
- B0505S-1W output: 200mA max ✅ (plenty of headroom)

**You can share one B0505S-1W across all 3 voltage channels** if desired.

### Digital Isolator Circuit (ISO7762)

**Schematic for SPI isolation:**

```
ADC SIDE (LOW-VOLTAGE)                 CONTROLLER SIDE (FPGA/RISC-V)

MCP3208 CLK  ──┬─────── IN1A ──┐      ┌─── OUT1A ──┬─────── FPGA CLK
               │                │      │            │
               └─ 100nF         │      │     100nF ─┘
                                │      │
MCP3208 MOSI ──┬─────── IN2A ───┤      │─── OUT2A ──┬─────── FPGA MOSI
               │                │ ISO  │            │
               └─ 100nF         │ 7762 │     100nF ─┘
                                │      │
MCP3208 MISO ──┬─────── OUT1B ──┤      │─── IN1B ───┬─────── FPGA MISO
               │                │      │            │
               └─ 100nF         │      │     100nF ─┘
                                │      │
MCP3208 CS ────┬─────── IN3A ───┤      │─── OUT3A ──┬─────── FPGA CS
               │                │      │            │
               └─ 100nF         │      │     100nF ─┘
                                │      │
       3.3V ───┬─ 10µF ── VCC1 ─┤      │─ VCC2 ── 10µF ─┬─── FPGA 3.3V
               │                │      │                │
               └─ 100nF         │ 2500V│         100nF ─┘
                                │Barrier│
       GND ─────────────── GND1 ┤      │─ GND2 ───────────── FPGA GND
                                └──────┘
```

**Note:** If ADC and controller share the same ground, digital isolation is **optional**.

### Current Sensor Circuit (ACS724)

**Schematic:**

```
HIGH VOLTAGE SIDE (AC OUTPUT)         LOW VOLTAGE SIDE (CONTROL)

AC Current Path (10A max)             ┌─────────────────────┐
      │                               │  ACS724LLCTR-10AB   │
      └─────[ PCB trace ]─────        │  (SOIC-16)          │
            Through sensor     ──────>│  Hall effect sensor │
            (magnetic coupling)       │  2100V isolation    │───> VOUT ─┬─ 100nF ── ADC input
                                      │                     │           │           (0.5-4.5V)
                                      └─────────────────────┘          GND
                                             │    │
                                      5V ────┴─ 10µF
                                             │
                                            GND

VOUT = 2.5V + (I × 0.2V/A)
```

**No additional isolation needed!** Built-in Hall effect provides 2100V isolation.

**Calibration:**
- Zero current: VOUT = 2.5V (use this for offset calibration)
- +10A: VOUT = 4.5V
- -10A: VOUT = 0.5V

---

## Turkey Sourcing Guide

### Turkish Distributors

#### 1. Direnc.net (direnc.net)

**What they stock:**
- ✅ STM32 development boards (Nucleo, Discovery)
- ✅ Resistors, capacitors, basic passives
- ✅ Common ICs (op-amps, regulators, etc.)
- ⚠️ Isolated components (limited)

**Recommended purchases:**
- STM32F303RE Nucleo board
- Resistors (0.1% metal film, various values)
- Capacitors (ceramic, electrolytic)
- Op-amps (TL072, LM358)
- Voltage regulators
- Wire, connectors, headers

**Contact:**
- Website: https://www.direnc.net
- Language: Turkish + English

#### 2. SAMM Teknoloji (samm.com)

**What they stock:**
- ✅ Raspberry Pi official distributor
- ✅ Development boards (Arduino, STM32, etc.)
- ✅ Sensors and modules
- ✅ Electronic components

**Recommended purchases:**
- STM32 boards
- FPGA boards (if available)
- Sensors, modules
- Prototyping supplies

**Contact:**
- Website: https://www.samm.com
- Language: Turkish + English

### International Suppliers (Ship to Turkey)

#### 3. AliExpress (aliexpress.com)

**Shipping to Turkey:**
- ✅ Standard shipping: 2-4 weeks (free or low cost)
- ✅ Express shipping: 1-2 weeks ($5-15)
- ⚠️ Customs: May apply import duties on orders >$150 USD

**Recommended purchases:**
| Component | Search Term | Price Range |
|-----------|-------------|-------------|
| AMC1301 Module | "AMC1301 module" or "AMC1301 isolation" | $15-20 |
| ACS724 Sensor | "ACS724LLCTR-10AB" or "ACS724 current sensor" | $4-8 |
| B0505S DC-DC | "B0505S-1W" or "5V isolated DC-DC" | $2-4 |
| AD7606 Module | "AD7606 ADC module" | $15-25 |
| ADS1256 Module | "ADS1256 ADC" or "HX711 24-bit ADC" | $8-15 |
| MCP3208 | "MCP3208 ADC" | $3-6 |
| 6N137 Optocoupler | "6N137 high speed optocoupler" | $1-2 |
| FPGA Board | "Artix-7 FPGA" or "Xilinx development board" | $50-200 |

**Tips:**
- Check seller ratings (>95% positive)
- Read reviews carefully
- Verify specifications in product description
- Message seller to confirm chip authenticity

#### 4. DigiKey / Mouser (Ships to Turkey)

**Shipping:**
- ✅ DHL Express: 2-5 days ($25-50)
- ⚠️ Import duties: Calculated at checkout + possible customs fees

**When to use:**
- ✅ For genuine, guaranteed-authentic ICs
- ✅ When you need specific part numbers
- ✅ For professional/production use
- ⚠️ More expensive than AliExpress

**Recommended purchases:**
- AMC1301DWV (Texas Instruments)
- ISO7762FDW (Texas Instruments)
- MCP3208-CI/P or MCP3208-CI/SL (Microchip)

### PCB Fabrication

#### JLCPCB (jlcpcb.com)

**Services:**
- PCB fabrication: $2 for 5 pcs (10×10cm, 2-layer)
- Shipping to Turkey: ~$5-15 (2-3 weeks)
- Assembly service available (+$3 setup)

**When to use:**
- For custom control boards
- For sensor interface boards

#### Local Turkish PCB Fabs

**Search for:**
- "PCB üretimi Türkiye"
- "Elektronik PCB istanbul"

**Advantages:**
- Faster turnaround (1-2 days possible)
- No customs/shipping delays
- Face-to-face communication

**Disadvantages:**
- Higher cost than JLCPCB
- May have minimum quantity requirements

---

## Complete Bill of Materials

### Stage 2: STM32F303RE (Complete System)

| Category | Component | Qty | Part Number | Source | Unit Price | Total |
|----------|-----------|-----|-------------|--------|------------|-------|
| **Controller** | STM32F303RE Nucleo | 1 | NUCLEO-F303RE | Direnc.net | $12 | $12 |
| **Isolation** | AMC1301 Module | 3 | AMC1301 breakout | AliExpress | $15 | $45 |
| **Isolation** | Isolated DC-DC | 3 | B0505S-1W | AliExpress | $3 | $9 |
| **Sensing** | Current Sensor | 1 | ACS724LLCTR-10AB | AliExpress | $6 | $6 |
| **Passives** | Resistors 0.1% 1MΩ | 10 | Metal film | Direnc.net | $0.80 | $8 |
| **Passives** | Resistors 0.1% 5.1kΩ | 10 | Metal film | Direnc.net | $0.50 | $5 |
| **Passives** | Capacitors 100nF | 20 | Ceramic X7R | Direnc.net | $0.10 | $2 |
| **Passives** | Capacitors 10µF | 10 | Electrolytic | Direnc.net | $0.20 | $2 |
| **PCB** | Control Board | 1 | Custom 10×10cm | JLCPCB | $10 | $10 |
| **Misc** | Connectors, wire | - | Various | Direnc.net | - | $5 |
| | | | | **TOTAL** | | **$104** |

### Stage 3: FPGA + MCP3208 (Complete System)

| Category | Component | Qty | Part Number | Source | Unit Price | Total |
|----------|-----------|-----|-------------|--------|------------|-------|
| **Controller** | FPGA Board | 1 | Basys 3 (Artix-7) | AliExpress | $150 | $150 |
| **ADC** | SAR ADC | 1 | MCP3208-CI/P | Direnc.net | $5 | $5 |
| **Isolation** | AMC1301 Module | 3 | AMC1301 breakout | AliExpress | $15 | $45 |
| **Isolation** | Isolated DC-DC | 3 | B0505S-1W | AliExpress | $3 | $9 |
| **Isolation** | Digital Isolator | 1 | ISO7762FDW | AliExpress | $4 | $4 |
| **Sensing** | Current Sensor | 1 | ACS724LLCTR-10AB | AliExpress | $6 | $6 |
| **Passives** | Resistors 0.1% 1MΩ | 10 | Metal film | Direnc.net | $0.80 | $8 |
| **Passives** | Resistors 0.1% 5.1kΩ | 10 | Metal film | Direnc.net | $0.50 | $5 |
| **Passives** | Capacitors 100nF | 20 | Ceramic X7R | Direnc.net | $0.10 | $2 |
| **Passives** | Capacitors 10µF | 10 | Electrolytic | Direnc.net | $0.20 | $2 |
| **PCB** | ADC Interface Board | 1 | Custom 10×10cm | JLCPCB | $10 | $10 |
| **Misc** | Connectors, wire | - | Various | Direnc.net | - | $5 |
| | | | | **TOTAL** | | **$251** |

### Stage 4: RISC-V + ADS1256 (Complete System)

| Category | Component | Qty | Part Number | Source | Unit Price | Total |
|----------|-----------|-----|-------------|--------|------------|-------|
| **Controller** | FPGA Board (RISC-V) | 1 | Basys 3 (Artix-7) | AliExpress | $150 | $150 |
| **ADC** | 24-bit ADC Module | 1 | ADS1256 module | AliExpress | $12 | $12 |
| **Isolation** | AMC1301 Module | 3 | AMC1301 breakout | AliExpress | $15 | $45 |
| **Isolation** | Isolated DC-DC | 3 | B0505S-1W | AliExpress | $3 | $9 |
| **Isolation** | Digital Isolator | 1 | ISO7762FDW | AliExpress | $4 | $4 |
| **Sensing** | Current Sensor | 1 | ACS724LLCTR-10AB | AliExpress | $6 | $6 |
| **Passives** | Resistors 0.1% 1MΩ | 10 | Metal film | Direnc.net | $0.80 | $8 |
| **Passives** | Resistors 0.1% 5.1kΩ | 10 | Metal film | Direnc.net | $0.50 | $5 |
| **Passives** | Capacitors 100nF | 20 | Ceramic X7R | Direnc.net | $0.10 | $2 |
| **Passives** | Capacitors 10µF | 10 | Electrolytic | Direnc.net | $0.20 | $2 |
| **PCB** | ADC Interface Board | 1 | Custom 10×10cm | JLCPCB | $10 | $10 |
| **Misc** | Connectors, wire | - | Various | Direnc.net | - | $5 |
| | | | | **TOTAL** | | **$258** |

### Grand Total (All 3 Stages)

**Total Project Cost:** $104 + $251 + $258 = **$613**

**Note:** This assumes you are building 3 completely separate systems running simultaneously.

---

## Implementation Roadmap

### Phase 1: Order Components (Week 1)

**From Turkey (Direnc.net or SAMM):**
- [ ] STM32F303RE Nucleo board
- [ ] Resistors: 1MΩ, 5.1kΩ, 3.9kΩ, 2.2MΩ (0.1% metal film)
- [ ] Capacitors: 100nF ceramic, 10µF electrolytic
- [ ] Wire, connectors, headers
- [ ] Breadboards for prototyping

**From AliExpress (order NOW, 2-4 week shipping):**
- [ ] AMC1301 modules (3×)
- [ ] ACS724LLCTR-10AB current sensors (3×, order extras)
- [ ] B0505S-1W isolated DC-DC (5×, order extras)
- [ ] MCP3208-CI/P ADC chips (2×)
- [ ] ADS1256 ADC module (1×)
- [ ] ISO7762FDW digital isolator (2×)
- [ ] FPGA development board (Basys 3 or similar)

### Phase 2: STM32 Prototype on Breadboard (Week 2-3)

**While waiting for AliExpress shipment:**
- [ ] Set up STM32F303RE in STM32CubeIDE
- [ ] Configure ADC1 and ADC2 with DMA
- [ ] Test ADC sampling at 10 kHz
- [ ] Develop control algorithm in software
- [ ] Test PWM generation (8 channels)

**When AMC1301 modules arrive:**
- [ ] Build voltage dividers on breadboard
- [ ] Connect AMC1301 modules (3×)
- [ ] Test isolated voltage measurements
- [ ] Calibrate voltage scaling

**When ACS724 arrives:**
- [ ] Breadboard current sensor circuit
- [ ] Test current measurement
- [ ] Calibrate zero-current offset

### Phase 3: Design Custom PCB (Week 4)

**PCB Design (KiCad or EasyEDA):**
- [ ] Schematic: STM32, 3× AMC1301, 1× ACS724, 3× B0505S-1W
- [ ] Layout with proper isolation clearances
- [ ] Add mounting holes, test points
- [ ] Generate Gerber files

**Order PCB:**
- [ ] Upload to JLCPCB or local fab
- [ ] Order 5-10 pieces
- [ ] Wait 1-2 weeks for delivery

### Phase 4: Assemble and Test Stage 2 (Week 5-6)

- [ ] Solder components on PCB
- [ ] Visual inspection (shorts, bridges)
- [ ] Power-on test (isolated supplies)
- [ ] Test ADC readings (no high voltage yet)
- [ ] Test with low voltage (5-10V) first
- [ ] Gradually increase voltage to 50V/100V
- [ ] Full system test with dummy load

### Phase 5: FPGA Development (Week 7-10)

**FPGA Setup:**
- [ ] Install Vivado (Xilinx) or Quartus (Intel)
- [ ] Create new FPGA project
- [ ] Implement SPI master in Verilog/VHDL
- [ ] Test SPI with MCP3208 ADC
- [ ] Port control algorithm to FPGA
- [ ] Generate PWM in FPGA logic

**Integration:**
- [ ] Build ADC interface board (MCP3208 + isolation)
- [ ] Connect to FPGA dev board
- [ ] Test ADC readings
- [ ] Close control loop in FPGA
- [ ] Full system test

### Phase 6: RISC-V Development (Week 11-14)

**RISC-V Soft-Core:**
- [ ] Choose RISC-V core (PicoRV32, VexRiscv, etc.)
- [ ] Synthesize on FPGA
- [ ] Add SPI peripheral
- [ ] Write C code for ADC driver (ADS1256)
- [ ] Port control algorithm to C
- [ ] Generate PWM from RISC-V code
- [ ] Full system test

### Phase 7: Final Integration (Week 15+)

- [ ] Test all 3 systems simultaneously
- [ ] Calibrate and tune controllers
- [ ] Measure THD, efficiency, performance
- [ ] Document results
- [ ] Create demonstration video
- [ ] Prepare thesis/report

---

## Safety Checklist

Before powering on ANY system:

- [ ] **Verify all isolation barriers** are correctly implemented
- [ ] **Check PCB clearances** (8mm creepage, 4mm clearance minimum)
- [ ] **Test isolated power supplies** with multimeter (no shorts)
- [ ] **Verify ADC input voltages** are within safe range (0-5V)
- [ ] **Confirm current sensor** is properly rated (10A max)
- [ ] **Add fuses** on high-voltage DC inputs
- [ ] **Use isolated power supply** for initial testing
- [ ] **Start with low voltage** (5-10V DC) before going to 50V
- [ ] **Keep one hand behind back** when probing live circuits
- [ ] **Wear safety glasses**
- [ ] **Work on insulated mat**
- [ ] **Have fire extinguisher nearby**
- [ ] **Never work alone** on high-voltage tests

---

## Frequently Asked Questions

### Q1: Can I skip isolation for low-voltage testing (5V)?

**A:** For initial software testing at very low voltages (<12V), you *could* temporarily skip isolation, but:
- ⚠️ **Not recommended** - easy to forget and accidentally apply high voltage
- ✅ **Better:** Design isolation in from the start
- If you do skip: Add physical barriers, warning labels, and remove high-voltage power supplies from the lab

### Q2: Can I use cheaper alternatives to AMC1301?

**A:** Yes, alternatives:
- **ACPL-C87A/C87B:** Cheaper (~$5), lower bandwidth (200 kHz vs 250 kHz)
- **IL300 linear optocoupler:** Budget option (~$3), requires more external components
- **HCPL-7800/7840:** Isolated sigma-delta modulator (complex but good)

### Q3: My country has import restrictions. What do I do?

**A:** Options:
- Use STM32F303RE internal ADC only (Stage 2) - no external ADC needed
- Source components locally (check Direnc.net, SAMM)
- Use university/company purchasing department for bulk imports
- Buy from DigiKey/Mouser (handles customs documentation)

### Q4: Can I use the same ADC board for all 3 stages?

**A:** Partially:
- ✅ Analog isolation circuits (AMC1301, ACS724) can be shared/reused
- ⚠️ ADC chips are different (STM32 internal vs MCP3208 vs ADS1256)
- ✅ You could design one modular board with multiple ADC options (use jumpers)

### Q5: What if I can't find AMC1301 modules?

**A:** Alternatives in order of preference:
1. **ACPL-C87A modules** on AliExpress (search "ACPL-C87A")
2. **Use differential probes** + non-isolated ADC (expensive, $100+ per probe)
3. **DIY IL300 optocoupler circuit** (more complex, requires calibration)
4. **Use isolated ADC** like AD7400 (digital output, requires FPGA to decode)

### Q6: How do I calibrate the voltage dividers?

**Procedure:**
1. Apply known voltage (e.g., 5.000V from lab power supply)
2. Measure ADC output with multimeter
3. Calculate actual divider ratio: `ratio = Vin / Vout_measured`
4. Store calibration constant in software
5. Repeat for multiple voltage points (0V, 25V, 50V)
6. Use linear fit if needed: `Vreal = gain × Vmeasured + offset`

### Q7: What FPGA board should I buy?

**Recommendations:**
- **Budget ($50-80):** Digilent Basys 3 (Artix-7 35T, plenty of resources)
- **Mid-range ($100-150):** Nexys A7 (Artix-7 100T, more I/O)
- **High-end ($200+):** Arty Z7 (Zynq SoC, ARM + FPGA, easier RISC-V integration)

For Turkey: Check AliExpress for clones/alternatives (cheaper but verify specs).

---

## References

### Datasheets

1. **STM32F303RE:** [STM32F303xB/C/D/E Datasheet](https://www.st.com/resource/en/datasheet/stm32f303re.pdf)
2. **AMC1301:** [AMC1301 Isolated Amplifier Datasheet](https://www.ti.com/lit/ds/symlink/amc1301.pdf)
3. **ACPL-C87A:** [ACPL-C87A Isolation Amplifier Datasheet](https://docs.broadcom.com/doc/AV02-3562EN)
4. **ACS724:** [ACS724 Current Sensor Datasheet](https://www.allegromicro.com/en/products/sense/current-sensor-ics/zero-to-fifty-amp-integrated-conductor-sensor-ics/acs724)
5. **MCP3208:** [MCP3204/3208 12-bit ADC Datasheet](https://ww1.microchip.com/downloads/en/DeviceDoc/21298e.pdf)
6. **ADS1256:** [ADS1256 24-bit ADC Datasheet](https://www.ti.com/lit/ds/symlink/ads1256.pdf)
7. **ISO7762:** [ISO776x Digital Isolator Datasheet](https://www.ti.com/lit/ds/symlink/iso7762.pdf)
8. **B0505S-1W:** [B_S-1WR3 Series Datasheet](https://www.mornsun-power.com/html/pdf/B_S-1WR3.html)

### Application Notes

1. **AN4195:** STM32F3 Series ADC Modes and Applications
2. **AN1831:** Optically Isolated Amplifiers for Current and Voltage Sensing
3. **TI SLYY063:** Isolation Design Guidelines for IEC 61010-1
4. **Microchip AN1286:** Using MCP320x ADCs

### Standards

1. **IEC 61010-1:** Safety requirements for electrical equipment for measurement, control, and laboratory use
2. **IEC 60664-1:** Insulation coordination for equipment within low-voltage systems
3. **UL 1577:** Standard for Optical Isolators

### Web Resources

- [Direnc.net](https://www.direnc.net) - Turkish electronics distributor
- [SAMM Teknoloji](https://www.samm.com) - Turkish Raspberry Pi distributor
- [AliExpress Electronics](https://www.aliexpress.com) - International component source
- [JLCPCB](https://jlcpcb.com) - PCB fabrication
- [EEVblog Forum](https://www.eevblog.com/forum) - Electronics community
- [STM32 Community](https://community.st.com) - STM32 support

---

## Appendix A: Quick Reference Tables

### Isolation Components Comparison

| Component | Type | Isolation | Bandwidth | Availability | Cost |
|-----------|------|-----------|-----------|--------------|------|
| AMC1301 | Analog amplifier | 7070V pk | 250 kHz | AliExpress modules | $15 |
| ACPL-C87A | Analog amplifier | 5000V RMS | 200 kHz | AliExpress | $5 |
| IL300 | Linear optocoupler | 5000V RMS | 3 kHz | Limited | $3 |
| ACS724 | Hall effect sensor | 2100V RMS | 120 kHz | AliExpress | $6 |
| ISO7762 | Digital isolator | 2500V RMS | 150 Mbps | AliExpress | $4 |
| 6N137 | Optocoupler | 5000V RMS | 10 Mbps | Direnc.net | $1 |
| B0505S-1W | DC-DC converter | 1500V DC | N/A | AliExpress | $3 |

### ADC Comparison

| ADC | Resolution | Channels | Speed | Interface | Available | Cost |
|-----|------------|----------|-------|-----------|-----------|------|
| STM32F303 Internal | 12-bit | 40 | 5 MSPS | Internal | ✅ Turkey | $0 (built-in) |
| MCP3208 | 12-bit | 8 | 100 kSPS | SPI | ✅ Turkey | $5 |
| MCP3008 | 10-bit | 8 | 200 kSPS | SPI | ✅ Turkey | $3 |
| ADS1256 | 24-bit | 8 diff | 30 kSPS | SPI | ✅ AliExpress | $12 (module) |
| AD7606 | 16-bit | 8 | 200 kSPS | SPI | ✅ AliExpress | $18 (module) |

### Voltage Divider Values

| Input Voltage | Divider Ratio | R1 | R2 | Output Voltage |
|---------------|---------------|----|----|----------------|
| 50V DC | 197:1 | 1MΩ | 5.1kΩ | 0.254V |
| 141V AC peak | 565:1 | 2.2MΩ | 3.9kΩ | 0.250V |

### Pin Assignments

**STM32F303RE:**

| Signal | Pin | ADC Channel | Purpose |
|--------|-----|-------------|---------|
| DC Bus 1 | PA0 | ADC1_IN1 | Voltage measurement |
| DC Bus 2 | PA1 | ADC1_IN2 | Voltage measurement |
| AC Voltage | PA4 | ADC2_IN1 | Voltage measurement |
| AC Current | PA5 | ADC2_IN2 | Current measurement |

---

## Document History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2025-11-29 | AI Assistant | Initial comprehensive document |

---

**END OF DOCUMENT**

---

## Contact & Support

For questions or issues with this document:
- Review the [FAQ section](#frequently-asked-questions)
- Consult referenced datasheets and application notes
- Check EEVblog or STM32 Community forums
- Contact Turkish distributors (Direnc.net, SAMM) for component availability

**Good luck with your 5-level inverter project! Stay safe and happy building! ⚡🔬**
