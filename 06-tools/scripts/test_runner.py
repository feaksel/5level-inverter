#!/usr/bin/env python3
"""
Automated Test Runner for 5-Level Inverter
Runs test sequences and validates results

Usage:
    python test_runner.py config.yaml
    python test_runner.py --port /dev/ttyUSB0 --test-suite basic

Author: 5-Level Inverter Project
Date: 2025-11-15
"""

import serial
import time
import json
import yaml
import argparse
import sys
from pathlib import Path
from datetime import datetime
import csv


class TestRunner:
    """Automated test runner for inverter"""

    def __init__(self, port, baudrate=115200):
        """
        Initialize test runner

        Args:
            port: Serial port
            baudrate: Baud rate
        """
        self.port = port
        self.baudrate = baudrate
        self.ser = None
        self.test_results = []
        self.current_test = None

    def connect(self):
        """Connect to serial port"""
        try:
            self.ser = serial.Serial(
                port=self.port,
                baudrate=self.baudrate,
                timeout=2.0
            )
            print(f"✓ Connected to {self.port}")
            time.sleep(2)  # Wait for STM32 reset
            return True
        except serial.SerialException as e:
            print(f"✗ Error connecting: {e}")
            return False

    def disconnect(self):
        """Disconnect from serial port"""
        if self.ser and self.ser.is_open:
            self.ser.close()

    def send_command(self, command):
        """Send command to inverter"""
        if self.ser and self.ser.is_open:
            self.ser.write((command + '\n').encode())
            self.ser.flush()

    def read_response(self, timeout=5.0):
        """Read response from inverter"""
        start_time = time.time()
        response = []

        while time.time() - start_time < timeout:
            if self.ser.in_waiting > 0:
                line = self.ser.readline().decode('utf-8', errors='ignore').strip()
                if line:
                    response.append(line)
                    print(f"  << {line}")

        return response

    def run_test(self, test_config):
        """
        Run a single test

        Args:
            test_config: Dictionary with test configuration
                {
                    'name': 'Test name',
                    'description': 'Test description',
                    'duration': 10,  # seconds
                    'validation': {
                        'thd_max': 5.0,
                        'current_rms_min': 4.5,
                        'current_rms_max': 5.5
                    }
                }
        """
        test_name = test_config.get('name', 'Unknown Test')
        print(f"\n{'='*60}")
        print(f"Running: {test_name}")
        print(f"{'='*60}")

        self.current_test = {
            'name': test_name,
            'description': test_config.get('description', ''),
            'start_time': datetime.now().isoformat(),
            'status': 'RUNNING'
        }

        # Duration
        duration = test_config.get('duration', 10)
        print(f"Duration: {duration}s")

        # Collect data
        print("Collecting data...")
        data = self.collect_data(duration)

        # Validate results
        validation = test_config.get('validation', {})
        if validation:
            print("\nValidating results...")
            passed, validation_results = self.validate_data(data, validation)
            self.current_test['validation'] = validation_results
            self.current_test['status'] = 'PASSED' if passed else 'FAILED'
        else:
            self.current_test['status'] = 'COMPLETED'

        # Store results
        self.current_test['end_time'] = datetime.now().isoformat()
        self.current_test['data_points'] = len(data)
        self.test_results.append(self.current_test)

        # Print result
        status_symbol = '✓' if self.current_test['status'] == 'PASSED' else '✗'
        print(f"\n{status_symbol} Test {self.current_test['status']}: {test_name}")

        return self.current_test['status'] == 'PASSED'

    def collect_data(self, duration):
        """Collect data for specified duration"""
        data = []
        start_time = time.time()

        while time.time() - start_time < duration:
            if self.ser.in_waiting > 0:
                line = self.ser.readline().decode('utf-8', errors='ignore').strip()

                # Parse CSV data
                try:
                    parts = line.split(',')
                    if len(parts) >= 3:
                        sample = {
                            'time_ms': float(parts[0]),
                            'current': float(parts[1]),
                            'voltage': float(parts[2])
                        }
                        data.append(sample)
                except (ValueError, IndexError):
                    pass  # Skip invalid lines

        print(f"  Collected {len(data)} samples")
        return data

    def validate_data(self, data, validation_rules):
        """
        Validate collected data against rules

        Args:
            data: List of data samples
            validation_rules: Dict of validation criteria

        Returns:
            Tuple of (passed, results_dict)
        """
        import numpy as np
        from scipy.fft import fft, fftfreq

        if not data:
            return False, {'error': 'No data collected'}

        results = {}
        all_passed = True

        # Extract signals
        current = np.array([d['current'] for d in data])
        voltage = np.array([d['voltage'] for d in data])

        # RMS calculations
        current_rms = np.sqrt(np.mean(current**2))
        voltage_rms = np.sqrt(np.mean(voltage**2))

        results['current_rms'] = current_rms
        results['voltage_rms'] = voltage_rms

        # Validate current RMS
        if 'current_rms_min' in validation_rules:
            passed = current_rms >= validation_rules['current_rms_min']
            results['current_rms_min_check'] = {
                'expected': validation_rules['current_rms_min'],
                'actual': current_rms,
                'passed': passed
            }
            all_passed = all_passed and passed

        if 'current_rms_max' in validation_rules:
            passed = current_rms <= validation_rules['current_rms_max']
            results['current_rms_max_check'] = {
                'expected': validation_rules['current_rms_max'],
                'actual': current_rms,
                'passed': passed
            }
            all_passed = all_passed and passed

        # THD calculation
        if 'thd_max' in validation_rules:
            # Simple THD estimation (would need proper FFT for accuracy)
            N = len(current)
            yf = fft(current)
            magnitude = 2.0/N * np.abs(yf[0:N//2])

            # Estimate fundamental (assuming 50Hz)
            fund_idx = int(50 * N / 5000)  # Assuming 5kHz sampling
            fund_amp = magnitude[fund_idx] if fund_idx < len(magnitude) else 0

            # Estimate harmonics
            harmonic_power = 0
            for h in range(2, 11):
                h_idx = int(h * 50 * N / 5000)
                if h_idx < len(magnitude):
                    harmonic_power += magnitude[h_idx]**2

            thd = 100 * np.sqrt(harmonic_power) / fund_amp if fund_amp > 0 else 999

            passed = thd <= validation_rules['thd_max']
            results['thd_check'] = {
                'expected_max': validation_rules['thd_max'],
                'actual': thd,
                'passed': passed
            }
            all_passed = all_passed and passed

        return all_passed, results

    def run_test_suite(self, suite_config):
        """
        Run a suite of tests

        Args:
            suite_config: Dict or path to YAML file with test suite configuration
        """
        # Load config if it's a file path
        if isinstance(suite_config, (str, Path)):
            with open(suite_config, 'r') as f:
                if str(suite_config).endswith('.yaml') or str(suite_config).endswith('.yml'):
                    config = yaml.safe_load(f)
                else:
                    config = json.load(f)
        else:
            config = suite_config

        print(f"\n{'#'*60}")
        print(f"# Test Suite: {config.get('name', 'Unnamed Suite')}")
        print(f"{'#'*60}")

        tests = config.get('tests', [])
        passed_count = 0
        failed_count = 0

        for test in tests:
            if self.run_test(test):
                passed_count += 1
            else:
                failed_count += 1

            # Wait between tests
            time.sleep(2)

        # Summary
        print(f"\n{'='*60}")
        print(f"TEST SUITE COMPLETE")
        print(f"{'='*60}")
        print(f"Passed: {passed_count}")
        print(f"Failed: {failed_count}")
        print(f"Total:  {passed_count + failed_count}")
        print(f"{'='*60}\n")

        return passed_count, failed_count

    def save_results(self, output_file):
        """Save test results to JSON file"""
        results = {
            'test_suite': {
                'timestamp': datetime.now().isoformat(),
                'port': self.port,
                'baudrate': self.baudrate
            },
            'tests': self.test_results
        }

        with open(output_file, 'w') as f:
            json.dump(results, f, indent=2)

        print(f"Results saved to {output_file}")


# Example test suite configuration
EXAMPLE_TEST_SUITE = {
    'name': 'Basic Validation Suite',
    'description': 'Basic tests for 5-level inverter',
    'tests': [
        {
            'name': 'Test Mode 1 - Low Frequency',
            'description': '5Hz sine wave at 50% MI',
            'duration': 10,
            'validation': {
                'current_rms_min': 0.0,
                'current_rms_max': 10.0
            }
        },
        {
            'name': 'Test Mode 2 - Normal Operation',
            'description': '50Hz sine wave at 80% MI',
            'duration': 15,
            'validation': {
                'thd_max': 5.0,
                'current_rms_min': 3.0,
                'current_rms_max': 7.0
            }
        }
    ]
}


def main():
    parser = argparse.ArgumentParser(description='Automated test runner for 5-level inverter')
    parser.add_argument('config', nargs='?', help='Test suite configuration file (YAML/JSON)')
    parser.add_argument('--port', default='/dev/ttyUSB0', help='Serial port')
    parser.add_argument('--baud', type=int, default=115200, help='Baud rate')
    parser.add_argument('--output', default='test_results.json', help='Output file for results')
    parser.add_argument('--example', action='store_true', help='Generate example config file')

    args = parser.parse_args()

    # Generate example config
    if args.example:
        example_file = 'test_suite_example.yaml'
        with open(example_file, 'w') as f:
            yaml.dump(EXAMPLE_TEST_SUITE, f, default_flow_style=False)
        print(f"Example config saved to {example_file}")
        sys.exit(0)

    # Check config file
    if not args.config:
        print("Error: Test suite configuration file required")
        print("\nUse --example to generate an example configuration")
        parser.print_help()
        sys.exit(1)

    if not Path(args.config).exists():
        print(f"Error: Config file '{args.config}' not found")
        sys.exit(1)

    # Create test runner
    runner = TestRunner(args.port, args.baud)

    # Connect
    if not runner.connect():
        sys.exit(1)

    try:
        # Run test suite
        passed, failed = runner.run_test_suite(args.config)

        # Save results
        runner.save_results(args.output)

        # Exit code based on results
        sys.exit(0 if failed == 0 else 1)

    except KeyboardInterrupt:
        print("\n\nTest interrupted by user")
        sys.exit(1)
    finally:
        runner.disconnect()


if __name__ == '__main__':
    main()
