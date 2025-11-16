# Current and Voltage Sensing Circuits

**Document Type:** Hardware Design Specification
**Project:** 5-Level Cascaded H-Bridge Inverter
**Author:** 5-Level Inverter Project
**Date:** 2025-11-15
**Version:** 1.0
**Status:** Design - Not Yet Validated

---

## Table of Contents

1. [Overview](#overview)
2. [Sensing Requirements](#sensing-requirements)
3. [Current Sensing](#current-sensing)
4. [Voltage Sensing](#voltage-sensing)
5. [Signal Conditioning](#signal-conditioning)
6. [ADC Interface](#adc-interface)
7. [Calibration and Accuracy](#calibration-and-accuracy)
8. [Testing and Validation](#testing-and-validation)
9. [Bill of Materials](#bill-of-materials)

---

## Overview

### Purpose

Accurate sensing of current and voltage is critical for:
- **Closed-loop control:** PR controller requires real-time current feedback
- **Protection:** Overcurrent and overvoltage detection
- **Monitoring:** Power calculation, efficiency measurement
- **Diagnostics:** Fault detection and analysis

### System Context

**Signals to Measure:**

| Signal | Parameter | Range | Accuracy | Bandwidth |
|--------|-----------|-------|----------|-----------|
| Output Current | AC, 50 Hz | ±15A peak | ±1% | 5 kHz |
| Output Voltage | AC, 50 Hz | ±150V peak | ±1% | 5 kHz |
| DC Bus 1 Voltage | DC | 0-60V | ±2% | 1 kHz |
| DC Bus 2 Voltage | DC | 0-60V | ±2% | 1 kHz |

**Sampling:**
- ADC sampling rate: 10 kHz (synchronized with PWM)
- ADC resolution: 12-bit (STM32F401RE built-in)
- ADC input range: 0-3.3V

---

## Sensing Requirements

### Electrical Requirements

**Output Current Sensing:**
- Measurement range: **±15A peak** (±10.6A RMS)
- Resolution: 15A / 4096 = **3.66 mA** per ADC LSB
- Accuracy: ±1% (±150 mA at full scale)
- Isolation: Preferred for safety, but not mandatory if low-side sensing
- Bandwidth: DC to 5 kHz (for PWM harmonics)

**Output Voltage Sensing:**
- Measurement range: **±150V peak** (±106V RMS)
- Resolution: 150V / 4096 = **36.6 mV** per ADC LSB
- Accuracy: ±1% (±1.5V at full scale)
- Isolation: **MANDATORY** (high voltage to microcontroller)
- Bandwidth: DC to 5 kHz

**DC Bus Voltage Sensing:**
- Measurement range: **0-60V DC**
- Resolution: 60V / 4096 = **14.6 mV** per ADC LSB
- Accuracy: ±2% (±1.2V at full scale)
- Isolation: Preferred but not mandatory (same ground as ADC)
- Bandwidth: DC to 1 kHz (mainly DC with some ripple)

### Safety Requirements

1. **Overvoltage Protection:**
   - ADC inputs must be protected from overvoltage (> 3.6V)
   - Use clamping diodes or TVS diodes

2. **ESD Protection:**
   - All sensor inputs must have ESD protection
   - Use TVS diodes rated for ±15 kV (IEC 61000-4-2)

3. **Isolation (for high voltage signals):**
   - Isolation voltage: ≥ 1000V
   - Use isolation amplifiers or optocouplers

4. **Short Circuit Protection:**
   - Sensing circuits must survive output short circuit
   - Limit maximum current through sense resistors

---

## Current Sensing

### Option 1: Shunt Resistor with Differential Amplifier

**Topology:** Low-side shunt (between load and ground)

**Circuit:**
```
Output ──→ Load ──→ R_shunt ──→ GND
                      │  │
                      │  └──────────┬─────── V_shunt+ (to diff amp)
                      └─────────────┴─────── V_shunt- (to diff amp)

                     Differential Amplifier
                            │
                            ├─── Gain (G = 100)
                            │
                        0-3.3V ──→ ADC (STM32)
```

**Shunt Resistor Selection:**

For ±15A range and 150 mV max voltage drop:
```
R_shunt = V_max / I_max = 150 mV / 15A = 10 mΩ
```

**Power rating:**
```
P_shunt = I²R = (15A)² × 10 mΩ = 2.25W
```

Use **10 mΩ / 5W** current sense resistor.

**Recommended Parts:**
- **Vishay WSL2512** (10 mΩ, 2W, 2512 package) - Use 3 in parallel for 5W
- **Ohmite LVK12** (10 mΩ, 3W)
- **TE Connectivity LVR03R0100FE70** (10 mΩ, 3W, 1% tolerance)

**Differential Amplifier:**

Use **INA240A1** (Texas Instruments):
- Bidirectional current sensing
- Gain: 20 V/V
- Bandwidth: 400 kHz
- Common-mode range: -4V to +80V
- Output: 0-3.3V (single-ended)
- Supply: 2.7-5.5V (use +5V)

**Alternative:** **INA169** (unidirectional, cheaper) - Not suitable for AC current

**Gain Calculation:**

For ±15A → ±150 mV at shunt
Want ±15A → 0-3.3V at ADC output

Midpoint: 1.65V (zero current)
Maximum: 3.3V (+15A)
Minimum: 0V (-15A)

Required gain:
```
G = (3.3V / 2) / 150 mV = 1.65V / 150 mV = 11 V/V
```

**INA240A1** has fixed gain of 20 V/V, so need to adjust:
- Use 5 mΩ shunt instead: V_shunt = 15A × 5 mΩ = 75 mV
- Gain 20: V_out = 20 × 75 mV = 1.5V swing
- Total range: 1.65V ± 1.5V = 0.15V to 3.15V ✓

**Revised Shunt: 5 mΩ / 3W**

---

### Option 2: Hall Effect Current Sensor (RECOMMENDED)

**Topology:** Closed-loop Hall effect sensor (isolated)

**Circuit:**
```
Output Current ──→ Primary (wire through sensor)
                        │
                   [Hall Sensor]
                        │
                   Output ──→ Resistor ──→ ADC (0-3.3V)
```

**Advantages:**
- ✅ Galvanic isolation (safer)
- ✅ No power dissipation in primary
- ✅ Wide bandwidth (DC to 200 kHz)
- ✅ Bidirectional measurement
- ✅ No inserted resistance (no voltage drop)

**Recommended Sensors:**

**1. ACS724 (Allegro MicroSystems):**
- Range: ±20A
- Sensitivity: 40 mV/A
- Output: 0.5× Vcc ± (Sens × I) = 2.5V ± 0.8V for ±20A
- Supply: 4.5-5.5V (use +5V)
- Bandwidth: 120 kHz
- Accuracy: ±1%
- Package: SOIC-8
- Price: ~$4

**Output Voltage:**
```
V_out = Vcc/2 + Sens × I
      = 2.5V + 0.04 V/A × I

For I = +15A: V_out = 2.5V + 0.6V = 3.1V ✓
For I = -15A: V_out = 2.5V - 0.6V = 1.9V ✓
For I = 0A:   V_out = 2.5V
```

Perfect fit for 0-3.3V ADC range!

**2. LEM HO 15-NP (LEM):**
- Range: ±15A (nominal)
- Turns ratio: 1:2000
- Output: ±15 mA (requires burden resistor)
- Accuracy: ±0.5%
- Bandwidth: DC to 200 kHz
- Price: ~$15 (more expensive, higher accuracy)

**For our application:** **ACS724** (best cost/performance balance)

**Circuit Implementation:**

```
              Output Current Wire
                    │
                    ↓  (passes through sensor)
            ┌───────────────┐
    +5V ────┤ ACS724        │
            │  Vcc   Vout   ├──┬─── 100 nF ─── GND (filtering)
    GND ────┤ GND    (2.5V) │  │
            └───────────────┘  └─── To ADC (PA0)
```

**Filtering:**
Add 100 nF ceramic + 10 μF electrolytic on Vout for noise filtering.

---

### Final Current Sensing Choice: **ACS724**

---

## Voltage Sensing

### Output Voltage Sensing (±150V AC)

**Requirements:**
- Measure: ±150V peak (106V RMS)
- ADC input: 0-3.3V
- **Isolation: MANDATORY**

### Option 1: Resistive Divider + Isolation Amplifier

**Topology:**

```
Output Voltage ──┬─── R1 (High voltage)
  (±150V)        │
                 ├──── V_div (±2.5V)
                 │
                 └─── R2 (to GND)
                      │
                     GND

    V_div ──→ [Isolation Amplifier] ──→ 0-3.3V ADC
                  (AMC1200)
```

**Resistor Divider:**

For ±150V → ±2.5V (input to isolation amp):
```
Ratio = 150V / 2.5V = 60:1

R1 + R2 = 60 × R2
R1 = 59 × R2

Choose R2 = 10 kΩ (low impedance for noise immunity)
Then R1 = 590 kΩ

Use standard values:
R1 = 590 kΩ (1%, 1W)
R2 = 10 kΩ (1%, 1/4W)
```

**Power Dissipation:**
```
P_max = V² / (R1 + R2) = (150V)² / 600 kΩ = 37.5 mW
```

R1 power: 37.5 mW × (590/600) = 36.9 mW → Use **1W** resistor for safety

**Isolation Amplifier:**

**AMC1200** (Texas Instruments):
- Isolation: 2500V RMS
- Input range: ±250 mV differential
- Output: 0-2.5V (single-ended)
- Bandwidth: 50 kHz
- Supply: 5V both sides
- Package: SOIC-8
- Price: ~$5

**Issue:** AMC1200 input range (±250 mV) is too small for ±2.5V divided signal.

**Solution:** Divide further to ±250 mV:
```
Revised divider ratio: 150V / 250 mV = 600:1
R1 = 5.9 MΩ, R2 = 10 kΩ
```

**Problem:** 5.9 MΩ is too high (noise susceptible)

**Better Solution:** Use AMC1200 with gain stage after isolation.

---

### Option 2: Differential Voltage Probe + Isolation (COMPLEX)

Too complex for our application.

---

### Option 3: AC Transformer (RECOMMENDED)

**Topology:** Step-down transformer for voltage sensing

**Circuit:**
```
Output Voltage ──→ Transformer ──→ Rectifier ──→ Filter ──→ ADC
  (±150V, 50 Hz)   (100:1 ratio)   (Precision)   (Low-pass)  (0-3.3V)
```

**Transformer Specifications:**
- Primary: 100V RMS (150V peak)
- Secondary: 1.5V RMS (2.1V peak)
- Turns ratio: 100:1
- Frequency: 50/60 Hz
- Power: < 1VA (sense only)
- Isolation: ≥ 1000V

**Recommended Part:**
- **Talema PV20001-S** (Voltage sensing transformer, PCB mount)
- Or custom wind on small ferrite toroid (100 turns : 1 turn)

**Rectifier + Conditioning:**

For AC voltage measurement (magnitude):
```
Secondary AC ──→ Precision Rectifier ──→ Peak Detector ──→ ADC
```

**For AC waveform measurement (for THD analysis):**

Need to preserve AC waveform, not just magnitude.

**Use:** Direct AC sensing with protection

**Revised Circuit:**
```
Transformer Secondary ──┬─── R_burden (1 kΩ)
  (±2.1V peak)          │
                        ├──── Buffer (op-amp follower)
                        │
                        ├──── Level shift (+1.65V offset)
                        │
                        └──── To ADC (0-3.3V)
```

**Level Shifting:**

Convert ±2.1V to 0-3.3V range:
```
V_ADC = (V_transformer / G) + 1.65V

For ±2.1V input → 0-3.3V output:
G = 2.1V / 1.65V = 1.27

Use G = 1.3 (slightly reduce input swing for headroom)
V_transformer_max = ±1.65V / 1.3 = ±1.27V

Adjust transformer burden to give ±1.27V:
```

**Simplified Approach (RECOMMENDED):**

Use **voltage divider + differential amplifier** (similar to current sensing) but with optocoupler isolation for safety.

---

### Final Voltage Sensing Choice: **Resistive Divider + Optocoupler Isolation**

**Circuit:**

```
Output Voltage ──┬─── R1 (590 kΩ, 1W) ──┬─── Clamp Diodes (±5.1V Zener)
  (±150V)        │                       │
                 ├─── R2 (10 kΩ)  ───────┴─── Optocoupler LED (HCNR200)
                 │                             │
                GND                      Optocoupler PD ──→ Trans-impedance amp
                                                               │
                                                         0-3.3V ──→ ADC
```

**HCNR200/201 (Broadcom):**
- Analog optocoupler (linear transfer)
- Isolation: 5000V RMS
- Bandwidth: DC to 500 kHz
- Linearity: 0.05%
- Price: ~$3

**Better Alternative for Simplicity:** Use **isolated ADC** like **AMC1301**

---

### FINAL SIMPLIFIED SOLUTION: AMC1301 Isolated ADC

**AMC1301** (Texas Instruments):
- Fully differential isolated ADC input stage
- Input range: ±250 mV
- Isolation: 7000V peak
- Bandwidth: 250 kHz
- Output: Digital bitstream (connect to STM32 SPI/UART)
- Supply: 3.3V or 5V both sides
- Package: SOIC-16
- Price: ~$4

**Circuit:**

```
Output Voltage ──┬─── R1 (590 kΩ) ──┬─── AMC1301 ──→ STM32 (SPI)
  (±150V)        │                  VINP            Digital data
                 └─── R2 (10 kΩ) ───┴───
                                    VINN
```

Divider creates ±250 mV from ±150V (600:1 ratio).

---

## DC Bus Voltage Sensing

Simpler than AC sensing (no isolation needed, same ground as STM32).

**Circuit:**

```
DC Bus (+50V) ──┬─── R1 (47 kΩ) ──┬─── 3.3V Zener (protection)
                │                 │
                └─── R2 (3.3 kΩ) ─┴─── 100 nF (filter) ──→ ADC (PA4)
                     │
                    GND
```

**Divider Ratio:**
```
Vout = Vin × R2 / (R1 + R2)
     = 50V × 3.3 kΩ / 50.3 kΩ
     = 3.28V (just under 3.3V limit) ✓
```

**Protection:**
- 3.3V Zener diode (1N4728A) clamps voltage to safe level
- 100 nF capacitor filters switching noise

**For 60V max input:**
```
Vout = 60V × 3.3 kΩ / 50.3 kΩ = 3.93V
```

Zener will clamp to 3.3V, protecting ADC.

---

## Signal Conditioning

### Anti-Aliasing Filter

**Purpose:** Prevent aliasing of high-frequency noise into ADC

**Cutoff Frequency:**
```
f_cutoff = f_sample / 2 = 10 kHz / 2 = 5 kHz (Nyquist)
```

Use 3 kHz cutoff for safety margin.

**RC Low-Pass Filter:**

```
fc = 1 / (2πRC)
C = 1 / (2π × fc × R)

For R = 10 kΩ, fc = 3 kHz:
C = 1 / (2π × 3 kHz × 10 kΩ) = 5.3 nF

Use standard value: 4.7 nF or 5.6 nF
```

**Circuit (per ADC input):**

```
Sensor Output ──┬─── 10 kΩ ──┬──→ ADC input
                │             │
                └─── 5.6 nF ──┴──→ GND
```

### Overvoltage Protection

**Schottky Diode Clamps:**

```
              ┌─── Schottky D1 ──→ +3.3V
              │
ADC Input ────┼──→ To STM32 ADC pin
              │
              └─── Schottky D2 ──→ GND
```

**Parts:**
- **BAT54S** (dual Schottky in SOT-23) - Fast, low capacitance
- Forward voltage: 0.3V
- Clamps ADC input to -0.3V to +3.6V

---

## ADC Interface

### STM32F401RE ADC Configuration

**ADC Channels Used:**

| Signal | ADC Channel | Pin | Range |
|--------|-------------|-----|-------|
| Output Current | ADC1_IN0 | PA0 | 0-3.3V (2.5V center) |
| Output Voltage | ADC1_IN1 | PA1 | 0-3.3V (1.65V center) |
| DC Bus 1 Voltage | ADC1_IN4 | PA4 | 0-3.3V |
| DC Bus 2 Voltage | ADC1_IN5 | PA5 | 0-3.3V |

**ADC Settings:**
- Resolution: 12-bit (4096 counts)
- Sampling rate: 10 kHz (synchronized with PWM timer)
- Trigger: TIM1 update event
- DMA: Continuous transfer to buffer
- Reference: VDDA = 3.3V (measure with VREFINT for calibration)

**ADC Timing:**
```
Sample time: 15 cycles (for 1.8 μs settling time)
Conversion time: 12 cycles (12-bit)
Total: 27 cycles @ 84 MHz / 8 (prescaler) = 2.57 μs per conversion
```

For 4 channels: 10.3 μs total (well within 100 μs PWM period)

---

## Calibration and Accuracy

### Offset Calibration

**Current Sensor (ACS724):**
- Zero current should give 2.5V output
- Measure actual zero-current output and store as offset
- Subtract offset from all readings

**Implementation:**
```c
float current_offset = 2.5f; // Calibrated value
float adc_voltage = adc_reading * (3.3f / 4096.0f);
float current = (adc_voltage - current_offset) / 0.04f; // 40 mV/A sensitivity
```

### Gain Calibration

Use precision reference (calibrated multimeter or power analyzer):
1. Apply known current (e.g., 10A RMS)
2. Measure ADC reading
3. Calculate gain correction factor
4. Store in EEPROM or flash

**Implementation:**
```c
float current_gain = 1.00f; // Calibrated value (typically 0.98-1.02)
float current = ((adc_voltage - current_offset) / 0.04f) * current_gain;
```

### Voltage Reference Calibration

STM32F401RE has internal VREFINT (~1.21V):
- Measure VREFINT with ADC
- Calculate actual VDDA: `VDDA = 1.21V × 4096 / VREFINT_ADC`
- Use calculated VDDA for all conversions

---

## Testing and Validation

### Sensor Testing Procedure

**1. Zero-Current Test:**
- Disconnect load
- Measure current sensor output (should be 2.5V ± 10 mV)
- Record offset value

**2. Known Current Test:**
- Apply 5A DC from bench power supply
- Measure sensor output: should be 2.5V + (0.04 V/A × 5A) = 2.7V
- Verify within ±1%

**3. AC Current Test:**
- Apply 5A RMS AC (50 Hz) from signal generator
- Measure RMS of sensor output with oscilloscope
- Verify: RMS swing = 0.04 V/A × 5A × √2 = 0.28V peak
- Output should swing 2.5V ± 0.28V

**4. Voltage Divider Test:**
- Apply known voltage (e.g., 50V DC from bench PSU)
- Measure ADC reading
- Calculate: should be 50V × (3.3kΩ / 50.3kΩ) = 3.28V
- Verify within ±2%

**5. Frequency Response Test:**
- Sweep AC frequency from 1 Hz to 10 kHz
- Verify amplitude remains constant (< 3 dB variation)
- Check phase shift is minimal

---

## Bill of Materials

### BOM for Complete Sensing System

| Qty | Part Number | Description | Specs | Price (approx) |
|-----|-------------|-------------|-------|----------------|
| 1 | ACS724LLCTR-20AB-T | Current sensor | ±20A, Hall effect, SOIC-8 | $4.00 |
| 1 | AMC1301DWV | Isolated ADC | ±250 mV input, SOIC-16 | $4.00 |
| 2 | Resistor 47kΩ | DC bus divider high-side | 1%, 1/4W | $0.05 each |
| 2 | Resistor 3.3kΩ | DC bus divider low-side | 1%, 1/4W | $0.05 each |
| 1 | Resistor 590kΩ | AC voltage divider high-side | 1%, 1W | $0.20 |
| 1 | Resistor 10kΩ | AC voltage divider low-side | 1%, 1/4W | $0.05 |
| 4 | Capacitor 5.6nF | Anti-aliasing filter | Ceramic, X7R | $0.10 each |
| 4 | Capacitor 100nF | Decoupling | Ceramic, X7R | $0.05 each |
| 2 | 1N4728A | 3.3V Zener diode | Protection | $0.10 each |
| 2 | BAT54S | Dual Schottky | Overvoltage clamp | $0.15 each |
| | | | **Total** | **~$10** |

**Notes:**
- All resistors: Metal film, 1% tolerance
- All capacitors: X7R ceramic, ±10%
- Zener diodes: 1W, ±5%

---

## Wiring Diagram

### Complete Sensing System

```
                          ┌──────────────┐
   Output Current ──────→ │   ACS724     │ ──→ 2.5V ± 0.6V ──→ Filter ──→ ADC1_IN0 (PA0)
                          └──────────────┘

                          ┌──────────────┐
   Output Voltage ──→ R1──┤   AMC1301    │ ──→ Digital ──→ STM32 SPI
                 590kΩ └R2─┤  (Isolated)  │
                      10kΩ └──────────────┘

   DC Bus 1 ──→ R1 ──┬──→ Zener + Filter ──→ ADC1_IN4 (PA4)
               47kΩ  R2
                    3.3kΩ

   DC Bus 2 ──→ R1 ──┬──→ Zener + Filter ──→ ADC1_IN5 (PA5)
               47kΩ  R2
                    3.3kΩ
```

---

## Appendix: Alternative Sensors

### High-Precision Current Sensing

For applications requiring < 0.5% accuracy:

**1. Closed-Loop Hall Effect (LEM HO-NP series):**
- Accuracy: 0.2-0.5%
- Bandwidth: DC to 200 kHz
- Price: $10-20

**2. Fluxgate Current Sensor:**
- Accuracy: 0.1%
- Bandwidth: DC to 100 kHz
- Price: $30-50

**3. Rogowski Coil:**
- AC only (no DC measurement)
- Very wide bandwidth (1 Hz to 1 MHz)
- Galvanically isolated
- Price: $20-40

---

**Document Status:** Design complete using ACS724 + AMC1301 + resistive dividers
**Next Steps:** PCB layout, prototype testing, calibration

**Related Documents:**
- `01-Gate-Driver-Design.md` - Gate driver circuits
- `02-Power-Supply-Design.md` - Power supply design
- `04-Protection-Circuits.md` - Protection using sensor signals
- `05-PCB-Layout-Guide.md` - Layout considerations for sensor traces
