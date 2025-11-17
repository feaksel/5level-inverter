/**
 * @file uart_vivado_test.v
 * @brief Comprehensive UART Test for Vivado Simulation
 *
 * This testbench provides clear, easy-to-interpret results for Vivado simulation.
 * Tests:
 * 1. Basic UART TX functionality
 * 2. Back-to-back character transmission (verifies tx_empty race condition fix)
 * 3. UART RX functionality
 * 4. Status register behavior
 *
 * Expected results are clearly printed to console.
 */

`timescale 1ns / 1ps

module uart_vivado_test;

    //==========================================================================
    // Parameters
    //==========================================================================

    parameter CLK_FREQ = 50_000_000;  // 50 MHz
    parameter BAUD_RATE = 115200;
    parameter CLK_PERIOD = 20;  // 20 ns = 50 MHz
    parameter BIT_PERIOD = 1_000_000_000 / BAUD_RATE;  // ~8680 ns

    //==========================================================================
    // DUT Signals
    //==========================================================================

    reg clk;
    reg rst_n;
    reg [7:0] wb_addr;
    reg [31:0] wb_dat_i;
    wire [31:0] wb_dat_o;
    reg wb_we;
    reg wb_stb;
    reg [3:0] wb_sel;
    wire wb_ack;
    wire uart_tx;
    reg uart_rx;
    wire irq;

    //==========================================================================
    // Test Status
    //==========================================================================

    integer test_number = 0;
    integer tests_passed = 0;
    integer tests_failed = 0;
    integer chars_sent = 0;
    integer chars_received = 0;
    reg [7:0] received_data [0:9];  // Store up to 10 received characters

    //==========================================================================
    // DUT Instantiation
    //==========================================================================

    uart #(
        .CLK_FREQ(CLK_FREQ),
        .DEFAULT_BAUD(BAUD_RATE)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .wb_addr(wb_addr),
        .wb_dat_i(wb_dat_i),
        .wb_dat_o(wb_dat_o),
        .wb_we(wb_we),
        .wb_sel(wb_sel),
        .wb_stb(wb_stb),
        .wb_ack(wb_ack),
        .uart_rx(uart_rx),
        .uart_tx(uart_tx),
        .irq(irq)
    );

    //==========================================================================
    // Clock Generation
    //==========================================================================

    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    //==========================================================================
    // Wishbone Bus Tasks
    //==========================================================================

    // Wishbone write transaction
    task wb_write;
        input [7:0] addr;
        input [31:0] data;
        begin
            @(posedge clk);
            #1;
            wb_addr = addr;
            wb_dat_i = data;
            wb_we = 1'b1;
            wb_sel = 4'hF;
            wb_stb = 1'b1;

            @(posedge clk);
            while (!wb_ack) @(posedge clk);
            #1;

            wb_stb = 1'b0;
            wb_we = 1'b0;
            @(posedge clk);
            #1;
        end
    endtask

    // Wishbone read transaction
    task wb_read;
        input [7:0] addr;
        output [31:0] data;
        begin
            @(posedge clk);
            #1;
            wb_addr = addr;
            wb_we = 1'b0;
            wb_sel = 4'hF;
            wb_stb = 1'b1;

            @(posedge clk);
            while (!wb_ack) @(posedge clk);
            data = wb_dat_o;
            #1;

            wb_stb = 1'b0;
            @(posedge clk);
            #1;
        end
    endtask

    //==========================================================================
    // UART Protocol Tasks
    //==========================================================================

    // Monitor UART TX and capture transmitted byte
    task uart_monitor_tx;
        output [7:0] data;
        integer i;
        begin
            // Wait for start bit (falling edge on uart_tx)
            @(negedge uart_tx);
            #(BIT_PERIOD/2);  // Move to center of start bit

            if (uart_tx == 1'b0) begin
                // Valid start bit
                #BIT_PERIOD;  // Move to first data bit

                // Capture 8 data bits (LSB first)
                for (i = 0; i < 8; i = i + 1) begin
                    data[i] = uart_tx;
                    #BIT_PERIOD;
                end

                // Verify stop bit
                if (uart_tx == 1'b1) begin
                    // Valid stop bit - successful reception
                    received_data[chars_received] = data;
                    chars_received = chars_received + 1;

                    if (data >= 32 && data <= 126) begin
                        $display("    [TIME=%0t] RX: 0x%02h '%c'", $time, data, data);
                    end else begin
                        $display("    [TIME=%0t] RX: 0x%02h (non-printable)", $time, data);
                    end
                end else begin
                    $display("    [ERROR] Frame error - invalid stop bit at time %0t", $time);
                end
            end
        end
    endtask

    // Send byte via UART RX (simulate external device sending to SoC)
    task uart_send_rx;
        input [7:0] data;
        integer i;
        begin
            // Start bit
            uart_rx = 1'b0;
            #BIT_PERIOD;

            // Data bits (LSB first)
            for (i = 0; i < 8; i = i + 1) begin
                uart_rx = data[i];
                #BIT_PERIOD;
            end

            // Stop bit
            uart_rx = 1'b1;
            #BIT_PERIOD;
        end
    endtask

    //==========================================================================
    // Test Helper Tasks
    //==========================================================================

    // Print test header
    task test_start;
        input [80*8-1:0] description;
        begin
            test_number = test_number + 1;
            $display("");
            $display("========================================");
            $display("TEST %0d: %0s", test_number, description);
            $display("========================================");
        end
    endtask

    // Check test result
    task test_check;
        input condition;
        input [80*8-1:0] pass_msg;
        input [80*8-1:0] fail_msg;
        begin
            if (condition) begin
                $display("  [PASS] %0s", pass_msg);
                tests_passed = tests_passed + 1;
            end else begin
                $display("  [FAIL] %0s", fail_msg);
                tests_failed = tests_failed + 1;
            end
        end
    endtask

    // Wait for TX to complete by polling TX_EMPTY flag
    task wait_tx_complete;
        integer timeout;
        reg [31:0] status;
        begin
            timeout = 0;
            status = 0;

            // Poll STATUS register for TX_EMPTY=1
            while (!status[1] && timeout < 100000) begin
                #(CLK_PERIOD * 10);  // Wait a bit between polls
                wb_read(8'h04, status);  // Read STATUS register
                timeout = timeout + 1;
            end

            if (status[1]) begin
                $display("    [INFO] TX completed (polled %0d times)", timeout);
            end else begin
                $display("    [ERROR] TX timeout after %0d polls!", timeout);
            end
        end
    endtask

    //==========================================================================
    // Background UART Monitor
    //==========================================================================

    // Continuously monitor UART TX line
    initial begin
        #1;  // Small delay to let initialization happen
        forever begin
            uart_monitor_tx(received_data[chars_received]);
        end
    end

    //==========================================================================
    // Main Test Sequence
    //==========================================================================

    initial begin
        // Waveform dump for debugging
        $dumpfile("uart_vivado_test.vcd");
        $dumpvars(0, uart_vivado_test);

        // Initialize signals
        rst_n = 0;
        uart_rx = 1'b1;
        wb_addr = 0;
        wb_dat_i = 0;
        wb_we = 0;
        wb_sel = 0;
        wb_stb = 0;
        chars_sent = 0;
        chars_received = 0;

        $display("");
        $display("================================================================================");
        $display("                    UART COMPREHENSIVE VERIFICATION TEST");
        $display("================================================================================");
        $display("Clock Frequency: %0d Hz", CLK_FREQ);
        $display("Baud Rate:       %0d bps", BAUD_RATE);
        $display("Bit Period:      %0d ns", BIT_PERIOD);
        $display("================================================================================");
        $display("");

        // Release reset
        #100;
        rst_n = 1;
        #100;

        //======================================================================
        // TEST 1: Basic Register Access
        //======================================================================
        test_start("Basic Register Access");

        begin
            reg [31:0] read_data;

            // Read STATUS register
            wb_read(8'h04, read_data);
            $display("    STATUS = 0x%08h (TX_EMPTY=%0d, RX_READY=%0d)",
                     read_data, read_data[1], read_data[0]);
            test_check(read_data[1] == 1'b1,
                      "TX_EMPTY should be 1 after reset",
                      "TX_EMPTY not set after reset");

            // Read CTRL register
            wb_read(8'h08, read_data);
            $display("    CTRL = 0x%08h", read_data);
            test_check(read_data[0] == 1'b1 && read_data[1] == 1'b1,
                      "TX and RX enabled by default",
                      "TX/RX not properly enabled");
        end

        //======================================================================
        // TEST 2: Single Character Transmission
        //======================================================================
        test_start("Single Character TX ('A')");

        begin
            integer start_time, end_time;

            start_time = $time;
            $display("    Sending 'A' (0x41)...");
            wb_write(8'h00, 32'h41);  // Write 'A' to DATA register
            chars_sent = chars_sent + 1;

            // Wait for transmission
            wait_tx_complete();
            end_time = $time;

            #(BIT_PERIOD * 2);  // Extra time for RX monitor to complete

            $display("    Transmission time: %0d ns", end_time - start_time);
            test_check(chars_received == 1,
                      "Character 'A' received",
                      "Character not received");
            if (chars_received >= 1) begin
                test_check(received_data[0] == 8'h41,
                          "Received data matches (0x41)",
                          $sformatf("Received 0x%02h instead of 0x41", received_data[0]));
            end
        end

        //======================================================================
        // TEST 3: Back-to-Back Transmission (Race Condition Test)
        //======================================================================
        test_start("Back-to-Back TX ('B' then 'C') - Race Condition Fix Verification");

        begin
            integer start_time, end_time, elapsed;
            integer prev_received;

            prev_received = chars_received;
            start_time = $time;

            $display("    Sending 'B' (0x42)...");
            wb_write(8'h00, 32'h42);
            chars_sent = chars_sent + 1;
            wait_tx_complete();

            $display("    Sending 'C' (0x43) immediately...");
            wb_write(8'h00, 32'h43);
            chars_sent = chars_sent + 1;
            wait_tx_complete();

            end_time = $time;
            elapsed = end_time - start_time;

            #(BIT_PERIOD * 2);

            $display("    Total time for 2 chars: %0d ns (%0.3f ms)",
                     elapsed, elapsed / 1000000.0);
            $display("    Expected time: ~%0d ns (%0.3f ms)",
                     BIT_PERIOD * 20, (BIT_PERIOD * 20) / 1000000.0);

            // Check both characters received
            test_check(chars_received == prev_received + 2,
                      "Both characters received",
                      $sformatf("Only %0d of 2 characters received",
                                chars_received - prev_received));

            // Verify data
            if (chars_received >= prev_received + 2) begin
                test_check(received_data[prev_received] == 8'h42,
                          "First char is 'B' (0x42)",
                          $sformatf("Got 0x%02h", received_data[prev_received]));
                test_check(received_data[prev_received + 1] == 8'h43,
                          "Second char is 'C' (0x43)",
                          $sformatf("Got 0x%02h", received_data[prev_received + 1]));
            end

            // Critical test: timing should be reasonable (< 1ms, not seconds!)
            test_check(elapsed < 1_000_000,  // Less than 1ms
                      "Timing is fast (race condition FIXED)",
                      "Timing is slow (race condition present!)");
        end

        //======================================================================
        // TEST 4: Multiple Characters
        //======================================================================
        test_start("Send String 'HELLO'");

        begin
            integer i;
            integer prev_received;
            reg [7:0] test_string [0:4];

            test_string[0] = "H";
            test_string[1] = "E";
            test_string[2] = "L";
            test_string[3] = "L";
            test_string[4] = "O";

            prev_received = chars_received;

            for (i = 0; i < 5; i = i + 1) begin
                $display("    Sending '%c' (0x%02h)...", test_string[i], test_string[i]);
                wb_write(8'h00, {24'h0, test_string[i]});
                chars_sent = chars_sent + 1;
                wait_tx_complete();
            end

            #(BIT_PERIOD * 5);

            test_check(chars_received == prev_received + 5,
                      "All 5 characters received",
                      $sformatf("Only %0d of 5 received", chars_received - prev_received));

            // Verify string
            if (chars_received >= prev_received + 5) begin
                reg string_ok;
                string_ok = 1;
                for (i = 0; i < 5; i = i + 1) begin
                    if (received_data[prev_received + i] != test_string[i]) begin
                        string_ok = 0;
                    end
                end
                test_check(string_ok, "String 'HELLO' matches", "String mismatch");
            end
        end

        //======================================================================
        // TEST 5: UART RX (Receive from external device)
        //======================================================================
        test_start("UART RX - Receive from External Device");

        begin
            reg [31:0] status, rx_data;

            $display("    Sending byte 0x55 via uart_rx...");
            uart_send_rx(8'h55);

            // Small delay for processing
            #(BIT_PERIOD * 2);

            // Read STATUS - should have RX_READY=1
            wb_read(8'h04, status);
            $display("    STATUS = 0x%08h (RX_READY=%0d)", status, status[0]);
            test_check(status[0] == 1'b1,
                      "RX_READY flag is set",
                      "RX_READY flag not set");

            // Read received data
            wb_read(8'h00, rx_data);
            $display("    Received data: 0x%02h", rx_data[7:0]);
            test_check(rx_data[7:0] == 8'h55,
                      "Received data matches (0x55)",
                      $sformatf("Got 0x%02h", rx_data[7:0]));

            // STATUS should clear RX_READY after read
            wb_read(8'h04, status);
            test_check(status[0] == 1'b0,
                      "RX_READY cleared after DATA read",
                      "RX_READY still set after read");
        end

        //======================================================================
        // TEST 6: Status Flags
        //======================================================================
        test_start("Status Flag Behavior");

        begin
            reg [31:0] status1, status2;

            // Read initial status
            wb_read(8'h04, status1);
            $display("    Initial STATUS = 0x%08h (TX_EMPTY=%0d)", status1, status1[1]);

            // Start transmission
            wb_write(8'h00, 32'h58);  // Send 'X'
            chars_sent = chars_sent + 1;

            // Read status immediately - TX_EMPTY should be 0
            #(CLK_PERIOD * 5);
            wb_read(8'h04, status2);
            $display("    STATUS during TX = 0x%08h (TX_EMPTY=%0d)", status2, status2[1]);
            test_check(status2[1] == 1'b0,
                      "TX_EMPTY=0 during transmission",
                      "TX_EMPTY should be 0 during TX");

            // Wait for completion
            wait_tx_complete();

            // TX_EMPTY should be 1 again
            wb_read(8'h04, status1);
            $display("    STATUS after TX = 0x%08h (TX_EMPTY=%0d)", status1, status1[1]);
            test_check(status1[1] == 1'b1,
                      "TX_EMPTY=1 after transmission complete",
                      "TX_EMPTY should be 1 after TX complete");
        end

        //======================================================================
        // Final Summary
        //======================================================================
        #1000;

        $display("");
        $display("================================================================================");
        $display("                           TEST SUMMARY");
        $display("================================================================================");
        $display("Total Tests:    %0d", test_number);
        $display("Tests Passed:   %0d", tests_passed);
        $display("Tests Failed:   %0d", tests_failed);
        $display("Characters Sent:     %0d", chars_sent);
        $display("Characters Received: %0d", chars_received);
        $display("");

        if (tests_failed == 0) begin
            $display("     ██████╗  █████╗ ███████╗███████╗");
            $display("     ██╔══██╗██╔══██╗██╔════╝██╔════╝");
            $display("     ██████╔╝███████║███████╗███████╗");
            $display("     ██╔═══╝ ██╔══██║╚════██║╚════██║");
            $display("     ██║     ██║  ██║███████║███████║");
            $display("     ╚═╝     ╚═╝  ╚═╝╚══════╝╚══════╝");
            $display("");
            $display("     ✓ ALL TESTS PASSED!");
            $display("     ✓ UART tx_empty race condition is FIXED");
            $display("     ✓ UART is working correctly");
        end else begin
            $display("     ███████╗ █████╗ ██╗██╗     ");
            $display("     ██╔════╝██╔══██╗██║██║     ");
            $display("     █████╗  ███████║██║██║     ");
            $display("     ██╔══╝  ██╔══██║██║██║     ");
            $display("     ██║     ██║  ██║██║███████╗");
            $display("     ╚═╝     ╚═╝  ╚═╝╚═╝╚══════╝");
            $display("");
            $display("     ✗ SOME TESTS FAILED");
            $display("     Review the test output above for details");
        end

        $display("================================================================================");
        $display("");

        // End simulation
        #1000;
        $finish;
    end

    //==========================================================================
    // Timeout Watchdog
    //==========================================================================

    initial begin
        #100_000_000;  // 100ms timeout
        $display("");
        $display("ERROR: Simulation timeout!");
        $display("Simulation exceeded 100ms - possible hang or race condition");
        $finish;
    end

endmodule
