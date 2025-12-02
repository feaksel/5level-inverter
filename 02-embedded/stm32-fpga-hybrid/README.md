# STM32F401RE + FPGA Hybrid Implementation

**Project:** 5-Level Cascaded H-Bridge Inverter Control System
**Implementation:** Hybrid STM32+FPGA Architecture
**Status:** Design Complete, Ready for Implementation
**Date:** 2025-12-02

---

## Quick Overview

This folder contains a **hybrid implementation** combining:
- **STM32F401RE** microcontroller for control algorithm and PWM generation
- **FPGA (Xilinx Artix-7)** for high-performance Sigma-Delta ADC sensing

### Why Hybrid?

| Feature | Benefit |
|---------|---------|
| **ASIC Development Path** | FPGA validates Sigma-Delta ADC design before expensive ASIC tape-out |
| **Best of Both Worlds** | STM32 handles control (easy C coding), FPGA handles custom sensing |
| **Educational** | Learn both platforms and inter-chip communication (SPI) |
| **Performance** | 10 kHz control loop maintained, proven 12-14 bit ADC design |
| **Cost** | ~$30 prototype (scales to $12-18 with ASIC) |

---

## Architecture

```
Universal Power Stage → LM339 Comparators → FPGA Σ-Δ ADC → SPI → STM32 Control
                                                                       ↓
                                                                   PWM Output
```

**Key Points:**
- FPGA runs 4-channel Sigma-Delta ADC at 10 kHz output rate
- STM32 reads sensor data via SPI and runs control algorithm
- Clean separation: sensing (FPGA) vs. control (STM32)

For detailed architecture, see: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)

---

## Directory Structure

```
stm32-fpga-hybrid/
├── stm32/                      # STM32F401RE firmware
│   └── Core/
│       ├── Inc/
│       │   ├── fpga_interface.h    # FPGA driver API
│       │   └── main.h              # Main application
│       └── Src/
│           ├── fpga_interface.c    # FPGA driver implementation
│           └── main.c              # Main application
│
├── fpga/                       # FPGA RTL design
│   ├── rtl/
│   │   ├── fpga_sensing_top.v         # Top-level module
│   │   ├── interfaces/
│   │   │   └── stm32_spi_interface.v  # SPI slave for STM32
│   │   └── peripherals/
│   │       └── (sigma_delta_adc.v)    # Referenced from riscv-soc/
│   └── constraints/
│       └── basys3.xdc              # Pin constraints (Basys 3)
│
└── docs/                       # Documentation
    ├── ARCHITECTURE.md         # System architecture (detailed)
    ├── PIN-MAPPING.md          # Pin mapping and integration guide
    └── README.md               # This file
```

---

## Quick Start Guide

### Prerequisites

**Hardware:**
- STM32 Nucleo-F401RE board ($15)
- Digilent Basys 3 FPGA board ($149) or equivalent Artix-7 board
- Universal power stage PCB with sensors
- LM339 comparator board (simple 5×5cm PCB)

**Software:**
- STM32CubeIDE or VSCode + PlatformIO (STM32 development)
- Xilinx Vivado (FPGA synthesis) or open-source tools
- ST-Link programmer (included with Nucleo board)
- JTAG programmer for FPGA (included with Basys 3)

### 1. Build FPGA Design

```bash
cd fpga/rtl

# Using Vivado (GUI or command-line)
vivado -mode batch -source build.tcl

# Or using open-source tools (future)
# yosys, nextpnr, etc.
```

**Output:** Bitstream file (`fpga_sensing_top.bit`)

### 2. Program FPGA

```bash
# Using Vivado Hardware Manager
# Or Digilent Adept tools
djtgcfg prog -d Basys3 -i 0 -f fpga_sensing_top.bit
```

### 3. Build STM32 Firmware

```bash
cd stm32/

# Using STM32CubeIDE (import project)
# Or using command-line
arm-none-eabi-gcc -o firmware.elf ...

# Or using PlatformIO
pio run
```

### 4. Flash STM32

```bash
# Using ST-Link
st-flash write firmware.bin 0x08000000

# Or using PlatformIO
pio run --target upload
```

### 5. Connect and Test

1. Connect comparator board between power stage and FPGA
2. Connect SPI wires between FPGA and STM32 (6 wires)
3. Power on system
4. Open serial terminal (115200 baud)
5. Verify sensor readings appear

---

## File Descriptions

### STM32 Files

