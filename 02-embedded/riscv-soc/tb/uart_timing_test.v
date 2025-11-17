/**
 * @file uart_timing_test.v
 * @brief UART Race Condition Fix Verification Testbench
 *
 * Tests that the tx_empty race condition is fixed by verifying:
 * 1. Two characters can be sent back-to-back
 * 2. Total transmission time is ~2ms (not 2 seconds)
 * 3. tx_empty flag behavior is correct
 */

`timescale 1ns / 1ps

module uart_timing_test;

    parameter CLK_FREQ = 50_000_000;
    parameter BAUD_RATE = 115200;
    parameter CLK_PERIOD = 20;  // 50 MHz = 20 ns
    parameter BIT_PERIOD = 1000_000_000 / BAUD_RATE;  // ~8680 ns

    // Signals
    reg clk, rst_n;
    reg [7:0] wb_addr;
    reg [31:0] wb_dat_i;
    wire [31:0] wb_dat_o;
    reg wb_we, wb_stb;
    reg [3:0] wb_sel;
    wire wb_ack;
    wire uart_tx, irq;
    reg uart_rx;

    integer chars_received = 0;
    reg [7:0] received_chars [0:1];
    integer start_time, end_time, elapsed_time;

    // DUT
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

    // Clock
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // Wishbone write
    task wb_write;
        input [7:0] addr;
        input [31:0] data;
        begin
            @(posedge clk);
            wb_addr = addr;
            wb_dat_i = data;
            wb_we = 1'b1;
            wb_sel = 4'hF;
            wb_stb = 1'b1;
            @(posedge clk);
            while (!wb_ack) @(posedge clk);
            wb_stb = 1'b0;
            wb_we = 1'b0;
            @(posedge clk);
        end
    endtask

    // Wishbone read
    task wb_read;
        input [7:0] addr;
        output [31:0] data;
        begin
            @(posedge clk);
            wb_addr = addr;
            wb_we = 1'b0;
            wb_sel = 4'hF;
            wb_stb = 1'b1;
            @(posedge clk);
            while (!wb_ack) @(posedge clk);
            data = wb_dat_o;
            wb_stb = 1'b0;
            @(posedge clk);
        end
    endtask

    // UART receiver - monitors uart_tx
    task uart_receive_byte;
        output [7:0] data;
        integer i;
        begin
            // Wait for start bit
            @(negedge uart_tx);
            #(BIT_PERIOD/2);  // Center of start bit

            if (uart_tx == 1'b0) begin
                #BIT_PERIOD;  // Move to first data bit

                // Receive 8 data bits (LSB first)
                for (i = 0; i < 8; i = i + 1) begin
                    data[i] = uart_tx;
                    #BIT_PERIOD;
                end

                // Check stop bit
                if (uart_tx == 1'b1) begin
                    $display("  [TIME=%0t] Received: 0x%02h ('%c')",
                             $time, data, (data >= 32 && data < 127) ? data : ".");
                    received_chars[chars_received] = data;
                    chars_received = chars_received + 1;
                    if (chars_received == 2) begin
                        end_time = $time;
                    end
                end else begin
                    $display("  [FAIL] Frame error at time %0t", $time);
                end
            end
        end
    endtask

    // Background task to monitor UART
    initial begin
        forever begin
            uart_receive_byte(received_chars[chars_received]);
        end
    end

    // Main test
    initial begin
        // Initialize
        rst_n = 0;
        uart_rx = 1'b1;
        wb_addr = 0;
        wb_dat_i = 0;
        wb_we = 0;
        wb_sel = 0;
        wb_stb = 0;
        chars_received = 0;

        #100 rst_n = 1;
        #100;

        $display("");
        $display("========================================");
        $display("UART Race Condition Fix Verification");
        $display("========================================");
        $display("Testing tx_empty flag timing...");
        $display("");

        // Record start time
        start_time = $time;
        $display("[TIME=%0t] Starting test - sending 'A' and 'B'", $time);

        // Send 'A' (0x41)
        $display("[TIME=%0t] Writing 'A' to UART...", $time);
        wb_write(8'h00, 32'h00000041);

        // Poll for TX_EMPTY before sending next character
        // This is the critical test - if race condition exists, this will hang
        begin
            reg [31:0] status;
            integer poll_count;

            poll_count = 0;
            status = 0;

            // Wait a tiny bit for the write to take effect
            #100;

            // Poll TX_EMPTY (should go 0 immediately, then 1 after transmission)
            while (!status[1] && poll_count < 10000) begin
                wb_read(8'h04, status);  // Read STATUS register
                poll_count = poll_count + 1;
                #(CLK_PERIOD * 10);  // Poll every 200ns
            end

            if (status[1]) begin  // TX_EMPTY bit
                $display("[TIME=%0t] TX_EMPTY=1 after %0d polls", $time, poll_count);
            end else begin
                $display("  [FAIL] TX_EMPTY stuck at 0 after %0d polls!", poll_count);
                $finish;
            end
        end

        // Send 'B' (0x42)
        $display("[TIME=%0t] Writing 'B' to UART...", $time);
        wb_write(8'h00, 32'h00000042);

        // Wait for transmission to complete
        begin
            reg [31:0] status;
            integer poll_count;

            poll_count = 0;
            status = 0;

            #100;

            while (!status[1] && poll_count < 10000) begin
                wb_read(8'h04, status);
                poll_count = poll_count + 1;
                #(CLK_PERIOD * 10);
            end

            if (status[1]) begin
                $display("[TIME=%0t] TX_EMPTY=1 after %0d polls", $time, poll_count);
            end else begin
                $display("  [FAIL] TX_EMPTY stuck at 0 after %0d polls!", poll_count);
                $finish;
            end
        end

        // Wait a bit more for UART receive task to complete
        #(BIT_PERIOD * 20);

        // Calculate elapsed time
        elapsed_time = end_time - start_time;

        $display("");
        $display("========================================");
        $display("Test Results");
        $display("========================================");
        $display("Characters received: %0d", chars_received);
        if (chars_received >= 1) $display("  Char 0: 0x%02h ('%c')", received_chars[0], received_chars[0]);
        if (chars_received >= 2) $display("  Char 1: 0x%02h ('%c')", received_chars[1], received_chars[1]);
        $display("");
        $display("Timing:");
        $display("  Start time:   %0t ns", start_time);
        $display("  End time:     %0t ns", end_time);
        $display("  Elapsed time: %0t ns", elapsed_time);
        $display("  Elapsed time: %0.3f ms", elapsed_time / 1000000.0);
        $display("");

        // Expected time: 2 characters × 10 bits × ~8680ns = ~173,600 ns = ~0.174 ms
        // Plus some overhead for polling = ~0.2-0.5 ms is reasonable
        // Anything over 100ms indicates the race condition is still present

        if (chars_received == 2 &&
            received_chars[0] == 8'h41 &&
            received_chars[1] == 8'h42) begin

            if (elapsed_time < 100_000_000) begin  // Less than 100ms
                $display("✓✓✓ TEST PASSED! ✓✓✓");
                $display("");
                $display("✅ Both characters received correctly");
                $display("✅ Timing is reasonable (%0.3f ms)", elapsed_time / 1000000.0);
                $display("✅ tx_empty race condition is FIXED!");

                if (elapsed_time < 10_000_000) begin  // Less than 10ms
                    $display("✅ Excellent timing (< 10ms)");
                end
            end else begin
                $display("✗ TEST FAILED!");
                $display("❌ Timing too slow (%0.3f ms)", elapsed_time / 1000000.0);
                $display("❌ Race condition likely still present");
            end
        end else begin
            $display("✗ TEST FAILED!");
            $display("❌ Did not receive both characters correctly");
        end

        $display("========================================");
        $display("");

        $finish;
    end

    // Timeout
    initial begin
        #500_000_000;  // 500ms timeout
        $display("");
        $display("ERROR: Simulation timeout after 500ms!");
        $display("This indicates the race condition is still present.");
        $finish;
    end

endmodule
