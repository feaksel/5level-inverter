/**
 * @file uart_tb.v
 * @brief Testbench for UART Peripheral
 *
 * Tests UART transmission and reception with 8N1 format.
 */

`timescale 1ns / 1ps

module uart_tb;

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

    integer errors = 0;

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

    // Send UART byte (simulate external device)
    task uart_send_byte;
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

    // Main test
    initial begin
        $dumpfile("sim/uart_tb.vcd");
        $dumpvars(0, uart_tb);

        // Initialize
        rst_n = 0;
        uart_rx = 1'b1;
        wb_addr = 0;
        wb_dat_i = 0;
        wb_we = 0;
        wb_sel = 0;
        wb_stb = 0;

        #100 rst_n = 1;
        #100;

        $display("========================================");
        $display("UART Testbench");
        $display("========================================");

        // Test 1: Transmit byte
        $display("\nTest 1: Transmit Byte 0x55");
        wb_write(8'h00, 32'h00000055);  // Write TX data

        // Wait for transmission to complete
        #(BIT_PERIOD * 11);  // 1 start + 8 data + 1 stop + margin
        $display("  TX complete");

        // Test 2: Receive byte
        $display("\nTest 2: Receive Byte 0xAA");
        uart_send_byte(8'hAA);
        #1000;

        begin
            reg [31:0] read_data;
            wb_read(8'h04, read_data);  // Read STATUS
            if (read_data[0]) begin  // RX_READY
                $display("  [PASS] RX data ready");
                wb_read(8'h00, read_data);  // Read DATA
                if (read_data[7:0] == 8'hAA) begin
                    $display("  [PASS] Received correct data: 0x%02h", read_data[7:0]);
                end else begin
                    $display("  [FAIL] Received wrong data: 0x%02h", read_data[7:0]);
                    errors = errors + 1;
                end
            end else begin
                $display("  [FAIL] RX data not ready");
                errors = errors + 1;
            end
        end

        // Test 3: Multiple bytes
        $display("\nTest 3: Multiple Bytes");
        uart_send_byte(8'h48);  // 'H'
        #(BIT_PERIOD * 12);
        uart_send_byte(8'h49);  // 'I'
        #(BIT_PERIOD * 12);

        $display("  Sent 'HI' via UART");

        #10000;

        $display("\n========================================");
        $display("Test Summary: %0d errors", errors);
        if (errors == 0)
            $display("  ✓ ALL TESTS PASSED!");
        else
            $display("  ✗ TESTS FAILED!");
        $display("========================================\n");

        $finish;
    end

    // Timeout
    initial begin
        #50_000_000;
        $display("ERROR: Simulation timeout!");
        $finish;
    end

endmodule
