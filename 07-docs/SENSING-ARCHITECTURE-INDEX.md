# Sensing Architecture Documentation Index

**Last Updated:** 2025-12-02
**Purpose:** Navigation guide for all sensing-related documentation

---

## Quick Navigation

### 🎯 Primary Design Documents (Use These!)

1. **[FPGA-SENSING-DESIGN.md](FPGA-SENSING-DESIGN.md)** ⭐ **START HERE**
   - Complete FPGA-based ADC design for Stage 2
   - Sigma-Delta ADC implementation in Verilog
   - ASIC migration strategy
   - Bill of materials and comparisons
   - **Use this for:** FPGA/ASIC implementation

2. **[MODULAR_ARCHITECTURE_GUIDE.md](MODULAR_ARCHITECTURE_GUIDE.md)** ⭐ **SYSTEM OVERVIEW**
   - Universal power stage architecture
   - 3 control board options (STM32, FPGA, ASIC)
   - Standard 16-pin interface
   - **Use this for:** Overall system understanding

### 📚 Reference Documents (Background Info)

3. **[ADC_SELECTION_AND_ISOLATION_GUIDE.md](ADC_SELECTION_AND_ISOLATION_GUIDE.md)**
   - ⚠️ **Partially superseded by FPGA-SENSING-DESIGN.md**
   - Still useful for: Turkey component sourcing
   - Still useful for: Isolation circuit designs (AMC1301, ACS724)
   - Skip sections on: External ADC chips (replaced by FPGA Σ-Δ)

4. **[FPGA_ADC_DESIGN_ADDENDUM.md](FPGA_ADC_DESIGN_ADDENDUM.md)**
   - ⚠️ **Superseded by FPGA-SENSING-DESIGN.md**
   - Was: Initial exploration of FPGA ADC options
   - Now: Integrated into comprehensive FPGA-SENSING-DESIGN.md

5. **[../04-hardware/schematics/03-Current-Voltage-Sensing.md](../04-hardware/schematics/03-Current-Voltage-Sensing.md)**
   - Hardware-level sensor circuits
   - Detailed component selection (resistors, capacitors)
   - Useful for: PCB design and component specs

---

## Architecture Summary

### Stage Comparison

| Stage | Platform | ADC Type | Where to Read |
|-------|----------|----------|---------------|
| **Stage 1** | STM32F303RE only | STM32 internal SAR ADC | MODULAR_ARCHITECTURE_GUIDE.md |
| **Stage 2** | FPGA (Artix-7) | **FPGA Sigma-Delta ADC** | **FPGA-SENSING-DESIGN.md** ⭐ |
| **Stage 3** | ASIC RISC-V | ASIC integrated Σ-Δ | FPGA-SENSING-DESIGN.md (ASIC section) |

### Universal Components (All Stages)

**Power Stage:** (Build once, use for all stages)
- 2× H-bridges (8 power switches)
- 3× AMC1301 isolated voltage sensors
- 1× ACS724 isolated current sensor
- Outputs: 4× pre-scaled analog signals (0-3.3V)

**Details:** See MODULAR_ARCHITECTURE_GUIDE.md

---

## Design Decision Tree

```
Are you implementing Stage 2 (FPGA)?
├─ YES → Read FPGA-SENSING-DESIGN.md
│         ├─ Want educational/thesis value? → Use FPGA Σ-Δ ADC
│         ├─ Want simplest route? → Use external MCP3208
│         └─ Planning ASIC later? → Use FPGA Σ-Δ ADC (direct port)
│
└─ NO → What stage are you building?
    ├─ Stage 1 (STM32 only)
    │   └─ Read: MODULAR_ARCHITECTURE_GUIDE.md (Stage 1 section)
    │
    └─ Stage 3 (ASIC)
        └─ Read: FPGA-SENSING-DESIGN.md (ASIC Migration section)
```

---

## Key Design Choices

### ✅ Why FPGA Sigma-Delta ADC? (Stage 2 Recommendation)

| Criterion | FPGA Σ-Δ ADC | External ADC Chip | STM32 Internal |
|-----------|--------------|-------------------|----------------|
| **ASIC Portable** | ✅ Yes (pure RTL) | ❌ No | ❌ No |
| **Cost** | $7 (comparator) | $15 (chip + isolation) | $0 |
| **Educational Value** | ⭐⭐⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐ |
| **Complexity** | Medium | Low | Low |
| **Resolution** | 12-14 bit ENOB | 12-24 bit | 12 bit |

**Verdict:** FPGA Σ-Δ ADC is best for thesis/learning and ASIC migration.

### Component Sourcing (Turkey)

**Available Locally (Direnc.net, SAMM):**
- ✅ STM32 Nucleo boards
- ✅ Resistors, capacitors (voltage dividers)
- ✅ LM339 comparator
- ✅ Basic passives

**Order from AliExpress:**
- AMC1301 modules (isolated amplifiers)
- ACS724 current sensor
- B0505S isolated DC-DC converters
- FPGA dev board (Basys 3 or clone)

**Details:** See ADC_SELECTION_AND_ISOLATION_GUIDE.md (Turkey Sourcing section)

---

## Complete Bill of Materials

### Option A: FPGA Sigma-Delta ADC (Recommended)

