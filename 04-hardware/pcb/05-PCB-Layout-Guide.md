# PCB Layout Guide - 5-Level Inverter

**Document Type:** Hardware Design Guide
**Project:** 5-Level Cascaded H-Bridge Multilevel Inverter
**Author:** 5-Level Inverter Project
**Date:** 2025-11-15
**Version:** 1.0
**Status:** Design - Not Yet Validated

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
│  • Gate driver ICs (IR2110)                 │
│  • Sensors (ACS724, AMC1301)                │
│  • Comparators (LM339)                      │
│  • SMD resistors, capacitors                │
│  • Control signals from STM32               │
├─────────────────────────────────────────────┤
│  Layer 2 - GND Plane (solid)                │ 1 oz copper
│  • Main ground reference                    │
│  • Continuous pour except for thermal vias  │
│  • Low impedance return path                │
├─────────────────────────────────────────────┤
│  Layer 3 - Power Planes (split)             │ 1 oz copper
│  • +12V region (gate driver supply)         │
│  • +5V region (logic supply)                │
│  • +3.3V region (ADC reference)             │
│  • Separated by 1mm gap                     │
├─────────────────────────────────────────────┤
│  Layer 4 (Bottom) - Power & Thermal         │ 2 oz copper
│  • Power MOSFETs (large pads for heatsink)  │
│  • DC bus traces (10mm wide)                │
│  • Output traces (8mm wide)                 │
│  • Thermal vias under MOSFETs               │
│  • Large copper pours for heat spreading    │
└─────────────────────────────────────────────┘
```

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

### IR2110 Placement

**Location:** Top layer, directly above MOSFETs

**Critical Connections:**

1. **Bootstrap Circuit:**
   - VB, VS, Bootstrap diode, Bootstrap cap
   - Minimize trace length (< 10mm total loop)
   - Place bootstrap components within 5mm of IC

```
       VB (pin 1) ──┬─── Cboot (1μF) ───┬─── VS (pin 3)
                    │                    │
                    │   Dboot (UF4007)   │
                    └────────┬───────────┘
                             │
                           Vcc (12V)
```

2. **Gate Drive Output:**
   - HO, LO directly to MOSFET gates
   - 10Ω series gate resistor close to MOSFET (< 5mm)
   - Minimize trace inductance

```
   IR2110 HO (pin 2) ──→ 10Ω ──→ MOSFET Gate (S1)
                         (< 30mm total trace length)
```

3. **Power Supply Decoupling:**
   - 100 nF ceramic cap between Vcc and GND (< 5mm from IC)
   - 100 nF ceramic cap between Vdd and COM (< 5mm from IC)
   - 100 μF electrolytic on Vcc rail (nearby, within 20mm)

**Grounding:**
- COM pin connects to local ground plane via multiple vias
- Separate analog and digital grounds if possible

### Level Shifter Placement

**SN74AHCT125** (3.3V → 5V)

Place near STM32 Nucleo board connector:
- Minimize trace length from STM32 GPIO to level shifter
- Decoupling cap (100 nF) on both 3.3V and 5V rails

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

### Ground Strategy

**Single-Point Grounding:**

The board uses a **star ground** topology:

```
                Power GND ──────┬──────── Analog GND
                                │
                                │
                           Main Ground
                           (connection point near PSU input)
                                │
                                │
                       Digital GND (STM32, gate drivers)
```

**Ground Plane Splits:**
- Do NOT split ground plane (creates current loops)
- Instead, use solid ground pour on Layer 2
- Connect power GND, analog GND, digital GND at single point near PSU

**Ground Vias:**
- Use many vias (every 10mm) to connect top-layer GND to plane
- Reduces impedance and improves EMI

### Power Planes (Layer 3)

**Regions:**

```
┌────────────────────────────────────────┐
│                                        │
│  +12V Region (Gate Drivers)            │
│  ────────────────────────────          │
│                             │          │
│                          1mm gap       │
│                             │          │
│  +5V Region (Logic) ────────────────   │
│                             │          │
│                          1mm gap       │
│                             │          │
│  +3.3V Region (ADC, STM32) ──────────  │
│                                        │
└────────────────────────────────────────┘
```

**Capacitor Placement on Power Planes:**
- 100 μF electrolytic at PSU input (per rail)
- 10 μF ceramic at each IC power pin
- 100 nF ceramic at every IC (0.1" from pin)

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
- Mains (if applicable): Use 6mm clearance, 8mm creepage

**Implementation:**
- Keep copper pours away from high-voltage areas
- Use solder mask as additional insulation (but don't rely on it!)
- Add silkscreen "keep-out" markings

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

**Document Status:** Design guide complete, ready for PCB layout
**Next Steps:** Create PCB layout in KiCad, generate Gerber files, order prototype

**Related Documents:**
- `../schematics/*.md` - Circuit schematics for layout
- `../bom/Complete-BOM.md` - Component selection and footprints
- `../../07-docs/05-Hardware-Testing-Procedures.md` - Testing after assembly
