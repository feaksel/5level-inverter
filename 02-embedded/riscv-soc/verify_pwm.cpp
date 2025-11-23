// Simple Verilator testbench to verify PWM operation
#include <stdlib.h>
#include <iostream>
#include <iomanip>
#include <verilated.h>
#include <verilated_vcd_c.h>
#include "Vriscv_soc_top.h"

#define MAX_SIM_TIME 5000000  // 5ms @ 50MHz = 250,000 cycles (increased)
#define CLK_PERIOD 2          // 20ns period = 50 MHz

vluint64_t sim_time = 0;
vluint64_t posedge_cnt = 0;

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    Vriscv_soc_top* dut = new Vriscv_soc_top;

    // Enable waveform dumping
    Verilated::traceEverOn(true);
    VerilatedVcdC* m_trace = new VerilatedVcdC;
    dut->trace(m_trace, 5);
    m_trace->open("waveform.vcd");

    std::cout << "========================================" << std::endl;
    std::cout << "  PWM Verification with Verilator" << std::endl;
    std::cout << "========================================" << std::endl;
    std::cout << "Clock: 50 MHz" << std::endl;
    std::cout << "Simulation time: 5ms" << std::endl;
    std::cout << "VCD output: waveform.vcd" << std::endl;
    std::cout << std::endl;

    // Initialize inputs
    dut->clk_100mhz = 0;
    dut->rst_n = 0;
    dut->uart_rx = 1;
    dut->fault_ocp = 0;
    dut->fault_ovp = 0;
    dut->estop_n = 1;
    dut->adc_miso = 0;

    uint8_t prev_pwm = 0;
    uint32_t pwm_edge_count = 0;
    uint32_t uart_tx_changes = 0;
    uint8_t prev_uart_tx = 1;
    uint32_t last_print_time = 0;
    bool pwm_active = false;

    std::cout << "Starting simulation..." << std::endl;
    std::cout << std::endl;

    // Run simulation
    while (sim_time < MAX_SIM_TIME && !Verilated::gotFinish()) {

        // Toggle clock
        dut->clk_100mhz ^= 1;

        // Release reset after 200ns
        if (sim_time == 200) {
            dut->rst_n = 1;
            std::cout << "[" << std::setw(10) << sim_time << " ns] Reset released" << std::endl;
        }

        dut->eval();
        m_trace->dump(sim_time);

        // On positive edge, monitor signals
        if (dut->clk_100mhz == 1) {
            posedge_cnt++;

            // Detect PWM changes
            if (dut->pwm_out != prev_pwm) {
                pwm_edge_count++;
                if (!pwm_active && dut->pwm_out != 0) {
                    std::cout << "[" << std::setw(10) << sim_time << " ns] PWM STARTED! Pattern: 0x"
                              << std::hex << std::setw(2) << std::setfill('0') << (int)dut->pwm_out
                              << std::dec << std::setfill(' ') << std::endl;
                    pwm_active = true;
                }
                prev_pwm = dut->pwm_out;
            }

            // Detect UART changes
            if (dut->uart_tx != prev_uart_tx) {
                uart_tx_changes++;
                prev_uart_tx = dut->uart_tx;
            }

            // Print status every 500us
            if (sim_time - last_print_time >= 500000) {
                std::cout << "[" << std::setw(10) << sim_time << " ns] "
                          << "PWM: 0x" << std::hex << std::setw(2) << std::setfill('0') << (int)dut->pwm_out
                          << std::dec << std::setfill(' ')
                          << " | Edges: " << std::setw(6) << pwm_edge_count
                          << " | UART TX: " << (int)dut->uart_tx
                          << " | LED: 0x" << std::hex << (int)dut->led << std::dec
                          << std::endl;
                last_print_time = sim_time;
            }
        }

        sim_time++;
    }

    m_trace->close();

    // Final report
    std::cout << std::endl;
    std::cout << "========================================" << std::endl;
    std::cout << "  Simulation Results" << std::endl;
    std::cout << "========================================" << std::endl;
    std::cout << "Total time:         " << sim_time << " ns (" << (sim_time/1000.0) << " us)" << std::endl;
    std::cout << "Clock cycles:       " << posedge_cnt << std::endl;
    std::cout << "PWM edge count:     " << pwm_edge_count;
    if (pwm_edge_count > 0) {
        std::cout << " ✓ PWM ACTIVE" << std::endl;
    } else {
        std::cout << " ✗ PWM INACTIVE" << std::endl;
    }
    std::cout << "UART TX changes:    " << uart_tx_changes;
    if (uart_tx_changes > 0) {
        std::cout << " ✓ UART ACTIVE" << std::endl;
    } else {
        std::cout << " ✗ UART INACTIVE" << std::endl;
    }
    std::cout << "Final PWM state:    0x" << std::hex << (int)dut->pwm_out << std::dec << std::endl;
    std::cout << "Final LED state:    0x" << std::hex << (int)dut->led << std::dec << std::endl;
    std::cout << std::endl;

    // Analysis
    if (pwm_edge_count > 100) {
        std::cout << "✓ SUCCESS: PWM is switching (" << pwm_edge_count << " edges)" << std::endl;
        std::cout << "  Expected ~50 edges per PWM cycle at 5kHz over 5ms" << std::endl;
        std::cout << "  View waveform.vcd with GTKWave to see details" << std::endl;
    } else if (pwm_edge_count > 0) {
        std::cout << "⚠ WARNING: PWM started but stopped early" << std::endl;
        std::cout << "  Only " << pwm_edge_count << " edges detected" << std::endl;
    } else {
        std::cout << "✗ FAILED: No PWM activity detected" << std::endl;
        std::cout << "  Check firmware loading and PWM peripheral initialization" << std::endl;
    }

    std::cout << std::endl;
    std::cout << "To view waveform:" << std::endl;
    std::cout << "  gtkwave waveform.vcd" << std::endl;
    std::cout << std::endl;
    std::cout << "Important signals to add:" << std::endl;
    std::cout << "  TOP.riscv_soc_top.pwm_out[7:0]  - PWM outputs" << std::endl;
    std::cout << "  TOP.riscv_soc_top.uart_tx       - UART transmit" << std::endl;
    std::cout << "  TOP.riscv_soc_top.led[3:0]      - LED status" << std::endl;
    std::cout << "========================================" << std::endl;

    delete m_trace;
    delete dut;
    exit(EXIT_SUCCESS);
}
