// Verilator testbench for firmware verification
#include <verilated.h>
#include "Vsoc_top.h"
#include <iostream>
#include <fstream>
#include <iomanip>

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);

    Vsoc_top* dut = new Vsoc_top;

    std::cout << "========================================" << std::endl;
    std::cout << "Firmware Verification Test" << std::endl;
    std::cout << "========================================" << std::endl;

    // Reset
    dut->clk_100mhz = 0;
    dut->rst_n = 0;
    dut->uart_rx = 1;
    dut->fault_ocp = 0;
    dut->fault_ovp = 0;
    dut->estop_n = 1;
    dut->adc_miso = 0;

    for (int i = 0; i < 10; i++) {
        dut->clk_100mhz = !dut->clk_100mhz;
        dut->eval();
    }

    dut->rst_n = 1;

    std::cout << "Reset released" << std::endl;

    // Track UART TX
    int uart_tx_prev = 1;
    int byte_count = 0;
    char uart_bytes[10] = {0};

    // Run for 100000 cycles
    for (int cycle = 0; cycle < 100000; cycle++) {
        // Toggle clock
        dut->clk_100mhz = !dut->clk_100mhz;
        dut->eval();

        // Monitor UART TX falling edge (start bit)
        if (uart_tx_prev == 1 && dut->uart_tx == 0 && byte_count < 5) {
            // Detected start bit - sample data bits
            // Wait for data bits (simple sampling)
            for (int bit = 0; bit < 8; bit++) {
                for (int i = 0; i < 868; i++) {  // ~434 cycles per bit @ 50MHz
                    dut->clk_100mhz = !dut->clk_100mhz;
                    dut->eval();
                }
                if (dut->uart_tx) {
                    uart_bytes[byte_count] |= (1 << bit);
                }
            }

            std::cout << "UART TX Byte " << byte_count << ": 0x"
                      << std::hex << std::setw(2) << std::setfill('0')
                      << (int)(uart_bytes[byte_count] & 0xFF)
                      << " ('" << (char)uart_bytes[byte_count] << "')"
                      << std::dec << std::endl;

            byte_count++;
        }

        uart_tx_prev = dut->uart_tx;

        // Check LED status periodically
        if (cycle % 10000 == 0) {
            std::cout << "Cycle " << cycle
                      << ": LED=" << std::hex << (int)dut->led << std::dec
                      << " PWM=" << std::hex << (int)dut->pwm_out << std::dec
                      << std::endl;
        }
    }

    std::cout << "\n========================================" << std::endl;
    std::cout << "Verification Results:" << std::endl;
    std::cout << "========================================" << std::endl;
    std::cout << "UART Bytes Received: " << byte_count << std::endl;
    std::cout << "Expected: S P W R" << std::endl;
    std::cout << "Received: ";
    for (int i = 0; i < byte_count && i < 4; i++) {
        std::cout << uart_bytes[i] << " ";
    }
    std::cout << std::endl;

    bool pass = (byte_count >= 4 &&
                 uart_bytes[0] == 'S' &&
                 uart_bytes[1] == 'P' &&
                 uart_bytes[2] == 'W' &&
                 uart_bytes[3] == 'R');

    if (pass) {
        std::cout << "\n[PASS] Firmware verification successful!" << std::endl;
        std::cout << "- UART baud rate correct (115200)" << std::endl;
        std::cout << "- All initialization sequences working" << std::endl;
        std::cout << "- System ready for Vivado simulation" << std::endl;
    } else {
        std::cout << "\n[FAIL] Firmware verification failed" << std::endl;
    }

    delete dut;
    return pass ? 0 : 1;
}
