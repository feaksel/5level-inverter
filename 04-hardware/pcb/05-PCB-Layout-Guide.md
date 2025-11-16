# PCB Layout Guide - 5-Level Inverter

**Document Type:** Hardware Design Guide
**Project:** 5-Level Cascaded H-Bridge Multilevel Inverter
**Author:** 5-Level Inverter Project
**Date:** 2025-11-15
**Version:** 2.0
**Status:** Validated Design - TLP250 Configuration

---

## Table of Contents

1. [Overview](#overview)
2. [PCB Specifications](#pcb-specifications)
3. [Layer Stackup](#layer-stackup)
4. [Power Stage Layout](#power-stage-layout)
5. [Gate Driver Layout](#gate-driver-layout)
6. [Sensing Circuit Layout](#sensing-circuit-layout)
7. [Ground and Power Planes](#ground-and-power-planes)
8. [Thermal Management](#thermal-management)
9. [EMI Considerations](#emi-considerations)
10. [Assembly and Testing](#assembly-and-testing)

---

## Overview

### Purpose

This document provides comprehensive PCB layout guidelines for the 5-level cascaded H-bridge inverter. Proper PCB layout is **critical** for:
- Safe operation (creepage/clearance distances)
- Reliable switching (low inductance)
- Thermal performance (heat dissipation)
- EMI compliance (minimal radiation)
- Ease of assembly and testing

### Design Philosophy

**Priorities (in order):**
1. **Safety** - Adequate isolation and creepage
2. **Thermal** - Effective heat dissipation
3. **Electrical** - Low inductance, good grounding
4. **EMI** - Minimize radiation and coupling
5. **Manufacturability** - Easy assembly and testing
6. **Cost** - Reasonable layer count and size

---

## PCB Specifications

### Physical Dimensions

**Board Size:** 200 mm × 150 mm (7.87" × 5.91")
- Chosen to fit standard enclosure (Hammond 1590WV)
- Allows adequate spacing for power components
- Fits in common PCB fab panel sizes

**Board Thickness:** 1.6 mm (0.063") standard

### Electrical Specifications

**Layer Count:** 4 layers
- Layer 1 (Top): Signal, SMD components, gate drivers
- Layer 2: Ground plane (GND)
- Layer 3: Power planes (+12V, +5V, +3.3V split)
- Layer 4 (Bottom): Power traces, MOSFETs, heatsinks

**Copper Weight:**
- Layers 1, 2, 3: 1 oz (35 μm) - standard
- Layer 4: **2 oz (70 μm)** - for high-current traces

**Via Specifications:**
- Standard via: 0.4mm drill, 0.8mm pad (for signals)
- Power via: 0.6mm drill, 1.2mm pad (for high current)
- Thermal via: 0.3mm drill, 0.6mm pad (for heatsink connection)

### Surface Finish

**Recommended:** ENIG (Electroless Nickel Immersion Gold)
- Excellent solderability
- Long shelf life (> 1 year)
- Good for fine-pitch components (IR2110, sensors)
- Slightly more expensive than HASL

**Alternative:** HASL (Hot Air Solder Leveling)
- Cheaper
- Adequate for through-hole and larger SMD
- Not ideal for fine-pitch ICs

### Solder Mask and Silkscreen

**Solder Mask:** Standard green (or any color)
- Thickness: 0.01-0.02mm
- Clearance: 0.1mm from pads

**Silkscreen:** White on green background
- Minimum text size: 1.0mm height, 0.15mm width
- Include: Component designators, polarity marks, test points, voltage warnings

**Safety Markings:**
- "⚡ HIGH VOLTAGE" near power stage
- "+ 50V DC BUS" labels
- "GND" markings
- Fuse ratings

---

## Layer Stackup

### 4-Layer Stackup (Recommended)

```
┌─────────────────────────────────────────────┐
│  Layer 1 (Top) - Signal & SMD Components    │ 1 oz copper
│  • Gate driver optocouplers (TLP250)        │
│  • Isolated DC-DC converters (R-78E15-0.5)  │
│  • Sensors (ACS724, AMC1301)                │
│  • Comparators (LM339)                      │
│  • SMD resistors, capacitors                │
│  • Control signals from STM32               │
├─────────────────────────────────────────────┤
│  Layer 2 - GND Plane (solid with splits)    │ 1 oz copper
│  • Main ground reference (common)           │
│  • Isolated GND plane 1 (H-Bridge 1)        │
│  • Isolated GND plane 2 (H-Bridge 2)        │
│  • 5mm isolation barrier between regions    │
│  • Low impedance return path                │
├─────────────────────────────────────────────┤
│  Layer 3 - Power Planes (split)             │ 1 oz copper
│  • +12V region (DC-DC converter input)      │
│  • +15V Isolated 1 (H-Bridge 1 drivers)     │
│  • +15V Isolated 2 (H-Bridge 2 drivers)     │
│  • +5V region (logic supply)                │
│  • +3.3V region (ADC reference)             │
│  • Separated by 2mm gaps (5mm for isolated) │
├─────────────────────────────────────────────┤
│  Layer 4 (Bottom) - Power & Thermal         │ 2 oz copper
│  • Power MOSFETs (large pads for heatsink)  │
│  • DC bus traces (10mm wide)                │
│  • Output traces (8mm wide)                 │
│  • Thermal vias under MOSFETs               │
│  • Large copper pours for heat spreading    │
└─────────────────────────────────────────────┘
```

**Critical Design Note for TLP250:**

⚠️ **Isolation Barriers Required:** Unlike IR2110 bootstrap drivers, TLP250 optocouplers require true galvanic isolation between input (STM32 side) and output (MOSFET gate drive side). This means:
- Separate ground planes for each H-bridge module (Layer 2)
- Separate +15V power planes for each module (Layer 3)
- 5mm minimum isolation barrier between common ground and isolated grounds
- 5mm minimum isolation barrier between +15V regions
- Optocoupler bridges the isolation barrier (2.5kV isolation rating)

**Dielectric Material:** FR-4, Tg > 170°C (high-temperature rated)

**Impedance Control:** Not critical for this design (low frequency, < 100 kHz)

---

## Power Stage Layout

### MOSFET Placement

**Topology:** 2 H-bridges, each with 4 MOSFETs

**H-Bridge 1 Layout:**
```
   DC Bus (+50V) ──────┬────────────┬────────
                       │            │
                    ┌──┴──┐      ┌──┴──┐
                    │ S1  │      │ S3  │   High-side MOSFETs
                    │(Q1) │      │(Q3) │
                    └──┬──┘      └──┬──┘
                       │    Out1    │
                       ├────────────┤────────→ Output (to H-Bridge 2)
                       │            │
                    ┌──┴──┐      ┌──┴──┐
                    │ S2  │      │ S4  │   Low-side MOSFETs
                    │(Q2) │      │(Q4) │
                    └──┬──┘      └──┬──┘
                       │            │
                       └────────────┴──────── GND
```

**Layout Rules:**

1. **Minimize Source Inductance:**
   - Keep source connection traces short (< 10mm)
   - Wide traces (10mm for 10A current)
   - Multiple vias to ground plane

2. **Gate Loop Minimization:**
   - Place gate driver IC within 20mm of MOSFET gates
   - Short, direct gate traces (< 30mm)
   - Gate return path through ground plane

3. **Thermal Isolation:**
   - Space MOSFETs 15mm apart (for heatsink clearance)
   - Use thermal vias under MOSFET tabs (connect to copper pour)
   - Large copper area (50×50mm per MOSFET) on bottom layer

4. **High-Current Traces:**
   - DC bus: 10mm width (2 oz copper → 10A capacity)
   - Output: 8mm width
   - Use thermal relief for vias (not direct connection)

### DC Bus Capacitor Placement

**Bulk Capacitors:** 1000 μF × 4 (one per H-bridge leg)

**Placement:**
- As close as possible to MOSFET source-drain connections
- Minimize inductance between cap and switching node
- Use short, wide traces (5mm width)

**Layout:**
```
        DC+ ──┬─── Cap1+ ───┬─── MOSFET Drain (high-side)
              │             │
              │    [1000μF] │
              │             │
        DC- ──┴─── Cap1- ───┴─── MOSFET Source (low-side)
```

**Critical:** Keep this loop area < 500 mm² to minimize switching noise.

---

## Gate Driver Layout

### TLP250 Placement and Isolation Design

**Location:** Top layer, with strict isolation barrier layout

**Critical Design Principle:** TLP250 optocouplers provide galvanic isolation between input (STM32 side) and output (MOSFET drive side). PCB layout must maintain this isolation.

### Isolation Barrier Architecture

```
┌─────────────────────────────┬─────────────────────────────┐
│   COMMON SIDE (STM32)       │  ISOLATED SIDE (H-Bridge)   │
│   (No restrictions)         │  (Maintain isolation!)      │
│                             │                             │
│  STM32 GPIO                 │               MOSFET Gate   │
│     │                       │                     │       │
│     └──→ 150Ω ──→ TLP250 LED │ Photodetector ──→ 10Ω ──┘  │
│                  (Pin 1,2) │ (Pin 7,6)                   │
│                             │                             │
│  Common GND                 │  Isolated GND               │
│  (Plane region 1)           │  (Plane region 2)           │
│                             │                             │
│  +3.3V Rail (STM32)         │  +15V Isolated Rail         │
│                             │  (from DC-DC converter)     │
│                             │                             │
└─────────────────────────────┴─────────────────────────────┘
         ← 5mm Isolation Barrier →
```

**Isolation Barrier Rules:**
1. **5mm minimum clearance** between common and isolated copper
2. **No copper pours crossing** the isolation barrier (except through TLP250)
3. **Solder mask dam** across isolation barrier (for creepage)
4. **Silkscreen marking** showing isolation barrier

### TLP250 Component Placement

**One TLP250 per MOSFET** (8× total):
- Place TLP250 straddling the isolation barrier
- Input side (LED, pins 1-2) on common ground side
- Output side (detector, pins 6-7) on isolated ground side
- Orient all TLP250s in same direction for clarity

**Layout for one H-Bridge Module (4× TLP250):**

```
Common Side          │        Isolated Side (H-Bridge 1)
                     │
STM32 PWM1 ──150Ω──→ TLP250_1 ──10Ω──→ S1 Gate (High-side 1)
                     │
STM32 PWM2 ──150Ω──→ TLP250_2 ──10Ω──→ S2 Gate (Low-side 1)
                     │
STM32 PWM3 ──150Ω──→ TLP250_3 ──10Ω──→ S3 Gate (High-side 2)
                     │
STM32 PWM4 ──150Ω──→ TLP250_4 ──10Ω──→ S4 Gate (Low-side 2)
                     │
Common GND           │        Isolated GND 1
                     │
                     5mm isolation barrier
```

### Component Placement Details

**1. Input Side (STM32/Common):**
- **150Ω resistor** within 5mm of TLP250 LED input (pin 1, anode)
- Connect resistor to STM32 GPIO trace
- Pin 2 (cathode) connects to common GND via short trace (< 10mm)
- Decoupling cap (100 nF) on +3.3V rail near TLP250 area

**2. Output Side (MOSFET/Isolated):**
- **10Ω gate resistor** within 5mm of MOSFET gate
- TLP250 output (pins 6&7 tied together) connects to 10Ω resistor
- Keep trace from TLP250 to gate resistor short (< 20mm)
- Pin 8 (Vcc) connects to +15V isolated plane via multiple vias
- Pin 5 (GND) connects to isolated GND plane via multiple vias

**3. Power Supply Decoupling (Per Module):**
- **100 nF ceramic** between +15V isolated and isolated GND (< 5mm from TLP250 Vcc pin)
- **100 μF electrolytic** on +15V isolated rail (one per 4× TLP250 group, within 30mm)

**Power Distribution Layout:**
```
DC-DC Converter (R-78E15-0.5)
       │
   +15V Iso 1 ────┬──→ TLP250_1 (Pin 8)
   (Isolated)     ├──→ TLP250_2 (Pin 8)
                  ├──→ TLP250_3 (Pin 8)
                  └──→ TLP250_4 (Pin 8)
                       │
                  100μF Bulk Cap (one per module)
                       │
                  4× 100nF decoupling (one per TLP250)
```

### Grounding Strategy for TLP250

**Three Separate Ground Regions:**

1. **Common GND** (STM32, sensors, control logic)
   - Solid plane on Layer 2
   - All TLP250 input sides (pin 2) connect here

2. **Isolated GND 1** (H-Bridge 1)
   - Isolated plane region on Layer 2
   - 4× TLP250 output sides (pin 5) connect here
   - DC-DC converter #1 output ground
   - MOSFETs S1-S4 source connections

3. **Isolated GND 2** (H-Bridge 2)
   - Separate isolated plane region on Layer 2
   - 4× TLP250 output sides (pin 5) connect here
   - DC-DC converter #2 output ground
   - MOSFETs S5-S8 source connections

**CRITICAL:** Isolated GND 1 and Isolated GND 2 must **NEVER** connect to each other or to Common GND on the PCB. Only connection is through the H-bridge MOSFET switching nodes.

### Trace Routing Across Isolation Barrier

**ONLY these signals cross the isolation barrier:**
- 8× TLP250 optocoupler packages (internal optical coupling)
- **NO copper traces** may cross the barrier

**How to Route Signals:**
```
STM32 GPIO ───── (Common side traces) ───── TLP250 input
                                              │
                                     (Optical coupling)
                                              │
                    TLP250 output ───── (Isolated side traces) ───── MOSFET gate
```

### Isolation Barrier Silkscreen Markings

Add clear markings on silkscreen:
```
Common Side:           │  Isolated Side:
"COMMON GND"           │  "ISOLATED GND 1"
"3.3V / 5V Logic"      │  "+15V Isolated"
                       │
     ═══════════ ISOLATION BARRIER ═══════════
                       │
                  (5mm clearance)
```

---

## Sensing Circuit Layout

### Current Sensor (ACS724)

**Placement:** Near output terminal

**Primary Conductor:**
- Route high-current output trace through ACS724 sensor
- Use wide trace (8mm) for low resistance
- Minimize additional inductance

**Output Signal:**
- Shield analog output trace (0-3.3V) from switching noise
- Route on top layer with guard ring (GND pour around trace)
- Add 100 nF cap close to sensor output

### Voltage Sensor (AMC1301)

**Placement:** Near high-voltage sensing point

**Input Side (high voltage):**
- Resistive divider (590kΩ + 10kΩ) on top layer
- Adequate creepage distance (8mm for 150V)
- TVS diode for overvoltage protection

**Output Side (isolated):**
- Digital interface to STM32 (SPI or UART)
- Keep traces short, no special shielding needed

### ADC Input Traces

**Routing:**
- Keep ADC input traces short (< 50mm)
- Route on top layer, away from power traces
- Add guard traces (GND) on both sides of sensitive traces

**Filtering:**
- Place anti-aliasing filter components (10kΩ + 5.6nF) close to ADC input
- BAT54S Schottky clamp diodes directly at ADC pin

**Layout:**
```
Sensor Output ──→ 10kΩ ──┬──→ STM32 ADC Pin
                         │
                   5.6nF ─┴─→ GND
                         │
                    BAT54S (to +3.3V and GND)
```

---

## Ground and Power Planes

### Ground Strategy for TLP250 Isolation

**Multiple Isolated Ground Regions:**

The board uses **separate isolated ground regions** for TLP250 configuration:

```
┌──────────────────────────────────────────────────┐
│                  Layer 2 (GND Plane)             │
│                                                  │
│  ┌─────────────┐   5mm   ┌────────┐  5mm ┌────┐│
│  │   Common    │ barrier │ Iso 1  │ gap  │Iso2││
│  │     GND     │═════════│  GND   │══════│GND ││
│  │             │         │        │      │    ││
│  │ • STM32     │         │• TLP250│      │•TLP││
│  │ • Sensors   │         │  out   │      │ out││
│  │ • TLP250 in │         │• DC-DC │      │•DC ││
│  │ • Logic     │         │  #1    │      │-DC ││
│  │             │         │• S1-S4 │      │ #2 ││
│  └─────────────┘         └────────┘      └────┘│
│                                                  │
└──────────────────────────────────────────────────┘
```

**Critical Isolation Rules:**
1. **5mm minimum gap** between Common GND and Isolated GND regions
2. **5mm minimum gap** between Isolated GND 1 and Isolated GND 2
3. **No copper fill** in isolation barriers
4. **Silkscreen warning** across isolation barriers
5. All TLP250 input sides connect to Common GND only
6. All TLP250 output sides connect to respective Isolated GND only

**Ground Vias:**
- Use many vias (every 10mm) within each ground region
- **NO vias crossing** isolation barriers
- Thermal vias under MOSFETs connect to respective Isolated GND

### Power Planes (Layer 3) with Isolated Regions

**Layout with Isolation:**

```
┌─────────────────────────────────────────────────┐
│                Layer 3 (Power Planes)           │
│                                                 │
│  ┌──────────┐   ┌────────────┐   ┌──────────┐ │
│  │  Common  │   │  Isolated  │   │ Isolated │ │
│  │  Power   │   │  Power #1  │   │ Power #2 │ │
│  │          │   │            │   │          │ │
│  │ • +12V   │   │ • +15V Iso1│   │• +15V Iso│ │
│  │ • +5V    │   │   (from    │   │    (from │ │
│  │ • +3.3V  │   │   DC-DC #1)│   │   DC-DC2)│ │
│  │          │   │ • TLP250   │   │ • TLP250 │ │
│  │          │   │   output   │   │   output │ │
│  │          │   │   side     │   │   side   │ │
│  └──────────┘   └────────────┘   └──────────┘ │
│       ↑               ↑                 ↑      │
│    2mm gap       5mm barrier      5mm barrier  │
│                                                 │
└─────────────────────────────────────────────────┘
```

**Power Region Details:**

1. **Common Power Region:**
   - +12V plane (for DC-DC converter inputs)
   - +5V plane (for STM32, sensors, logic)
   - +3.3V plane (for STM32 core, ADC reference)
   - Separated by 2mm gaps within region

2. **Isolated Power Region 1:**
   - +15V plane for H-Bridge 1 TLP250 drivers (4× TLP250)
   - Connected to DC-DC converter #1 output
   - 5mm barrier from Common and Isolated Region 2

3. **Isolated Power Region 2:**
   - +15V plane for H-Bridge 2 TLP250 drivers (4× TLP250)
   - Connected to DC-DC converter #2 output
   - 5mm barrier from Common and Isolated Region 1

**Capacitor Placement on Power Planes:**
- **Common side:**
  - 100 μF electrolytic at PSU input (per rail: +12V, +5V)
  - 100 nF ceramic at each IC (STM32, sensors, logic)
  - 100 nF at TLP250 input side (between +3.3V and Common GND)

- **Isolated side (per module):**
  - 100 μF electrolytic on +15V isolated rail (one per module)
  - 100 nF ceramic at each TLP250 output side Vcc pin (between +15V Iso and Iso GND)
  - Place caps on isolated side of barrier only

### DC-DC Converter Placement

**RECOM R-78E15-0.5 Placement:**

```
                Isolation Barrier
                       │
   +12V (Common) ──→ [DC-DC] ──→ +15V Isolated 1
   GND (Common)  ──→   │    ──→ GND Isolated 1
                       │
         SIP-4 package straddles barrier
```

- Place DC-DC converter straddling the isolation barrier
- Input pins (+12V, GND) on Common side
- Output pins (+15V, GND) on Isolated side
- Follow datasheet for minimum creepage (typically 4-5mm)

---

## Thermal Management

### Heatsink Attachment

**MOSFETs are mounted on bottom layer:**

```
         PCB Top
            │
    ────────┼──────────  Layer 1 (signal)
            │
    ════════╪══════════  Layer 2 (GND plane)
            │
    ════════╪══════════  Layer 3 (power planes)
            │
    ────────┼──────────  Layer 4 (power + thermal)
            │            - Large copper pad under MOSFET
            │            - Thermal vias to Layer 2 GND plane
            ↓
      [MOSFET TO-220]
            │
      [Thermal Pad]
            │
      [Heatsink]
```

**Thermal Via Array:**

Place thermal vias under MOSFET mounting pad:
- Via size: 0.3mm drill, 0.6mm pad
- Via count: 16-25 vias per MOSFET
- Pattern: 4×4 or 5×5 grid
- Spacing: 2mm between vias

**Copper Pour:**
- Maximum copper area on Layer 4 under MOSFETs
- At least 50×50mm per MOSFET
- Connected to GND plane via thermal vias
- Allows heat spreading across PCB

**Heatsink Mounting:**
- Heatsink attached to bottom of PCB
- Thermal interface material (Arctic MX-4) between MOSFET and heatsink
- M3 screw through heatsink → MOSFET → PCB → standoff

---

## EMI Considerations

### Switching Noise Reduction

**1. Minimize Loop Areas:**

High di/dt loops create EMI. Minimize area of:
- DC bus capacitor → MOSFET loop
- Gate drive loop
- Output current loop

**2. Snubber Circuits (Optional):**

For reduced ringing, add RC snubber across MOSFET drain-source:
- R = 10-100Ω (wirewound)
- C = 100-1000 pF (film capacitor)

```
MOSFET Drain ──┬─── 47Ω ─── 220pF ───┬─── MOSFET Source
               │                      │
               └──────────────────────┘
```

Place snubber components within 10mm of MOSFET.

**3. Common-Mode Choke:**

Add common-mode choke on AC output (off-board):
- Reduces common-mode EMI
- Two windings on ferrite core
- Inductance: 1-10 mH

### Trace Routing

**Switching Node Traces:**
- Keep short (< 50mm)
- Route on inner layers if possible (shielded by ground planes)
- Avoid running parallel to sensitive analog traces
- Maintain 5mm separation from analog signals

**Signal Integrity:**
- No right-angle corners (use 45° or curves)
- Avoid long stubs
- Match trace impedance for high-speed signals (not critical here)

---

## Assembly and Testing

### Assembly Sequence

**Recommended Order:**

1. **SMD components on top layer:**
   - Start with smallest (0603 resistors/caps)
   - Then ICs (IR2110, ACS724, AMC1301, LM339)
   - Use solder paste stencil + reflow oven or hot air

2. **Through-hole components:**
   - Resistors, capacitors (if any)
   - Electrolytic capacitors (observe polarity!)
   - Screw terminals, headers

3. **Power MOSFETs (bottom layer):**
   - Apply thermal paste to MOSFET tabs
   - Insert MOSFETs through PCB holes
   - Solder from top side
   - Attach heatsinks with M3 screws

4. **Inspection:**
   - Visual check for solder bridges
   - Continuity test for shorts
   - Resistance check on power rails

### Test Points

**Include test points for:**
- +50V DC bus (both H-bridges)
- +12V (gate driver supply)
- +5V (logic supply)
- +3.3V (ADC reference)
- GND (multiple locations)
- PWM signals (HIN, LIN for each bridge)
- Output current sensor (analog voltage)
- Output voltage sense (divided voltage)
- Fault signals (OCP, OVP, thermal)

**Test point style:**
- Through-hole (1mm dia) for oscilloscope probe
- Label clearly on silkscreen
- Place on board edge for easy access

---

## Design for Manufacturing (DFM)

### PCB Design Rules

**Minimum Trace Width:**
- Signal: 0.2mm (8 mil)
- Power (1 oz): 1.0mm (40 mil) for 3A
- Power (2 oz): 2.0mm (80 mil) for 10A

**Minimum Spacing:**
- Trace-to-trace: 0.2mm (8 mil)
- High voltage (> 50V): 1.5mm (60 mil)
- Very high voltage (> 100V): 3.0mm (120 mil)

**Trace Width Calculator:**

For 10A current on 2 oz copper with 10°C temperature rise:
```
Width = 2.5mm (100 mil)
```

But we use 10mm (400 mil) for extra margin and lower resistance.

### Creepage and Clearance

**Definitions:**
- **Clearance:** Shortest distance through air between conductors
- **Creepage:** Shortest distance along surface of insulating material

**Requirements (per IEC 60950-1):**

| Voltage | Clearance | Creepage |
|---------|-----------|----------|
| < 50V | 0.5mm | 1.0mm |
| 50-150V | 1.5mm | 2.5mm |
| 150-300V | 3.0mm | 6.0mm |
| > 300V | 6.0mm | 10.0mm |

**Our Design:**
- 50V DC bus: Use 2mm clearance, 3mm creepage (safety margin)
- 100V AC output: Use 3mm clearance, 5mm creepage
- **TLP250 isolation barriers:** Use 5mm clearance, 5mm creepage (2.5kV isolation)
- **DC-DC converter isolation:** Use 5mm clearance, 5mm creepage (1kV isolation)
- Mains (if applicable): Use 6mm clearance, 8mm creepage

**Implementation:**
- Keep copper pours away from high-voltage areas
- **Maintain 5mm isolation barrier** between Common and Isolated ground/power regions
- Use solder mask as additional insulation (but don't rely on it!)
- Add silkscreen "keep-out" markings and isolation barrier warnings
- TLP250 and DC-DC converters straddle isolation barriers

**TLP250-Specific Isolation Requirements:**
- **Input to output:** 2.5kV isolation (TLP250 internal)
- **PCB creepage:** 5mm minimum between input-side copper and output-side copper
- **Clearance:** 5mm minimum through air
- **Solder mask dam:** Required across isolation barrier (0.1mm minimum thickness)

---

## Appendix A: PCB Checklist

### Pre-Fabrication Checklist

- [ ] All component footprints verified against datasheets
- [ ] Polarity markings for electrolytic caps, diodes, MOSFETs
- [ ] Power trace widths adequate for current (use calculator)
- [ ] Thermal vias under MOSFETs (16-25 per device)
- [ ] Decoupling caps within 5mm of IC power pins
- [ ] Ground vias every 10mm on signal traces
- [ ] Creepage/clearance distances checked (IEC 60950-1)
- [ ] Test points included for all critical signals
- [ ] Mounting holes placed (4× M3, 10mm from board edge)
- [ ] Silkscreen labels clear and readable (> 1mm text)
- [ ] High-voltage warning labels added
- [ ] DRC (Design Rule Check) passed with 0 errors
- [ ] Gerber files generated and reviewed

### Pre-Assembly Checklist

- [ ] PCBs inspected for defects (scratches, exposed copper)
- [ ] Solder paste stencil aligns correctly with PCB
- [ ] All components received and checked against BOM
- [ ] Component polarity marked (diodes, caps, MOSFETs)
- [ ] ESD-sensitive components handled properly
- [ ] Reflow oven profile configured for lead-free solder
- [ ] Thermal paste and heatsinks ready for MOSFET assembly

### Post-Assembly Checklist

- [ ] Visual inspection for solder bridges (use magnifier)
- [ ] Continuity test: All GND points connected (< 1Ω)
- [ ] Resistance test: Power rails not shorted to GND (> 100kΩ)
- [ ] Polarity check: Electrolytic caps, diodes oriented correctly
- [ ] Component orientation: ICs in correct direction (pin 1 marked)
- [ ] Solder joint quality: All pins soldered, no cold joints
- [ ] Flux residue cleaned (if using no-clean flux, optional)

---

## Appendix B: PCB Layer Drawings

**Note:** Actual Gerber files and KiCad/Altium design files to be created separately.

**Recommended Tools:**
- **KiCad** (open-source, free, powerful)
- **Altium Designer** (professional, $$$)
- **Eagle** (Autodesk, hobby license available)
- **EasyEDA** (web-based, integrated with JLCPCB)

---

**Document Version:** 2.0
**Last Updated:** 2025-11-15
**Document Status:** Design guide complete for TLP250 configuration, ready for PCB layout

**Major Changes in v2.0:**
- Replaced IR2110 bootstrap driver layout with TLP250 optocoupler isolation design
- Added comprehensive isolation barrier guidelines (5mm clearance/creepage)
- Updated ground plane strategy to include 3 isolated regions (Common, Iso1, Iso2)
- Updated power plane layout for +15V isolated supplies (2 regions)
- Added DC-DC converter placement guidelines (RECOM R-78E15-0.5)
- Removed bootstrap circuit layout section (no longer applicable)
- Removed level shifter placement section (no longer needed with TLP250)
- Updated layer stackup to show isolated ground/power regions
- Added TLP250-specific component placement and routing rules
- Updated creepage/clearance requirements for optocoupler isolation

**Critical Design Differences from IR2110:**
- **Isolation barriers:** TLP250 requires true isolation vs. IR2110 bootstrap
- **Ground planes:** Split into 3 regions vs. single unified ground
- **Power planes:** 2× isolated +15V regions vs. single +12V region
- **Component count:** 8× TLP250 + 2× DC-DC vs. 4× IR2110
- **PCB complexity:** Higher due to isolation requirements

**Next Steps:** Create PCB layout in KiCad following isolation guidelines, generate Gerber files, order prototype

**Related Documents:**
- `../schematics/01-Gate-Driver-Design.md` - TLP250 gate driver circuit design
- `../schematics/02-Power-Supply-Design.md` - Power supply with isolated DC-DC converters
- `../bom/Complete-BOM.md` - Component selection and footprints
- `../../07-docs/ELE401_Fall2025_IR_Group1.pdf` - Graduation project report with validation
- `../../07-docs/05-Hardware-Testing-Procedures.md` - Testing after assembly
