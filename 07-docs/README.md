# Documentation & Technical Guides

This directory contains comprehensive documentation, theory, design guides, and educational content for the 5-level cascaded H-bridge multilevel inverter project.

## Document Overview

### 📘 Theory and Educational

| Document | Description | Audience | Length |
|----------|-------------|----------|--------|
| **01-Level-Shifted-PWM-Theory.md** | Complete theoretical explanation of level-shifted carrier PWM modulation | Technical / Academic | 45+ pages |
| **04-Understanding-5-Level-Topology.md** | Beginner-friendly explanation of multilevel inverters and cascaded H-bridges | Students / Beginners | 35+ pages |

### 🔧 Design and Implementation

| Document | Description | Audience | Length |
|----------|-------------|----------|--------|
| **02-PR-Controller-Design-Guide.md** | Step-by-step guide to designing and tuning Proportional-Resonant controllers | Engineers / Implementers | 40+ pages |
| **05-Hardware-Testing-Procedures.md** | Detailed testing procedures from component-level to full-power validation | Test Engineers | 50+ pages |

### ⚠️ Safety Critical

| Document | Description | Audience | Length |
|----------|-------------|----------|--------|
| **03-Safety-and-Protection-Guide.md** | Safety requirements, protection systems, and emergency procedures | **EVERYONE** (mandatory reading) | 45+ pages |

---

## Quick Navigation

### For Beginners

**Start here if you're new to multilevel inverters:**

1. Read: [`04-Understanding-5-Level-Topology.md`](04-Understanding-5-Level-Topology.md)
   - Learn what an inverter does
   - Understand why multilevel is better
   - See how H-bridges cascade
   - Visual explanations and analogies

2. Read: [`01-Level-Shifted-PWM-Theory.md`](01-Level-Shifted-PWM-Theory.md)
   - Deep dive into modulation theory
   - Mathematical foundations
   - Comparison with other strategies

### For Implementers

**Building or programming the inverter:**

1. **MUST READ:** [`03-Safety-and-Protection-Guide.md`](03-Safety-and-Protection-Guide.md)
   - Electrical hazards
   - Protection requirements
   - Safe operating procedures

2. Read: [`02-PR-Controller-Design-Guide.md`](02-PR-Controller-Design-Guide.md)
   - Control system design
   - Implementation details
   - Tuning procedures

3. Follow: [`05-Hardware-Testing-Procedures.md`](05-Hardware-Testing-Procedures.md)
   - Progressive testing approach
   - Phase-by-phase validation
   - Troubleshooting guide

### For Researchers / Advanced Users

**All documents provide:**
- Academic references
- Mathematical derivations
- Performance analysis
- Design trade-offs

---

## Document Summaries

### 01-Level-Shifted-PWM-Theory.md

**What it covers:**

- Multilevel inverter fundamentals
- 5-level cascaded H-bridge topology
- PWM modulation strategies comparison
- Level-shifted carrier PWM in detail
- Mathematical analysis (Fourier, THD)
- Advantages and limitations
- Practical implementation considerations

**Key sections:**
- Harmonic analysis
- Voltage synthesis explanation
- Switching frequency selection
- Comparison with phase-shifted and space-vector PWM

**Use this for:**
- Understanding modulation theory
- Academic/research work
- Algorithm implementation
- Performance prediction

---

### 02-PR-Controller-Design-Guide.md

**What it covers:**

- Why PR controllers for AC systems
- PR controller theory and transfer functions
- Step-by-step design methodology
- Digital implementation (C code included)
- Tuning procedures and rules of thumb
- Performance analysis
- Troubleshooting common issues

**Key sections:**
- Frequency response analysis
- Discretization using bilinear transform
- Integration with inverter control loop
- Parameter selection guidelines

**Use this for:**
- Designing current control loops
- Implementing PR controllers
- Tuning control parameters
- Debugging control issues

---

### 03-Safety-and-Protection-Guide.md

**⚠️ MANDATORY READING BEFORE ANY HARDWARE WORK**

**What it covers:**

- Electrical hazards (shock, arc flash, fire)
- Protection requirements (overcurrent, overvoltage, thermal)
- Hardware protection implementation
- Software protection architecture
- Safe operating procedures
- Emergency procedures
- Pre-operation checklists

**Key sections:**
- Shoot-through protection (critical!)
- PCB safety design
- Testing safety requirements
- Fault handling strategies

**Use this for:**
- Safety planning
- Protection system design
- Emergency response preparation
- Regulatory compliance

**WARNING:** High voltage (100V+) can be lethal. This document is safety-critical.

---

### 04-Understanding-5-Level-Topology.md

**Educational / Tutorial document**

**What it covers:**

- What is an inverter? (basics)
- 2-level vs multilevel comparison
- H-bridge building block explanation
- Cascading concept with visual aids
- How 5 voltage levels are created
- PWM and modulation (simplified)
- Practical applications
- Common questions answered

**Key features:**
- Beginner-friendly language
- Visual diagrams and analogies
- Step-by-step explanations
- Real-world examples
- Learning path recommendations

**Use this for:**
- Educational purposes
- Introduction to power electronics
- Understanding the project motivation
- Sharing with non-experts

---

### 05-Hardware-Testing-Procedures.md

**Comprehensive test plan**

**What it covers:**

- Progressive testing philosophy
- Required test equipment
- Test environment setup
- 5 testing phases:
  1. Component testing
  2. Subsystem testing
  3. Low-power integration
  4. Full-power testing
  5. Performance validation
- Documentation requirements
- Troubleshooting guide

**Test phases:**

**Phase 1 (2-4h):** Power supplies, MCU, sensors
**Phase 2 (3-6h):** PWM generation, modulation, protection
**Phase 3 (4-8h):** First power-on at 12V
**Phase 4 (2-4h):** Full voltage (50V) and power
**Phase 5 (4-8h):** THD, efficiency, reliability

