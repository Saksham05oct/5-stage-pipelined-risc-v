`timescale 1ns/1ps
import risc_pkg::*;

module tb_test7_store_fwd;
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
    $dumpfile("tb_test7_store_fwd.vcd");
    $dumpvars(0, tb_test7_store_fwd);

    // Initialize test program instructions directly using inline byte concatenation
    {u_top.u_instruction_memory.mem[0],  u_top.u_instruction_memory.mem[1],  u_top.u_instruction_memory.mem[2],  u_top.u_instruction_memory.mem[3]}  = 32'h063000d3; // addi x1, x0, 99
    {u_top.u_instruction_memory.mem[4],  u_top.u_instruction_memory.mem[5],  u_top.u_instruction_memory.mem[6],  u_top.u_instruction_memory.mem[7]}  = 32'h00102023; // sw   x1, 0(x0)     (store uses value produced by previous instruction)
    {u_top.u_instruction_memory.mem[8],  u_top.u_instruction_memory.mem[9],  u_top.u_instruction_memory.mem[10], u_top.u_instruction_memory.mem[11]} = 32'h00002103; // lw   x2, 0(x0)     (load value to verify it was stored correctly)

    // Pad remaining instruction memory with NOPs
    for (int i = 12; i < 128; i = i + 4) begin
      {u_top.u_instruction_memory.mem[i], u_top.u_instruction_memory.mem[i+1], u_top.u_instruction_memory.mem[i+2], u_top.u_instruction_memory.mem[i+3]} = 32'h00000013; // nop
    end

    // Reset sequence
    reset_n = 0;
    repeat(3) @(posedge clk);
    reset_n = 1;
    $display("Test 7: Store Data Forwarding started");

    // Run 15 cycles
    while (cycle_count < 15) begin
      @(posedge clk);
      cycle_count++;
    end

    $display("--- Registers ---");
    $display("x1 = %d (exp 99)", u_top.u_register_file.regs[1]);
    $display("x2 = %d (exp 99)", u_top.u_register_file.regs[2]);
    $display("--- Data Memory ---");
    $display("mem[0] = %d (exp 99)", {u_top.u_data_memory.mem[3], u_top.u_data_memory.mem[2], u_top.u_data_memory.mem[1], u_top.u_data_memory.mem[0]});

    // Verify Results
    if (u_top.u_register_file.regs[1] !== 32'd99) test_passed = 0;
    if (u_top.u_register_file.regs[2] !== 32'd99) test_passed = 0;
    if ({u_top.u_data_memory.mem[3], u_top.u_data_memory.mem[2], u_top.u_data_memory.mem[1], u_top.u_data_memory.mem[0]} !== 32'd99)            test_passed = 0;

    if (test_passed) begin
      $display("RESULT: TEST 7 PASSED");
    end else begin
      $display("RESULT: TEST 7 FAILED");
    end

    $finish;
  end

  final begin
    $dumpflush;
  end
endmodule