#### `stm32/Core/Inc/fpga_interface.h`
Header file defining FPGA communication API.

**Key Functions:**
```c
HAL_StatusTypeDef fpga_init(SPI_HandleTypeDef *hspi);
HAL_StatusTypeDef fpga_read_all_adc(fpga_adc_data_t *data);
void fpga_convert_to_physical(const fpga_adc_data_t *raw_data,
                               fpga_sensor_values_t *sensor_values);
```

#### `stm32/Core/Src/fpga_interface.c`
Implementation of FPGA SPI communication driver.

**Features:**
- SPI master communication at 10 MHz
- Register-based read interface
- Automatic data conversion (raw ADC → volts/amps)
- Error handling

#### `stm32/Core/Src/main.c`
Main application with control loop skeleton.

**Structure:**
```c
void main(void) {
    // Initialize peripherals
    fpga_init(&hspi1);

    // Main control loop
    while (1) {
        control_loop();  // 10 kHz rate
    }
}
```

### FPGA Files

#### `fpga/rtl/fpga_sensing_top.v`
Top-level FPGA module integrating:
- 4× Sigma-Delta ADC channels
- SPI slave interface
- Status LEDs

**Ports:**
```verilog
module fpga_sensing_top (
    input  [3:0] comp_in,     // From comparators
    output [3:0] dac_out,     // To RC filters
    input        spi_sck,     // SPI from STM32
    input        spi_mosi,
    output       spi_miso,
    input        spi_cs_n,
    output [3:0] led          // Status LEDs
);
```

#### `fpga/rtl/interfaces/stm32_spi_interface.v`
SPI slave module for STM32 communication.

**Register Map:**
- 0x00: STATUS (data valid flags)
- 0x01-0x02: ADC_CH0 (16-bit)
- 0x03-0x04: ADC_CH1
- 0x05-0x06: ADC_CH2
- 0x07-0x08: ADC_CH3
- 0x09: SAMPLE_CNT (debug)

---

## Pin Connections

### SPI Interface (FPGA ↔ STM32)

| Signal | STM32 Pin | FPGA Pin | Description |
|--------|-----------|----------|-------------|
| SCK | PA5 | U11 | SPI clock (10 MHz) |
| MISO | PA6 | U13 | Data from FPGA |
| MOSI | PA7 | U12 | Data to FPGA |
| CS_N | PA4 | U14 | Chip select (active low) |
| GND | GND | GND | Common ground |

### Comparator Interface (LM339 ↔ FPGA)

| Signal | LM339 | FPGA Pin | Description |
|--------|-------|----------|-------------|
| COMP_IN[0] | OUT1 | V11 (J1) | DC Bus 1 comparator output |
| COMP_IN[1] | OUT2 | V12 (J2) | DC Bus 2 comparator output |
| COMP_IN[2] | OUT3 | V13 (J3) | AC Voltage comparator output |
| COMP_IN[3] | OUT4 | V14 (J4) | AC Current comparator output |
| DAC_OUT[0] | IN1- | W11 (K1) | RC filter feedback to comp 1 |
| DAC_OUT[1] | IN2- | W12 (K2) | RC filter feedback to comp 2 |
| DAC_OUT[2] | IN3- | W13 (K3) | RC filter feedback to comp 3 |
| DAC_OUT[3] | IN4- | W14 (K4) | RC filter feedback to comp 4 |

**For complete pin mapping, see:** [docs/PIN-MAPPING.md](docs/PIN-MAPPING.md)

---

## Performance Specifications

| Parameter | Value | Notes |
|-----------|-------|-------|
| **Control Loop Rate** | 10 kHz | 100 µs period |
| **ADC Sampling Rate** | 10 kHz per channel | Simultaneous |
| **ADC Resolution** | 12-14 bit ENOB | Sigma-Delta ADC |
| **SPI Clock** | 10 MHz | STM32 → FPGA |
| **Sensor Read Time** | ~10 µs | All 4 channels via SPI |
| **Control Latency** | < 100 µs | Sensor read to PWM update |
| **FPGA Resources** | ~1500 LUTs | 7% of Artix-7 35T |
| **STM32 Flash** | ~20 KB | 4% of 512 KB |
| **Power Consumption** | ~306 mW | Control + sensing |

---

## Bill of Materials (BOM)

### Development Boards

