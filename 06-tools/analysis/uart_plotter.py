#!/usr/bin/env python3
"""
Real-Time UART Data Plotter for 5-Level Inverter
Plots live data streaming from STM32 via UART

Usage:
    python uart_plotter.py /dev/ttyUSB0
    python uart_plotter.py COM3 --baud 115200 --samples 1000

Author: 5-Level Inverter Project
Date: 2025-11-15
"""

import serial
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.animation as animation
from collections import deque
import argparse
import sys
import re


class UARTPlotter:
    """Real-time plotter for UART serial data"""

    def __init__(self, port, baudrate=115200, max_samples=1000):
        """
        Initialize UART plotter

        Args:
            port: Serial port (e.g., '/dev/ttyUSB0' or 'COM3')
            baudrate: Baud rate (default: 115200)
            max_samples: Maximum samples to display (default: 1000)
        """
        self.port = port
        self.baudrate = baudrate
        self.max_samples = max_samples

        # Data buffers (using deque for efficient append/pop)
        self.time_buffer = deque(maxlen=max_samples)
        self.current_buffer = deque(maxlen=max_samples)
        self.voltage_buffer = deque(maxlen=max_samples)
        self.duty1_buffer = deque(maxlen=max_samples)
        self.duty2_buffer = deque(maxlen=max_samples)

        # Serial connection
        self.ser = None
        self.connected = False

        # Statistics
        self.sample_count = 0
        self.parse_errors = 0

    def connect(self):
        """Connect to serial port"""
        try:
            self.ser = serial.Serial(
                port=self.port,
                baudrate=self.baudrate,
                timeout=1.0
            )
            self.connected = True
            print(f"Connected to {self.port} at {self.baudrate} baud")
            return True
        except serial.SerialException as e:
            print(f"Error connecting to {self.port}: {e}")
            return False

    def disconnect(self):
        """Disconnect from serial port"""
        if self.ser and self.ser.is_open:
            self.ser.close()
            self.connected = False
            print("Disconnected from serial port")

    def parse_csv_line(self, line):
        """
        Parse CSV line from UART

        Expected format: time_ms,current_A,voltage_V,duty1,duty2

        Args:
            line: CSV line string

        Returns:
            Tuple of (time, current, voltage, duty1, duty2) or None if parse fails
        """
        try:
            # Remove whitespace and split by comma
            parts = line.strip().split(',')

            if len(parts) < 4:
                return None

            # Parse values
            time_ms = float(parts[0])
            current = float(parts[1])
            voltage = float(parts[2])
            duty1 = float(parts[3]) if len(parts) > 3 else 0
            duty2 = float(parts[4]) if len(parts) > 4 else 0

            return (time_ms, current, voltage, duty1, duty2)

        except (ValueError, IndexError):
            return None

    def read_data(self):
        """Read and parse data from UART"""
        if not self.connected or not self.ser.is_open:
            return False

        try:
            # Read line from serial
            if self.ser.in_waiting > 0:
                line = self.ser.readline().decode('utf-8', errors='ignore').strip()

                # Skip empty lines and status messages
                if not line or line.startswith('===') or line.startswith('Mode'):
                    return False

                # Parse CSV data
                data = self.parse_csv_line(line)

                if data:
                    time_ms, current, voltage, duty1, duty2 = data

                    # Add to buffers
                    self.time_buffer.append(time_ms / 1000.0)  # Convert to seconds
                    self.current_buffer.append(current)
                    self.voltage_buffer.append(voltage)
                    self.duty1_buffer.append(duty1)
                    self.duty2_buffer.append(duty2)

                    self.sample_count += 1
                    return True
                else:
                    self.parse_errors += 1

        except Exception as e:
            print(f"Error reading data: {e}")

        return False

    def update_plot(self, frame):
        """Update plot with new data (called by animation)"""
        # Read new data
        for _ in range(10):  # Read up to 10 samples per frame
            self.read_data()

        if len(self.time_buffer) < 2:
            return self.lines

        # Convert deques to numpy arrays
        time = np.array(self.time_buffer)
        current = np.array(self.current_buffer)
        voltage = np.array(self.voltage_buffer)
        duty1 = np.array(self.duty1_buffer)
        duty2 = np.array(self.duty2_buffer)

        # Update line data
        self.lines[0].set_data(time, current)
        self.lines[1].set_data(time, voltage)
        self.lines[2].set_data(time, duty1)
        self.lines[3].set_data(time, duty2)

        # Update axis limits
        time_min = np.min(time)
        time_max = np.max(time)
        time_range = time_max - time_min

        if time_range > 0:
            self.axes[0].set_xlim(time_min, time_max)
            self.axes[1].set_xlim(time_min, time_max)
            self.axes[2].set_xlim(time_min, time_max)

        # Auto-scale y-axes
        if len(current) > 0:
            i_margin = (np.max(current) - np.min(current)) * 0.1
            self.axes[0].set_ylim(np.min(current) - i_margin, np.max(current) + i_margin)

        if len(voltage) > 0:
            v_margin = (np.max(voltage) - np.min(voltage)) * 0.1
            self.axes[1].set_ylim(np.min(voltage) - v_margin, np.max(voltage) + v_margin)

        # Update title with statistics
        self.fig.suptitle(
            f'5-Level Inverter - Live Data (Samples: {self.sample_count}, Errors: {self.parse_errors})',
            fontsize=12, fontweight='bold'
        )

        return self.lines

    def start_plotting(self):
        """Start real-time plotting"""
        if not self.connected:
            print("Error: Not connected to serial port")
            return

        # Create figure and subplots
        self.fig, self.axes = plt.subplots(3, 1, figsize=(12, 9))

        # Initialize empty lines
        self.lines = []

        # Current plot
        line, = self.axes[0].plot([], [], 'b-', linewidth=1.0, label='Current')
        self.axes[0].set_ylabel('Current (A)', fontsize=10)
        self.axes[0].grid(True, alpha=0.3)
        self.axes[0].legend(loc='upper right')
        self.axes[0].set_title('Output Current', fontsize=11, fontweight='bold')
        self.lines.append(line)

        # Voltage plot
        line, = self.axes[1].plot([], [], 'r-', linewidth=1.0, label='Voltage')
        self.axes[1].set_ylabel('Voltage (V)', fontsize=10)
        self.axes[1].grid(True, alpha=0.3)
        self.axes[1].legend(loc='upper right')
        self.axes[1].set_title('Output Voltage', fontsize=11, fontweight='bold')
        self.lines.append(line)

        # Duty cycles plot
        line1, = self.axes[2].plot([], [], 'g-', linewidth=1.0, label='H-Bridge 1')
        line2, = self.axes[2].plot([], [], 'm-', linewidth=1.0, label='H-Bridge 2')
        self.axes[2].set_ylabel('Duty Cycle', fontsize=10)
        self.axes[2].set_xlabel('Time (s)', fontsize=10)
        self.axes[2].grid(True, alpha=0.3)
        self.axes[2].legend(loc='upper right')
        self.axes[2].set_title('PWM Duty Cycles', fontsize=11, fontweight='bold')
        self.lines.append(line1)
        self.lines.append(line2)

        plt.tight_layout()

        # Start animation
        ani = animation.FuncAnimation(
            self.fig,
            self.update_plot,
            interval=50,  # Update every 50ms
            blit=True,
            cache_frame_data=False
        )

        print("\nReal-time plotting started. Close window to exit.")
        print("Make sure data logger is in WAVEFORM mode on STM32.\n")

        try:
            plt.show()
        except KeyboardInterrupt:
            print("\nStopped by user")
        finally:
            self.disconnect()


