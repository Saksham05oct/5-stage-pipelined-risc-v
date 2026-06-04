`timescale 1ns/1ps
import risc_pkg::*;

module tb_test3_load_store;
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
    $dumpfile("tb_test3_load_store.vcd");
    $dumpvars(0, tb_test3_load_store);

    // Initialize test program instructions directly using inline byte concatenation
    {u_top.u_instruction_memory.mem[0],  u_top.u_instruction_memory.mem[1],  u_top.u_instruction_memory.mem[2],  u_top.u_instruction_memory.mem[3]}  = 32'hfff00093; // addi x1, x0, -1
    {u_top.u_instruction_memory.mem[4],  u_top.u_instruction_memory.mem[5],  u_top.u_instruction_memory.mem[6],  u_top.u_instruction_memory.mem[7]}  = 32'h00102023; // sw   x1, 0(x0)     (store word 0xFFFFFFFF at address 0)
    {u_top.u_instruction_memory.mem[8],  u_top.u_instruction_memory.mem[9],  u_top.u_instruction_memory.mem[10], u_top.u_instruction_memory.mem[11]} = 32'h00000103; // lb   x2, 0(x0)     (load byte from address 0 -> sign extended -> 0xFFFFFFFF)
    {u_top.u_instruction_memory.mem[12], u_top.u_instruction_memory.mem[13], u_top.u_instruction_memory.mem[14], u_top.u_instruction_memory.mem[15]} = 32'h00004183; // lbu  x3, 0(x0)     (load byte unsigned from address 0 -> zero extended -> 0x000000FF)
    {u_top.u_instruction_memory.mem[16], u_top.u_instruction_memory.mem[17], u_top.u_instruction_memory.mem[18], u_top.u_instruction_memory.mem[19]} = 32'h00001203; // lh   x4, 0(x0)     (load halfword from address 0 -> sign extended -> 0xFFFFFFFF)
    {u_top.u_instruction_memory.mem[20], u_top.u_instruction_memory.mem[21], u_top.u_instruction_memory.mem[22], u_top.u_instruction_memory.mem[23]} = 32'h00005283; // lhu  x5, 0(x0)     (load halfword unsigned from address 0 -> zero extended -> 0x0000FFFF)
    {u_top.u_instruction_memory.mem[24], u_top.u_instruction_memory.mem[25], u_top.u_instruction_memory.mem[26], u_top.u_instruction_memory.mem[27]} = 32'h01200313; // addi x6, x0, 18     (x6 = 0x12)
    {u_top.u_instruction_memory.mem[28], u_top.u_instruction_memory.mem[29], u_top.u_instruction_memory.mem[30], u_top.u_instruction_memory.mem[31]} = 32'h00600423; // sb   x6, 8(x0)     (store byte 0x12 to address 8)
    {u_top.u_instruction_memory.mem[32], u_top.u_instruction_memory.mem[33], u_top.u_instruction_memory.mem[34], u_top.u_instruction_memory.mem[35]} = 32'h00800383; // lb   x7, 8(x0)     (load byte from address 8 -> 0x00000012)
    {u_top.u_instruction_memory.mem[36], u_top.u_instruction_memory.mem[37], u_top.u_instruction_memory.mem[38], u_top.u_instruction_memory.mem[39]} = 32'h00302623; // sw   x3, 12(x0)    (store word 0x000000FF at address 12)

    // Pad remaining instruction memory with NOPs
    for (int i = 40; i < 128; i = i + 4) begin
      {u_top.u_instruction_memory.mem[i], u_top.u_instruction_memory.mem[i+1], u_top.u_instruction_memory.mem[i+2], u_top.u_instruction_memory.mem[i+3]} = 32'h00000013; // nop
    end

    // Reset sequence
    reset_n = 0;
    repeat(3) @(posedge clk);
    reset_n = 1;
    $display("Test 3: Load And Store Sizes started");

    // Run 25 cycles
    while (cycle_count < 25) begin
      @(posedge clk);
      cycle_count++;
    end

    $display("--- Registers ---");
    $display("x2 (lb)  = 0x%08X (exp 0xFFFFFFFF)", u_top.u_register_file.regs[2]);
    $display("x3 (lbu) = 0x%08X (exp 0x000000FF)", u_top.u_register_file.regs[3]);
    $display("x4 (lh)  = 0x%08X (exp 0xFFFFFFFF)", u_top.u_register_file.regs[4]);
    $display("x5 (lhu) = 0x%08X (exp 0x0000FFFF)", u_top.u_register_file.regs[5]);
    $display("x7 (lb)  = 0x%08X (exp 0x00000012)", u_top.u_register_file.regs[7]);
    $display("--- Data Memory ---");
    $display("mem[12]  = 0x%08X (exp 0x000000FF)", {u_top.u_data_memory.mem[15], u_top.u_data_memory.mem[14], u_top.u_data_memory.mem[13], u_top.u_data_memory.mem[12]});

    // Verify Results
    if (u_top.u_register_file.regs[2] !== 32'hFFFFFFFF) test_passed = 0;
    if (u_top.u_register_file.regs[3] !== 32'h000000FF) test_passed = 0;
    if (u_top.u_register_file.regs[4] !== 32'hFFFFFFFF) test_passed = 0;
    if (u_top.u_register_file.regs[5] !== 32'h0000FFFF) test_passed = 0;
    if (u_top.u_register_file.regs[7] !== 32'h00000012) test_passed = 0;
    if ({u_top.u_data_memory.mem[15], u_top.u_data_memory.mem[14], u_top.u_data_memory.mem[13], u_top.u_data_memory.mem[12]} !== 32'h000000FF)            test_passed = 0;

    if (test_passed) begin
      $display("RESULT: TEST 3 PASSED");
    end else begin
      $display("RESULT: TEST 3 FAILED");
    end

    $finish;
  end

  final begin
    $dumpflush;
  end
endmodule
