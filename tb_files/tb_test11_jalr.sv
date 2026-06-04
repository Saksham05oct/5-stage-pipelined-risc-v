`timescale 1ns/1ps
import risc_pkg::*;

module tb_test11_jalr;
  logic clk;
  logic reset_n;

  initial clk = 0;
  always #5 clk = ~clk;

  top #(.RESET_PC(32'h0000)) u_top (
    .clk     (clk),
    .reset_n (reset_n)
  );

  int cycle_count = 0;
  logic test_passed = 1'b1;

  initial begin
    $dumpfile("tb_test11_jalr.vcd");
    $dumpvars(0, tb_test11_jalr);

    // Initialize test program instructions directly using inline byte concatenation
    {u_top.u_instruction_memory.mem[0],  u_top.u_instruction_memory.mem[1],  u_top.u_instruction_memory.mem[2],  u_top.u_instruction_memory.mem[3]}  = 32'h00d00093; // addi  x1, x0, 13    (target base is 13, an odd address)
    {u_top.u_instruction_memory.mem[4],  u_top.u_instruction_memory.mem[5],  u_top.u_instruction_memory.mem[6],  u_top.u_instruction_memory.mem[7]}  = 32'h000082e7; // jalr  x5, 0(x1)     (target = 13 + 0 = 13 -> LSB cleared to 12. Link = PC+4 = 8)
    {u_top.u_instruction_memory.mem[8],  u_top.u_instruction_memory.mem[9],  u_top.u_instruction_memory.mem[10], u_top.u_instruction_memory.mem[11]} = 32'h06300113; // addi  x2, x0, 99    (PC=8: should be flushed / skipped!)
    {u_top.u_instruction_memory.mem[12], u_top.u_instruction_memory.mem[13], u_top.u_instruction_memory.mem[14], u_top.u_instruction_memory.mem[15]} = 32'h02100193; // addi  x3, x0, 33    (PC=12: target of jalr. x3 = 33)
    {u_top.u_instruction_memory.mem[16], u_top.u_instruction_memory.mem[17], u_top.u_instruction_memory.mem[18], u_top.u_instruction_memory.mem[19]} = 32'h00302023; // sw    x3, 0(x0)     (store x3 to memory)

    // Pad remaining instruction memory with NOPs
    for (int i = 20; i < 128; i = i + 4) begin
      {u_top.u_instruction_memory.mem[i], u_top.u_instruction_memory.mem[i+1], u_top.u_instruction_memory.mem[i+2], u_top.u_instruction_memory.mem[i+3]} = 32'h00000013; // nop
    end

    // Reset sequence
    reset_n = 0;
    repeat(3) @(posedge clk);
    reset_n = 1;
    $display("Test 11: JALR Link And Bit-Zero Clearing started");

    // Run 20 cycles
    while (cycle_count < 20) begin
      @(posedge clk);
      cycle_count++;
    end

    $display("--- Registers ---");
    $display("x1 (base) = %d (exp 13)", u_top.u_register_file.regs[1]);
    $display("x5 (link) = 0x%08X (exp 0x00000008)", u_top.u_register_file.regs[5]);
    $display("x2 (skip) = %d (exp 0)", u_top.u_register_file.regs[2]);
    $display("x3 (target)= %d (exp 33)", u_top.u_register_file.regs[3]);
    $display("--- Data Memory ---");
    $display("mem[0]    = %d (exp 33)", {u_top.u_data_memory.mem[3], u_top.u_data_memory.mem[2], u_top.u_data_memory.mem[1], u_top.u_data_memory.mem[0]});

    // Verify Results
    if (u_top.u_register_file.regs[1] !== 32'd13)       test_passed = 0;
    if (u_top.u_register_file.regs[5] !== 32'h00000008) test_passed = 0;
    if (u_top.u_register_file.regs[2] !== 32'd0)        test_passed = 0;
    if (u_top.u_register_file.regs[3] !== 32'd33)       test_passed = 0;
    if ({u_top.u_data_memory.mem[3], u_top.u_data_memory.mem[2], u_top.u_data_memory.mem[1], u_top.u_data_memory.mem[0]} !== 32'd33)                  test_passed = 0;

    if (test_passed) begin
      $display("RESULT: TEST 11 PASSED");
    end else begin
      $display("RESULT: TEST 11 FAILED");
    end

    $finish;
  end

  final begin
    $dumpflush;
  end
endmodule