def list_serial_ports():
    """List available serial ports"""
    import serial.tools.list_ports

    ports = serial.tools.list_ports.comports()

    if not ports:
        print("No serial ports found")
        return

    print("\nAvailable serial ports:")
    for i, port in enumerate(ports):
        print(f"  {i+1}. {port.device} - {port.description}")


def main():
    parser = argparse.ArgumentParser(
        description='Real-time plotter for 5-level inverter UART data'
    )
    parser.add_argument('port', nargs='?', help='Serial port (e.g., /dev/ttyUSB0 or COM3)')
    parser.add_argument('--baud', type=int, default=115200, help='Baud rate (default: 115200)')
    parser.add_argument('--samples', type=int, default=1000, help='Max samples to display (default: 1000)')
    parser.add_argument('--list', action='store_true', help='List available serial ports')

    args = parser.parse_args()

    # List ports if requested
    if args.list:
        list_serial_ports()
        sys.exit(0)

    # Check if port specified
    if not args.port:
        print("Error: Serial port not specified")
        print("\nUse --list to see available ports")
        parser.print_help()
        sys.exit(1)

    # Create plotter
    plotter = UARTPlotter(args.port, args.baud, args.samples)

    # Connect to serial port
    if not plotter.connect():
        sys.exit(1)

    # Start plotting
    plotter.start_plotting()


if __name__ == '__main__':
    main()
