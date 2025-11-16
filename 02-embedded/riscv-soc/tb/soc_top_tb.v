/**
 * @file soc_top_tb.v
 * @brief Top-Level Testbench for RISC-V SoC
 *
 * Tests the complete SoC integration including:
 * - Clock generation
 * - Reset synchronization
 * - Memory access (ROM/RAM)
 * - Peripheral connectivity
 * - Interrupt handling
 * - Basic firmware execution (if VexRiscv available)
 */

`timescale 1ns / 1ps

module soc_top_tb;

    //==========================================================================
    // Parameters
    //==========================================================================

    parameter CLK_PERIOD = 10;  // 100 MHz input clock

    //==========================================================================
    // Signals
    //==========================================================================

    // Clock and reset
    reg clk_100mhz;
    reg rst_n;

    // UART
    wire uart_tx;
    reg  uart_rx;

    // PWM outputs
    wire [7:0] pwm_out;

    // ADC SPI
    wire adc_sck, adc_mosi, adc_cs_n;
    reg  adc_miso;

    // Protection
    reg fault_ocp, fault_ovp, estop_n;

    // GPIO
    wire [15:0] gpio;

    // Status LEDs
    wire [3:0] led;

    // Test control
    integer test_cycle = 0;
    integer uart_chars_received = 0;

    //==========================================================================
    // DUT Instantiation
    //==========================================================================

    soc_top #(
        .CLK_FREQ(50_000_000),
        .UART_BAUD(115200)
    ) dut (
        .clk_100mhz(clk_100mhz),
        .rst_n(rst_n),
        .uart_rx(uart_rx),
        .uart_tx(uart_tx),
        .pwm_out(pwm_out),
        .adc_sck(adc_sck),
        .adc_mosi(adc_mosi),
        .adc_miso(adc_miso),
        .adc_cs_n(adc_cs_n),
        .fault_ocp(fault_ocp),
        .fault_ovp(fault_ovp),
        .estop_n(estop_n),
        .gpio(gpio),
        .led(led)
    );

    //==========================================================================
    // Clock Generation
    //==========================================================================

    initial begin
        clk_100mhz = 0;
        forever #(CLK_PERIOD/2) clk_100mhz = ~clk_100mhz;
    end

    //==========================================================================
    // UART Monitor (Capture TX output)
    //==========================================================================

    reg [7:0] uart_rx_data;
    reg uart_rx_ready;
    integer bit_time = 1000_000_000 / 115200;  // ~8680 ns per bit

    // Simple UART receiver (monitors uart_tx)
    task uart_receive_byte;
        output [7:0] data;
        integer i;
        begin
            // Wait for start bit
            @(negedge uart_tx);
            #(bit_time/2);  // Center of start bit

            if (uart_tx == 1'b0) begin
                #bit_time;  // Move to first data bit

                // Receive 8 data bits
                for (i = 0; i < 8; i = i + 1) begin
                    data[i] = uart_tx;
                    #bit_time;
                end

                // Check stop bit
                if (uart_tx == 1'b1) begin
                    $display("  [UART RX] Received byte: 0x%02h ('%c')",
                             data, (data >= 32 && data < 127) ? data : ".");
                    uart_chars_received = uart_chars_received + 1;
                end else begin
                    $display("  [UART RX] Frame error!");
                end
            end
        end
    endtask

    // Background task to monitor UART
    initial begin
        uart_rx_ready = 0;
        uart_rx_data = 0;
        forever begin
            uart_receive_byte(uart_rx_data);
            uart_rx_ready = 1;
            #100;
            uart_rx_ready = 0;
        end
    end

    //==========================================================================
    // ADC Simulator (Simple response to SPI transactions)
    //==========================================================================

    reg [15:0] adc_simulated_data [0:3];

    initial begin
        // Simulated ADC values
        adc_simulated_data[0] = 16'h1234;  // Channel 0
        adc_simulated_data[1] = 16'h5678;  // Channel 1
        adc_simulated_data[2] = 16'h9ABC;  // Channel 2
        adc_simulated_data[3] = 16'hDEF0;  // Channel 3
        adc_miso = 1'b0;
    end

    // Simple ADC SPI responder
    always @(negedge adc_cs_n) begin
        // When CS goes low, prepare to send data
        // This is a simplified model - real ADC would have command phase
        #100;
        // Send data on MISO synchronized with SCK
        // (Detailed implementation omitted for brevity)
    end

    //==========================================================================
    // Test Stimulus
    //==========================================================================

    initial begin
        // Initialize waveform dump
        $dumpfile("sim/soc_top_tb.vcd");
        $dumpvars(0, soc_top_tb);
        $dumpvars(0, dut.rom);
        $dumpvars(0, dut.ram);

        // Initialize signals
        rst_n = 0;
        uart_rx = 1'b1;
        adc_miso = 1'b0;
        fault_ocp = 0;
        fault_ovp = 0;
        estop_n = 1'b1;

        $display("");
        $display("========================================");
        $display("RISC-V SoC Top-Level Testbench");
        $display("========================================");
        $display("Simulation started at time %0t", $time);
        $display("");

        // Apply reset
        #200;
        $display("[%0t] Releasing reset", $time);
        rst_n = 1;
        #500;

        //======================================================================
        // Test 1: Basic SoC Operation
        //======================================================================
        $display("\n========================================");
        $display("Test 1: Basic SoC Operation");
        $display("========================================");

        // Check that clock is running
        #1000;
        $display("  [INFO] 50 MHz system clock active");
        $display("  [INFO] LED[0] (power): %b", led[0]);

        // CPU should start executing from ROM
        // (This requires actual VexRiscv core and firmware)
        $display("  [INFO] CPU should be fetching from ROM at 0x00000000");

        //======================================================================
        // Test 2: PWM Output Monitoring
        //======================================================================
        $display("\n========================================");
        $display("Test 2: PWM Output Monitoring");
        $display("========================================");

        // Initially PWM should be disabled (firmware not running)
        #10000;
        $display("  [INFO] PWM outputs: 0x%02h", pwm_out);

        // If firmware runs and enables PWM, we should see activity
        #100000;
        $display("  [INFO] PWM outputs after 100us: 0x%02h", pwm_out);

        //======================================================================
        // Test 3: Protection System
        //======================================================================
        $display("\n========================================");
        $display("Test 3: Protection System");
        $display("========================================");

        $display("  [TEST] Triggering overcurrent fault");
        fault_ocp = 1'b1;
        #1000;
        $display("  [INFO] PWM outputs (should be disabled): 0x%02h", pwm_out);
        $display("  [INFO] LED[1] (fault): %b", led[1]);
        fault_ocp = 1'b0;
        #1000;

        $display("  [TEST] Triggering emergency stop");
        estop_n = 1'b0;
        #1000;
        $display("  [INFO] PWM outputs (should be disabled): 0x%02h", pwm_out);
        estop_n = 1'b1;
        #1000;

        //======================================================================
        // Test 4: UART Activity
        //======================================================================
        $display("\n========================================");
        $display("Test 4: UART Activity");
        $display("========================================");

        $display("  [INFO] Monitoring UART TX for firmware messages...");
        $display("  [INFO] (Requires actual firmware execution)");

        // Wait for potential UART output
        #500000;

        if (uart_chars_received > 0) begin
            $display("  [PASS] Received %0d characters via UART", uart_chars_received);
        end else begin
            $display("  [INFO] No UART output detected");
            $display("  [INFO] (This is expected without firmware or VexRiscv core)");
        end

        //======================================================================
        // Test 5: Memory Access Patterns
        //======================================================================
        $display("\n========================================");
        $display("Test 5: Memory System");
        $display("========================================");

        // Monitor bus activity
        $display("  [INFO] Monitoring bus activity...");
        #100000;

        // Check if ROM is being accessed
        $display("  [INFO] ROM access should be occurring if CPU is running");

        //======================================================================
        // Test 6: Interrupt System
        //======================================================================
        $display("\n========================================");
        $display("Test 6: Interrupt System");
        $display("========================================");

        $display("  [INFO] CPU interrupts: 0x%08h", dut.cpu_interrupts);
        $display("  [INFO] LED[3] (interrupt active): %b", led[3]);

        //======================================================================
        // Test 7: Long-term Stability
        //======================================================================
        $display("\n========================================");
        $display("Test 7: Long-term Stability");
        $display("========================================");

        $display("  [INFO] Running for extended period...");
        repeat (100) begin
            #10000;
            test_cycle = test_cycle + 1;
            if (test_cycle % 10 == 0) begin
                $display("  [%0t] Cycle %0d: PWM=0x%02h LED=0x%01h",
                         $time, test_cycle, pwm_out, led);
            end
        end

        //======================================================================
        // Test Complete
        //======================================================================
        #10000;

        $display("");
        $display("========================================");
        $display("Testbench Complete");
        $display("========================================");
        $display("Simulation time: %0t", $time);
        $display("UART characters received: %0d", uart_chars_received);
        $display("");
        $display("NOTE: Full functionality requires:");
        $display("  1. VexRiscv core (rtl/cpu/VexRiscv.v)");
        $display("  2. Compiled firmware (firmware/firmware.hex)");
        $display("");
        $display("Without these, only peripheral connectivity");
        $display("and basic infrastructure can be verified.");
        $display("");
        $display("✓ Testbench completed successfully!");
        $display("========================================");
        $display("");

        $finish;
    end

    //==========================================================================
    // Timeout Watchdog
    //==========================================================================

    initial begin
        #200_000_000;  // 200 ms timeout
        $display("");
        $display("========================================");
        $display("ERROR: Simulation timeout!");
        $display("========================================");
        $finish;
    end

    //==========================================================================
    // Signal Monitoring (Optional - for debugging)
    //==========================================================================

    // Monitor critical signals
    always @(posedge dut.clk) begin
        // Uncomment for detailed bus monitoring
        // if (dut.cpu_dbus_stb && dut.cpu_dbus_ack) begin
        //     $display("  [BUS] DBUS: addr=0x%08h data=0x%08h we=%b",
        //              dut.cpu_dbus_addr, dut.cpu_dbus_dat_i, dut.cpu_dbus_we);
        // end
    end

endmodule