**Use this for:**
- First-time bring-up
- Validation testing
- Quality assurance
- Troubleshooting hardware issues

---

## System Diagrams

The `/07-docs/` directory also contains system architecture diagrams:

### Abstract System Diagram.png

High-level conceptual diagram showing:
- Power stage
- Control system
- Protection systems
- Signal flow

### Hybrid system diagram.png

Hybrid implementation showing:
- STM32 for control
- FPGA for PWM generation
- Sensor interfaces
- Communication paths

### stm32 only diagram.png

STM32-only implementation:
- All control and PWM on STM32
- Peripheral assignments
- Pin connections

**These diagrams complement the written documentation.**

---

## Additional Resources

### Referenced in Documentation

**Academic Papers:**
- Rodriguez et al., "Multilevel Inverters: A Survey" (IEEE 2002)
- Zmood & Holmes, "Stationary Frame Current Regulation" (IEEE 2003)
- McGrath & Holmes, "Multicarrier PWM Strategies" (IEEE 2002)

**Standards:**
- IEEE 519: Harmonic control in power systems
- IEC 61010-1: Safety requirements for electrical equipment
- IEC 60664-1: Insulation coordination

**Books:**
- "Power Electronics Handbook" by Muhammad H. Rashid
- "Digital Control in Power Electronics" by Buso & Mattavelli
- "Voltage-Sourced Converters in Power Systems" by Yazdani & Iravani

### External Links

**Manufacturer Resources:**
- Texas Instruments: Multilevel inverter app notes
- Infineon: IGBT application guides
- Silicon Labs: Isolated gate driver datasheets

**Software Tools:**
- MATLAB/Simulink: `01-simulation/inverter_1.slx`
- Python Analysis Tools: `06-tools/analysis/`
- Verilog Implementation: `03-fpga/rtl/`

---

## Document Statistics

**Total Pages:** ~215 pages (if printed)
**Total Words:** ~65,000 words
**Total Code Examples:** 50+ snippets
**Total Tables:** 30+
**Total Diagrams:** 15+ (ASCII art included)

**Coverage:**
- ✅ Theory and fundamentals
- ✅ Design methodology
- ✅ Implementation details
- ✅ Safety and protection
- ✅ Testing and validation
- ✅ Troubleshooting
- ✅ Educational content

---

## Contributing to Documentation

### Documentation Standards

**When adding/updating docs:**

1. **Markdown format** (`.md` files)
2. **Clear headings** and table of contents
3. **Code examples** with syntax highlighting
4. **Equations** in standard mathematical notation
5. **References** to sources
6. **Practical examples** where applicable

### Suggested Additions

**Future documentation needs:**

- [ ] FPGA implementation guide (detailed)
- [ ] PCB design guide (when hardware is finalized)
- [ ] EMI/EMC testing procedures
- [ ] Grid-tied operation guide
- [ ] Parallel operation / scalability guide
- [ ] RISC-V implementation guide (Stage 4)
- [ ] ASIC design guide (Stage 5-6)

### Document Review

**Before finalizing new docs:**

- Technical accuracy reviewed
- Tested procedures verified
- Safety warnings included where appropriate
- References checked and cited
- Readable by target audience
- Spell-checked and proofread

---

## FAQ About the Documentation

### Q: Which document should I read first?

**A:** Depends on your background:
- **Complete beginner:** Start with `04-Understanding-5-Level-Topology.md`
- **Engineering student:** Read `01-Level-Shifted-PWM-Theory.md`
- **Building hardware:** Read `03-Safety-and-Protection-Guide.md` FIRST (mandatory)
- **Implementing control:** Read `02-PR-Controller-Design-Guide.md`
- **Testing:** Follow `05-Hardware-Testing-Procedures.md`

### Q: Are these documents complete?

**A:** Yes, for current project scope. They cover:
- All implemented features (STM32 + FPGA)
- Complete theory and design
- Safety and testing

Future enhancements (RISC-V, ASIC) will require additional documentation.

### Q: Can I use this for my own project?

**A:** Yes! Documentation is provided for educational and reference purposes. Please:
- Attribute the source
- Understand safety is YOUR responsibility
- Adapt to your specific requirements
- Verify all information for your application

### Q: I found an error. How do I report it?

**A:** See project repository issues section or contact maintainers.

### Q: Can I contribute improvements?

**A:** Yes! Contributions welcome:
- Corrections and clarifications
- Additional examples
- Improved diagrams
- Translations
- Application notes

---

## Document Change Log

### Version 1.0 (2025-11-15)

**Initial release containing:**
- 01-Level-Shifted-PWM-Theory.md
- 02-PR-Controller-Design-Guide.md
- 03-Safety-and-Protection-Guide.md
- 04-Understanding-5-Level-Topology.md
- 05-Hardware-Testing-Procedures.md
- This README.md

**Total:** 5 comprehensive technical documents + README

---

## License

Documentation is part of the 5-Level Inverter Project.

**Use responsibly:**
- Educational purposes
- Reference for design
- Safety guidelines

**Disclaimer:** While every effort has been made to ensure accuracy, users are responsible for verification and safety in their own applications.

---

## Contact and Support

**For documentation questions:**
- Check FAQ sections in individual documents
- Review troubleshooting sections
- Consult project CLAUDE.md
- See project repository

**For safety concerns:**
- Always prioritize safety
- When in doubt, consult qualified professionals
- Follow local electrical codes and regulations
- Do not exceed your skill level

---

**End of README**

*Thank you for reading! We hope these documents help you understand and implement multilevel inverter technology.*

*Stay safe, and happy learning!*
