# Custom RISC-V SoC for 5-Level Inverter

**Status:** Ready for Core Implementation ✅
**Date:** 2025-12-03  
**Architecture:** Custom RV32IM + Zpec Extension

---

## Overview

This directory contains a **complete SoC infrastructure** ready for your custom RISC-V core implementation. All peripherals, memory, firmware drivers, and build system are set up and working - you just need to implement the processor core!

### What's Ready

✅ **All Peripherals**
- PWM Accelerator (8 channels with dead-time)
- Sigma-Delta ADC (4 channels, 10 kHz, 12-14 bit ENOB)
- Protection/Fault logic (OCP, OVP, E-stop, watchdog)
- Timer (32-bit with interrupt)
- GPIO (32 pins with interrupt)
- UART (115200 baud, debug/communication)

✅ **Memory System**
- 32 KB ROM (instruction memory)
- 64 KB RAM (data memory)
- Wishbone interconnect

✅ **Firmware Infrastructure**
- Complete memory map (`firmware/memory_map.h`)
- Peripheral drivers (`firmware/sigma_delta_adc.h`)
- Example programs (`firmware/examples/`)

✅ **Build System**
- Simulation testbenches
- Constraints for Basys 3 FPGA

✅ **Documentation**
- Detailed implementation roadmap (`docs/IMPLEMENTATION_ROADMAP.md`)
- Drop-in replacement guide (`docs/DROP_IN_REPLACEMENT_GUIDE.md`)
- ISA definitions (`rtl/core/riscv_defines.vh`)

---

## Quick Start

1. **Read `docs/DROP_IN_REPLACEMENT_GUIDE.md`** - START HERE!
2. **Follow `docs/IMPLEMENTATION_ROADMAP.md`** - Week-by-week plan
3. **Implement `rtl/core/custom_riscv_core.v`** - Your RV32IM + Zpec core
4. **Implement `rtl/core/custom_core_wrapper.v`** - Wishbone wrapper
5. **Test with existing peripherals** - Everything else is ready!

---

## What You Need to Implement

🔧 **Custom RV32IM Core** (`rtl/core/custom_riscv_core.v`)
- 3-stage pipeline
- RV32I + M extension
- Zpec custom instructions  
- Interrupts and CSRs

🔧 **Core Wrapper** (`rtl/core/custom_core_wrapper.v`)
- Converts core interface to Wishbone
- Drop-in replacement for VexRiscv

See the comprehensive guides in `docs/` for complete instructions!

---

**Estimated Time:** 8-12 weeks  
**All infrastructure ready - just implement the core!** 🚀
