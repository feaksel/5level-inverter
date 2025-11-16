# Power Supply Design - Isolated 50V DC Sources

**Document Type:** Hardware Design Specification
**Project:** 5-Level Cascaded H-Bridge Inverter
**Author:** 5-Level Inverter Project
**Date:** 2025-11-15
**Version:** 1.0
**Status:** Design - Not Yet Validated

---

## Table of Contents

1. [Overview](#overview)
2. [Power Supply Requirements](#power-supply-requirements)
3. [Topology Selection](#topology-selection)
4. [Transformer Design](#transformer-design)
5. [Rectifier and Filter Design](#rectifier-and-filter-design)
6. [Auxiliary Supplies](#auxiliary-supplies)
7. [Isolation and Safety](#isolation-and-safety)
8. [Testing and Validation](#testing-and-validation)
9. [Bill of Materials](#bill-of-materials)

---

## Overview

### Purpose

The 5-level cascaded H-bridge inverter requires **two isolated 50V DC sources**, one for each H-bridge module. Isolation is critical because the H-bridges are connected in series on the AC output.

### System Context

**Power Flow:**
```
AC Mains      ──→  Isolated DC    ──→  H-Bridge 1   ──┐
(120/240V)         Supply 1 (50V)                     │
                                                       ├──→  5-Level
AC Mains      ──→  Isolated DC    ──→  H-Bridge 2   ──┘     AC Output
(120/240V)         Supply 2 (50V)                            (100V RMS)
```

**Key Requirements:**
- Two fully isolated 50V DC outputs
- Load current: 10A per supply (500W / 50V)
- Galvanic isolation: ≥ 1000V between supplies and from mains
- Low ripple voltage: < 1% (< 500 mV)
- Protection: Overcurrent, overvoltage, short circuit

---

## Power Supply Requirements

### Electrical Specifications

**Per Supply (2 required):**

| Parameter | Value | Notes |
|-----------|-------|-------|
| Output Voltage | 50V DC | Nominal |
| Voltage Regulation | ±2% | Under full load |
| Output Current (Continuous) | 10A | For 500W output |
| Output Current (Peak) | 15A | For transients |
| Output Power | 500W | Continuous per supply |
| Ripple Voltage | < 500 mV | < 1% of Vdc |
| Isolation Voltage | ≥ 1500V | Between outputs and mains |
| Efficiency | ≥ 85% | Target efficiency |
| Line Regulation | < 1% | For mains ±10% variation |
| Load Regulation | < 2% | From 10% to 100% load |

**Total System Power:**

```
P_total = 2 × 500W = 1000W (inverter output)
P_input = 1000W / 0.85 = 1176W (assuming 85% PSU efficiency)
```

From 120V AC mains: I_mains = 1176W / 120V = **9.8A** (requires 15A circuit)

### Safety Requirements

**Isolation:**
- Primary-secondary isolation: ≥ 3000V (for safety)
- Between secondary outputs: ≥ 1500V (for cascaded operation)
- Creepage distance: ≥ 8mm (per IEC 60950)
- Clearance distance: ≥ 6mm

**Protection:**
- Input fuse: Slow-blow 15A
- Inrush current limiting
- Overcurrent protection on each output
- Overvoltage protection (crowbar or clamp)
- Thermal shutdown

**Standards Compliance:**
- UL 60950-1 (Safety of IT Equipment)
- IEC 61010-1 (Safety for Measurement Equipment)
- EMC: FCC Part 15 Class A, CE

---

## Topology Selection

### Option 1: Offline Flyback Converter (Dual Output)

**Topology:**
```
AC Mains  ─→  Bridge  ─→  Flyback  ─→  Output 1 (50V, 10A)
             Rectifier    Transformer
                             └────────→  Output 2 (50V, 10A)
```

**Advantages:**
- ✅ Simple, single transformer provides isolation
- ✅ Low part count
- ✅ Multiple outputs easily achieved

**Disadvantages:**
- ❌ Limited to ~300W per output (total ~600W) without extreme design
- ❌ Poor cross-regulation between outputs
- ❌ Large transformer size at 1kW

**Verdict:** Not suitable for 1kW total power.

---

### Option 2: Offline Forward Converter (Dual Output)

**Topology:**
```
AC Mains  ─→  PFC     ─→  Forward  ─→  Output 1 (50V, 10A)
             Boost       Converter
                            └────────→  Output 2 (50V, 10A)
```

**Advantages:**
- ✅ Suitable for 500-1000W per output
- ✅ Better efficiency than flyback
- ✅ Multiple isolated outputs

**Disadvantages:**
- ❌ Requires PFC stage (complex)
- ❌ Active-clamp or RCD snubber needed
- ❌ More expensive controller ICs

**Verdict:** Good option but complex design.

---

### Option 3: Two Separate Offline Supplies (Commercial Modules)

**Topology:**
```
AC Mains  ─→  Commercial  ─→  Output 1 (50V, 10A)
             PSU Module 1

AC Mains  ─→  Commercial  ─→  Output 2 (50V, 10A)
             PSU Module 2
```

**Advantages:**
- ✅ Simple, proven, safe
- ✅ Built-in protections
- ✅ UL/CE certified
- ✅ Fast development time
- ✅ Guaranteed isolation

**Disadvantages:**
- ❌ Higher cost (~$50-100 per unit)
- ❌ Less customizable
- ❌ Larger physical size

**Recommended Commercial Modules:**
- **Mean Well RSP-500-48** (48V, 10.5A, 504W) - $45 - Adjustable to 50V
- **Mean Well LRS-350-48** (48V, 7.3A, 350W) - $25 - For lower power variant
- **TDK-Lambda LS100-48** (48V, 2.3A, 110W) - $30 - For testing/prototyping

**Verdict:** **RECOMMENDED** for safety and simplicity. Use **Mean Well RSP-500-48** × 2.

---

### Option 4: Dual-Output Transformer with Linear Regulation

**Topology:**
```
AC Mains  ─→  Dual-Secondary  ─→  Rectifier  ─→  Linear Reg  ─→  50V Out 1
             Transformer                        ─→  Linear Reg  ─→  50V Out 2
```

**Advantages:**
- ✅ Very simple design
- ✅ Excellent line/load regulation
- ✅ Low noise and ripple
- ✅ Inherently isolated outputs

**Disadvantages:**
- ❌ Very low efficiency (~50-60% for 50V from 60V secondary)
- ❌ Massive heat dissipation (400-500W wasted as heat!)
- ❌ Large heatsinks required
- ❌ Heavy transformer (1kVA rating needed)

**Verdict:** Not suitable due to efficiency and thermal issues.

---

### Option 5: Custom Dual-Output SMPS (RECOMMENDED FOR CUSTOM DESIGN)

**Topology:**
```
AC Mains  ─→  Bridge  ─→  Bulk     ─→  Half-Bridge  ─→  Dual Output
             Rectifier    Cap (400V)   SMPS          Transformer
                                      (50-100 kHz)      ↓
                                                    Rectifier 1 → 50V, 10A
                                                    Rectifier 2 → 50V, 10A
```

**Advantages:**
- ✅ High efficiency (85-90%)
- ✅ Compact size
- ✅ Good cross-regulation with proper feedback
- ✅ Full isolation
- ✅ Customizable

**Disadvantages:**
- ❌ Complex design (requires SMPS expertise)
- ❌ EMI filtering required
- ❌ Safety certification required
- ❌ Long development time

**Verdict:** Best for custom ASIC/production version, but not for prototype.

---

### **FINAL DECISION: Use Commercial PSU Modules**

For safety, speed, and reliability, we will use:

**2× Mean Well RSP-500-48 modules** (or similar)

Adjusted to 50V output via onboard potentiometer.

---

## Using Mean Well RSP-500-48

### Specifications

**Model:** RSP-500-48

| Parameter | Value |
|-----------|-------|
| Input Voltage | 88-264V AC (universal input) |
| Output Voltage | 48V DC (adjustable 43-56V) |
| Output Current | 10.5A max |
| Output Power | 504W |
| Efficiency | 89% typ |
| Ripple & Noise | 150 mV p-p |
| Isolation | 3000V AC (input-output) |
| Protection | OVP, OCP, OTP, Short circuit |
| Operating Temp | -30°C to +70°C |
| Dimensions | 215 × 115 × 30 mm |
| Weight | 0.95 kg |
| Price | ~$45 USD |

**Datasheet:** [Mean Well RSP-500-48](https://www.meanwell.com/webapp/product/search.aspx?prod=RSP-500)

### Adjustment to 50V Output

The RSP-500-48 has an onboard **output voltage adjustment potentiometer** (VR1).

**Procedure:**
1. Disconnect load
2. Apply AC input power
3. Measure output voltage with multimeter
4. Adjust VR1 clockwise to increase voltage to **50.0V ± 0.1V**
5. Verify voltage under load (should not drop more than 1V at 10A)

**Adjustment Range:** 43-56V (48V ± 8V)

50V is well within range.

### Wiring

**Input Side (Per Module):**
```
AC Mains ─┬─── L (Line, Brown)   ────→  RSP-500-48
          ├─── N (Neutral, Blue) ────→  [Input]
          └─── PE (Ground, Green/Yellow) → FG (Frame Ground)
```

**Output Side:**
```
RSP-500-48 ────→  +V (Positive)  ────→  H-Bridge DC Bus (+)
  [Output]  ────→  -V (Negative)  ────→  H-Bridge DC Bus (-)
            ────→  FG (Frame Ground) → Chassis (DO NOT connect to -V)
```

**CRITICAL:**
- DO NOT connect -V outputs together (this defeats isolation!)
- Each supply powers ONE H-bridge only
- Frame ground (FG) connects to protective earth, NOT to -V

### Parallel Operation (NOT USED)

The RSP-500-48 supports parallel operation for current sharing, but we **DO NOT** parallel them since we need isolated outputs.

---

## Rectifier and Filter Design (If Using Custom SMPS)

*This section describes rectifier design if building custom SMPS. Skip if using commercial modules.*

### Transformer Secondary Rectification

**Topology:** Center-tapped full-wave rectifier

**Circuit (Per Output):**
```
Transformer           Rectifier                  Filter
Secondary
           CT ─────────────┬──────────────────────────────── 0V (Common)
                           │
         Sec1 ──┬─────────[│>]──── D1 (Fast recovery)
                │          │
               ∿          [│] C_bulk (Electrolytic)
                │          │
         Sec2 ──┴─────────[│>]──── D2 (Fast recovery)
                                   │
                                   ├──── L_filter ──── C_filter ──── +50V Out
                                   │                        │
                                   └──────────────────────────────── 0V Out
```

**Component Selection:**

**Diodes (D1, D2):**
- Reverse voltage: ≥ 2 × Vsec_peak = 2 × 70V = **140V** → Use **200V rated**
- Forward current: ≥ 15A (for transients)
- Recovery time: < 35 ns (for 100 kHz SMPS)
- Recommended: **MBR20200CT** (Schottky, 20A, 200V, TO-220)

**Bulk Capacitor (C_bulk):**
```
C_bulk = I_load / (f_ripple × ΔV_ripple)

For 10A load, 100 kHz switching, 1V ripple:
C_bulk = 10A / (100 kHz × 1V) = 100 μF
```

Use **220 μF / 100V electrolytic** (standard value with margin)

**Filter Inductor (L_filter):**

For LC filter with fc = 10 kHz cutoff:
```
fc = 1 / (2π√(LC))
L = 1 / (4π² × fc² × C)
L = 1 / (4π² × (10 kHz)² × 100 μF) = 2.5 μH
```

Use **4.7 μH / 15A** ferrite core inductor

**Output Capacitor (C_filter):**

Same as C_bulk: **220 μF / 100V** (low ESR, 105°C rated)

---

## Auxiliary Supplies

In addition to the main 50V supplies, we need lower voltage supplies for control circuitry.

### Required Auxiliary Voltages

| Rail | Voltage | Current | Purpose |
|------|---------|---------|---------|
| +12V | 12V DC | 500 mA | Gate driver Vcc (8× IR2110) |
| +5V | 5V DC | 500 mA | STM32, sensors, gate driver logic |
| +3.3V | 3.3V DC | 300 mA | STM32 core, peripherals |

### Option 1: Linear Regulators from One 50V Supply

**Circuit:**
```
+50V ──→ LM317 (adj) ──→ +12V (500 mA)
           │
           └──→ 7805 ──→ +5V (500 mA)
                  │
                  └──→ AMS1117-3.3 ──→ +3.3V (300 mA)
```

**Problems:**
- Massive power dissipation: (50V - 12V) × 0.5A = **19W** just for 12V rail!
- Not feasible

### Option 2: Buck Converters from One 50V Supply

**Circuit:**
```
+50V ──→ Buck Converter (LM2596) ──→ +12V (500 mA)
     ──→ Buck Converter (LM2596) ──→ +5V (500 mA)
+5V  ──→ LDO (AMS1117-3.3)      ──→ +3.3V (300 mA)
```

**Components:**
- **LM2596-ADJ** (adjustable buck, 3A, Vin up to 40V) - **ISSUE: 50V exceeds max input!**
- Need higher voltage buck: **LM5116** (6-100V input, 0.5A)

**Alternative: XL4016 buck module** (8-36V input) - **Still too low**

**Use:** **LM5116** (100V capable) or step down to 24V intermediate rail then to 12V/5V.

### Option 3: Separate Auxiliary PSU (RECOMMENDED)

**Use commercial module:**
- **Mean Well RD-35B** (Dual output: +5V/3A, +12V/1.5A) - **$12**
- Powered from AC mains (isolated)
- Much simpler and safer

**Verdict:** Use **Mean Well RD-35B** or similar for auxiliary supplies.

---

## Isolation and Safety

### Isolation Requirements

**Why isolation is critical:**

In a cascaded H-bridge, the output of H-Bridge 1 connects to the input of H-Bridge 2. If the DC supplies shared a common ground, this would create a short circuit.

**Required Isolation:**

```
Mains ──────┬──→ PSU 1 (isolated) ──→ H-Bridge 1 ──┐
            │                                      │
            └──→ PSU 2 (isolated) ──→ H-Bridge 2 ──┴──→ Series AC Output
```

- PSU 1 ground and PSU 2 ground are **floating** with respect to each other
- Both are isolated from mains earth ground
- Isolation voltage: ≥ 1500V (3× max output voltage for safety)

### Safety Measures

**1. Mains Input Protection:**
- Fuse: 15A slow-blow (per PSU)
- Inrush limiting: NTC thermistor (5Ω, 10A)
- EMI filter: Common-mode choke + X/Y capacitors
- Varistor (MOV): 275V AC (mains overvoltage protection)

**2. Output Protection:**
- Overcurrent: Built into RSP-500-48 (foldback current limiting)
- Overvoltage: Built into RSP-500-48 (OVP at 54-60V)
- Short circuit: Built into RSP-500-48 (hiccup mode)

**3. Grounding:**
- Chassis/frame connected to mains protective earth (PE)
- PSU frame ground (FG) connected to PE
- DC output grounds floating (not connected to PE)

**4. Isolation Testing:**
- Hipot test: 3000V AC for 1 minute (input-output)
- Insulation resistance: > 100 MΩ at 500V DC
- Conducted by certified lab for production units

---

## Testing and Validation

### Pre-Power Checks

**1. Visual Inspection:**
- Verify correct wiring (L, N, PE to correct terminals)
- Check polarity of DC outputs
- Ensure no shorts between outputs

**2. Isolation Testing:**
- Use megohm meter to verify isolation between:
  - PSU 1 output and PSU 2 output (should be > 100 MΩ)
  - Each PSU output and mains earth (should be > 100 MΩ)

**3. Wiring Verification:**
- Continuity check: mains PE to chassis ground
- Confirm no connection between DC- and chassis ground

### Low-Power Testing

**1. No-Load Test:**
- Apply AC mains to one PSU at a time
- Measure output voltage (should be 50V ± 0.5V)
- Measure ripple with oscilloscope (should be < 500 mV)
- Check efficiency: measure input power vs output power

**2. Light Load Test (10% load):**
- Connect 500Ω / 25W resistor to output
- Load current: 50V / 500Ω = 0.1A (10% of rated)
- Verify voltage regulation (should remain within ±1%)

### Full-Power Testing

**1. Gradual Load Increase:**
- Start with 25% load: 5Ω / 100W resistor → 10A × 5Ω = 50W load
- Increase to 50% load: 10Ω / 100W resistor → 5A
- Increase to 100% load: 5Ω / 100W resistor → 10A

**2. Thermal Testing:**
- Run at 100% load for 1 hour
- Monitor PSU case temperature (should not exceed 70°C)
- Monitor output voltage (should remain within ±2%)
- Check fan operation (if equipped)

**3. Transient Response:**
- Apply step load change (10% → 100%)
- Measure voltage dip/overshoot (should be < 5%)
- Recovery time should be < 100 ms

**4. Ripple and Noise:**
- Measure output ripple with oscilloscope (AC coupling, 20 MHz bandwidth)
- Should be < 500 mV peak-to-peak
- Check for high-frequency noise spikes

---

## Bill of Materials

### BOM for Complete Power Supply System

**Option 1: Commercial Modules (RECOMMENDED)**

| Qty | Part Number | Description | Specs | Price (approx) |
|-----|-------------|-------------|-------|----------------|
| 2 | RSP-500-48 | Switching PSU | 48V (adj to 50V), 10.5A, 504W | $45 each = $90 |
| 1 | RD-35B | Dual auxiliary PSU | +5V/3A, +12V/1.5A | $12 |
| 2 | NTC 5Ω 10A | Inrush limiter | 5Ω @ 25°C, 10A | $1 each = $2 |
| 2 | Fuse 15A | Slow-blow fuse | 250V AC, 15A | $1 each = $2 |
| 2 | Fuse holder | Panel mount | For 5×20mm fuse | $1 each = $2 |
| 2 | MOV 275V | Varistor | 275V AC, 14mm | $0.50 each = $1 |
| 2 | EMI filter | IEC inlet with filter | 10A rated | $5 each = $10 |
| | Terminals | Screw terminals | For output wiring | $5 |
| | Enclosure | Vented metal box | 300×200×100mm | $20 |
| | | | **Total** | **~$144** |

**Notes:**
- Prices are approximate (2024 USD)
- Commercial modules include all protections and certifications
- Total cost significantly lower than custom SMPS development
- Faster time-to-market and proven reliability

---

**Option 2: Custom SMPS (For Reference Only)**

*Not recommended for prototype. Estimated BOM cost: $60-80 per supply, but requires extensive design, testing, and safety certification. Development time: 3-6 months.*

---

## Wiring Diagram

### Complete Power Distribution

```
                             Mains Input (120/240V AC)
                                      │
                    ┌─────────────────┼─────────────────┐
                    │                 │                 │
                  Fuse              Fuse              Fuse
                    │                 │                 │
                 NTC Lim           NTC Lim          (Filter)
                    │                 │                 │
            ┌───────┴──────┐  ┌───────┴──────┐  ┌───────┴──────┐
            │  RSP-500-48  │  │  RSP-500-48  │  │   RD-35B     │
            │   (PSU 1)    │  │   (PSU 2)    │  │  (Aux PSU)   │
            └──────┬───────┘  └──────┬───────┘  └──────┬───────┘
                   │                 │                 │
                +50V              +50V             +12V +5V
                   │                 │                 │
                   │                 │           ┌─────┴──────┐
                   │                 │           │ LDO 3.3V   │
                   │                 │           └─────┬──────┘
                   │                 │                 │
                   │                 │              +3.3V
                   │                 │                 │
            ┌──────┴──────┐   ┌──────┴──────┐   ┌─────┴──────┐
            │  H-Bridge 1 │   │  H-Bridge 2 │   │   STM32    │
            │  (S1-S4)    │   │  (S5-S8)    │   │ + Drivers  │
            └──────┬──────┘   └──────┬──────┘   └────────────┘
                   │                 │
                   └────────┬────────┘
                            │
                     5-Level AC Output
                        (100V RMS)
```

---

## Appendix: Future Improvements

### For Production Version

1. **Integrated Multi-Output SMPS:**
   - Single transformer with multiple isolated outputs
   - Better cross-regulation
   - More compact
   - Lower total cost at volume

2. **Digital Control:**
   - Microcontroller-based PSU control
   - Programmable output voltage
   - Real-time monitoring (voltage, current, temperature)
   - Communication with main controller (I²C/CAN)

3. **Power Factor Correction:**
   - Active PFC stage (boost converter)
   - Meets EN 61000-3-2 harmonic limits
   - Reduces mains current draw

4. **Soft-Start Circuit:**
   - Controlled ramp-up of output voltage
   - Reduces inrush to inverter capacitors
   - Extends PSU lifespan

---

**Document Status:** Design complete using commercial modules
**Next Steps:** Procure Mean Well PSUs, test, integrate with H-bridge

**Related Documents:**
- `01-Gate-Driver-Design.md` - Gate driver circuits
- `03-Current-Voltage-Sensing.md` - Sensing circuits (powered from auxiliary PSU)
- `04-Protection-Circuits.md` - System-level protection
- `06-Complete-BOM.md` - Master bill of materials
