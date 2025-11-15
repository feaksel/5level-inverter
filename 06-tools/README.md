# Analysis & Testing Tools

This directory contains Python and MATLAB tools for analyzing, testing, and validating the 5-level inverter implementation.

## Directory Structure

```
06-tools/
├── analysis/               # Data analysis tools
│   ├── waveform_analyzer.py
│   ├── uart_plotter.py
│   └── compare_with_simulink.m
├── scripts/                # Automation scripts
│   └── test_runner.py
└── requirements.txt        # Python dependencies
```

## Python Tools

### Installation

Install Python dependencies:

```bash
cd 06-tools
pip install -r requirements.txt
```

### 1. Waveform Analyzer

Analyzes CSV waveform data logged from the STM32 inverter.

**Features:**
- RMS voltage/current calculation
- THD (Total Harmonic Distortion) analysis
- Harmonic spectrum analysis
- Power calculations (real, apparent, power factor)
- Waveform plotting
- FFT spectrum plots
- Automated report generation

**Usage:**

```bash
# Basic analysis (console output)
python analysis/waveform_analyzer.py data.csv

# With plots
python analysis/waveform_analyzer.py data.csv --plot

# Save plots to file
python analysis/waveform_analyzer.py data.csv --plot --save-fig waveforms.png

# Show FFT spectrum
python analysis/waveform_analyzer.py data.csv --fft --save-fft spectrum.png

# Generate text report
python analysis/waveform_analyzer.py data.csv --report analysis_report.txt

# Custom sampling frequency
python analysis/waveform_analyzer.py data.csv --fs 10000 --plot
```

**Example Output:**

```
Loaded 5000 samples from data.csv
Columns: ['time_ms', 'current_A', 'voltage_V', 'duty1', 'duty2']

=== Current Analysis ===
RMS:        4.523 A
Peak:       6.890 A
Range:      -6.851 to 6.890 A
THD:        3.45%
Fundamental: 6.395 A

=== Voltage Analysis ===
RMS:        98.5 V
Peak:       140.2 V
Range:      -139.8 to 140.2 V
THD:        2.87%
Fundamental: 139.8 V

=== Power Analysis ===
Real Power:     445.5 W
Apparent Power: 445.5 VA
Power Factor:   1.000
```

### 2. Real-Time UART Plotter

Plots live waveform data streaming from STM32 via UART.

**Features:**
- Real-time plotting of current, voltage, and PWM duty cycles
- Auto-scaling axes
- Configurable buffer size
- Error tracking

**Usage:**

```bash
# List available serial ports
python analysis/uart_plotter.py --list

# Start real-time plotting (Linux)
python analysis/uart_plotter.py /dev/ttyUSB0

# Start real-time plotting (Windows)
python analysis/uart_plotter.py COM3

# Custom baud rate and buffer size
python analysis/uart_plotter.py /dev/ttyUSB0 --baud 115200 --samples 2000
```

**Requirements:**
- STM32 must be in **WAVEFORM logging mode** (not STATUS mode)
- UART connected and recognized by OS
- Data format: `time_ms,current_A,voltage_V,duty1,duty2`

**Tips:**
- Close the plot window to exit
- Increase `--samples` for longer time history
- Make sure no other program (e.g., minicom, PuTTY) is using the serial port

### 3. Automated Test Runner

Runs automated test sequences and validates results.

**Features:**
- YAML/JSON test configuration
- Automated data collection
- Result validation (THD, RMS values, etc.)
- JSON output for CI/CD integration
- Pass/fail reporting

**Usage:**

```bash
# Generate example test configuration
python scripts/test_runner.py --example

# Run test suite
python scripts/test_runner.py test_suite.yaml --port /dev/ttyUSB0

# Custom output file
python scripts/test_runner.py test_suite.yaml --port COM3 --output results.json
```

**Example Test Configuration (`test_suite.yaml`):**

```yaml
name: Basic Validation Suite
description: Basic tests for 5-level inverter
tests:
  - name: Test Mode 2 - Normal Operation
    description: 50Hz sine wave at 80% MI
    duration: 15
    validation:
      thd_max: 5.0
      current_rms_min: 3.0
      current_rms_max: 7.0

  - name: Test Mode 3 - Full Power
    description: 50Hz sine wave at 100% MI
    duration: 20
    validation:
      thd_max: 5.0
      current_rms_min: 4.5
      current_rms_max: 5.5
      voltage_rms_min: 95.0
      voltage_rms_max: 105.0
```

**Output (`test_results.json`):**

