`timescale 1ns/1ps
import risc_pkg::*;

module tb_test12_lui_auipc;
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
    $dumpfile("tb_test12_lui_auipc.vcd");
    $dumpvars(0, tb_test12_lui_auipc);

    // Initialize test program instructions directly using inline byte concatenation
    {u_top.u_instruction_memory.mem[0],  u_top.u_instruction_memory.mem[1],  u_top.u_instruction_memory.mem[2],  u_top.u_instruction_memory.mem[3]}  = 32'h123450b7; // lui   x1, 0x12345     (x1 = 0x12345000)
    {u_top.u_instruction_memory.mem[4],  u_top.u_instruction_memory.mem[5],  u_top.u_instruction_memory.mem[6],  u_top.u_instruction_memory.mem[7]}  = 32'h00001117; // auipc x2, 0x00001     (x2 = PC + 0x00001000 = 0x04 + 0x1000 = 0x1004)
    {u_top.u_instruction_memory.mem[8],  u_top.u_instruction_memory.mem[9],  u_top.u_instruction_memory.mem[10], u_top.u_instruction_memory.mem[11]} = 32'h00102023; // sw    x1, 0(x0)       (store x1)
    {u_top.u_instruction_memory.mem[12], u_top.u_instruction_memory.mem[13], u_top.u_instruction_memory.mem[14], u_top.u_instruction_memory.mem[15]} = 32'h00202223; // sw    x2, 4(x0)       (store x2)

    // Pad remaining instruction memory with NOPs
    for (int i = 16; i < 128; i = i + 4) begin
      {u_top.u_instruction_memory.mem[i], u_top.u_instruction_memory.mem[i+1], u_top.u_instruction_memory.mem[i+2], u_top.u_instruction_memory.mem[i+3]} = 32'h00000013; // nop
    end

    // Reset sequence
    reset_n = 0;
    repeat(3) @(posedge clk);
    reset_n = 1;
    $display("Test 12: LUI And AUIPC started");

    // Run 15 cycles
    while (cycle_count < 15) begin
      @(posedge clk);
      cycle_count++;
    end

    $display("--- Registers ---");
    $display("x1 (lui)   = 0x%08X (exp 0x12345000)", u_top.u_register_file.regs[1]);
    $display("x2 (auipc) = 0x%08X (exp 0x00001004)", u_top.u_register_file.regs[2]);
    $display("--- Data Memory ---");
    $display("mem[0]     = 0x%08X (exp 0x12345000)", {u_top.u_data_memory.mem[3], u_top.u_data_memory.mem[2], u_top.u_data_memory.mem[1], u_top.u_data_memory.mem[0]});
    $display("mem[4]     = 0x%08X (exp 0x00001004)", {u_top.u_data_memory.mem[7], u_top.u_data_memory.mem[6], u_top.u_data_memory.mem[5], u_top.u_data_memory.mem[4]});

    // Verify Results
    if (u_top.u_register_file.regs[1] !== 32'h12345000) test_passed = 0;
    if (u_top.u_register_file.regs[2] !== 32'h00001004) test_passed = 0;
    if ({u_top.u_data_memory.mem[3], u_top.u_data_memory.mem[2], u_top.u_data_memory.mem[1], u_top.u_data_memory.mem[0]} !== 32'h12345000)            test_passed = 0;
    if ({u_top.u_data_memory.mem[7], u_top.u_data_memory.mem[6], u_top.u_data_memory.mem[5], u_top.u_data_memory.mem[4]} !== 32'h00001004)            test_passed = 0;

    if (test_passed) begin
      $display("RESULT: TEST 12 PASSED");
    end else begin
      $display("RESULT: TEST 12 FAILED");
    end

    $finish;
  end

  final begin
    $dumpflush;
  end
endmodule
