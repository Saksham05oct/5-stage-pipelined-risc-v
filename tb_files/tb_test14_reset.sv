`timescale 1ns/1ps
import risc_pkg::*;

module tb_test14_reset;
  logic clk;
  logic reset_n;

  initial clk = 0;
  always #5 clk = ~clk;

  top #(.RESET_PC(32'h0000)) u_top (
    .clk     (clk),
    .reset_n (reset_n)
  );

  function automatic logic [31:0] read_dmem_word(input int addr);
    return {u_top.u_data_memory.mem[addr+3],
            u_top.u_data_memory.mem[addr+2],
            u_top.u_data_memory.mem[addr+1],
            u_top.u_data_memory.mem[addr]};
  endfunction

  task write_instruction(input int addr, input logic [31:0] inst);
    u_top.u_instruction_memory.mem[addr]   = inst[31:24];
    u_top.u_instruction_memory.mem[addr+1] = inst[23:16];
    u_top.u_instruction_memory.mem[addr+2] = inst[15:8];
    u_top.u_instruction_memory.mem[addr+3] = inst[7:0];
  endtask

  int cycle_count = 0;
  logic test_passed = 1'b1;

  initial begin
    $dumpfile("tb_test14_reset.vcd");
    $dumpvars(0, tb_test14_reset);

    // Initialize test program instructions
    write_instruction(32'h00, 32'h00500093); // addi x1, x0, 5
    write_instruction(32'h04, 32'h00102023); // sw   x1, 0(x0)     (store x1 at address 0)

    // Pad remaining instruction memory with NOPs
    for (int i = 8; i < 128; i = i + 4) begin
      write_instruction(i, 32'h00000013); // nop
    end

    // 1. Initial Reset sequence
    reset_n = 0;
    repeat(3) @(posedge clk);
    reset_n = 1;
    $display("Test 14: Reset Behavior started");

    // 2. Let it run for 10 cycles (registers should get populated)
    repeat(10) @(posedge clk);
    $display("--- State before reset ---");
    $display("PC = 0x%08X", u_top.current_pc);
    $display("x1 = %d (exp 5)", u_top.u_register_file.regs[1]);
    $display("mem[0] = %d (exp 5)", read_dmem_word(0));
    if (u_top.u_register_file.regs[1] !== 32'd5) test_passed = 0;
    if (read_dmem_word(0) !== 32'd5)            test_passed = 0;

    // 3. Assert reset again
    reset_n = 0;
    repeat(2) @(posedge clk);
    #1; // Settling time

    $display("--- State during reset ---");
    $display("PC = 0x%08X (exp 0x00000000)", u_top.current_pc);
    $display("x1 = %d (exp 0)", u_top.u_register_file.regs[1]);
    if (u_top.current_pc !== 32'h00000000)      test_passed = 0;
    if (u_top.u_register_file.regs[1] !== 32'd0) test_passed = 0;

    // Clear memory to see if it writes again after reset release
    u_top.u_data_memory.mem[0] = 8'd0;
    u_top.u_data_memory.mem[1] = 8'd0;
    u_top.u_data_memory.mem[2] = 8'd0;
    u_top.u_data_memory.mem[3] = 8'd0;

    // 4. Release reset and verify execution restarts
    reset_n = 1;
    repeat(10) @(posedge clk);
    #1;

    $display("--- State after reset release ---");
    $display("PC = 0x%08X", u_top.current_pc);
    $display("x1 = %d (exp 5)", u_top.u_register_file.regs[1]);
    $display("mem[0] = %d (exp 5)", read_dmem_word(0));
    if (u_top.u_register_file.regs[1] !== 32'd5) test_passed = 0;
    if (read_dmem_word(0) !== 32'd5)            test_passed = 0;

    if (test_passed) begin
      $display("RESULT: TEST 14 PASSED");
    end else begin
      $display("RESULT: TEST 14 FAILED");
    end

    $finish;
  end

  final begin
    $dumpflush;
  end
endmodule
