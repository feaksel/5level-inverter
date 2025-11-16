# Complete Bill of Materials (BOM)

**Document Type:** Hardware BOM
**Project:** 5-Level Cascaded H-Bridge Multilevel Inverter
**Author:** 5-Level Inverter Project
**Date:** 2025-11-15
**Version:** 1.0
**Status:** Design - Not Yet Validated

---

## Table of Contents

1. [BOM Summary](#bom-summary)
2. [Power Components](#power-components)
3. [Gate Driver Components](#gate-driver-components)
4. [Sensing Components](#sensing-components)
5. [Protection Components](#protection-components)
6. [Control and Interface](#control-and-interface)
7. [Passive Components Summary](#passive-components-summary)
8. [PCB and Enclosure](#pcb-and-enclosure)
9. [Tools and Consumables](#tools-and-consumables)
10. [Supplier Information](#supplier-information)
11. [Cost Analysis](#cost-analysis)

---

## BOM Summary

**Total Component Count:** ~150 items (including passives)
**Estimated Total Cost:** ~$350-400 USD
**Recommended Suppliers:** Digi-Key, Mouser, Newark, LCSC (for PCB assembly)

**Categories:**
- Power Stage: $200 (PSUs + MOSFETs)
- Gate Drivers: $20
- Sensing: $10
- Protection: $16
- Control: $15 (STM32 Nucleo board)
- Passives: $30
- PCB + Enclosure: $50-100

---

## Power Components

### Power Supplies

| Qty | Part Number | Manufacturer | Description | Specs | Unit Price | Total | Supplier |
|-----|-------------|--------------|-------------|-------|------------|-------|----------|
| 2 | RSP-500-48 | Mean Well | Switching PSU | 48V (adj to 50V), 10.5A, 504W | $45.00 | $90.00 | Digi-Key |
| 1 | RD-35B | Mean Well | Dual auxiliary PSU | +5V/3A, +12V/1.5A | $12.00 | $12.00 | Digi-Key |
| 2 | NTC 5Ω 10A | Ametherm | Inrush limiter | SL12 5R010, 5Ω @ 25°C | $1.00 | $2.00 | Mouser |
| 2 | Fuse 15A | Littelfuse | Slow-blow fuse | 5×20mm, 250V AC | $0.50 | $1.00 | Digi-Key |
| 2 | Fuse holder | Keystone | Panel mount holder | 3557-2, 5×20mm | $1.00 | $2.00 | Digi-Key |
| 2 | MOV 275V | Littelfuse | Varistor | V275LA20AP, 14mm | $0.50 | $1.00 | Mouser |
| 2 | EMI filter | Schaffner | IEC inlet with filter | FN 9222, 10A | $5.00 | $10.00 | Newark |
| | | | | **Subtotal** | | **$118.00** | |

### Power Semiconductors (MOSFETs)

**Option 1: IRF540N (Low-cost prototyping)**

| Qty | Part Number | Manufacturer | Description | Specs | Unit Price | Total | Supplier |
|-----|-------------|--------------|-------------|-------|------------|-------|----------|
| 8 | IRF540N | Infineon | N-Channel MOSFET | 100V, 33A, 44mΩ, TO-220 | $1.50 | $12.00 | Digi-Key |

**Option 2: IRFB4110 (Higher current, production)**

| Qty | Part Number | Manufacturer | Description | Specs | Unit Price | Total | Supplier |
|-----|-------------|--------------|-------------|-------|------------|-------|----------|
| 8 | IRFB4110PBF | Infineon | N-Channel MOSFET | 100V, 180A, 3.7mΩ, TO-220AB | $3.50 | $28.00 | Mouser |

**Recommended for prototype:** IRF540N
**Recommended for production:** IRFB4110PBF

### Heatsinks and Thermal Management

| Qty | Part Number | Manufacturer | Description | Specs | Unit Price | Total | Supplier |
|-----|-------------|--------------|-------------|-------|------------|-------|----------|
| 4 | 531802B03700G | Aavid | TO-220 Heatsink | 15°C/W, 38mm height | $1.50 | $6.00 | Digi-Key |
| 1 | Arctic MX-4 | Arctic | Thermal paste | 4g tube | $8.00 | $8.00 | Amazon |
| 8 | TO-220 kit | Wakefield | Insulating kit | Mica + shoulder washer | $0.50 | $4.00 | Mouser |
| 2 | Fan 40mm | Sunon | Cooling fan | 12V DC, 0.1A, 10 CFM | $5.00 | $10.00 | Digi-Key |
| | | | | **Subtotal (with IRF540N)** | | **$158.00** | |
| | | | | **Subtotal (with IRFB4110)** | | **$174.00** | |

---

## Gate Driver Components

### Driver ICs

| Qty | Part Number | Manufacturer | Description | Specs | Unit Price | Total | Supplier |
|-----|-------------|--------------|-------------|-------|------------|-------|----------|
| 4 | IR2110 | Infineon | High-Low Side Driver | 600V, 2A, DIP-14/SOIC-16 | $2.00 | $8.00 | Digi-Key |
| 4 | UF4007 | ON Semi | Fast Recovery Diode | 1A, 1000V | $0.10 | $0.40 | Mouser |
| 4 | Cap 1μF 25V | TDK | Bootstrap Cap | Ceramic X7R, 0805 | $0.15 | $0.60 | LCSC |
| 8 | Cap 100nF 25V | Murata | Decoupling Vcc | Ceramic X7R, 0603 | $0.05 | $0.40 | LCSC |
| 4 | Cap 100nF 16V | Murata | Decoupling Vdd | Ceramic X7R, 0603 | $0.05 | $0.20 | LCSC |
| 4 | Cap 100μF 25V | Panasonic | Bulk Vcc | Electrolytic, radial | $0.20 | $0.80 | Digi-Key |
| 8 | Res 10Ω 1/4W | Yageo | Gate Resistor | 1%, 0805 or through-hole | $0.02 | $0.16 | LCSC |
| | | | | **Subtotal** | | **$10.56** | |

### Level Shifters (3.3V STM32 → 5V IR2110)

| Qty | Part Number | Manufacturer | Description | Specs | Unit Price | Total | Supplier |
|-----|-------------|--------------|-------------|-------|------------|-------|----------|
| 1 | SN74AHCT125N | Texas Instruments | Quad level shifter | 3.3V → 5V, DIP-14 | $0.50 | $0.50 | Digi-Key |
| 4 | Res 1kΩ | Yageo | Pull-up resistor | 1%, 0603 | $0.02 | $0.08 | LCSC |
| 4 | Res 2.2kΩ | Yageo | Divider resistor | 1%, 0603 | $0.02 | $0.08 | LCSC |
| | | | | **Subtotal** | | **$0.66** | |

**Gate Driver Section Total:** ~$11.22

---

## Sensing Components

### Current Sensing

| Qty | Part Number | Manufacturer | Description | Specs | Unit Price | Total | Supplier |
|-----|-------------|--------------|-------------|-------|------------|-------|----------|
| 1 | ACS724LLCTR-20AB-T | Allegro | Current sensor | ±20A, Hall effect, SOIC-8 | $4.00 | $4.00 | Mouser |
| 1 | Cap 100nF | Murata | Filtering | Ceramic X7R, 0603 | $0.05 | $0.05 | LCSC |
| 1 | Cap 10μF 25V | TDK | Filtering | Ceramic X7R, 0805 | $0.10 | $0.10 | LCSC |
| | | | | **Subtotal** | | **$4.15** | |

### Voltage Sensing

| Qty | Part Number | Manufacturer | Description | Specs | Unit Price | Total | Supplier |
|-----|-------------|--------------|-------------|-------|------------|-------|----------|
| 1 | AMC1301DWV | Texas Instruments | Isolated ADC | ±250 mV, SOIC-16 | $4.00 | $4.00 | Digi-Key |
| 1 | Res 590kΩ 1W | Vishay | Divider high-side | 1%, metal film | $0.20 | $0.20 | Mouser |
| 1 | Res 10kΩ 1/4W | Yageo | Divider low-side | 1%, 0805 | $0.02 | $0.02 | LCSC |
| | | | | **Subtotal** | | **$4.22** | |

### DC Bus Voltage Sensing

| Qty | Part Number | Manufacturer | Description | Specs | Unit Price | Total | Supplier |
|-----|-------------|--------------|-------------|-------|------------|-------|----------|
| 2 | Res 47kΩ 1/4W | Yageo | Divider high-side | 1%, 0805 | $0.02 | $0.04 | LCSC |
| 2 | Res 3.3kΩ 1/4W | Yageo | Divider low-side | 1%, 0805 | $0.02 | $0.04 | LCSC |
| 2 | 1N4728A | ON Semi | 3.3V Zener | 1W, DO-41 | $0.10 | $0.20 | Mouser |
| 2 | Cap 100nF | Murata | Filter cap | Ceramic X7R, 0603 | $0.05 | $0.10 | LCSC |
| | | | | **Subtotal** | | **$0.38** | |

### Anti-Aliasing and Protection

| Qty | Part Number | Manufacturer | Description | Specs | Unit Price | Total | Supplier |
|-----|-------------|--------------|-------------|-------|------------|-------|----------|
| 4 | Res 10kΩ | Yageo | AA filter R | 1%, 0603 | $0.02 | $0.08 | LCSC |
| 4 | Cap 5.6nF | Murata | AA filter C | Ceramic X7R, 0603 | $0.05 | $0.20 | LCSC |
| 2 | BAT54S | ON Semi | Dual Schottky | SOT-23 | $0.15 | $0.30 | Digi-Key |
| | | | | **Subtotal** | | **$0.58** | |

**Sensing Section Total:** ~$9.33

---

## Protection Components

### Overcurrent Protection

| Qty | Part Number | Manufacturer | Description | Specs | Unit Price | Total | Supplier |
|-----|-------------|--------------|-------------|-------|------------|-------|----------|
| 2 | LM339N | Texas Instruments | Quad comparator | DIP-14 | $0.50 | $1.00 | Digi-Key |
| 4 | Res 10kΩ | Yageo | Pull-up | 1%, 0603 | $0.02 | $0.08 | LCSC |
| 2 | Res 16kΩ | Yageo | Vref divider | 1%, 0603 | $0.02 | $0.04 | LCSC |
| | | | | **Subtotal** | | **$1.12** | |

### Overvoltage Protection

| Qty | Part Number | Manufacturer | Description | Specs | Unit Price | Total | Supplier |
|-----|-------------|--------------|-------------|-------|------------|-------|----------|
| 2 | Res 82kΩ 1W | Vishay | OVP divider | 1%, metal film | $0.10 | $0.20 | Mouser |
| 2 | Res 6.8kΩ 1/4W | Yageo | OVP divider | 1%, 0805 | $0.02 | $0.04 | LCSC |
| 2 | C106D | ON Semi | SCR (optional) | 400V, 4A, TO-126 | $0.30 | $0.60 | Mouser |
| 2 | Fuse 20A | Littelfuse | DC bus fuse | Fast-blow, 63V DC | $1.00 | $2.00 | Digi-Key |
| | | | | **Subtotal** | | **$2.84** | |

### Thermal Protection

| Qty | Part Number | Manufacturer | Description | Specs | Unit Price | Total | Supplier |
|-----|-------------|--------------|-------------|-------|------------|-------|----------|
| 2 | NTC 10kΩ | TDK | Thermistor | β=3950, 1%, radial | $0.50 | $1.00 | Digi-Key |
| 2 | Res 10kΩ | Yageo | Pull-up | 1%, 0603 | $0.02 | $0.04 | LCSC |
| 1 | Thermal epoxy | Arctic | Adhesive | 5g tube | $5.00 | $5.00 | Amazon |
| | | | | **Subtotal** | | **$6.04** | |

### Fault Indication

| Qty | Part Number | Manufacturer | Description | Specs | Unit Price | Total | Supplier |
|-----|-------------|--------------|-------------|-------|------------|-------|----------|
| 1 | LED 5mm Green | Kingbright | Status indicator | 2V, 20mA | $0.10 | $0.10 | Digi-Key |
| 1 | LED 5mm Yellow | Kingbright | Warning indicator | 2V, 20mA | $0.10 | $0.10 | Digi-Key |
| 1 | LED 5mm Red | Kingbright | Fault indicator | 2V, 20mA | $0.10 | $0.10 | Digi-Key |
| 3 | Res 470Ω | Yageo | LED current limit | 1%, 0603 | $0.02 | $0.06 | LCSC |
| | | | | **Subtotal** | | **$0.36** | |

### Emergency Stop

| Qty | Part Number | Manufacturer | Description | Specs | Unit Price | Total | Supplier |
|-----|-------------|--------------|-------------|-------|------------|-------|----------|
| 1 | XB4BS8442 | Schneider Electric | E-Stop button | Red mushroom, 40mm, NO | $15.00 | $15.00 | Digi-Key |
| 1 | Res 10kΩ | Yageo | Pull-up | 1%, 0603 | $0.02 | $0.02 | LCSC |
| | | | | **Subtotal** | | **$15.02** | |

**Protection Section Total:** ~$25.38

---

## Control and Interface

### Microcontroller

| Qty | Part Number | Manufacturer | Description | Specs | Unit Price | Total | Supplier |
|-----|-------------|--------------|-------------|-------|------------|-------|----------|
| 1 | NUCLEO-F401RE | STMicroelectronics | Development board | STM32F401RE, 84MHz, USB | $15.00 | $15.00 | Digi-Key |
| | | | | **Subtotal** | | **$15.00** | |

### Connectors and Headers

| Qty | Part Number | Manufacturer | Description | Specs | Unit Price | Total | Supplier |
|-----|-------------|--------------|-------------|-------|------------|-------|----------|
| 8 | Terminal 2-pos | Phoenix | Screw terminal | 5.08mm pitch, 10A | $0.50 | $4.00 | Digi-Key |
| 4 | Terminal 3-pos | Phoenix | Screw terminal | 5.08mm pitch, 10A | $0.75 | $3.00 | Digi-Key |
| 10 | Header 2×10 | Samtec | Pin header | 2.54mm pitch, female | $0.30 | $3.00 | Mouser |
| 1 | USB cable | Generic | USB A to Micro-B | 1m, for programming | $3.00 | $3.00 | Amazon |
| | | | | **Subtotal** | | **$13.00** | |

### Debug and Communication

| Qty | Part Number | Manufacturer | Description | Specs | Unit Price | Total | Supplier |
|-----|-------------|--------------|-------------|-------|------------|-------|----------|
| 1 | ST-LINK V2 | STMicroelectronics | Debugger/Programmer | (Optional, Nucleo has onboard) | $25.00 | - | Digi-Key |
| 1 | UART-USB | FTDI | USB-Serial adapter | FT232RL, 3.3V/5V | $5.00 | $5.00 | Amazon |
| | | | | **Subtotal** | | **$5.00** | |

**Control & Interface Total:** ~$33.00

---

## Passive Components Summary

### Resistors

**Through-Hole (1/4W, Metal Film, 1%):**

| Value | Quantity | Unit Price | Total |
|-------|----------|------------|-------|
| 10Ω | 8 | $0.05 | $0.40 |
| 470Ω | 3 | $0.05 | $0.15 |
| 1kΩ | 4 | $0.05 | $0.20 |
| 2.2kΩ | 4 | $0.05 | $0.20 |
| 3.3kΩ | 2 | $0.05 | $0.10 |
| 6.8kΩ | 2 | $0.05 | $0.10 |
| 10kΩ | 20 | $0.05 | $1.00 |
| 16kΩ | 2 | $0.05 | $0.10 |
| 47kΩ | 2 | $0.05 | $0.10 |
| 82kΩ (1W) | 2 | $0.15 | $0.30 |
| 590kΩ (1W) | 1 | $0.25 | $0.25 |
| **Subtotal** | | | **$2.90** |

### Capacitors

**Ceramic (X7R, SMD 0603/0805):**

| Value | Voltage | Quantity | Unit Price | Total |
|-------|---------|----------|------------|-------|
| 5.6nF | 50V | 4 | $0.05 | $0.20 |
| 100nF | 50V | 20 | $0.05 | $1.00 |
| 1μF | 25V | 4 | $0.15 | $0.60 |
| 10μF | 25V | 2 | $0.15 | $0.30 |
| **Subtotal** | | | | **$2.10** |

**Electrolytic (Radial, 105°C):**

| Value | Voltage | Quantity | Unit Price | Total |
|-------|---------|----------|------------|-------|
| 100μF | 25V | 4 | $0.20 | $0.80 |
| 1000μF | 63V | 4 | $1.00 | $4.00 |
| **Subtotal** | | | | **$4.80** |

**Passives Total:** ~$9.80

---

## PCB and Enclosure

### PCB Fabrication

| Qty | Description | Specs | Unit Price | Total | Supplier |
|-----|-------------|-------|------------|-------|----------|
| 5 | PCB 200×150mm | 4-layer, 2oz copper, ENIG | $10.00 | $50.00 | JLCPCB / PCBWay |
| 1 | Stencil | Laser-cut, 200×150mm | $10.00 | $10.00 | JLCPCB |
| | | | **Subtotal** | **$60.00** | |

**Note:** Prices for 5 pcs (typical minimum order). Cost per board: $12.

### Enclosure and Mounting

| Qty | Part Number | Manufacturer | Description | Specs | Unit Price | Total | Supplier |
|-----|-------------|--------------|-------------|-------|------------|-------|----------|
| 1 | 1590WV | Hammond | Diecast enclosure | 300×250×100mm, vented | $40.00 | $40.00 | Digi-Key |
| 10 | M3 standoff | Generic | PCB standoffs | 10mm, brass | $0.20 | $2.00 | Amazon |
| 20 | M3 screw | Generic | Machine screw | 6mm, Phillips | $0.05 | $1.00 | Amazon |
| 4 | Rubber feet | Generic | Adhesive feet | 12mm dia | $0.25 | $1.00 | Amazon |
| | | | **Subtotal** | | **$44.00** | |

**PCB & Enclosure Total:** ~$104.00

---

## Tools and Consumables

**Essential Tools (if not already owned):**

| Item | Description | Unit Price | Supplier |
|------|-------------|------------|----------|
| Soldering iron | Temperature controlled, 60W | $50.00 | Amazon |
| Solder | 60/40 or lead-free, 0.8mm | $10.00 | Amazon |
| Flux | Rosin flux pen | $5.00 | Amazon |
| Wire | 18 AWG silicone (red/black) | $10.00 | Amazon |
| Heat shrink | Assorted sizes | $8.00 | Amazon |
| Multimeter | Basic DMM | $20.00 | Amazon |
| Oscilloscope | 2-channel, 50 MHz (if needed) | $300-500 | Rigol/Siglent |
| Power supply | 0-60V, 0-10A bench PSU | $100-200 | Generic |
| **Tool Total** | | **~$200 (excluding scope/PSU)** | |

---

## Supplier Information

### Recommended Suppliers

**United States:**
- **Digi-Key** (www.digikey.com) - Fast shipping, large inventory, excellent service
- **Mouser** (www.mouser.com) - Similar to Digi-Key, competitive pricing
- **Newark** (www.newark.com) - Good for industrial components
- **Amazon** - Tools, consumables, enclosures

**International / Low-cost PCB:**
- **JLCPCB** (www.jlcpcb.com) - $2 for 5 pcs 2-layer PCBs, cheap 4-layer
- **PCBWay** (www.pcbway.com) - Slightly higher quality than JLCPCB
- **LCSC** (www.lcsc.com) - Cheap SMD components (ships from China)

**Minimum Order Quantities (MOQ):**
- Most distributors: No MOQ or very low (1-10 pcs)
- PCB fabs: Typically 5 pcs minimum
- Some ICs (like custom ASICs): 100-1000 pcs (not applicable to this project)

---

## Cost Analysis

### Cost Summary by Section

| Section | Cost (USD) | Percentage |
|---------|------------|------------|
| Power Supplies | $118.00 | 33% |
| Power Semiconductors | $12.00 (IRF540N) | 3% |
| Heatsinks & Thermal | $28.00 | 8% |
| Gate Drivers | $11.22 | 3% |
| Sensing | $9.33 | 3% |
| Protection | $25.38 | 7% |
| Control & Interface | $33.00 | 9% |
| Passives | $9.80 | 3% |
| PCB & Enclosure | $104.00 | 29% |
| Tools (one-time) | $200.00 | - |
| **Total (w/o tools)** | **~$350** | **100%** |
| **Total (w/ tools)** | **~$550** | |

### Cost Optimization Options

**Budget Version (~$250):**
- Use open-frame PSUs instead of enclosed Mean Well units (-$50)
- Skip enclosure, use breadboard mounting (-$40)
- Use IRF540N MOSFETs (already selected)
- Single-layer or 2-layer PCB (-$40)
- **Total: ~$220**

**Production Version (~$250 per unit at 100 qty):**
- Bulk pricing on PSUs (50% discount)
- Bulk pricing on MOSFETs and ICs (30-40% discount)
- PCB assembly in China (PCBA)
- Custom enclosure (injection molded)
- **Estimated: $150-200 per unit at volume**

---

## Procurement Checklist

### Before Ordering

- [ ] Review schematic and verify all part numbers
- [ ] Check stock availability at suppliers
- [ ] Compare prices across Digi-Key, Mouser, Newark
- [ ] Add 10% spare quantity for critical components
- [ ] Verify voltage/current ratings for all parts
- [ ] Check package sizes (SMD vs through-hole)
- [ ] Confirm pin-compatible alternatives exist

### Order Grouping

**Order 1: PCB Fabrication (JLCPCB)**
- Submit Gerber files
- 4-layer, 2oz copper, ENIG finish
- Lead time: 5-7 days + shipping (7-14 days)

**Order 2: Power Components (Digi-Key/Mouser)**
- Mean Well PSUs
- MOSFETs
- Heatsinks
- Fuses, MOVs
- Lead time: 1-3 days (in stock)

**Order 3: ICs and Active Components (Digi-Key)**
- IR2110 gate drivers
- ACS724, AMC1301 sensors
- LM339 comparators
- STM32 Nucleo board
- Lead time: 1-3 days

**Order 4: Passives (LCSC or Digi-Key)**
- All resistors and capacitors
- Can use LCSC for low-cost SMD parts
- Lead time: 2-4 weeks (LCSC), 1-3 days (Digi-Key)

**Order 5: Mechanical (Amazon)**
- Enclosure
- Terminals, connectors
- E-stop button
- Hardware (screws, standoffs)
- Lead time: 1-2 days (Prime)

---

## Appendix A: Component Substitutions

### Acceptable Substitutions

**Power MOSFETs:**
- IRF540N → IRFZ44N (50V, 55A, cheaper)
- IRFB4110 → IXFH32N100Q (1000V, 32A, higher voltage)

**Gate Drivers:**
- IR2110 → IR2113 (same family, different package)
- IR2110 → UCC27211 (newer, higher performance)

**Current Sensor:**
- ACS724 → ACS712 (older, cheaper, -20A to +20A)
- ACS724 → INA240 + shunt (differential amp method)

**PSUs:**
- Mean Well RSP-500-48 → TDK-Lambda RWS-500B-48 (equivalent)
- Mean Well RD-35B → Traco TXL 035-1212D (dual output)

**Comparators:**
- LM339 → LM393 (dual instead of quad)
- LM339 → TLV3501 (faster, more expensive)

---

## Appendix B: Lead Time and Availability

**As of November 2024:**

| Component | Typical Lead Time | Stock Status |
|-----------|-------------------|--------------|
| Mean Well PSUs | In stock | ✅ Readily available |
| IR2110 | In stock | ✅ Readily available |
| IRF540N | In stock | ✅ Readily available |
| IRFB4110 | 2-4 weeks | ⚠️ Check availability |
| ACS724 | In stock | ✅ Readily available |
| AMC1301 | In stock | ✅ Readily available |
| STM32 Nucleo | In stock | ✅ Readily available |
| LM339 | In stock | ✅ Readily available |

**Semiconductor Shortage Note:** As of late 2024, the global chip shortage has mostly resolved. However, always check real-time stock before ordering.

---

## Appendix C: Recommended Spares

**Critical Spares (order extra):**

| Component | Reason | Spare Qty |
|-----------|--------|-----------|
| MOSFETs (IRF540N) | May fail during testing | +4 (50%) |
| IR2110 | Sensitive to ESD | +2 (50%) |
| Fuses (20A, 15A) | Consumable | +10 each |
| ACS724 | May damage with overcurrent | +1 (100%) |
| Resistors/Caps | General spares | +20% |

**Total spare cost: ~$30**

---

**Document Version:** 1.0
**Last Updated:** 2025-11-15
**Next Update:** After prototype validation

**Related Documents:**
- `../schematics/*.md` - Individual circuit designs
- `../pcb/05-PCB-Layout-Guide.md` - PCB design guide
- `../../07-docs/05-Hardware-Testing-Procedures.md` - Testing procedures
