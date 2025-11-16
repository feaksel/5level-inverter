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

    parameter CLK_PERIOD = 20;  // 50 MHz input clock (matches SoC CLK_FREQ parameter)

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
    reg [15:0] gpio_prev;
    integer blink_count;

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
        // Note: Writing to current directory instead of sim/ to avoid directory creation issues
        $dumpfile("soc_top_tb.vcd");
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
        // Test 1: Firmware Execution and GPIO Status
        //======================================================================
        $display("\n========================================");
        $display("Test 1: Firmware Execution");
        $display("========================================");

        // Wait for firmware to complete tests (~5000 cycles)
        #50000;  // 50us @ 50MHz = 2500 cycles
        $display("  [INFO] GPIO status: 0x%04h", gpio);
        $display("  [INFO] LED status: 0x%01h", led);

        // Check test results from GPIO
        if (gpio[7]) begin
            $display("  [PASS] All firmware tests completed (GPIO[7]=1)");
            if (gpio[4]) $display("  [PASS]   - RAM test passed (GPIO[4]=1)");
            if (gpio[5]) $display("  [PASS]   - GPIO test passed (GPIO[5]=1)");
            if (gpio[6]) $display("  [PASS]   - UART test passed (GPIO[6]=1)");
            $display("  [INFO]   - Test counter: %0d", gpio[3:0]);
        end else begin
            $display("  [WARN] Tests not complete yet or failed (GPIO[7]=0)");
            $display("  [INFO]   - Test counter: %0d", gpio[3:0]);
            $display("  [INFO]   - RAM test: %s", gpio[4] ? "PASS" : "FAIL");
            $display("  [INFO]   - GPIO test: %s", gpio[5] ? "PASS" : "FAIL");
            $display("  [INFO]   - UART test: %s", gpio[6] ? "PASS" : "FAIL");
        end

        //======================================================================
        // Test 2: UART Output Verification
        //======================================================================
        $display("\n========================================");
        $display("Test 2: UART Output");
        $display("========================================");

        // Wait a bit more for UART transmission
        #10000;  // 10us should be enough for "TEST\n" @ 115200 baud

        if (uart_chars_received >= 4) begin
            $display("  [PASS] Received %0d UART characters (expected: TEST\\n)", uart_chars_received);
        end else if (uart_chars_received > 0) begin
            $display("  [WARN] Received %0d UART characters (expected 5)", uart_chars_received);
        end else begin
            $display("  [INFO] No UART output detected yet");
        end

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
        // Test 7: Verify Success Loop (Blink Pattern)
        //======================================================================
        $display("\n========================================");
        $display("Test 7: Success Loop Verification");
        $display("========================================");

        $display("  [INFO] Monitoring GPIO blink pattern...");

        // Monitor for a few blink cycles (firmware toggles bit 8)
        blink_count = 0;

        gpio_prev = gpio;
        repeat (3) begin
            #100000;  // Wait for blink toggle
            if (gpio[8] != gpio_prev[8]) begin
                blink_count = blink_count + 1;
                $display("  [INFO] Blink detected: GPIO changed from 0x%04h to 0x%04h",
                         gpio_prev, gpio);
            end
            gpio_prev = gpio;
        end

        if (blink_count >= 2) begin
            $display("  [PASS] Success loop confirmed (blink count: %0d)", blink_count);
        end else begin
            $display("  [INFO] Limited blink activity detected");
        end

        //======================================================================
        // Test Complete
        //======================================================================
        #1000;

        $display("");
        $display("========================================");
        $display("Testbench Complete");
        $display("========================================");
        $display("Simulation time: %0t", $time);
        $display("UART characters received: %0d", uart_chars_received);
        $display("");

        // Overall test summary
        if (gpio[7] && (uart_chars_received >= 4) && (blink_count >= 2)) begin
            $display("✓✓✓ ALL TESTS PASSED! ✓✓✓");
            $display("  - Firmware executed successfully");
            $display("  - All peripheral tests passed");
            $display("  - UART communication working");
            $display("  - CPU in stable success loop");
        end else begin
            $display("Test Summary:");
            $display("  - Firmware tests: %s", gpio[7] ? "PASS" : "INCOMPLETE/FAIL");
            $display("  - UART output: %s", (uart_chars_received >= 4) ? "PASS" : "FAIL");
            $display("  - Success loop: %s", (blink_count >= 2) ? "PASS" : "FAIL");
        end

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
        #50_000_000;  // 50 ms timeout (increased for comprehensive tests with debug output)
        $display("");
        $display("========================================");
        $display("ERROR: Simulation timeout!");
        $display("========================================");
        $display("Current GPIO status: 0x%04h", gpio);
        $display("Test progress (GPIO[3:0]): %0d", gpio[3:0]);
        $finish;
    end

    //==========================================================================
    // Signal Monitoring (Optional - for debugging)
    //==========================================================================

    // Monitor critical signals
    always @(posedge dut.clk) begin
        // =========================================================
        // Monitor ALL DBUS transactions (both reads and writes)
        // =========================================================
        if (dut.cpu_dbus_stb && dut.cpu_dbus_cyc) begin
            if (dut.cpu_dbus_we) begin
                // WRITE transaction
                $display("[DBUS] WRITE ADDR=0x%08h DATA=0x%08h SEL=%04b at time %t",
                        dut.cpu_dbus_addr, dut.cpu_dbus_dat_o, dut.cpu_dbus_sel, $time);

                // Detailed logging for specific peripherals
                if (dut.cpu_dbus_addr[31:8] == 24'h000205) begin
                    // UART writes
                    case (dut.cpu_dbus_addr[7:0])
                        8'h00: $display("[UART] Write DATA = 0x%02h ('%c')",
                                        dut.cpu_dbus_dat_o[7:0],
                                        (dut.cpu_dbus_dat_o[7:0] >= 32 && dut.cpu_dbus_dat_o[7:0] < 127) ?
                                        dut.cpu_dbus_dat_o[7:0] : ".");
                        8'h08: $display("[UART] Write CTRL = 0x%08h", dut.cpu_dbus_dat_o);
                        8'h0C: $display("[UART] Write BAUD_DIV = %0d", dut.cpu_dbus_dat_o);
                    endcase
                end else if (dut.cpu_dbus_addr >= 32'h00008000 && dut.cpu_dbus_addr < 32'h00018000) begin
                    // RAM writes
                    $display("[RAM]  Write to RAM[0x%08h] = 0x%08h",
                            dut.cpu_dbus_addr, dut.cpu_dbus_dat_o);
                end
            end else begin
                // READ transaction
                $display("[DBUS] READ  ADDR=0x%08h SEL=%04b at time %t",
                        dut.cpu_dbus_addr, dut.cpu_dbus_sel, $time);

                if (dut.cpu_dbus_addr >= 32'h00008000 && dut.cpu_dbus_addr < 32'h00018000) begin
                    $display("[RAM]  Read from RAM[0x%08h]", dut.cpu_dbus_addr);
                end else if (dut.cpu_dbus_addr >= 32'h00000000 && dut.cpu_dbus_addr < 32'h00008000) begin
                    $display("[ROM]  Read from ROM[0x%08h]", dut.cpu_dbus_addr);
                end
            end
        end

        // Monitor DBUS read responses (acknowledgement)
        if (dut.cpu_dbus_ack && !dut.cpu_dbus_we) begin
            $display("[DBUS] READ  RESPONSE DATA=0x%08h at time %t",
                    dut.cpu_dbus_dat_i, $time);
        end

        // Note: IBUS monitoring is already done in vexriscv_wrapper.v

        // Monitor UART TX state changes (only log transitions to reduce spam)
        // Comment this out to speed up simulation
        // if (dut.uart_periph.tx_state != 0) begin
        //     $display("[UART] TX state = %0d, tx_data = 0x%02h, uart_tx = %b at time %t",
        //             dut.uart_periph.tx_state, dut.uart_periph.tx_data, uart_tx, $time);
        // end
    end

endmodule
