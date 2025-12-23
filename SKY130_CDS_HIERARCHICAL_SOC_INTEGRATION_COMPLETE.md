# Complete Guide: SKY130 CDS Hierarchical SOC Integration
**RTL to GDSII Flow for Multi-Macro SOC Design**

**Date:** 2025-12-23
**Author:** Complete Integration Workflow Guide
**Target:** SKY130 PDK + Cadence Digital Suite (Genus + Innovus)

---

## Table of Contents

1. [Overview](#1-overview)
2. [Prerequisites](#2-prerequisites)
3. [Design Hierarchy](#3-design-hierarchy)
4. [Standard SKY130_CDS Flow for Leaf Macros](#4-standard-sky130_cds-flow-for-leaf-macros)
5. [Hierarchical Integration Flow](#5-hierarchical-integration-flow)
6. [Complete Script Examples](#6-complete-script-examples)
7. [Step-by-Step Workflow](#7-step-by-step-workflow)
8. [Troubleshooting](#8-troubleshooting)

---

## 1. Overview

### 1.1 What is Hierarchical Integration?

In ASIC design, **hierarchical integration** means:
- Building individual blocks (macros) separately → **leaf macros**
- Hardening each macro to produce GDS, LEF, and timing models
- Integrating hardened macros into a top-level SOC → **integration**
- Generating final merged GDSII

```
┌────────────────────────────────────────────────────────────────┐
│                    HIERARCHICAL SOC FLOW                        │
└────────────────────────────────────────────────────────────────┘

STAGE 1: Build Leaf Macros (in parallel)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  CPU Macro          UART Macro         PWM Macro          ADC Macro
  ┌────────┐         ┌────────┐         ┌────────┐        ┌────────┐
  │  RTL   │         │  RTL   │         │  RTL   │        │  RTL   │
  └────┬───┘         └────┬───┘         └────┬───┘        └────┬───┘
       ↓                  ↓                  ↓                   ↓
  ┌────────┐         ┌────────┐         ┌────────┐        ┌────────┐
  │ Synth  │         │ Synth  │         │ Synth  │        │ Synth  │
  └────┬───┘         └────┬───┘         └────┬───┘        └────┬───┘
       ↓                  ↓                  ↓                   ↓
  ┌────────┐         ┌────────┐         ┌────────┐        ┌────────┐
  │  P&R   │         │  P&R   │         │  P&R   │        │  P&R   │
  └────┬───┘         └────┬───┘         └────┬───┘        └────┬───┘
       ↓                  ↓                  ↓                   ↓
  ┌────────┐         ┌────────┐         ┌────────┐        ┌────────┐
  │ GDS+LEF│         │ GDS+LEF│         │ GDS+LEF│        │ GDS+LEF│
  └────┬───┘         └────┬───┘         └────┬───┘        └────┬───┘
       │                  │                  │                   │
       └──────────────────┴──────────────────┴───────────────────┘
                                 ↓
STAGE 2: SOC Integration
━━━━━━━━━━━━━━━━━━━━━━━━━
                    ┌──────────────────┐
                    │ Integration RTL  │ (glue logic only)
                    │ + Macro Netlists │
                    └────────┬─────────┘
                             ↓
                    ┌──────────────────┐
                    │   Genus Synth    │ (glue logic only,
                    │                  │  macros are black boxes)
                    └────────┬─────────┘
                             ↓
                    ┌──────────────────┐
                    │  Innovus P&R     │ (place macros first,
                    │                  │  then route glue logic)
                    └────────┬─────────┘
                             ↓
                    ┌──────────────────┐
                    │ Merge GDS Files  │ (streamOut with -merge)
                    └────────┬─────────┘
                             ↓
                    ┌──────────────────┐
                    │  SOC_TOP.gds     │ ✅ FINAL OUTPUT
                    └──────────────────┘
```

### 1.2 Benefits of Hierarchical Flow

✅ **Parallel Development**: Multiple engineers can work on different macros
✅ **Faster Iteration**: Fix one macro without re-running entire SOC
✅ **Better Timing**: Each macro is optimized independently
✅ **Reusability**: Use same macro in multiple SOCs
✅ **Scalability**: Add/remove macros easily

### 1.3 Key Outputs from Each Stage

**From Each Leaf Macro:**
- `.gds` - Physical layout (for merging)
- `.lef` - Abstract view (for placement)
- `.lib` - Timing model (for STA)
- `.v` - Verilog netlist (for integration)

**From SOC Integration:**
- `soc_top.gds` - Final merged layout
- Timing reports - Full SOC timing
- Power/area reports - Full SOC metrics

---

## 2. Prerequisites

### 2.1 Required Tools

1. **Cadence Genus** - Logic synthesis
2. **Cadence Innovus** - Place & Route
3. **SKY130 PDK** - Process Design Kit from SkyWater

### 2.2 SKY130_CDS Infrastructure

**What is SKY130_CDS?**
- A standardized template/infrastructure for building SKY130 designs with Cadence tools
- Provides standard Makefiles, TCL scripts, and directory structure
- Used by OpenLane and other academic flows

**Directory Structure:**
```
your_macro/
├── Makefile                  # Standard: make synth, make pr
├── genus_script.tcl          # Standard synthesis script
├── setup.tcl                 # Standard setup (LEF, libs, etc.)
├── init.tcl                  # Standard floorplan/init
├── route.tcl                 # Standard routing
├── signoff.tcl               # Standard signoff (GDS generation)
├── rtl/                      # Your RTL files
│   └── your_module.v
└── outputs/
    ├── netlist.vh            # After synthesis
    ├── macro.lef             # After P&R
    └── macro.gds             # After signoff
```

**Standard Makefile Commands:**
```bash
make synth    # Run Genus synthesis
make pr       # Run Innovus place & route (init + place + cts + route + signoff)
make clean    # Clean outputs
```

---

## 3. Design Hierarchy

### 3.1 RISC-V SOC Hierarchy

For our 5-level inverter RISC-V SOC:

```
soc_top (TOP LEVEL - INTEGRATION)
├── cpu_macro ★ (LEAF MACRO)
│   ├── custom_riscv_core
│   ├── regfile
│   ├── alu
│   └── decoder
├── uart_macro ★ (LEAF MACRO)
│   └── uart
├── pwm_macro ★ (LEAF MACRO)
│   └── pwm_accelerator
├── adc_macro ★ (LEAF MACRO)
│   └── sigma_delta_adc
├── timer_macro ★ (LEAF MACRO)
│   └── timer
├── gpio_macro ★ (LEAF MACRO)
│   └── gpio
├── protection_macro ★ (LEAF MACRO)
│   └── protection
├── wishbone_interconnect (GLUE LOGIC - synthesized with integration)
└── sram_macros (FROM PDK - pre-built)
    ├── ram_banks (48x)
    └── rom_banks (16x)
```

### 3.2 What Gets Built Separately vs Together

**LEAF MACROS (build separately, in parallel):**
- ✅ CPU core
- ✅ UART peripheral
- ✅ PWM accelerator
- ✅ Sigma-delta ADC
- ✅ Timer
- ✅ GPIO
- ✅ Protection

**INTEGRATION (build together at top level):**
- ✅ Wishbone interconnect (glue logic)
- ✅ Clock distribution
- ✅ Reset synchronizer
- ✅ Top-level wiring

**FROM PDK (use as-is):**
- ✅ SRAM macros (RAM/ROM)

---

## 4. Standard SKY130_CDS Flow for Leaf Macros

### 4.1 Can You Use Standard Makefiles?

**YES!** ✅

The standard `sky130_cds` Makefiles (`make synth`, `make pr`) work perfectly for **leaf macros**.

**What Works:**
```bash
cd cpu_macro/
make synth    # ✅ Synthesizes CPU RTL → netlist
make pr       # ✅ Place & route → GDS + LEF
```

**Outputs You Get:**
- `outputs/cpu_macro.vh` - Verilog netlist
- `outputs/cpu_macro.lef` - LEF abstract
- `outputs/cpu_macro.gds` - GDSII layout
- `outputs/cpu_macro.lib` - Liberty timing model (if configured)

### 4.2 Standard Leaf Macro Scripts

**Example: CPU Macro using Standard Flow**

**`cpu_macro/genus_script.tcl` (STANDARD - no changes needed):**
```tcl
# Standard Genus script from sky130_cds
source setup.tcl

# Read RTL
read_hdl {
    rtl/custom_riscv_core.v
    rtl/regfile.v
    rtl/alu.v
    rtl/decoder.v
}

# Elaborate
elaborate custom_riscv_core

# Clock constraint (100 MHz)
create_clock -name clk -period 10.0 [get_ports clk]

# Synthesis
syn_generic
syn_map
syn_opt

# Write netlist
write_hdl > outputs/cpu_macro.vh
write_sdc > outputs/cpu_macro.sdc
```

**`cpu_macro/setup.tcl` (STANDARD - from sky130_cds):**
```tcl
# Standard setup from sky130_cds template
set PDK_ROOT $::env(PDK_ROOT)
set TECH_LEF ${PDK_ROOT}/sky130A/libs.ref/sky130_fd_sc_hd/techlef/sky130_fd_sc_hd__nom.tlef

# Read tech LEF
read_physical -lefs $TECH_LEF

# Read timing library
read_libs ${PDK_ROOT}/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib
```

**`cpu_macro/init.tcl` (STANDARD - defines floorplan):**
```tcl
# Standard init from sky130_cds
source setup.tcl

# Read netlist from synthesis
read_netlist outputs/cpu_macro.vh

# Init design
init_design

# Floorplan (200um x 200um for CPU)
floorPlan -site unithd -s 200 200 5 5 5 5

# Power rings
addRing -nets {VPWR VGND} ...
```

**`cpu_macro/Makefile` (STANDARD from sky130_cds):**
```makefile
# Standard Makefile from sky130_cds template

.PHONY: synth pr clean

synth:
	genus -f genus_script.tcl -log logs/genus.log

pr: init place cts route signoff

init:
	innovus -init init.tcl -log logs/init.log

place:
	innovus -init place.tcl -log logs/place.log

cts:
	innovus -init cts.tcl -log logs/cts.log

route:
	innovus -init route.tcl -log logs/route.log

signoff:
	innovus -init signoff.tcl -log logs/signoff.log

clean:
	rm -rf outputs/* logs/*
```

### 4.3 What You MUST Change for Each Macro

Even though the **structure** is standard, you must customize:

1. **RTL file list** (in `genus_script.tcl`)
2. **Module name** (in `elaborate` command)
3. **Floorplan size** (in `init.tcl`) - different macros need different sizes
4. **Clock period** (if different performance targets)

**Example Floorplan Sizes:**

| Macro | Size (µm²) | Utilization | Estimated Gates |
|-------|-----------|-------------|-----------------|
| CPU   | 200 × 200 | 60% | ~5,000 |
| UART  | 80 × 80   | 50% | ~500 |
| PWM   | 100 × 100 | 55% | ~1,500 |
| ADC   | 120 × 120 | 55% | ~2,000 |
| Timer | 60 × 60   | 50% | ~300 |
| GPIO  | 100 × 100 | 50% | ~800 |
| Protection | 80 × 80 | 50% | ~600 |

---

## 5. Hierarchical Integration Flow

### 5.1 Key Differences: Leaf vs Integration

| Aspect | Leaf Macro | Integration |
|--------|-----------|-------------|
| **RTL Input** | Your RTL code | Macro netlists + glue RTL |
| **Synthesis** | Full synthesis | Only glue logic |
| **set_dont_touch** | No | ✅ YES (macros are black boxes) |
| **LEF Files** | Tech LEF only | Tech LEF + macro LEFs |
| **Placement** | Place all cells | Place macros first (fixed), then glue logic |
| **GDS Output** | Single GDS | Merged GDS with `-merge` option |

### 5.2 Files Needed from Each Leaf Macro

After building each leaf macro with `make pr`, you need these files for integration:

```
cpu_macro/outputs/
├── cpu_macro.vh         # Verilog netlist (for read_hdl)
├── cpu_macro.lef        # LEF abstract (for read_physical)
├── cpu_macro.gds        # GDSII layout (for streamOut -merge)
└── cpu_macro.lib        # Timing model (for timing analysis)
```

### 5.3 Integration Directory Structure

**Create separate directory for integration:**

```
soc_integration/
├── Makefile_integrated           # NEW: Integration Makefile
├── genus_script_integrated.tcl   # NEW: Modified for integration
├── setup_integrated.tcl          # NEW: Reads macro LEFs
├── init_integrated.tcl           # NEW: Places macros
├── signoff_integrated.tcl        # NEW: Merges GDS files
├── route.tcl                     # STANDARD: Can reuse
├── cts.tcl                       # STANDARD: Can reuse
├── rtl/
│   └── soc_top.v                 # Integration RTL (glue logic only)
├── macros/                       # NEW: Copy outputs from leaf macros
│   ├── cpu_macro.vh
│   ├── cpu_macro.lef
│   ├── cpu_macro.gds
│   ├── cpu_macro.lib
│   ├── uart_macro.vh
│   ├── uart_macro.lef
│   ├── uart_macro.gds
│   └── ... (all other macros)
└── outputs/
    └── soc_top.gds              # FINAL MERGED GDS ✅
```

---

## 6. Complete Script Examples

### 6.1 Integration Synthesis Script

**`soc_integration/genus_script_integrated.tcl`:**

```tcl
#===============================================================================
# Genus Script for SOC Integration (Hierarchical Flow)
# Purpose: Synthesize ONLY glue logic, treat macros as black boxes
#===============================================================================

source setup_integrated.tcl

#===============================================================================
# Step 1: Read Pre-Built Macro Netlists
#===============================================================================

puts "Reading pre-built macro netlists..."

# Read netlist for each hardened macro
read_hdl macros/cpu_macro.vh
read_hdl macros/uart_macro.vh
read_hdl macros/pwm_macro.vh
read_hdl macros/adc_macro.vh
read_hdl macros/timer_macro.vh
read_hdl macros/gpio_macro.vh
read_hdl macros/protection_macro.vh

# Mark these modules as black boxes (don't synthesize them!)
set_dont_touch custom_riscv_core
set_dont_touch uart
set_dont_touch pwm_accelerator
set_dont_touch sigma_delta_adc
set_dont_touch timer
set_dont_touch gpio
set_dont_touch protection

#===============================================================================
# Step 2: Read Integration RTL (Glue Logic Only)
#===============================================================================

puts "Reading integration RTL (glue logic)..."

# Read top-level RTL
read_hdl {
    rtl/soc_top.v
    rtl/wishbone_interconnect.v
    rtl/wishbone_arbiter_2x1.v
    rtl/reset_synchronizer.v
}

# Don't read macro RTL - we use netlists instead!

#===============================================================================
# Step 3: Elaborate Top-Level Design
#===============================================================================

puts "Elaborating top-level SOC..."

elaborate soc_top

# Check design
check_design -unresolved

#===============================================================================
# Step 4: Apply Top-Level Constraints
#===============================================================================

puts "Applying top-level constraints..."

# System clock (50 MHz)
create_clock -name clk -period 20.0 [get_ports clk]

# Input/output delays
set_input_delay 2.0 -clock clk [all_inputs]
set_output_delay 2.0 -clock clk [all_outputs]

# Set don't touch on macro instances
set_dont_touch [get_cells u_cpu]
set_dont_touch [get_cells u_uart]
set_dont_touch [get_cells u_pwm]
set_dont_touch [get_cells u_adc]
set_dont_touch [get_cells u_timer]
set_dont_touch [get_cells u_gpio]
set_dont_touch [get_cells u_protection]

# Timing budgets for macro interfaces
# (Set input delay for signals coming FROM macros)
set_input_delay 3.0 -clock clk [get_pins u_cpu/*_out]
set_output_delay 3.0 -clock clk [get_pins u_cpu/*_in]

# Repeat for all macros...

#===============================================================================
# Step 5: Synthesize (Only Glue Logic!)
#===============================================================================

puts "Synthesizing glue logic only..."

# Synthesis
syn_generic
syn_map
syn_opt

# The macros are NOT synthesized - they're already hardened!

#===============================================================================
# Step 6: Write Outputs
#===============================================================================

puts "Writing integrated netlist..."

# Write integrated netlist (includes macro instances + glue logic)
write_hdl > outputs/soc_integrated.vh
write_sdc > outputs/soc_integrated.sdc

puts "Integration synthesis complete!"
```

### 6.2 Integration Setup Script

**`soc_integration/setup_integrated.tcl`:**

```tcl
#===============================================================================
# Setup for SOC Integration
# Difference from standard: Reads macro LEF files
#===============================================================================

set PDK_ROOT $::env(PDK_ROOT)

# Tech LEF (standard)
set TECH_LEF ${PDK_ROOT}/sky130A/libs.ref/sky130_fd_sc_hd/techlef/sky130_fd_sc_hd__nom.tlef

# Standard cell library (standard)
set STD_CELL_LIB ${PDK_ROOT}/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib

#===============================================================================
# Read Technology Files (Standard)
#===============================================================================

read_physical -lefs $TECH_LEF
read_libs $STD_CELL_LIB

#===============================================================================
# ✅ NEW: Read Macro LEF Files
#===============================================================================

puts "Reading macro LEF files..."

read_physical -lefs macros/cpu_macro.lef
read_physical -lefs macros/uart_macro.lef
read_physical -lefs macros/pwm_macro.lef
read_physical -lefs macros/adc_macro.lef
read_physical -lefs macros/timer_macro.lef
read_physical -lefs macros/gpio_macro.lef
read_physical -lefs macros/protection_macro.lef

# Read SRAM macros from PDK
read_physical -lefs ${PDK_ROOT}/sky130A/libs.ref/sky130_sram_2kbyte_1rw1r/lef/sky130_sram_2kbyte_1rw1r.lef

#===============================================================================
# ✅ NEW: Read Macro Timing Libraries
#===============================================================================

puts "Reading macro timing libraries..."

read_libs macros/cpu_macro.lib
read_libs macros/uart_macro.lib
read_libs macros/pwm_macro.lib
read_libs macros/adc_macro.lib
read_libs macros/timer_macro.lib
read_libs macros/gpio_macro.lib
read_libs macros/protection_macro.lib

# Read SRAM timing models
read_libs ${PDK_ROOT}/sky130A/libs.ref/sky130_sram_2kbyte_1rw1r/lib/sky130_sram_2kbyte_1rw1r_ss_1p65v_25c.lib
```

### 6.3 Integration Floorplan/Init Script

**`soc_integration/init_integrated.tcl`:**

```tcl
#===============================================================================
# Innovus Init for SOC Integration
# Key difference: Place macros FIRST with fixed locations
#===============================================================================

source setup_integrated.tcl

# Read integrated netlist from synthesis
read_netlist outputs/soc_integrated.vh

# Init design
init_design

#===============================================================================
# ✅ NEW: Larger Floorplan for SOC (includes all macros)
#===============================================================================

puts "Creating SOC floorplan..."

# SOC needs larger die
# Estimate: 7 macros + glue logic + SRAMs ≈ 800µm × 800µm
floorPlan -site unithd -s 800 800 20 20 20 20

#===============================================================================
# ✅ NEW: Place Macros with Fixed Locations
#===============================================================================

puts "Placing macros at fixed locations..."

# Place CPU in center-left
placeInstance u_cpu 100 300 -fixed

# Place UART top-right
placeInstance u_uart 600 600 -fixed

# Place PWM bottom-left
placeInstance u_pwm 100 100 -fixed

# Place ADC bottom-right
placeInstance u_adc 600 100 -fixed

# Place Timer top-center
placeInstance u_timer 350 650 -fixed

# Place GPIO center-right
placeInstance u_gpio 650 350 -fixed

# Place Protection near CPU
placeInstance u_protection 280 300 -fixed

# Place SRAMs in rows (48 RAM banks + 16 ROM banks)
set ram_x 80
set ram_y 400
for {set i 0} {$i < 48} {incr i} {
    set x [expr $ram_x + ($i % 8) * 70]
    set y [expr $ram_y + ($i / 8) * 60]
    placeInstance ram_bank_$i $x $y -fixed
}

set rom_x 80
set rom_y 200
for {set i 0} {$i < 16} {incr i} {
    set x [expr $rom_x + ($i % 8) * 70]
    set y [expr $rom_y + ($i / 8) * 60]
    placeInstance rom_bank_$i $x $y -fixed
}

# Blockages around macros (prevent glue logic placement too close)
createPlaceBlockage -box {90 290 320 510} -type soft
# ... add more blockages ...

#===============================================================================
# Power Planning (Standard, but for larger die)
#===============================================================================

addRing -nets {VPWR VGND} \
        -width 5 \
        -spacing 2 \
        -layer {top metal5 bottom metal5 left metal4 right metal4}

addStripe -nets {VPWR VGND} \
          -layer metal4 \
          -direction vertical \
          -width 2 \
          -spacing 2 \
          -number_of_sets 10

addStripe -nets {VPWR VGND} \
          -layer metal3 \
          -direction horizontal \
          -width 2 \
          -spacing 2 \
          -number_of_sets 10

# Special route
sroute -nets {VPWR VGND}
```

### 6.4 Integration Signoff Script

**`soc_integration/signoff_integrated.tcl`:**

```tcl
#===============================================================================
# Signoff for SOC Integration
# Key difference: Merge macro GDS files into final output
#===============================================================================

# DRC/LVS verification
verify_drc -report reports/drc.rpt
verify_connectivity -report reports/connectivity.rpt

# Final timing reports
report_timing > reports/final_timing.rpt

#===============================================================================
# ✅ NEW: streamOut with -merge Option
#===============================================================================

puts "Generating final merged GDSII..."

# Standard GDS output path
set PDK_ROOT $::env(PDK_ROOT)
set GDS_MAP ${PDK_ROOT}/sky130A/libs.tech/klayout/tech/sky130A.gds.map

# ✅ KEY: Use -merge to include macro GDS files
streamOut outputs/soc_top.gds \
    -mapFile $GDS_MAP \
    -merge {
        macros/cpu_macro.gds
        macros/uart_macro.gds
        macros/pwm_macro.gds
        macros/adc_macro.gds
        macros/timer_macro.gds
        macros/gpio_macro.gds
        macros/protection_macro.gds
        ${PDK_ROOT}/sky130A/libs.ref/sky130_sram_2kbyte_1rw1r/gds/sky130_sram_2kbyte_1rw1r.gds
    } \
    -units 1000 \
    -mode ALL

puts "Final GDSII written to outputs/soc_top.gds"
puts "This file contains all macros merged together!"
```

### 6.5 Integration Makefile

**`soc_integration/Makefile_integrated`:**

```makefile
#===============================================================================
# Makefile for SOC Integration (Hierarchical Flow)
#===============================================================================

.PHONY: all synth pr init place cts route signoff clean

all: synth pr

#===============================================================================
# Integration Synthesis (Glue Logic Only)
#===============================================================================

synth:
	@echo "==================================================="
	@echo "Synthesizing SOC Integration (glue logic only)..."
	@echo "==================================================="
	mkdir -p outputs logs
	genus -f genus_script_integrated.tcl -log logs/genus_integrated.log

#===============================================================================
# Integration Place & Route
#===============================================================================

pr: init place cts route signoff

init:
	@echo "==================================================="
	@echo "Initializing SOC with macro placement..."
	@echo "==================================================="
	innovus -init init_integrated.tcl -log logs/init_integrated.log

place:
	@echo "==================================================="
	@echo "Placing glue logic around macros..."
	@echo "==================================================="
	innovus -init place.tcl -log logs/place_integrated.log

cts:
	@echo "==================================================="
	@echo "Clock tree synthesis..."
	@echo "==================================================="
	innovus -init cts.tcl -log logs/cts_integrated.log

route:
	@echo "==================================================="
	@echo "Routing SOC..."
	@echo "==================================================="
	innovus -init route.tcl -log logs/route_integrated.log

signoff:
	@echo "==================================================="
	@echo "Signoff: Merging GDS files..."
	@echo "==================================================="
	innovus -init signoff_integrated.tcl -log logs/signoff_integrated.log
	@echo ""
	@echo "✅ SUCCESS! Final GDSII ready:"
	@echo "   outputs/soc_top.gds"
	@echo ""

clean:
	rm -rf outputs/* logs/*
	@echo "Cleaned integration outputs."

#===============================================================================
# Helper: Copy macro outputs from leaf builds
#===============================================================================

copy-macros:
	@echo "Copying macro outputs from leaf builds..."
	mkdir -p macros
	cp ../cpu_macro/outputs/cpu_macro.vh macros/
	cp ../cpu_macro/outputs/cpu_macro.lef macros/
	cp ../cpu_macro/outputs/cpu_macro.gds macros/
	cp ../cpu_macro/outputs/cpu_macro.lib macros/
	# Repeat for all macros...
	cp ../uart_macro/outputs/uart_macro.vh macros/
	cp ../uart_macro/outputs/uart_macro.lef macros/
	cp ../uart_macro/outputs/uart_macro.gds macros/
	cp ../uart_macro/outputs/uart_macro.lib macros/
	# ... etc
	@echo "✅ All macro files copied to macros/ directory"
```

---

## 7. Step-by-Step Workflow

### Phase 1: Build All Leaf Macros

**Run standard flow for EACH macro:**

```bash
# Terminal 1: Build CPU
cd cpu_macro/
make synth    # ✅ Synthesis
make pr       # ✅ Place & Route
# Output: cpu_macro.vh, cpu_macro.lef, cpu_macro.gds, cpu_macro.lib

# Terminal 2: Build UART (parallel!)
cd uart_macro/
make synth
make pr
# Output: uart_macro.vh, uart_macro.lef, uart_macro.gds, uart_macro.lib

# Terminal 3: Build PWM (parallel!)
cd pwm_macro/
make synth
make pr
# Output: pwm_macro.vh, pwm_macro.lef, pwm_macro.gds, pwm_macro.lib

# ... Repeat for ADC, Timer, GPIO, Protection
```

**Verify Each Macro:**

After each macro build, check:
```bash
cd cpu_macro/
ls -lh outputs/
# Should see:
#   cpu_macro.vh    (netlist)
#   cpu_macro.lef   (abstract)
#   cpu_macro.gds   (layout)
#   cpu_macro.lib   (timing)

# Check timing met
grep "slack" reports/timing.rpt
# Should see positive slack

# Check DRC clean
grep "Violation" reports/drc.rpt
# Should see zero violations
```

### Phase 2: Prepare Integration

```bash
cd soc_integration/

# Copy macro outputs
make -f Makefile_integrated copy-macros
# ✅ All .vh, .lef, .gds, .lib files copied to macros/

# Verify files
ls -lh macros/
# Should see all macro files
```

### Phase 3: Run Integration

```bash
cd soc_integration/

# Step 1: Synthesize glue logic
make -f Makefile_integrated synth
# ✅ Creates outputs/soc_integrated.vh (glue logic only, macros are black boxes)

# Step 2: Place & Route
make -f Makefile_integrated pr
# This runs: init → place → cts → route → signoff
# ✅ Creates outputs/soc_top.gds (MERGED GDS with all macros!)
```

### Phase 4: Verify Final Output

```bash
cd soc_integration/

# Check final GDSII exists
ls -lh outputs/soc_top.gds
# Should be ~100-500 MB (contains all macros)

# Check timing closure
grep "slack" reports/final_timing.rpt
# All paths should have positive slack

# Check DRC
grep "Violation" reports/drc.rpt
# Should be zero violations

# View in layout viewer
klayout outputs/soc_top.gds
# You should see all 7 macros + 64 SRAMs placed!
```

---

## 8. Troubleshooting

### Issue 1: "Cannot find macro netlist"

**Error:**
```
ERROR: Cannot resolve reference to module 'custom_riscv_core'
```

**Cause:** Macro netlist not read or wrong path

**Fix:**
```tcl
# In genus_script_integrated.tcl, check:
read_hdl macros/cpu_macro.vh  # ✅ Correct path?
```

### Issue 2: "Macro has no LEF view"

**Error:**
```
ERROR: Cell 'custom_riscv_core' has no LEF view
```

**Cause:** LEF file not read or incomplete

**Fix:**
```tcl
# In setup_integrated.tcl, check:
read_physical -lefs macros/cpu_macro.lef

# Verify LEF exists:
ls -lh macros/cpu_macro.lef

# Verify LEF is complete (should have MACRO block):
grep "MACRO custom_riscv_core" macros/cpu_macro.lef
```

### Issue 3: "GDS merge failed"

**Error:**
```
ERROR: Cannot open GDS file: macros/cpu_macro.gds
```

**Cause:** GDS file missing or corrupted

**Fix:**
```bash
# Check GDS exists and is not zero-size
ls -lh macros/*.gds

# If zero-size, macro P&R didn't complete correctly
cd ../cpu_macro/
make pr  # Re-run P&R
```

### Issue 4: "Timing violation at integration level"

**Symptom:** Macros meet timing individually, but integration fails

**Cause:** Interface timing budget too tight

**Fix:**
```tcl
# In genus_script_integrated.tcl, relax interface budgets:
set_input_delay 5.0 -clock clk [get_pins u_cpu/*_out]  # Was 3.0
set_output_delay 5.0 -clock clk [get_pins u_cpu/*_in]  # Was 3.0
```

### Issue 5: "Macros overlap in placement"

**Symptom:** Innovus errors about overlapping instances

**Cause:** Macro placement coordinates conflict

**Fix:**
```tcl
# In init_integrated.tcl, check placement coordinates:
placeInstance u_cpu 100 300 -fixed
placeInstance u_uart 600 600 -fixed  # ✅ Far enough from u_cpu?

# Rule: Leave at least (macro_width + 50µm) spacing
```

---

## Summary

### Standard Flow Works for Leaf Macros ✅

**Question:** Can I use standard sky130_cds Makefiles for leaf macros?
**Answer:** **YES!** `make synth` and `make pr` work perfectly.

### Integration Needs Modified Scripts ✅

**What's Different:**
1. **`genus_script_integrated.tcl`** - Read netlists, set_dont_touch
2. **`setup_integrated.tcl`** - Read macro LEFs and libs
3. **`init_integrated.tcl`** - Place macros first
4. **`signoff_integrated.tcl`** - streamOut with `-merge`

### Final Output ✅

After all steps complete, you get:
```
soc_integration/outputs/soc_top.gds
```

This single GDSII file contains:
- ✅ All 7 hardened leaf macros
- ✅ All 64 SRAM macros
- ✅ All glue logic (interconnect, clock tree, etc.)
- ✅ Fully routed and verified

**This is your final chip layout ready for fabrication!** 🎉

---

**Document Version:** 1.0
**Last Updated:** 2025-12-23
**Next:** Tape-out via university shuttle program or continue to ASIC validation
