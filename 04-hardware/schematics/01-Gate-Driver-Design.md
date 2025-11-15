# Gate Driver Circuit Design

**Document Type:** Hardware Design Specification
**Project:** 5-Level Cascaded H-Bridge Inverter
**Author:** 5-Level Inverter Project
**Date:** 2025-11-15
**Version:** 1.0
**Status:** Design - Not Yet Validated

---

## Table of Contents

1. [Overview](#overview)
2. [Gate Driver Requirements](#gate-driver-requirements)
3. [IR2110 High-Low Side Driver](#ir2110-high-low-side-driver)
4. [Bootstrap Circuit Design](#bootstrap-circuit-design)
5. [Gate Resistor Selection](#gate-resistor-selection)
6. [PCB Layout Considerations](#pcb-layout-considerations)
7. [Testing and Validation](#testing-and-validation)
8. [Bill of Materials](#bill-of-materials)

---

## Overview

### Purpose

This document describes the gate driver circuit design for the 5-level cascaded H-bridge multilevel inverter. Each H-bridge requires 4 gate drivers (8 total), carefully designed to:

- Provide adequate gate drive current for MOSFETs/IGBTs
- Implement shoot-through protection via dead-time
- Handle high-side and low-side switching
- Ensure fast switching transitions
- Provide isolation where required

### System Context

**Inverter Topology:**
- 2 cascaded H-bridges (8 power switches total)
- Each H-bridge: 4 switches (2 high-side, 2 low-side)
- Switching frequency: 5 kHz
- DC bus voltage per bridge: 50V
- Dead-time requirement: 1 μs minimum

**Power Switch Selection:**
- **Option 1:** IRF540N N-channel MOSFETs (100V, 33A, Rds(on)=44mΩ)
- **Option 2:** IRFB4110 N-channel MOSFETs (100V, 180A, Rds(on)=3.7mΩ)
- **Option 3:** FGA25N120ANTD IGBTs (1200V, 25A) for high-voltage variant

This design uses **IRF540N** for cost-effectiveness and **IRFB4110** for higher current applications.

---

## Gate Driver Requirements

### Electrical Requirements

**Gate Drive Voltage:**
- MOSFET gate threshold: 2-4V
- Required Vgs for full enhancement: 10-12V
- Driver output voltage: **+12V / 0V** (for N-channel MOSFETs)
- Gate charge (IRF540N): Qg = 72 nC
- Gate charge (IRFB4110): Qg = 210 nC

**Current Requirements:**

For 5 kHz switching with 100 ns rise/fall times:

```
I_gate_peak = Qg / t_rise
```

For IRF540N:
```
I_gate_peak = 72 nC / 100 ns = 0.72 A
```

For IRFB4110:
```
I_gate_peak = 210 nC / 100 ns = 2.1 A
```

**Driver Specifications Required:**
- Output current: ≥ 2A source, ≥ 2A sink
- Rise/fall time: < 100 ns
- Propagation delay: < 200 ns
- Supply voltage: 10-20V
- Operating frequency: > 10 kHz
- Dead-time generation: Hardware or external

### Protection Requirements

1. **Shoot-Through Protection:**
   - Dead-time insertion (1 μs minimum)
   - Implemented in STM32 timer hardware
   - Driver must respect dead-time

2. **Under-Voltage Lockout (UVLO):**
   - Disable outputs if Vcc < threshold
   - Prevents weak gate drive
   - Built into IR2110

3. **Desaturation Protection (Optional):**
   - Detects MOSFET/IGBT failure
   - Monitors Vds during on-state
   - Shuts down on overcurrent

4. **Fault Feedback:**
   - Signal to microcontroller on fault
   - Allows emergency shutdown
   - Implemented via opto-isolator

---

## IR2110 High-Low Side Driver

### Why IR2110?

The **IR2110** is an industry-standard high-voltage, high-speed gate driver IC ideal for this application:

**Advantages:**
- ✅ High-side and low-side driver in one IC
- ✅ Bootstrap operation (no isolated supply needed)
- ✅ 500V/600V voltage rating (sufficient for 50V bus)
- ✅ 2A source/sink current
- ✅ Built-in UVLO and shoot-through protection
- ✅ Logic-level inputs (3.3V/5V compatible with level shifter)
- ✅ Low cost (~$2 per IC)
- ✅ DIP and SOIC packages available

**Specifications:**
- Absolute maximum rating: 600V
- Output current: 2A source / 2A sink
- Propagation delay: 120 ns (typ), 180 ns (max)
- Supply voltage (Vcc): 10-20V (we use 12V)
- Logic supply (Vdd): 5-20V (we use 5V from STM32)
- UVLO thresholds: 8.7V (turn-off), 9.7V (turn-on)

### IR2110 Pin Configuration

```
        IR2110 (DIP-14 / SOIC-16)

        VB  (1)  ━━━━━  (14/16) Vcc
        HO  (2)  ━━━━━  (13/15) Vdd
        VS  (3)  ━━━━━  (12/14) LO
        NC  (4)  ━━━━━  (11/13) GND
        NC  (5)  ━━━━━  (10/12) SD (Shutdown)
        LIN (6)  ━━━━━  (9/11)  HIN
        NC  (7)  ━━━━━  (8/10)  COM
```

**Pin Descriptions:**

| Pin | Name | Function |
|-----|------|----------|
| VB | Bootstrap Supply | High-side floating supply (VS + 12V) |
| HO | High-Side Output | Gate drive for high-side MOSFET |
| VS | High-Side Return | Floating ground (source of high-side MOSFET) |
| Vcc | Low-Side Supply | 12V supply for low-side driver and logic |
| Vdd | Logic Supply | 5V supply for input logic |
| LO | Low-Side Output | Gate drive for low-side MOSFET |
| GND | Ground | System ground |
| LIN | Low-Side Input | PWM input for low-side (active high) |
| HIN | High-Side Input | PWM input for high-side (active high) |
| SD | Shutdown | Active low shutdown (pull high for operation) |
| COM | Common | Logic ground (connected to GND) |

### Typical Application Circuit

```
                    +12V (Vcc)
                      │
              ┌───────┴───────┐
              │   Bootstrap   │
         VB ──┤   Diode &     │
              │   Capacitor   │
              └───────┬───────┘
                      │
         ┌────────────┴────────────┐
         │                         │
         │       IR2110            │
         │                         │
   HIN ──┤(9)                 (2)  ├── HO ──┬─── Rg ──── Gate (High-Side MOSFET)
         │                         │        │
         │                         │        └─── Rgd ──┐
   LIN ──┤(6)                (12)  ├── LO ──┬─── Rg ────┤
         │                         │        │           │
   +5V ──┤(13) Vdd       Vcc (14)  ├── +12V └─── Rgd ──┘
         │                         │
   GND ──┤(11) COM       GND       ├── GND
         │                         │
   +5V ──┤(10) SD        VS  (3)   ├── Source (High-Side MOSFET)
         │                         │
         └─────────────────────────┘
```

### Input Logic

The IR2110 requires **positive logic** inputs:

**From STM32 (via level shifter if using 3.3V):**
- HIN = HIGH → High-side MOSFET ON
- LIN = HIGH → Low-side MOSFET ON

**Important:** STM32 dead-time insertion ensures HIN and LIN are never HIGH simultaneously.

**Level Shifting (if needed):**

If using 3.3V STM32 outputs with 5V IR2110 logic:

```
STM32 (3.3V) ──┬─── 1kΩ ──┬─── HIN/LIN (IR2110)
               │          │
               └─ 2.2kΩ ──┴─── +5V
```

Or use dedicated level shifter IC like **SN74AHCT125** (3.3V → 5V).

---

## Bootstrap Circuit Design

### Bootstrap Principle

The IR2110 uses a **bootstrap circuit** to power the high-side driver without an isolated supply.

**How it works:**

1. When low-side MOSFET is ON, VS node is pulled to ground
2. Bootstrap capacitor (Cboot) charges through bootstrap diode (Dboot) from Vcc
3. When high-side MOSFET turns ON, VS rises to +Vdc
4. Capacitor voltage floats with VS, providing (VS + 12V) to VB pin
5. This maintains 12V across high-side MOSFET gate-source

**Circuit:**

```
         +12V (Vcc)
           │
           ├─────┐
          [│]    │ Dboot (fast recovery diode)
          Rboot  │
           │     ↓
           └─────┴──── VB (Bootstrap Supply)
                 │
                [│] Cboot (Bootstrap Capacitor)
                 │
                 └──── VS (High-Side Source)
```

### Bootstrap Component Selection

**Bootstrap Diode (Dboot):**

Requirements:
- Reverse voltage > Vdc + Vcc = 50V + 12V = 62V → Use **100V rated**
- Forward current > 100 mA
- Fast recovery (trr < 50 ns for 5 kHz operation)

**Recommended:**
- **UF4007** (1A, 1000V, fast recovery) - Overkill but cheap and robust
- **1N4148** (200 mA, 100V, fast switching) - Minimum acceptable
- **MBRS340** (3A, 40V, Schottky) - Fast but voltage too low for this application

**Choice:** **UF4007** for reliability.

**Bootstrap Resistor (Rboot):**

Optional current-limiting resistor (often omitted):
- Purpose: Limit inrush current to Cboot
- Value: 10-100Ω
- Power: 1/4W sufficient

**We omit Rboot** for faster charging and simpler design.

**Bootstrap Capacitor (Cboot):**

Critical design parameter. Must supply charge to gate during entire ON period.

**Calculation:**

```
Cboot = (Qg + Iq × ton_max) / ΔVboot
```

Where:
- Qg = Gate charge of high-side MOSFET
- Iq = Quiescent current of IR2110 high-side (~230 μA)
- ton_max = Maximum continuous ON time
- ΔVboot = Acceptable bootstrap voltage droop (typically 1V)

**For IRF540N:**

```
Qg = 72 nC
ton_max = 100 μs (at 5 kHz, 50% duty cycle max)
Iq = 230 μA

Cboot = (72 nC + 230 μA × 100 μs) / 1V
      = (72 nC + 23 nC) / 1V
      = 95 nC / 1V
      = 0.095 μF
```

**Standard value:** 0.1 μF minimum.

**Recommended:** **1 μF** for safety margin (10× calculated value).

**Capacitor type:**
- **Ceramic (X7R or C0G):** Low ESR, high frequency performance
- Voltage rating: ≥ 25V (2× Vcc for safety)
- Package: 0805 SMD or through-hole

**Choice:** **1 μF / 25V / X7R ceramic capacitor**

### Bootstrap Circuit Limitations

**Important:** Bootstrap operation requires periodic low-side conduction to recharge Cboot.

**Minimum duty cycle requirement:**
- Low-side MOSFET must conduct long enough to recharge Cboot
- Minimum ON time ≈ 5 × Rds(on) × Cboot (rule of thumb)
- For our circuit: ~1 μs (well within our 1 μs dead-time)

**For continuous high-side operation (>95% duty cycle):**
- Bootstrap may fail to recharge
- Solution: Isolated gate driver supply or charge pump circuit
- **Our application:** Inverter duty cycle varies 0-100%, no issue

---

## Gate Resistor Selection

### Purpose of Gate Resistors

Gate resistors control:
1. **Switching speed** (di/dt and dv/dt)
2. **EMI and ringing**
3. **Gate driver power dissipation**
4. **Oscillations and false triggering**

### Turn-On Resistor (Rg_on)

**Lower resistance → Faster switching → Lower switching losses BUT higher EMI**

**Calculation:**

```
Rg_on = (Vdrv - Vgs_th) / I_gate_peak
```

For moderate speed (100 ns rise time):

```
I_gate = Qg / t_rise = 72 nC / 100 ns = 0.72 A

Rg_on = (12V - 4V) / 0.72A = 11Ω
```

**Standard value:** **10Ω** (allows slightly faster switching)

**Power rating:**

```
P_rg = Qg × Vdrv × f_sw
P_rg = 72 nC × 12V × 5 kHz = 4.3 mW
```

**Use:** 1/4W resistor (plenty of margin)

### Turn-Off Resistor (Rg_off)

Typically **same as or lower than** Rg_on for fast turn-off:

**Reason:** Faster turn-off reduces current tail and switching losses.

**Choice:** **10Ω** (same as Rg_on)

### Gate-Drain Resistor (Rgd) - Optional

**Purpose:** Reduce Miller effect and dv/dt-induced turn-on.

**Value:** 1-10kΩ (high resistance, low power)

**We omit Rgd** for simplicity (not critical at 5 kHz).

### Final Gate Resistor Selection

| Resistor | Value | Power | Quantity per Bridge |
|----------|-------|-------|---------------------|
| Rg (turn-on/off) | 10Ω | 1/4W | 4 (one per MOSFET) |

**Total for 2 bridges:** 8× 10Ω 1/4W resistors

---

## PCB Layout Considerations

### Critical Layout Rules

**1. Minimize Gate Loop Inductance:**
- Keep gate driver IC close to MOSFET gates (< 5 cm)
- Wide, short traces from driver output to gate
- Ground plane for low impedance return path

**2. Bootstrap Circuit:**
- Place Cboot and Dboot very close to VB and VS pins
- Minimize trace length to reduce ESL
- Use ceramic capacitor for low ESR

**3. Decoupling:**
- Place 100 nF ceramic capacitor between Vcc and GND (close to IC)
- Place 100 nF ceramic capacitor between Vdd and COM (close to IC)
- Add bulk capacitance (10-100 μF electrolytic) on 12V rail

**4. Power and Signal Separation:**
- Separate high-current power traces from low-current signal traces
- Use ground plane to shield sensitive signals
- Route PWM inputs away from switching nodes

**5. Thermal Management:**
- Provide adequate copper area for heat dissipation
- Consider heatsinks for MOSFETs at high power
- Use thermal vias under power components

### Layout Example (One H-Bridge Leg)

```
        STM32
          │
      ┌───┴────┐
      │ PWM1   │   Level     ┌──────────┐
      │        ├──── Shift ──┤ IR2110   │
      │ PWM1N  │             │  HIN/LIN │
      └────────┘             └─────┬────┘
                                   │
                    ┌──────────────┼──────────────┐
                    │              │              │
                    │         ┌────┴────┐    ┌────┴────┐
                +50V ─────────┤  High-  │    │  Low-   │
                    │         │  Side   │    │  Side   │
                    │         │ MOSFET  │    │ MOSFET  │
                    │         └────┬────┘    └────┬────┘
                    │              │              │
                    └──────────────┴──────────────┘
                                   │
                                 Output
```

### Layer Stackup (4-layer PCB recommended)

```
Layer 1: Top - Signal and small components
Layer 2: Ground plane
Layer 3: Power plane (+12V, +5V, +50V areas)
Layer 4: Bottom - High-current traces and power components
```

---

## Testing and Validation

### Pre-Power Testing

**1. Visual Inspection:**
- Check all solder joints
- Verify correct component placement
- Check for solder bridges

**2. Continuity Testing:**
- Verify ground connections
- Check power rail continuity
- Confirm no shorts between power rails

**3. Power Supply Test:**
- Apply +12V to Vcc (no load) and measure current (should be < 10 mA per IC)
- Apply +5V to Vdd and measure current (should be < 5 mA per IC)
- Check bootstrap capacitor voltage (should charge to ~12V when low-side ON)

### Functional Testing (No Power MOSFETs)

**1. Dead Gate Test:**
- Remove MOSFETs or disconnect gates
- Apply PWM signals from function generator
- Verify outputs with oscilloscope:
  - HO and LO should never be HIGH simultaneously
  - Dead-time should be visible (at least 1 μs)
  - Rise/fall times should be < 200 ns

**2. Bootstrap Charging:**
- Monitor VB pin voltage with scope
- Apply low-side PWM
- Verify VB rises to Vcc when low-side is ON
- Verify VB maintains voltage during high-side ON

### Power Testing (With MOSFETs, Low Voltage)

**1. Reduced Voltage Test:**
- Start with 12V DC bus (instead of 50V)
- Connect resistive load (5-10Ω, 25W)
- Apply 50% duty cycle PWM at 1 kHz
- Verify:
  - MOSFETs switch properly
  - No shoot-through (monitor bus current for spikes)
  - Thermal performance acceptable

**2. Waveform Analysis:**
- Use oscilloscope with isolated probes
- Measure gate-source voltage (should swing 0-12V cleanly)
- Measure drain-source voltage (should be clean switching)
- Check for ringing (add snubbers if excessive)

**3. Gradual Power Increase:**
- Increase DC bus voltage in 10V steps up to 50V
- Monitor temperatures continuously
- Check for abnormal behavior at each step

---

## Bill of Materials

### BOM for One H-Bridge (4 Gate Drivers)

| Qty | Part Number | Description | Specs | Price (approx) |
|-----|-------------|-------------|-------|----------------|
| 2 | IR2110 | High-Low Side Gate Driver | 600V, 2A output | $2.00 each |
| 2 | UF4007 | Fast Recovery Diode | 1A, 1000V | $0.10 each |
| 2 | Ceramic Cap | Bootstrap Capacitor | 1μF, 25V, X7R | $0.15 each |
| 4 | Ceramic Cap | Decoupling Vcc | 100nF, 25V, X7R | $0.05 each |
| 2 | Ceramic Cap | Decoupling Vdd | 100nF, 16V, X7R | $0.05 each |
| 2 | Electrolytic Cap | Bulk Vcc | 100μF, 25V | $0.20 each |
| 4 | Resistor | Gate Resistor | 10Ω, 1/4W | $0.02 each |
| | | | **Subtotal per bridge** | **~$6** |

### BOM for Complete 5-Level Inverter (2 H-Bridges = 8 Drivers)

| Qty | Part Number | Description | Specs | Price (approx) |
|-----|-------------|-------------|-------|----------------|
| 4 | IR2110 | High-Low Side Gate Driver | 600V, 2A output | $8.00 |
| 4 | UF4007 | Fast Recovery Diode | 1A, 1000V | $0.40 |
| 4 | Ceramic Cap | Bootstrap Capacitor | 1μF, 25V, X7R | $0.60 |
| 8 | Ceramic Cap | Decoupling Vcc | 100nF, 25V, X7R | $0.40 |
| 4 | Ceramic Cap | Decoupling Vdd | 100nF, 16V, X7R | $0.20 |
| 4 | Electrolytic Cap | Bulk Vcc | 100μF, 25V | $0.80 |
| 8 | Resistor | Gate Resistor | 10Ω, 1/4W | $0.16 |
| | | | **Total** | **~$11** |

**Note:** Prices are approximate (2024 USD) and vary by supplier and quantity.

---

## Appendix: Alternative Gate Drivers

### When to Use Isolated Gate Drivers

For applications requiring full isolation between control and power sides:

**Recommended ICs:**
- **Si8271** (Silicon Labs): Isolated gate driver with integrated isolator
- **ACPL-332J** (Broadcom): Optocoupler gate driver, 2.5A output
- **ISO5451** (Texas Instruments): Isolated driver with 4A output

**Trade-offs:**
- ✅ True galvanic isolation
- ✅ No bootstrap limitations
- ❌ Higher cost ($5-15 per driver)
- ❌ More complex PCB layout
- ❌ Requires isolated power supplies for each driver

**Our choice:** IR2110 with bootstrap is sufficient for 50V bus voltage and simpler/cheaper.

---

## Appendix: IGBT Gate Drive Modifications

If using IGBTs instead of MOSFETs:

**Changes Required:**

1. **Gate Resistor:**
   - IGBTs require slower switching to avoid overcurrent
   - Increase Rg to 47-100Ω

2. **Negative Gate Voltage:**
   - IGBTs benefit from -5V to -15V gate turn-off voltage
   - Use gate driver with negative supply (e.g., **IXDN614**)
   - Or add negative bias circuit with Zener diode

3. **Desaturation Protection:**
   - IGBTs require Vce monitoring for overcurrent
   - Add external comparator or use driver with built-in desat (e.g., **2ED020I12-F2**)

**For this project using MOSFETs, these modifications are NOT needed.**

---

**Document Status:** Design complete, ready for PCB layout
**Next Steps:** PCB layout, prototype fabrication, testing

**Related Documents:**
- `02-Power-Supply-Design.md` - Isolated 50V supply design
- `03-Current-Voltage-Sensing.md` - Sensing circuit design
- `04-Protection-Circuits.md` - Overcurrent and fault protection
- `05-PCB-Layout-Guide.md` - Complete layout guidelines