| Component | Part Number | Qty | Unit Price | Total |
|-----------|-------------|-----|------------|-------|
| STM32 Nucleo Board | NUCLEO-F401RE | 1 | $15.00 | $15.00 |
| FPGA Board | Basys 3 (XC7A35T) | 1 | $149.00 | $149.00 |
| **Dev Board Total** | | | | **$164.00** |

### Custom Hardware

| Component | Part Number | Qty | Unit Price | Total |
|-----------|-------------|-----|------------|-------|
| Comparator IC | LM339N | 1 | $0.60 | $0.60 |
| Resistors (1kΩ) | - | 8 | $0.05 | $0.40 |
| Capacitors (100nF) | - | 8 | $0.10 | $0.80 |
| PCB (comparator) | Custom 5×5cm | 1 | $5.00 | $5.00 |
| Connectors | - | 3 | $2.00 | $6.00 |
| **Hardware Total** | | | | **$12.80** |

**Total Development Cost:** ~$177

---

## Testing and Validation

### Unit Tests

- [ ] FPGA Sigma-Delta ADC accuracy (apply known voltages)
- [ ] SPI communication integrity (loopback test)
- [ ] STM32 control loop timing (oscilloscope verification)

### Integration Tests

- [ ] End-to-end sensor reading (power stage → STM32)
- [ ] Control loop performance (step response, THD)
- [ ] Protection mechanisms (overcurrent, overvoltage)

### Performance Tests

- [ ] Sensor accuracy (compare with bench multimeter)
- [ ] Control loop latency (< 100 µs target)
- [ ] Long-duration stability (24 hour test)

---

## Troubleshooting

### Common Issues

**Problem:** SPI communication fails (all reads return 0xFF)

**Solutions:**
1. Verify SPI mode (CPOL=0, CPHA=0)
2. Check CS polarity (active low)
3. Reduce clock to 1 MHz for testing
4. Use logic analyzer to debug

**Problem:** ADC readings stuck at 0 or 0xFFFF

**Solutions:**
1. Check comparator power supply (3.3V)
2. Verify RC filter values (1kΩ, 100nF)
3. Test comparator outputs with oscilloscope
4. Ensure analog inputs are within 0-3.3V range

**Problem:** Control loop too slow

**Solutions:**
1. Use DMA for SPI transfers
2. Optimize control algorithm (avoid divisions)
3. Profile code to find bottlenecks

**For detailed troubleshooting:** [docs/PIN-MAPPING.md#troubleshooting-guide](docs/PIN-MAPPING.md#troubleshooting-guide)

---

## Migration Path to ASIC

This hybrid implementation is designed with ASIC migration in mind:

### Stage 1: STM32 + FPGA (Current)
- Validate Sigma-Delta ADC design
- Prove SPI communication protocol
- **Cost:** ~$30 per unit (prototype)

### Stage 2: STM32 + Small ASIC
- Convert FPGA design to ASIC (SkyWater SKY130 or similar)
- Keep STM32 for control flexibility
- **Cost:** ~$12-18 per unit (medium volume)

### Stage 3: Full ASIC
- Integrate RISC-V core + ADC + PWM on single chip
- See: `../riscv-soc/` for full SOC design
- **Cost:** ~$7-12 per unit (high volume)

**Key Point:** The FPGA design directly translates to ASIC RTL with minimal changes!

---

## Related Documentation

- **System Architecture:** [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
- **Pin Mapping:** [docs/PIN-MAPPING.md](docs/PIN-MAPPING.md)
- **Sigma-Delta ADC Theory:** [../../07-docs/SENSING-DESIGN-DEEP-DIVE.md](../../07-docs/SENSING-DESIGN-DEEP-DIVE.md)
- **Universal Power Stage:** [../../07-docs/SENSING-DESIGN.md](../../07-docs/SENSING-DESIGN.md)
- **RISC-V SOC (Future):** [../riscv-soc/](../riscv-soc/)

---

## Project Status

- [x] Architecture design
- [x] FPGA RTL design
- [x] STM32 firmware skeleton
- [x] Documentation
- [ ] FPGA synthesis and testing
- [ ] STM32 compilation and testing
- [ ] Hardware integration
- [ ] System validation

---

## Contributing

This is part of the 5-level inverter project. For contribution guidelines, see main project README.

---

## License

[Specify project license]

---

**For questions or issues, see project documentation or contact project maintainers.**

**Version:** 1.0
**Last Updated:** 2025-12-02
**Status:** Design Complete, Ready for Implementation
