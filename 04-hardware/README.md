# Hardware Documentation

**Project:** 5-Level Cascaded H-Bridge Inverter
**Status:** ✅ Production Ready
**Last Updated:** 2025-12-02

---

## Overview

This folder contains complete hardware documentation for the 5-level cascaded H-bridge inverter power stage.

**All detailed documentation is located in:** [`power-stage/`](power-stage/)

---

## System Specifications

| Parameter | Value |
|-----------|-------|
| **Output Power** | 707W continuous (~700W) |
| **Output Voltage** | 70.7V RMS (100V peak AC) |
| **Output Current** | 10A RMS (±14A peak) |
| **DC Input** | 2× 50VDC (isolated) |
| **Topology** | 2× Cascaded H-Bridges (5 voltage levels) |
| **Switching Frequency** | 5 kHz PWM |
| **Target THD** | < 5% (4.9% achieved in simulation) |
| **Control Platform** | STM32F303/F401 (72/84 MHz ARM Cortex-M4) |

---

## Documentation

### Power Stage Documentation
**Location:** [`power-stage/`](power-stage/)

The power stage folder contains comprehensive documentation covering:

1. **[POWER-STAGE-COMPLETE.md](power-stage/docs/POWER-STAGE-COMPLETE.md)** (25 KB)
   - Complete schematics with IRFZ44N MOSFETs + TLP250 drivers
   - Full bill of materials with part numbers
   - Component selection rationale (MOSFETs vs IGBTs analysis)
   - Sigma-Delta ADC sensing design with LM339 comparators

2. **[BREADBOARD-TESTING.md](power-stage/docs/BREADBOARD-TESTING.md)** (38 KB)
   - Progressive testing procedure for 707W, 10A system
   - Safety precautions for high-current testing
   - Comprehensive troubleshooting guide
   - Isolated gate driver validation procedures

3. **[PCB-DESIGN.md](power-stage/docs/PCB-DESIGN.md)** (32 KB)
   - 4-layer PCB layout for 10A continuous operation
   - High-current trace routing guidelines
   - Thermal management for MOSFET switching losses
   - TLP250 isolated driver placement

4. **[ASSEMBLY-GUIDE.md](power-stage/docs/ASSEMBLY-GUIDE.md)** (28 KB)
   - Step-by-step assembly with MOSFET installation
   - TLP250 optocoupler driver assembly
   - Quality inspection and testing
   - Initial 5kHz PWM validation

**Start here:** [power-stage/README.md](power-stage/README.md) for quick navigation

---

## Quick Links

| I want to... | Go to |
|--------------|-------|
| **Understand the complete system** | [power-stage/docs/POWER-STAGE-COMPLETE.md](power-stage/docs/POWER-STAGE-COMPLETE.md) |
| **Order components** | [Complete BOM](power-stage/docs/POWER-STAGE-COMPLETE.md#complete-bill-of-materials) |
| **Build a breadboard prototype** | [power-stage/docs/BREADBOARD-TESTING.md](power-stage/docs/BREADBOARD-TESTING.md) |
| **Design a PCB** | [power-stage/docs/PCB-DESIGN.md](power-stage/docs/PCB-DESIGN.md) |
| **Assemble a PCB** | [power-stage/docs/ASSEMBLY-GUIDE.md](power-stage/docs/ASSEMBLY-GUIDE.md) |

---

## Safety Warning

### ⚠️ HIGH VOLTAGE & HIGH CURRENT - POTENTIALLY LETHAL

This hardware operates at **up to 100V peak AC and 10A current** which is **potentially fatal**.

**Essential safety rules:**
- ❌ **NEVER** work on live circuits
- ✅ **ALWAYS** discharge capacitors before touching
- ✅ **USE** isolated power supplies only
- ✅ **START** at low voltage (12V) and increase gradually
- ✅ **WORK** with someone nearby for emergency assistance

**See:** [BREADBOARD-TESTING.md Safety Section](power-stage/docs/BREADBOARD-TESTING.md#safety-precautions) for complete guidelines.

---

## Related Documentation

**Control Firmware:**
- [`02-embedded/stm32/`](../02-embedded/stm32/) - STM32F401RE implementation
- [`02-embedded/stm32-fpga-hybrid/`](../02-embedded/stm32-fpga-hybrid/) - Hybrid STM32+FPGA architecture
- [`02-embedded/riscv-soc/`](../02-embedded/riscv-soc/) - RISC-V SOC implementation

**Sensing Design:**
- [`07-docs/SENSING-DESIGN.md`](../07-docs/SENSING-DESIGN.md) - Universal sensor interface
- [`07-docs/SENSING-DESIGN-DEEP-DIVE.md`](../07-docs/SENSING-DESIGN-DEEP-DIVE.md) - Sigma-Delta ADC theory

**System Architecture:**
- [`07-docs/`](../07-docs/) - System diagrams
- [`CLAUDE.md`](../CLAUDE.md) - Project guidelines

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 2.0 | 2025-12-02 | Reorganized into power-stage/ structure, comprehensive documentation |
| 1.0 | 2025-11-15 | Initial hardware documentation |

---

**Status:** ✅ Complete and production-ready
**Maintainer:** 5-Level Inverter Project Team
