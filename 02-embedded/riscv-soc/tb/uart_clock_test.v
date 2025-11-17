/**
 * @file uart_clock_test.v
 * @brief Verify UART works correctly with clock divider
 *
 * Tests that UART receives correct data when clock is divided by 2
 * (simulating soc_top's clock divider behavior).
 */

`timescale 1ns / 1ps

module uart_clock_test;

    parameter CLK_FREQ = 50_000_000;
    parameter BAUD_RATE = 115200;
    parameter INPUT_CLK_PERIOD = 10;  // 100 MHz input
    parameter BIT_PERIOD = 1000_000_000 / BAUD_RATE;  // ~8680 ns

    // Signals
    reg clk_100mhz, rst_n;
    reg clk_50mhz, clk_div;

    reg [7:0] wb_addr;
    reg [31:0] wb_dat_i;
    wire [31:0] wb_dat_o;
    reg wb_we, wb_stb;
    reg [3:0] wb_sel;
    wire wb_ack;
    wire uart_tx, irq;
    reg uart_rx;

    integer chars_received = 0;
    reg [7:0] received_chars [0:4];
    integer test_errors = 0;

    // Clock divider (same as soc_top.v) - Fixed to divide by 2
    always @(posedge clk_100mhz or negedge rst_n) begin
        if (!rst_n) begin
            clk_50mhz <= 1'b0;
        end else begin
            clk_50mhz <= ~clk_50mhz;  // Toggle every cycle = divide by 2
        end
    end

    // DUT - UART running on divided clock
    uart #(
        .CLK_FREQ(CLK_FREQ),
        .DEFAULT_BAUD(BAUD_RATE)
    ) dut (
        .clk(clk_50mhz),  // Use divided clock
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

    // Input clock (100 MHz)
    initial begin
        clk_100mhz = 0;
        forever #(INPUT_CLK_PERIOD/2) clk_100mhz = ~clk_100mhz;
    end

    // Wishbone write task - uses divided clock
    task wb_write;
        input [7:0] addr;
        input [31:0] data;
        begin
            @(posedge clk_50mhz);
            wb_addr = addr;
            wb_dat_i = data;
            wb_we = 1'b1;
            wb_sel = 4'hF;
            wb_stb = 1'b1;
            @(posedge clk_50mhz);
            while (!wb_ack) @(posedge clk_50mhz);
            wb_stb = 1'b0;
            wb_we = 1'b0;
            @(posedge clk_50mhz);
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
                end else begin
                    $display("  [FAIL] Frame error at time %0t", $time);
                    test_errors = test_errors + 1;
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
        test_errors = 0;

        #100 rst_n = 1;
        #100;

        $display("");
        $display("========================================");
        $display("UART Clock Divider Test");
        $display("========================================");
        $display("Input clock: 100 MHz");
        $display("System clock: 50 MHz (divided by 2)");
        $display("UART baud: 115200");
        $display("");

        // Wait for clock to stabilize
        repeat(10) @(posedge clk_50mhz);

        // Send test string: "ABCD"
        $display("[TIME=%0t] Sending 'ABCD'...", $time);

        wb_write(8'h00, 32'h00000041);  // 'A'
        #(BIT_PERIOD * 12);

        wb_write(8'h00, 32'h00000042);  // 'B'
        #(BIT_PERIOD * 12);

        wb_write(8'h00, 32'h00000043);  // 'C'
        #(BIT_PERIOD * 12);

        wb_write(8'h00, 32'h00000044);  // 'D'
        #(BIT_PERIOD * 12);

        // Wait for all transmissions
        #(BIT_PERIOD * 20);

        $display("");
        $display("========================================");
        $display("Test Results");
        $display("========================================");
        $display("Characters received: %0d", chars_received);

        if (chars_received >= 1) $display("  Char 0: 0x%02h ('%c') - Expected 0x41 ('A')",
                                          received_chars[0], received_chars[0]);
        if (chars_received >= 2) $display("  Char 1: 0x%02h ('%c') - Expected 0x42 ('B')",
                                          received_chars[1], received_chars[1]);
        if (chars_received >= 3) $display("  Char 2: 0x%02h ('%c') - Expected 0x43 ('C')",
                                          received_chars[2], received_chars[2]);
        if (chars_received >= 4) $display("  Char 3: 0x%02h ('%c') - Expected 0x44 ('D')",
                                          received_chars[3], received_chars[3]);
        $display("");

        // Verify results
        if (chars_received == 4 &&
            received_chars[0] == 8'h41 &&
            received_chars[1] == 8'h42 &&
            received_chars[2] == 8'h43 &&
            received_chars[3] == 8'h44 &&
            test_errors == 0) begin

            $display("✓✓✓ TEST PASSED! ✓✓✓");
            $display("");
            $display("✅ All 4 characters received correctly");
            $display("✅ No frame errors");
            $display("✅ Clock divider works correctly");
            $display("✅ UART baud rate is correct");
        end else begin
            $display("✗ TEST FAILED!");
            if (chars_received != 4)
                $display("❌ Expected 4 characters, got %0d", chars_received);
            if (test_errors > 0)
                $display("❌ Frame errors: %0d", test_errors);
            if (chars_received > 0 && received_chars[0] != 8'h41)
                $display("❌ Char 0 mismatch: got 0x%02h, expected 0x41", received_chars[0]);
            if (chars_received > 1 && received_chars[1] != 8'h42)
                $display("❌ Char 1 mismatch: got 0x%02h, expected 0x42", received_chars[1]);
            if (chars_received > 2 && received_chars[2] != 8'h43)
                $display("❌ Char 2 mismatch: got 0x%02h, expected 0x43", received_chars[2]);
            if (chars_received > 3 && received_chars[3] != 8'h44)
                $display("❌ Char 3 mismatch: got 0x%02h, expected 0x44", received_chars[3]);
        end

        $display("========================================");
        $display("");

        $finish;
    end

    // Timeout
    initial begin
        #10_000_000;  // 10ms timeout
        $display("");
        $display("ERROR: Simulation timeout!");
        $finish;
    end

endmodule
