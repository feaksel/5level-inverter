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
| **Output Power** | 500W continuous |
| **Output Voltage** | 100V RMS (±141V peak) |
| **Output Current** | 5A RMS (±7.07A peak) |
| **DC Input** | 2× 50VDC (isolated) |
| **Topology** | 2× Cascaded H-Bridges (5 voltage levels) |
| **Switching Frequency** | 10 kHz PWM |
| **Target THD** | < 5% |
| **Total Cost** | ~$218 (prototype quantities) |

---

## Documentation

### Power Stage Documentation
**Location:** [`power-stage/`](power-stage/)

The power stage folder contains comprehensive documentation covering:

1. **[POWER-STAGE-COMPLETE.md](power-stage/docs/POWER-STAGE-COMPLETE.md)** (25 KB)
   - Complete schematics and system architecture
   - Full bill of materials ($218) with part numbers
   - Component selection rationale and calculations

2. **[BREADBOARD-TESTING.md](power-stage/docs/BREADBOARD-TESTING.md)** (38 KB)
   - 6-stage safe testing procedure (low voltage → full power)
   - Safety precautions and procedures
   - Comprehensive troubleshooting guide

3. **[PCB-DESIGN.md](power-stage/docs/PCB-DESIGN.md)** (32 KB)
   - 4-layer PCB layout and routing guidelines
   - Thermal management and EMI considerations
   - Manufacturing specifications

4. **[ASSEMBLY-GUIDE.md](power-stage/docs/ASSEMBLY-GUIDE.md)** (28 KB)
   - Step-by-step assembly instructions
   - Soldering techniques and quality inspection
   - Initial testing procedures

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

### ⚠️ HIGH VOLTAGE - POTENTIALLY LETHAL

This hardware operates at **up to 141V peak** which is **potentially fatal**.

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