| Category | Cost | Document |
|----------|------|----------|
| Universal Power Stage | $181 | MODULAR_ARCHITECTURE_GUIDE.md |
| FPGA Board | $150 | FPGA-SENSING-DESIGN.md |
| Comparator Interface | $7 | FPGA-SENSING-DESIGN.md |
| Connectors/Misc | $3 | - |
| **TOTAL** | **$341** | - |

### Option B: External ADC Chip (Simpler)

| Category | Cost | Document |
|----------|------|----------|
| Universal Power Stage | $181 | MODULAR_ARCHITECTURE_GUIDE.md |
| FPGA Board | $150 | - |
| MCP3208 ADC + Isolation | $15 | ADC_SELECTION_AND_ISOLATION_GUIDE.md |
| Interface PCB | $10 | - |
| **TOTAL** | **$356** | - |

**Savings with FPGA Σ-Δ ADC: $15** (plus better educational value!)

---

## Implementation Roadmap

### Phase 1: Universal Power Stage
**Duration:** 2 weeks
**Documents:**
- MODULAR_ARCHITECTURE_GUIDE.md
- ADC_SELECTION_AND_ISOLATION_GUIDE.md (isolation circuits)
- 04-hardware/schematics/03-Current-Voltage-Sensing.md

**Tasks:**
- [ ] Order components (AMC1301, ACS724, power switches)
- [ ] Design power stage PCB (15×20cm)
- [ ] Assemble and test with dummy load
- [ ] Verify sensor outputs: 4× 0-3.3V analog signals

### Phase 2: FPGA ADC Implementation
**Duration:** 2 weeks
**Documents:**
- FPGA-SENSING-DESIGN.md (primary)

**Tasks:**
- [ ] Build comparator interface board (5×5cm)
- [ ] Implement Sigma-Delta modulator (Verilog)
- [ ] Implement CIC decimation filter (Verilog)
- [ ] Simulate with testbench
- [ ] Synthesize and test on FPGA
- [ ] Calibrate with known voltages

### Phase 3: Integration & Control
**Duration:** 2 weeks
**Documents:**
- FPGA-SENSING-DESIGN.md (integration section)
- 03-fpga/README.md (existing PWM code)

**Tasks:**
- [ ] Connect ADC to existing PWM generator
- [ ] Implement PR current controller (Verilog)
- [ ] Implement PI voltage controller (Verilog)
- [ ] Closed-loop testing
- [ ] Measure THD, efficiency

### Phase 4: ASIC Design (Optional)
**Duration:** 4-8 weeks
**Documents:**
- FPGA-SENSING-DESIGN.md (ASIC migration section)

**Tasks:**
- [ ] Port Verilog to ASIC flow (OpenLane)
- [ ] Add analog comparator (SkyWater SKY130)
- [ ] Simulate mixed-signal design
- [ ] Submit to MPW shuttle
- [ ] Wait for fabrication (6-9 months)
- [ ] Test ASIC chips

---

## Frequently Asked Questions

### Q1: Do I need to read all these documents?

**A: No!** Use this priority:
1. **Must read:** FPGA-SENSING-DESIGN.md (if doing FPGA ADC)
2. **Should read:** MODULAR_ARCHITECTURE_GUIDE.md (system overview)
3. **Reference:** ADC_SELECTION_AND_ISOLATION_GUIDE.md (component sourcing)

### Q2: Which approach should I use for Stage 2?

**A:** Depends on goals:
- **Thesis/Learning/ASIC path:** FPGA Sigma-Delta ADC ✅
- **Quick prototype:** STM32 internal ADC
- **Maximum resolution:** External ADS1256 module

### Q3: Can I skip the FPGA and go straight to ASIC?

**A:** Not recommended. FPGA is the **prototyping platform** for ASIC:
1. Test algorithms on FPGA first
2. Verify Verilog code works
3. Then port to ASIC with confidence

### Q4: How do I get started?

**A: Follow this path:**

```
Day 1-2:   Read MODULAR_ARCHITECTURE_GUIDE.md (understand system)
Day 3-5:   Read FPGA-SENSING-DESIGN.md (understand ADC design)
Day 6-10:  Order components (power stage + FPGA + comparators)
Week 2-3:  Build power stage PCB
Week 4-5:  Implement FPGA ADC (Verilog)
Week 6-7:  Integration and testing
Week 8:    Documentation and thesis writeup
```

---

## Document Version History

| Date | Change | Author |
|------|--------|--------|
| 2025-12-02 | Created index, consolidated FPGA ADC design | AI Assistant |
| 2025-11-29 | Original modular architecture guide | AI Assistant |
| 2025-11-29 | Original ADC selection guide | AI Assistant |

---

## Need Help?

**For implementation questions:**
- Check the relevant document first (see navigation above)
- Review the FAQ section
- Consult datasheets (linked in each document)

**For component sourcing in Turkey:**
- See ADC_SELECTION_AND_ISOLATION_GUIDE.md (Turkey Sourcing section)
- Contact: Direnc.net, SAMM Teknoloji
- International: AliExpress, DigiKey, Mouser

**For FPGA/Verilog help:**
- See 03-fpga/README.md (simulation guide)
- Reference existing modules (carrier_generator.v, etc.)
- Xilinx Vivado documentation

---

**This index will help you navigate the documentation efficiently!**
**Start with FPGA-SENSING-DESIGN.md for the complete Stage 2 implementation.**
