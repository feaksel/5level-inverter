# Complete Power Stage Design Guide

**Project:** 5-Level Cascaded H-Bridge Inverter
**Power Rating:** 707W (~700W), 70.7V RMS / 100V Peak AC Output
**Date:** 2025-12-03
**Status:** Updated with Latest Design Specifications (MOSFETs, TLP250, Sigma-Delta ADC)

---

## Table of Contents

1. [Overview](#overview)
2. [System Architecture](#system-architecture)
3. [Detailed Schematic - H-Bridge Stage](#detailed-schematic---h-bridge-stage)
4. [Detailed Schematic - Gate Drivers](#detailed-schematic---gate-drivers)
5. [Detailed Schematic - Sensing Stage](#detailed-schematic---sensing-stage)
6. [Detailed Schematic - Power Supply](#detailed-schematic---power-supply)
7. [Complete Bill of Materials](#complete-bill-of-materials)
8. [Component Selection Rationale](#component-selection-rationale)

---

## Overview

This document provides **complete, detailed** schematics and component lists for building the 5-level cascaded H-bridge inverter power stage.

### Power Stage Specifications

| Parameter | Value | Notes |
|-----------|-------|-------|
| **Output Power** | 707 W | Continuous (~700W) |
| **Output Voltage** | 70.7 V RMS | 100 V peak AC |
| **Output Current** | 10 A RMS | ±14 A peak |
| **DC Input** | 2× 50 VDC | Isolated sources |
| **Switching Frequency** | 5 kHz | PWM carrier (Level-Shifted) |
| **Topology** | 2× H-Bridge | 8 MOSFETs total (IRFZ44N) |
| **Voltage Levels** | 5 levels | +100V, +50V, 0, -50V, -100V |
| **Gate Drivers** | TLP250 | Optically isolated (8 total) |
| **Control** | STM32F303/F401 | 72/84 MHz ARM Cortex-M4 |
| **THD Achieved** | 4.9% | Simulink validated |

---

## System Architecture

### Complete System Block Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                     COMPLETE POWER STAGE                             │
│                                                                      │
│  ┌────────────────┐  ┌────────────────┐                           │
│  │  DC Source 1   │  │  DC Source 2   │                           │
│  │    50 VDC      │  │    50 VDC      │                           │
│  └───────┬────────┘  └───────┬────────┘                           │
│          │ +DC1  +DC2 │                                            │
│          │             │                                            │
│  ┌───────▼─────────────▼─────────────────────────────────────────┐ │
│  │              H-Bridge Module 1 + 2                            │ │
│  │  ┌──────────────────┐    ┌──────────────────┐               │ │
│  │  │   H-Bridge 1     │    │   H-Bridge 2     │               │ │
│  │  │ (Q1-Q4 MOSFETs)  │    │ (Q5-Q8 MOSFETs)  │               │ │
│  │  │  IRFZ44N 55V/49A │    │  IRFZ44N 55V/49A │               │ │
│  │  │  + RC Snubbers   │    │  + RC Snubbers   │               │ │
│  │  │  + TLP250×4      │    │  + TLP250×4      │               │ │
│  │  └──────┬───────────┘    └──────┬───────────┘               │ │
│  │         │ Out1                  │ Out2                       │ │
│  │         └───────────┬───────────┘                            │ │
│  │                     │ AC Output (5-level, 10A RMS)          │ │
│  └─────────────────────┼────────────────────────────────────────┘ │
│                        │                                           │
│  ┌─────────────────────▼────────────────────────────────────────┐ │
│  │              Output Filter (LC)                              │ │
│  │  L_filter (500 µH, 10A) + C_filter (10 µF) + Damping       │ │
│  └─────────────────────┬────────────────────────────────────────┘ │
│                        │ Filtered AC Output                       │
│                        ↓                                           │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │              Sensing Stage (Sigma-Delta ADC)                │  │
│  │  - LM339 Quad Comparator (4 channels)                      │  │
│  │  - RC filters + 1-bit DAC feedback                         │  │
│  │  - FPGA/STM32: CIC decimation (1MHz → 5kHz output rate)   │  │
│  │  - 12-14 bit ENOB resolution                               │  │
│  └────────────────────┬───────────────────────────────────────┘  │
│                       │ Digital Sensor Data (SPI/GPIO)           │
│  ┌────────────────────▼───────────────────────────────────────┐  │
│  │         Auxiliary Power Supply                              │  │
│  │  - Isolated 15V DC-DC for TLP250 drivers (×8)             │  │
│  │  - 5V for LM339 comparator                                 │  │
│  │  - Control logic power (3.3V for STM32)                    │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                    │
└────────────────────────────────────────────────────────────────────┘
```

---

## Detailed Schematic - H-Bridge Stage

### Single H-Bridge Full Circuit (H-Bridge 1)

```
                    +50VDC (DC Bus 1)
                         │
         ┌───────────────┴──────────────┐
         │                              │
    ┌────┴────┐                    ┌────┴────┐
    │   D1    │                    │   D3    │
    │  UF4007 │                    │  UF4007 │
    └────┬────┘                    └────┬────┘
         │                              │
    ┌────┴────┐                    ┌────┴────┐
    │   Q1    │ S1                 │   Q3    │ S3
    │ MOSFET    │ (High-side)        │ MOSFET    │ (High-side)
    │IKW15N120│                    │IKW15N120│
    │         │                    │         │
    │ G─10Ω─┬─┤                    │ G─10Ω─┬─┤
    │       │ │                    │       │ │
    │      10k│                    │      10k│
    │       │ │                    │       │ │
    │ E─────┴─┤                    │ E─────┴─┤
    └────┬────┘                    └────┬────┘
         │                              │
         │  ┌──────────────────────┐   │
         ├──┤  Snubber (47Ω+100nF) ├───┤
         │  └──────────────────────┘   │
         │                              │
         ├──────────┬───────────────────┤
         │       OUTPUT 1             OUTPUT 2
         │          │                   │
         │     ┌────┴────┐         ┌────┴────┐
         │     │   D2    │         │   D4    │
         │     │  UF4007 │         │  UF4007 │
         │     └────┬────┘         └────┬────┘
         │          │                   │
         │     ┌────┴────┐         ┌────┴────┐
         │     │   Q2    │ S2      │   Q4    │ S4
         │     │ MOSFET    │(Low-side)│ MOSFET    │(Low-side)
         │     │IKW15N120│         │IKW15N120│
         │     │         │         │         │
         │     │ G─10Ω─┬─┤         │ G─10Ω─┬─┤
         │     │       │ │         │       │ │
         │     │      10k│         │      10k│
         │     │       │ │         │       │ │
         │     │ E─────┴─┤         │ E─────┴─┤
         │     └────┬────┘         └────┬────┘
         │          │                   │
         │     ┌────┴────┐         ┌────┴────┐
         │     │Snubber  │         │Snubber  │
         │     │47Ω+100nF│         │47Ω+100nF│
         │     └────┬────┘         └────┬────┘
         │          │                   │
         └──────────┴───────────────────┘
                    │
                   GND
```

---

## Complete Bill of Materials

### Power Stage BOM (Both H-Bridges)

| Ref | Component | Part Number | Qty | Unit Price | Total | Notes |
|-----|-----------|-------------|-----|------------|-------|-------|
| **H-Bridge Power Devices** |
| Q1-Q8 | MOSFET 55V 49A | IRFZ44N | 8 | $2.00 | $16.00 | TO-220, 17.5mΩ Rds(on) |
| D1-D8 | Fast Diode 1kV 1A | UF4007 | 8 | $0.15 | $1.20 | Bootstrap diodes |
| **Gate Drive Components** |
| Rg1-Rg8 | Gate Resistor 10Ω 2W | - | 8 | $0.25 | $2.00 | Wirewound |
| Rge1-Rge8 | Pull-down 10kΩ 1/4W | - | 8 | $0.05 | $0.40 | Metal film |
| Rs1-Rs8 | Snubber Resistor 47Ω 2W | - | 8 | $0.30 | $2.40 | Metal film |
| Cs1-Cs8 | Snubber Cap 100nF 100V | - | 8 | $0.15 | $1.20 | X7R ceramic |
| **DC Bus Capacitors** |
| Cbulk1-2 | Bulk Cap 1000µF 100V | - | 2 | $2.50 | $5.00 | Low-ESR |
| Cbypass | Ceramic 1µF 100V X7R | - | 8 | $0.40 | $3.20 | HF bypass |
| **Gate Driver ICs** |
| U1-U8 | Optically Isolated Driver | TLP250 | 8 | $3.00 | $24.00 | One per MOSFET, 2.5kV isolation |
| **Gate Driver Passives** |
| Cbs1-Cbs4 | Bootstrap Cap 10µF 25V | - | 4 | $0.30 | $1.20 | Ceramic X7R |
| Dbs1-Dbs4 | Bootstrap Diode | UF4007 | 4 | $0.15 | $0.60 | Fast recovery |
| Cvcc | VCC Bypass 100µF 25V | - | 4 | $0.20 | $0.80 | Electrolytic |
| Cvcc_c | VCC Bypass 100nF 50V | - | 4 | $0.10 | $0.40 | Ceramic |
| Rin | Input Resistor 100Ω | - | 8 | $0.05 | $0.40 | PWM protection |
| **Subtotal H-Bridges** | | | | | **$59.20** | |

### Sensing Stage BOM

| Ref | Component | Part Number | Qty | Unit Price | Total | Notes |
|-----|-----------|-------------|-----|------------|-------|-------|
| **Sigma-Delta ADC (4 channels: DC1, DC2, AC_V, AC_I)** |
| U5 | Quad Comparator | LM339 | 1 | $0.50 | $0.50 | 4-channel Sigma-Delta ADC |
| R_adc | Feedback Resistors 10kΩ | - | 4 | $0.05 | $0.20 | RC filter (1-bit DAC) |
| C_adc | Feedback Capacitors 10nF | - | 4 | $0.10 | $0.40 | RC filter (1-bit DAC) |
| R_div | Voltage Dividers 10kΩ | - | 8 | $0.05 | $0.40 | Input scaling |
| Cvdd5 | VDD Bypass 100nF | - | 1 | $0.10 | $0.10 | Ceramic |
| **Protection Comparators** |
| U9 | Quad Comparator | LM339N | 1 | $0.60 | $0.60 | OCP/OVP detect |
| R_pullup | Pull-up 10kΩ | - | 4 | $0.05 | $0.20 | Comparator outputs |
| **Subtotal Sensing** | | | | | **$2.40** | |

### Power Supply BOM

| Ref | Component | Part Number | Qty | Unit Price | Total | Notes |
|-----|-----------|-------------|-----|------------|-------|-------|
| U10-U11 | DC-DC 15V 1W ISO | MEV1S1515SC | 2 | $12.00 | $24.00 | Gate driver supply |
| U12 | DC-DC 5V 3W ISO | TMR 3-0511 | 1 | $15.00 | $15.00 | Sensor supply |
| C_in | Input Cap 10µF | - | 3 | $0.15 | $0.45 | Per converter |
| C_out | Output Cap 100µF+100nF | - | 6 | $0.15 | $0.90 | Per converter |
| U13 | LDO 3.3V 1A | AMS1117-3.3 | 1 | $0.50 | $0.50 | Control logic |
| C_ldo | LDO Caps 10µF+22µF | - | 2 | $0.18 | $0.36 | In/Out |
| **Subtotal Power Supply** | | | | | **$41.21** | |

### Output Filter BOM

| Ref | Component | Specification | Qty | Unit Price | Total | Notes |
|-----|-----------|---------------|-----|------------|-------|-------|
| L1 | Filter Inductor 500µH 10A | - | 1 | $8.00 | $8.00 | Ferrite core |
| C_filt | Filter Cap 10µF 250VAC | - | 1 | $3.50 | $3.50 | X2 film cap |
| R_damp | Damping Resistor 10Ω 5W | - | 1 | $0.50 | $0.50 | Wirewound |
| C_damp | Damping Cap 1µF 250V | - | 1 | $1.00 | $1.00 | Film capacitor |
| **Subtotal Filter** | | | | | **$13.00** | |

### Connectors and Hardware

| Ref | Component | Specification | Qty | Unit Price | Total | Notes |
|-----|-----------|---------------|-----|------------|-------|-------|
| J1-J2 | DC Input Terminal | 2-pin, 20A, 5mm | 2 | $1.50 | $3.00 | Screw terminal |
| J3 | AC Output Terminal | 2-pin, 15A, 5mm | 1 | $1.50 | $1.50 | Screw terminal |
| J4 | PWM Input Header | 2×8 pin, 0.1" | 1 | $0.50 | $0.50 | IDC connector |
| J5 | Sensor Output | 1×6 pin, 0.1" | 1 | $0.30 | $0.30 | Pin header |
| Heatsink | TO-247 heatsink | 5°C/W | 8 | $2.00 | $16.00 | With thermal pad |
| Thermal Pad | Silicone pad | 0.5mm | 8 | $0.50 | $4.00 | Isolated |
| Mounting | Standoffs, screws | M3 | - | - | $2.00 | Hardware kit |
| **Subtotal Hardware** | | | | | **$27.30** | |
| **PCB (prototype)** | 4-layer, 150×100mm | - | 1 | - | $50.00 | Per spec |

---

### **GRAND TOTAL: $218.31**

*(Prices for single prototype quantities. Production costs 40-60% lower)*

---

**This document continues with breadboard testing, PCB design, and assembly guides in separate files.**

**See also:**
- BREADBOARD-TESTING.md - Step-by-step prototyping guide
- PCB-DESIGN.md - PCB layout and manufacturing specifications
- ASSEMBLY-GUIDE.md - Detailed assembly instructions with photos
