# Gate Driver Circuit Design

**Document Type:** Hardware Design Specification
**Project:** 5-Level Cascaded H-Bridge Inverter
**Author:** 5-Level Inverter Project
**Date:** 2025-11-16
**Version:** 2.0
**Status:** Validated Design - TLP250 Optically Isolated

---

## Table of Contents

1. [Overview](#overview)
2. [Gate Driver Requirements](#gate-driver-requirements)
3. [TLP250 Optically Isolated Gate Driver](#tlp250-optically-isolated-gate-driver)
4. [Why TLP250 Instead of IR2110](#why-tlp250-instead-of-ir2110)
5. [Isolated Power Supply Design](#isolated-power-supply-design)
6. [Gate Resistor Selection](#gate-resistor-selection)
7. [PCB Layout Considerations](#pcb-layout-considerations)
8. [Testing and Validation](#testing-and-validation)
9. [Bill of Materials](#bill-of-materials)

---

## Overview

### Purpose

This document describes the gate driver circuit design for the 5-level cascaded H-bridge multilevel inverter using **TLP250 optically isolated gate drivers**. The Cascaded H-Bridge (CHB) topology **requires true galvanic isolation** due to floating H-bridge potentials, making optocoupler-based drivers mandatory.

### System Context

**Inverter Topology:**
- 2 cascaded H-bridges (8 power switches total)
- Each H-bridge: 4 switches (2 high-side, 2 low-side)
- Switching frequency: 5 kHz
- DC bus voltage per bridge: 50V
- Dead-time requirement: 1-2 μs

**Power Switch Selection:**
- **Selected:** IRFZ44N N-channel MOSFETs (55V, 49A, Rds(on)=17.5mΩ)
- Qg = 72 nC (similar to IRF540N)
- Provides 37.5% voltage margin above 50V operation

**Gate Driver Topology:**
- **8× TLP250** optocouplers (one per MOSFET)
- **2× isolated DC-DC converters** (one per H-bridge module)
- Each DC-DC provides 15V isolated supply for 4× TLP250 drivers per module

### Critical Design Constraint: Why Optical Isolation is MANDATORY

**⚠️ CRITICAL:** In Cascaded H-Bridge topology, **bootstrap-based drivers like IR2110 CANNOT work** due to fundamental incompatibility with floating H-bridge potentials.

**Reason:**
- In CHB, only the bottom H-bridge is ground-referenced
- Upper H-bridge floats at +50V relative to system ground
- Bootstrap drivers reference the high-side source terminal, which never returns to true ground in floating configurations
- This was **proven through Simulink simulation** where IR2110 models failed for modules 2, 3, and 4

**Solution:**
- **TLP250 with optical isolation** provides 2.5kV galvanic isolation
- Each driver powered by independent isolated supply
- Works identically for all modules regardless of floating potential

---

## Gate Driver Requirements

### Electrical Requirements

**Gate Drive Voltage:**
- MOSFET gate threshold: 2-4V
- Required Vgs for full enhancement: 10-12V
- Driver output voltage: **15V / 0V** (from isolated DC-DC)
- Gate charge (IRFZ44N): Qg = 72 nC

**Current Requirements:**

For 5 kHz switching with 100 ns rise/fall times:

```
I_gate_peak = Qg / t_rise = 72 nC / 100 ns = 0.72 A
```

**TLP250 Specifications:**
- Output current: 1.5A source, 1.5A sink (exceeds requirement)
- Rise/fall time: ~150 ns (adequate for 5 kHz)
- Propagation delay: 500 ns typical
- Isolation voltage: 2500V (BV_{CES})
- Operating temperature: -55°C to +100°C

### Isolation Requirements (CHB-Specific)

**Mandatory for Cascaded Topology:**
1. **True Galvanic Isolation:** 2.5kV minimum between input and output
2. **Independent Power:** Each driver requires isolated 15V supply
3. **Common-Mode Immunity:** Must handle floating potentials up to 100V
4. **No Shared References:** Driver ground fully isolated from system ground

### Protection Requirements

1. **Shoot-Through Protection:**
   - Dead-time insertion (1.5 μs) implemented in STM32F303 timer hardware
   - TLP250 propagation delay adds additional safety margin

2. **Overcurrent Shutdown:**
   - External sensing circuit
   - Shuts down all gate drives via disable signal

3. **Under-Voltage Lockout:**
   - Implemented in isolated DC-DC converter
   - Prevents operation if isolated supply < 12V

---

## TLP250 Optically Isolated Gate Driver

### Why TLP250?

The **TLP250** is an optocoupler-based MOSFET driver specifically designed for isolated gate drive applications:

**Advantages:**
- ✅ True galvanic isolation (2.5kV) via LED-photodetector coupling
- ✅ **Works with floating H-bridge configurations** (mandatory for CHB)
- ✅ 1.5A source/sink output current
- ✅ Simple interface (LED input, totem-pole output)
- ✅ No bootstrap limitations or duty cycle restrictions
- ✅ Single-channel design (one driver per MOSFET = clear, modular layout)
- ✅ Low cost (~$1.50 per unit)
- ✅ DIP-8 package (breadboard-friendly for prototyping)

**Specifications:**
- Isolation voltage: 2500V (BV_{CES})
- Output current: 1.5A source / 1.5A sink
- Propagation delay: 500 ns (typ), 800 ns (max)
- Supply voltage (Vcc): 10-35V (we use 15V isolated)
- Input current: 7-16 mA (LED forward current)
- Operating frequency: DC to 1 MHz
- Package: DIP-8, SO-8

### TLP250 Pin Configuration

```
        TLP250 (DIP-8 / SO-8)

        Anode   (1)  ━━━━━  (8) Vcc
        Cathode (2)  ━━━━━  (7) Vo (Output)
        NC      (3)  ━━━━━  (6) Vo (Output)
        NC      (4)  ━━━━━  (5) GND
```

**Pin Descriptions:**

| Pin | Name | Function |
|-----|------|----------|
| 1 | Anode | LED anode (input from STM32 via current-limiting resistor) |
| 2 | Cathode | LED cathode (to STM32 ground) |
| 3, 4 | NC | No connection |
| 5 | GND | Isolated ground (references MOSFET source for high-side) |
| 6, 7 | Vo | Totem-pole output (two pins tied together for higher current) |
| 8 | Vcc | Isolated 15V supply |

**Important:** Pins 6 and 7 are tied together to increase output current capability to 1.5A.

### Typical Application Circuit (One MOSFET)

```
STM32 (3.3V)                        Isolated Side (floating)

    GPIO ───┬─── 150Ω ───┬─── (1) Anode           +15V (Isolated)
            │            │                          │
            │            │    TLP250            ┌───┴────┐
            │            │                      │ Vcc (8)│
        Status LED       │                      │        │
            │            │                  ┌───┤ GND (5)│
            └─── LED ────┘                  │   └───┬────┘
                 │                          │       │
                GND ─────────── (2) Cathode │   (7) Vo (6)
                                            │       │
                                            │   ┌───┴────┐
                                            │   │   Rg   │ 10Ω
                                            │   └───┬────┘
                                            │       │
                                            │     Gate ──── MOSFET
                                            │       │
                                            └───────┴──────── Source

                                   (GND references Source
                                    for high-side drivers)
```

### Input Drive Circuit (STM32F303 Side)

Each TLP250 input (LED) is driven by STM32 GPIO through current-limiting resistor:

**Calculation:**

```
I_LED = 10 mA (typical for reliable switching)
V_STM32 = 3.3V
V_F (TLP250 LED) = 1.2V typical

R_LED = (V_STM32 - V_F) / I_LED
      = (3.3V - 1.2V) / 10 mA
      = 210 Ω
```

**Standard value:** **150Ω** (provides ~14 mA, faster switching)

**Power dissipation:**
```
P = I²R = (14 mA)² × 150Ω = 29 mW
```

**Use:** 1/4W resistor (plenty of margin)

**Series Status LED (Optional):**
- Add indicator LED in series with TLP250 input
- Total R = 150Ω accommodates both LEDs
- Provides visual confirmation of gate drive signals

---

## Why TLP250 Instead of IR2110?

### The Fundamental Incompatibility Problem

**IR2110 Bootstrap Driver Limitation:**

Bootstrap drivers like IR2110 work excellently in **ground-referenced** half-bridge or full-bridge configurations. However, they **CANNOT work in Cascaded H-Bridge topology** due to a fundamental operating principle limitation.

**How IR2110 Bootstrap Works:**
1. During low-side conduction, V_S (high-side source) connects to ground through low-side MOSFET
2. Bootstrap capacitor charges from V_CC through bootstrap diode
3. When high-side turns ON, V_S rises to +V_DC
4. Bootstrap capacitor floats with V_S, providing V_GS = V_BOOT relative to floating V_S
5. **CRITICAL:** The driver COM pin (ground reference) connects to the FLOATING V_S terminal

**This works ONLY when V_S periodically returns to true ground.**

**The CHB Cascaded Problem:**

In our 5-level inverter with 2 cascaded H-bridges:
- **H-Bridge 1 (bottom):** Ground-referenced ✅ (IR2110 could work here)
- **H-Bridge 2 (top):** Floats at +50V ❌ (IR2110 CANNOT work here)

For H-Bridge 2:
- V_S terminal NEVER returns to system ground
- V_S floats at +50V (when H-bridge 1 outputs +50V)
- Bootstrap capacitor attempts to charge through series connection of lower module
- Common-mode voltage across driver exceeds IR2110's isolation capability
- Bootstrap refresh fails → inadequate or complete loss of gate drive

### Simulink Validation Evidence

**Critical experimental evidence from graduation project interim report:**

Our Simulink model incorporated detailed IR2110 driver models including:
- Bootstrap capacitor charging dynamics
- COM terminal referencing to floating V_S
- Common-mode voltage tracking

**Simulation Results:**

| Module | V_S Potential | Gate Drive Quality | Functional? |
|--------|---------------|-------------------|-------------|
| Case 1 (bottom) | Ground (0V) | Stable 10-15V | ✅ YES |
| Case 2 (top) | Floating (+50V) | Erratic, V_GS < 8V | ❌ NO |
| Case 3 (if 4 modules) | +100V | V_GS < 5V | ❌ NO |
| Case 4 (if 4 modules) | +150V | V_GS < 3V | ❌ NO |

**Output waveform with IR2110:** Severely distorted, non-functional

**After switching to TLP250 in simulation:**
- All modules: Stable 15V gate drive ✅
- Proper 5-level output waveform ✅
- All MOSFETs switching correctly ✅
- THD = 4.9% (meets <5% target) ✅

**Conclusion from simulation:** IR2110 is **fundamentally incompatible** with CHB topology due to floating bridge limitations.

### Decision Matrix: TLP250 vs IR2110

| Parameter | TLP250 (Selected) | IR2110 (Incompatible) |
|-----------|-------------------|----------------------|
| **Isolation Method** | Optical (LED + Photodetector) | Bootstrap Capacitor |
| **Isolation Rating** | 2.5kV galvanic | N/A (bootstrap only ~600V CM) |
| **Reference Point** | Fully isolated per driver | High-side source terminal |
| **CHB Compatibility** | ✅ YES - works for ALL modules | ❌ NO - only Module 1 |
| **Floating Bridge Support** | ✅ YES (with isolated supply) | ❌ NO (fundamental limitation) |
| **Duty Cycle Limits** | None (independent power) | Limited by bootstrap refresh |
| **Propagation Delay** | 500 ns | 120 ns |
| **Output Current** | 1.5A | 2A |
| **Supply Configuration** | Isolated DC-DC per module | Bootstrap + V_CC |
| **Simulink Validation** | ✅ Successful (all modules) | ❌ Failed (modules 2+) |
| **Cost per MOSFET** | ~$1.50 | ~$1.00 (if it worked) |
| **Total System Cost** | $12 for 8 drivers | N/A (doesn't work) |

### Speed Trade-Off is Irrelevant

**Yes, IR2110 is faster (120 ns vs 500 ns delay), BUT:**

1. **IR2110 doesn't function in CHB** (proven by simulation) →propagation delay comparison is meaningless
2. **TLP250 speed is adequate:**
   - 0.5 μs delay in 200 μs PWM period (0.25% of period)
   - Control loop limited by ADC conversion time (~5 μs), not gate driver
   - 5 kHz switching frequency is low-speed compared to modern inverters
3. **Dead-time margin increased:** Longer propagation provides additional shoot-through protection

### Key Learning: Topology Determines Driver Choice

**Bootstrap drivers (IR2110, IRS2110, etc.):**
- ✅ Excellent for: Single H-bridge, half-bridge, ground-referenced topologies
- ❌ **CANNOT be used for:** Cascaded H-bridges, floating bridges, multilevel inverters

**Isolated drivers (TLP250, HCPL-3120, Si827x):**
- ✅ Required for: CHB, MMC, any floating bridge configuration
- ✅ Works for: ALL topologies (universal solution)
- ❌ Trade-off: Higher cost, isolated power supply complexity

**For CHB topology, TLP250 is not a "design choice" - it's a fundamental requirement.**

---

## Isolated Power Supply Design

### Power Requirements

Each H-bridge module requires isolated 15V power for 4× TLP250 drivers:

**Per-Driver Current:**
- Quiescent: ~5 mA
- Peak during switching: ~100 mA (brief)
- Average: ~15 mA

**Per-Module Total (4× drivers):**
- Average: 60 mA
- Peak: 400 mA (when all 4 switching simultaneously)
- Design for: **500 mA** (safety margin)

### Isolated DC-DC Converter Selection

**Topology:** Flyback or push-pull isolated DC-DC converter

**Recommended Components:**

**Option 1: Off-the-shelf Module (Simplest)**
- **Part:** MORNSUN B0515S-1WR3
- Input: 5V (from STM32 power rail)
- Output: 15V isolated, 66 mA
- Isolation: 3kV
- Efficiency: ~75%
- Cost: ~$4 per module

**Problem:** 66 mA insufficient for 4× drivers

**Better Option 2: Higher Power Module**
- **Part:** TRACO TEN 5-0522 or RECOM RO-0515S
- Input: 5V
- Output: ±15V or single 15V, 200-400 mA
- Isolation: 1.5-3kV
- Cost: ~$10-15 per module

**Option 3: Custom Flyback Design**
- Use PWM controller (e.g., LT3748)
- Flyback transformer
- Full control over specifications
- Higher development effort

**Selected for Project:** **2× RECOM R-78E15-0.5 (15V, 500mA isolated modules)**
- Input: 12V from auxiliary supply
- Output: 15V, 500 mA per module
- Isolation: 1.5 kV (adequate)
- Efficiency: ~85%
- Cost: ~$12 each × 2 = $24 total

### Power Distribution Architecture

```
            Main DC Bus (2× 50V isolated sources)
                      │
                      ├─────┬────── H-Bridge 1 (50V)
                      │     │
                      │     └────── H-Bridge 2 (50V)
                      │
         Auxiliary 12V Supply (for control)
                      │
        ┌─────────────┴──────────────┐
        │                            │
   [DC-DC 1]                    [DC-DC 2]
   12V → 15V                    12V → 15V
   (Isolated)                   (Isolated)
        │                            │
        ├──── TLP250 #1 (H1 HS1)    ├──── TLP250 #5 (H2 HS1)
        ├──── TLP250 #2 (H1 LS1)    ├──── TLP250 #6 (H2 LS1)
        ├──── TLP250 #3 (H1 HS2)    ├──── TLP250 #7 (H2 HS2)
        └──── TLP250 #4 (H1 LS2)    └──── TLP250 #8 (H2 LS2)
```

**Key Points:**
- One isolated DC-DC per H-bridge module
- All 4 TLP250 drivers in same module share isolated ground
- Isolated ground references MOSFET sources (high-side) or system ground (low-side)

---

## Gate Resistor Selection

### Purpose of Gate Resistors

Gate resistors control:
1. Switching speed (di/dt and dv/dt)
2. EMI and ringing
3. Gate driver power dissipation
4. False triggering prevention

### Turn-On/Turn-Off Resistor (Rg)

**Calculation:**

For moderate speed (100 ns rise time):

```
I_gate = Qg / t_rise = 72 nC / 100 ns = 0.72 A

Rg = (Vdrv - Vgs_th) / I_gate
   = (15V - 4V) / 0.72 A
   = 15Ω
```

**Standard value:** **10Ω** (allows slightly faster switching, better efficiency)

**Power rating:**

```
P_rg = Qg × Vdrv × f_sw
     = 72 nC × 15V × 5 kHz
     = 5.4 mW
```

**Use:** 1/4W resistor (plenty of margin)

### Final Gate Resistor Selection

| Resistor | Value | Power | Quantity |
|----------|-------|-------|----------|
| Rg (turn-on/off) | 10Ω | 1/4W | 8 (one per MOSFET) |

**Note:** Same resistor for turn-on and turn-off ensures symmetric switching.

---

## PCB Layout Considerations

### Critical Layout Rules

**1. Optical Isolation Barrier:**
- Maintain **6mm minimum creepage distance** between input (STM32) and output (MOSFET) sides
- Separate ground planes (STM32 ground vs isolated driver ground)
- No copper crossing isolation barrier except through TLP250 pins

**2. Minimize Gate Loop Inductance:**
- Place TLP250 close to MOSFET gates (< 3 cm)
- Wide traces from Vo pins to gate resistor
- Keep Rg close to MOSFET gate pin

**3. Isolated Power Distribution:**
- Star-ground configuration for each isolated DC-DC output
- Decouple 15V supply with 100 μF electrolytic + 100 nF ceramic per module
- Separate isolated ground pour for each H-bridge module

**4. Input Side (STM32):**
- Route PWM signals with ground return paths
- Place LED resistors close to TLP250 anode pins
- Decouple STM32 3.3V rail

**5. EMI Mitigation:**
- Shield isolated 15V traces with ground pour
- Keep high dv/dt switching nodes away from sensitive signals
- Use ferrite beads on isolated DC-DC inputs

### Layout Example (One H-Bridge Module)

```
═══════════════ ISOLATION BARRIER (6mm clearance) ═══════════════

STM32 Side (Ground-Referenced)     Isolated Side (Floating for H2)

  ┌──────┐                              +15V (Isolated)
  │STM32 │                                  │
  │ GPIO ├──150Ω──┐                    ┌────┴─────┐
  │      │        │                    │  DC-DC   │
  │      │     TLP250 (1)              │ Converter│
  │      │        │ (Anode)            └────┬─────┘
  │      │    ┌───┴────┐                    │
  │      │    │ Input  │                ┌───┴────┐
  │      │    │  LED   │                │ 100μF  │ Bulk
  │ GPIO ├────┤        ├────(Vo)───Rg───┤        │
  │      │    │ Output │              Gate    100nF│ Ceramic
  │      │    │        │                │        │
  └──────┘    └────────┘                └────────┘
      │            │                         │
     GND      (Cathode)              Isolated GND
    (System)                         (Module GND)

═══════════════════════════════════════════════════════════════
```

---

## Testing and Validation

### Pre-Power Testing

**1. Isolation Resistance Test:**
- Use megohmmeter (500V setting)
- Measure resistance between STM32 ground and isolated ground
- Should be > 100 MΩ (confirms proper isolation)

**2. Continuity Testing:**
- Verify isolated ground connections within each module
- Confirm NO continuity between system ground and isolated grounds
- Check power rail continuity

**3. Low-Voltage LED Test:**
- Apply 3.3V to TLP250 input through 150Ω resistor
- LED should light (visible through package in some versions)
- Measure input current: should be ~14 mA

### Functional Testing (No MOSFETs)

**1. Isolated Supply Test:**
- Apply 12V to DC-DC converter input
- Measure isolated output: should be 15V ± 0.5V
- Load with 100Ω resistor, verify voltage stable
- Check ripple with oscilloscope: < 100 mVpp

**2. TLP250 Output Test:**
- Power isolated side with 15V
- Drive input with 1 kHz square wave (50% duty)
- Monitor output with oscilloscope (isolated probe!)
- Verify:
  - Output swings 0V to 15V cleanly
  - Propagation delay ~500 ns
  - Rise/fall times < 200 ns
  - No ringing or oscillation

**3. Dead-Time Verification:**
- Generate complementary PWM from STM32 (1.5 μs dead-time)
- Drive two TLP250s (high-side and low-side of one leg)
- Verify with oscilloscope that outputs are NEVER both HIGH
- Confirm dead-time > 1 μs

### Power Testing (With MOSFETs)

**1. Reduced Voltage Test:**
- Start with 12V DC bus (instead of 50V)
- Connect resistive load (10Ω, 50W)
- Apply 50% duty cycle PWM at 1 kHz
- Verify MOSFETs switch properly
- Monitor for shoot-through (current spikes)

**2. Thermal Testing:**
- Run at full power (50V, 10A)
- Monitor temperatures:
  - TLP250: should stay < 60°C
  - MOSFETs: < 80°C with heatsinks
  - Isolated DC-DC: < 70°C
- Use thermal camera if available

**3. Isolation Verification Under Power:**
- Use isolated oscilloscope channels
- Measure common-mode voltage between grounds
- For H-Bridge 2: should see up to 50V CM voltage
- Confirm no isolation breakdown

---

## Bill of Materials

### BOM for One H-Bridge Module (4 Gate Drivers)

| Qty | Part Number | Description | Specs | Price (approx) |
|-----|-------------|-------------|-------|----------------|
| 4 | TLP250 | Optocoupler Gate Driver | 2.5kV isolation, 1.5A output | $6.00 |
| 1 | RECOM R-78E15-0.5 | Isolated DC-DC Converter | 12V→15V, 500mA, 1.5kV isolation | $12.00 |
| 4 | Resistor 150Ω | LED Current Limiting | 1/4W, 5% tolerance | $0.08 |
| 4 | Resistor 10Ω | Gate Resistor | 1/4W, 5% tolerance | $0.08 |
| 1 | Capacitor 100μF | Isolated Supply Bulk | Electrolytic, 25V | $0.20 |
| 2 | Capacitor 100nF | Isolated Supply Decoupling | Ceramic X7R, 25V | $0.10 |
| | | | **Subtotal per module** | **~$19** |

### BOM for Complete 5-Level Inverter (2 H-Bridges = 8 Drivers)

| Qty | Part Number | Description | Specs | Total Price |
|-----|-------------|-------------|-------|-------------|
| 8 | TLP250 | Optocoupler Gate Driver | 2.5kV isolation, 1.5A | $12.00 |
| 2 | RECOM R-78E15-0.5 | Isolated DC-DC Converter | 12V→15V, 500mA | $24.00 |
| 8 | Resistor 150Ω | LED Current Limiting | 1/4W | $0.16 |
| 8 | Resistor 10Ω | Gate Resistor | 1/4W | $0.16 |
| 2 | Capacitor 100μF | Isolated Supply Bulk | 25V electrolytic | $0.40 |
| 4 | Capacitor 100nF | Isolated Supply Decoupling | Ceramic | $0.20 |
| | | | **Total** | **~$37** |

**Cost Comparison:**
- TLP250-based solution: ~$37 total
- IR2110-based solution (if it worked): ~$11 total
- **Premium for working solution:** $26 (2.4× more expensive)
- **Trade-off:** Mandatory for CHB topology to function at all

**Note:** Prices are approximate (2024-2025 USD) from typical distributors (Mouser, Digi-Key).

---

## Appendix: Alternative Isolated Gate Drivers

For future designs or different topologies:

| Part Number | Manufacturer | Type | Isolation | Output Current | Cost | Notes |
|-------------|--------------|------|-----------|----------------|------|-------|
| **TLP250** | Toshiba | Optocoupler | 2.5kV | 1.5A | ~$1.50 | **Selected** - proven, simple |
| HCPL-3120 | Broadcom | Optocoupler | 3.75kV | 2.5A | ~$3.00 | Higher current, more expensive |
| Si827x | Silicon Labs | Magnetic | 5kV | 4A | ~$5.00 | Integrated isolated power |
| ISO5451 | TI | Capacitive | 5kV | 4A | ~$4.50 | Faster (50ns), high isolation |
| ACPL-332J | Broadcom | Optocoupler | 3.75kV | 2.5A | ~$3.50 | Automotive grade |

**Why TLP250 was selected:**
1. Adequate specifications for 5 kHz, 55V application
2. Simple external circuit (just isolated power needed)
3. Proven through Simulink validation
4. Lower cost than alternatives
5. DIP-8 package available (prototyping-friendly)
6. Widely available from multiple distributors

---

## Appendix: Simulink Validation Summary

**From ELE401 Graduation Project Interim Report (November 2025):**

### IR2110 Simulation Failure

**Model Details:**
- Included detailed IR2110 driver models
- Bootstrap capacitor charging dynamics
- COM terminal referencing to V_S
- Floating potential tracking for cascaded modules

**Results:**
- ❌ Module 1: Works (ground-referenced)
- ❌ Module 2: Failed (V_S floating at +50V → inadequate gate drive)
- ❌ Modules 3-4 (if expanded): Complete failure

**Output Waveform:** Severely distorted, non-functional

### TLP250 Simulation Success

**Model Details:**
- 8× TLP250 optocoupler models
- Independent isolated 15V supplies per module
- Optical isolation and propagation delay included

**Results:**
- ✅ All modules: Stable 15V gate drive
- ✅ Proper 5-level output waveform
- ✅ All MOSFETs switching correctly
- ✅ THD = 4.9% (meets <5% target)
- ✅ Efficiency > 95%

**Conclusion:** TLP250 with isolated supplies is the correct and only viable solution for CHB topology.

---

**Document Status:** Design validated through simulation, ready for hardware implementation
**Next Steps:** PCB layout with proper isolation barriers, prototype fabrication, hardware testing

**Related Documents:**
- `02-Power-Supply-Design.md` - Isolated 50V DC sources and auxiliary 12V supply
- `03-Current-Voltage-Sensing.md` - Isolated sensing circuits
- `04-Protection-Circuits.md` - Overcurrent and fault protection
- `05-PCB-Layout-Guide.md` - Complete layout guidelines with isolation requirements
- `ELE401_Fall2025_IR_Group1.pdf` - Full project interim report with simulation results
