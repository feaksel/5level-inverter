# MATLAB/Simulink Simulation - 5-Level Inverter

**Track 1:** System modeling and validation

---

## Overview

This directory contains the Simulink model for complete 5-level cascaded H-bridge multilevel inverter system simulation. The model serves as the **reference implementation** for validating all hardware implementations (STM32, FPGA, RISC-V).

**Model Purpose:**
- System-level validation before hardware implementation
- Control algorithm development and tuning
- Performance prediction (THD, efficiency, waveforms)
- Educational demonstration of multilevel inverter operation

---

## Model: inverter_1.slx

**Contains:**
- 2× Cascaded H-bridge power stage (8 switches)
- Level-shifted PWM modulation
- PR (Proportional-Resonant) current controller
- PI voltage controller
- Load models (resistive, inductive, non-linear)
- Measurement and visualization blocks

**Topology Simulated:**
- DC Input: 2× 50V isolated sources
- AC Output: 100V RMS, 50Hz
- Switching Frequency: 10 kHz
- Output Levels: 5 (+100V, +50V, 0V, -50V, -100V)

---

## Requirements

### Software
- **MATLAB**: R2020b or later
- **Simulink**: Included with MATLAB
- **Required Toolboxes:**
  - Simulink
  - Simscape Electrical (formerly SimPowerSystems)
  - Control System Toolbox

### Hardware
- **RAM**: Minimum 8 GB
- **Disk**: ~500 MB free space

---

## How to Run

1. **Open MATLAB** and navigate to this directory:
   ```matlab
   cd /path/to/5level-inverter/01-simulation
   ```

2. **Open Simulink Model:**
   ```matlab
   open('inverter_1.slx')
   ```

3. **Run Simulation:**
   - Click "Run" button (▶) in toolbar
   - Or press `Ctrl+T`
   - Or command line: `sim('inverter_1')`

4. **View Results** in automatically opened scopes:
   - Output voltage waveform
   - Output current waveform
   - PWM gate signals
   - THD spectrum
   - 5-level voltage synthesis

---

## Expected Results

| Metric | Expected Value |
|--------|----------------|
| **Output Voltage** | 100V RMS @ 50Hz |
| **THD** | < 5% (typically 3-4%) |
| **Efficiency** | > 95% |
| **Switching Frequency** | 10 kHz |
| **Voltage Levels** | 5 distinct levels visible |

---

## Model Parameters

Key parameters (can be modified in model):

```matlab
V_dc = 50;           % DC voltage per bridge (V)
f_sw = 10e3;         % Switching frequency (Hz)
f_out = 50;          % Output frequency (Hz)
V_out_rms = 100;     % Target output voltage (V RMS)
R_load = 20;         % Load resistance (Ω)
```

---

## Validation

Compare simulation results with hardware:
1. Export simulation data to `.mat` file
2. Use comparison tool in `06-tools/analysis/`:
   ```matlab
   compare_with_simulink('sim_results.mat', 'hw_results.mat')
   ```

**Acceptance Criteria:**
- Voltage RMS difference: < 2%
- THD difference: < 1 percentage point

---

## Troubleshooting

**Issue:** Model won't open
- Check MATLAB version (R2020b+)
- Verify required toolboxes installed

**Issue:** Simulation runs slowly
- Increase max step size
- Reduce simulation time
- Use faster solver (ode23t)

**Issue:** Numerical instabilities
- Check initial conditions
- Reduce solver tolerance
- Add small resistance to ideal sources

---

## References

- **Simulink Documentation**: https://www.mathworks.com/help/simulink/
- **Level-Shifted PWM Theory**: See `07-docs/01-Level-Shifted-PWM-Theory.md`
- **Multilevel Inverters**: See `07-docs/04-Understanding-5-Level-Topology.md`