```json
{
  "test_suite": {
    "timestamp": "2025-11-15T12:34:56",
    "port": "/dev/ttyUSB0",
    "baudrate": 115200
  },
  "tests": [
    {
      "name": "Test Mode 2 - Normal Operation",
      "status": "PASSED",
      "data_points": 1250,
      "validation": {
        "current_rms": 4.52,
        "thd_check": {
          "expected_max": 5.0,
          "actual": 3.45,
          "passed": true
        }
      }
    }
  ]
}
```

## MATLAB Tools

### Compare with Simulink

Compares STM32 implementation results with MATLAB/Simulink simulation.

**Features:**
- Loads CSV data from STM32
- Runs corresponding Simulink model
- Calculates and compares metrics (RMS, THD, harmonics)
- Generates comparison plots
- Pass/fail validation

**Usage:**

```matlab
% In MATLAB command window
cd 06-tools/analysis

% Compare with default Simulink model
compare_with_simulink('stm32_data.csv')

% Compare with specific model
compare_with_simulink('stm32_data.csv', '../../01-simulation/inverter_1.slx')
```

**Output:**
- Console output with metrics and comparison
- Saved figure: `comparison_results.png` with 6 subplots:
  1. Current waveform comparison
  2. Voltage waveform comparison
  3. Current spectrum
  4. Voltage spectrum
  5. Current harmonics
  6. Voltage harmonics

**Example Console Output:**

```
Loading STM32 data from stm32_data.csv...
  Loaded 5000 samples (1.000 seconds)

Running Simulink simulation...
  Simulation complete

=== STM32 Implementation Metrics ===
Current RMS:  4.523 A
Voltage RMS:  98.5 V
Current THD:  3.45%
Voltage THD:  2.87%

=== Simulink Simulation Metrics ===
Current RMS:  4.550 A
Voltage RMS:  99.2 V
Current THD:  3.12%
Voltage THD:  2.65%

=== Comparison (STM32 vs Simulink) ===
Current RMS Error:   0.59%
Voltage RMS Error:   0.71%
Current THD Diff:    0.33% points
Voltage THD Diff:    0.22% points

=== Validation Status ===
✓ PASSED: STM32 matches Simulink within tolerance
```

## Typical Workflow

### 1. Hardware Testing with Live Monitoring

```bash
# Terminal 1: Monitor status messages
screen /dev/ttyUSB0 115200

# Terminal 2: Plot real-time waveforms
python analysis/uart_plotter.py /dev/ttyUSB0
```

### 2. Data Collection and Analysis

```bash
# 1. Set STM32 to WAVEFORM logging mode
# 2. Capture data to CSV file
python -c "import serial; s=serial.Serial('/dev/ttyUSB0',115200); \
[print(s.readline().decode().strip()) for _ in range(5000)]" > data.csv

# 3. Analyze captured data
python analysis/waveform_analyzer.py data.csv --plot --fft --report report.txt
```

### 3. Automated Testing

```bash
# 1. Create test configuration
python scripts/test_runner.py --example

# 2. Edit test_suite_example.yaml as needed

# 3. Run automated tests
python scripts/test_runner.py test_suite_example.yaml

# 4. Review results
cat test_results.json
```

### 4. Validation Against Simulink

```matlab
% In MATLAB
compare_with_simulink('data.csv')
```

## Tips & Troubleshooting

### Serial Port Issues

**Linux:**
```bash
# Check available ports
ls /dev/ttyUSB* /dev/ttyACM*

# Add user to dialout group (logout/login required)
sudo usermod -a -G dialout $USER

# Check permissions
ls -l /dev/ttyUSB0
```

**Windows:**
- Use Device Manager to find COM port number
- Close Arduino IDE, PuTTY, or other serial monitors
- Port is typically `COM3`, `COM4`, etc.

### Data Format Issues

The CSV data from STM32 must have this format:
```
time_ms,current_A,voltage_V,duty1,duty2
0,0.00,0.0,8400,8400
200,2.45,35.2,9500,7300
...
```

Make sure:
- Data logger is in **WAVEFORM mode** for real-time plotting
- CSV headers are present (first line)
- Values are comma-separated
- No extra spaces around commas

### Python Dependencies

If you encounter import errors:
```bash
pip install --upgrade pip
pip install -r requirements.txt
```

For MATLAB-like plotting:
```bash
pip install jupyter
jupyter notebook
```

## Future Enhancements

Planned additions:
- [ ] Web-based dashboard with Dash/Plotly
- [ ] Automated report generation (PDF)
- [ ] Bode plot analysis for control loop
- [ ] Efficiency calculation tools
- [ ] Multi-file batch processing
- [ ] Integration with CI/CD (GitHub Actions)

## Contributing

When adding new tools:
1. Add to appropriate subdirectory (`analysis/` or `scripts/`)
2. Update `requirements.txt` if adding dependencies
3. Add usage examples to this README
4. Include docstrings and comments
5. Test with sample data

## License

Part of the 5-Level Inverter Project
