`timescale 1ns/1ps
import risc_pkg::*;

module tb_test4_fwd_ex_mem;
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
    $dumpfile("tb_test4_fwd_ex_mem.vcd");
    $dumpvars(0, tb_test4_fwd_ex_mem);

    // Initialize test program instructions directly using inline byte concatenation
    {u_top.u_instruction_memory.mem[0],  u_top.u_instruction_memory.mem[1],  u_top.u_instruction_memory.mem[2],  u_top.u_instruction_memory.mem[3]}  = 32'h005000d3; // addi x1, x0, 5
    {u_top.u_instruction_memory.mem[4],  u_top.u_instruction_memory.mem[5],  u_top.u_instruction_memory.mem[6],  u_top.u_instruction_memory.mem[7]}  = 32'h00308113; // addi x2, x1, 3     (Depends on x1 in EX stage)
    {u_top.u_instruction_memory.mem[8],  u_top.u_instruction_memory.mem[9],  u_top.u_instruction_memory.mem[10], u_top.u_instruction_memory.mem[11]} = 32'h001101b3; // add  x3, x2, x1    (Depends on x2 in EX stage and x1 in MEM stage)
    {u_top.u_instruction_memory.mem[12], u_top.u_instruction_memory.mem[13], u_top.u_instruction_memory.mem[14], u_top.u_instruction_memory.mem[15]} = 32'h00302023; // sw   x3, 0(x0)     (store result)

    // Pad remaining instruction memory with NOPs
    for (int i = 16; i < 128; i = i + 4) begin
      {u_top.u_instruction_memory.mem[i], u_top.u_instruction_memory.mem[i+1], u_top.u_instruction_memory.mem[i+2], u_top.u_instruction_memory.mem[i+3]} = 32'h00000013; // nop
    end

    // Reset sequence
    reset_n = 0;
    repeat(3) @(posedge clk);
    reset_n = 1;
    $display("Test 4: EX/MEM Forwarding started");

    // Run 15 cycles
    while (cycle_count < 15) begin
      @(posedge clk);
      cycle_count++;
    end

    $display("--- Registers ---");
    $display("x1 = %d (exp 5)", u_top.u_register_file.regs[1]);
    $display("x2 = %d (exp 8)", u_top.u_register_file.regs[2]);
    $display("x3 = %d (exp 13)", u_top.u_register_file.regs[3]);
    $display("--- Data Memory ---");
    $display("mem[0] = %d (exp 13)", {u_top.u_data_memory.mem[3], u_top.u_data_memory.mem[2], u_top.u_data_memory.mem[1], u_top.u_data_memory.mem[0]});

    // Verify Results
    if (u_top.u_register_file.regs[1] !== 32'd5)  test_passed = 0;
    if (u_top.u_register_file.regs[2] !== 32'd8)  test_passed = 0;
    if (u_top.u_register_file.regs[3] !== 32'd13) test_passed = 0;
    if ({u_top.u_data_memory.mem[3], u_top.u_data_memory.mem[2], u_top.u_data_memory.mem[1], u_top.u_data_memory.mem[0]} !== 32'd13)            test_passed = 0;

    if (test_passed) begin
      $display("RESULT: TEST 4 PASSED");
    end else begin
      $display("RESULT: TEST 4 FAILED");
    end

    $finish;
  end

  final begin
    $dumpflush;
  end
endmodule
