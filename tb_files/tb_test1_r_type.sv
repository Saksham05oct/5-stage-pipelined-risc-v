`timescale 1ns/1ps
import risc_pkg::*;

module tb_test1_r_type;
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
    $dumpfile("tb_test1_r_type.vcd");
    $dumpvars(0, tb_test1_r_type);

    // Initialize test program instructions directly using inline byte concatenation
    {u_top.u_instruction_memory.mem[0],  u_top.u_instruction_memory.mem[1],  u_top.u_instruction_memory.mem[2],  u_top.u_instruction_memory.mem[3]}  = 32'h00a00093; // addi x1, x0, 10
    {u_top.u_instruction_memory.mem[4],  u_top.u_instruction_memory.mem[5],  u_top.u_instruction_memory.mem[6],  u_top.u_instruction_memory.mem[7]}  = 32'h00300113; // addi x2, x0, 3
    {u_top.u_instruction_memory.mem[8],  u_top.u_instruction_memory.mem[9],  u_top.u_instruction_memory.mem[10], u_top.u_instruction_memory.mem[11]} = 32'h002081b3; // add x3, x1, x2    (10 + 3 = 13)
    {u_top.u_instruction_memory.mem[12], u_top.u_instruction_memory.mem[13], u_top.u_instruction_memory.mem[14], u_top.u_instruction_memory.mem[15]} = 32'h40208233; // sub x4, x1, x2    (10 - 3 = 7)
    {u_top.u_instruction_memory.mem[16], u_top.u_instruction_memory.mem[17], u_top.u_instruction_memory.mem[18], u_top.u_instruction_memory.mem[19]} = 32'h0020f2b3; // and x5, x1, x2    (10 & 3 = 2)
    {u_top.u_instruction_memory.mem[20], u_top.u_instruction_memory.mem[21], u_top.u_instruction_memory.mem[22], u_top.u_instruction_memory.mem[23]} = 32'h0020e333; // or x6, x1, x2     (10 | 3 = 11)
    {u_top.u_instruction_memory.mem[24], u_top.u_instruction_memory.mem[25], u_top.u_instruction_memory.mem[26], u_top.u_instruction_memory.mem[27]} = 32'h0020c3b3; // xor x7, x1, x2    (10 ^ 3 = 9)
    {u_top.u_instruction_memory.mem[28], u_top.u_instruction_memory.mem[29], u_top.u_instruction_memory.mem[30], u_top.u_instruction_memory.mem[31]} = 32'h00211433; // sll x8, x2, x2    (3 << 3 = 24)
    {u_top.u_instruction_memory.mem[32], u_top.u_instruction_memory.mem[33], u_top.u_instruction_memory.mem[34], u_top.u_instruction_memory.mem[35]} = 32'h0020d4b3; // srl x9, x1, x2    (10 >> 3 = 1)
    {u_top.u_instruction_memory.mem[36], u_top.u_instruction_memory.mem[37], u_top.u_instruction_memory.mem[38], u_top.u_instruction_memory.mem[39]} = 32'h00112533; // slt x10, x2, x1   (3 < 10 signed = 1)
    {u_top.u_instruction_memory.mem[40], u_top.u_instruction_memory.mem[41], u_top.u_instruction_memory.mem[42], u_top.u_instruction_memory.mem[43]} = 32'h001135b3; // sltu x11, x2, x1  (3 < 10 unsigned = 1)
    {u_top.u_instruction_memory.mem[44], u_top.u_instruction_memory.mem[45], u_top.u_instruction_memory.mem[46], u_top.u_instruction_memory.mem[47]} = 32'h00302023; // sw x3, 0(x0)
    {u_top.u_instruction_memory.mem[48], u_top.u_instruction_memory.mem[49], u_top.u_instruction_memory.mem[50], u_top.u_instruction_memory.mem[51]} = 32'h00402223; // sw x4, 4(x0)

    // Pad remaining instruction memory with NOPs
    for (int i = 52; i < 128; i = i + 4) begin
      {u_top.u_instruction_memory.mem[i], u_top.u_instruction_memory.mem[i+1], u_top.u_instruction_memory.mem[i+2], u_top.u_instruction_memory.mem[i+3]} = 32'h00000013; // nop
    end

    // Reset sequence
    reset_n = 0;
    repeat(3) @(posedge clk);
    reset_n = 1;
    $display("Test 1: R-Type ALU Operations started");

    // Run 25 cycles to let instructions execute and drain pipeline
    while (cycle_count < 25) begin
      @(posedge clk);
      cycle_count++;
    end

    $display("--- Registers ---");
    $display("x3 (add)  = %d (exp 13)", u_top.u_register_file.regs[3]);
    $display("x4 (sub)  = %d (exp 7)",  u_top.u_register_file.regs[4]);
    $display("x5 (and)  = %d (exp 2)",  u_top.u_register_file.regs[5]);
    $display("x6 (or)   = %d (exp 11)", u_top.u_register_file.regs[6]);
    $display("x7 (xor)  = %d (exp 9)",  u_top.u_register_file.regs[7]);
    $display("x8 (sll)  = %d (exp 24)", u_top.u_register_file.regs[8]);
    $display("x9 (srl)  = %d (exp 1)",  u_top.u_register_file.regs[9]);
    $display("x10 (slt) = %d (exp 1)",  u_top.u_register_file.regs[10]);
    $display("x11 (sltu)= %d (exp 1)",  u_top.u_register_file.regs[11]);
    $display("--- Data Memory ---");
    $display("mem[0]    = %d (exp 13)", {u_top.u_data_memory.mem[3], u_top.u_data_memory.mem[2], u_top.u_data_memory.mem[1], u_top.u_data_memory.mem[0]});
    $display("mem[4]    = %d (exp 7)",  {u_top.u_data_memory.mem[7], u_top.u_data_memory.mem[6], u_top.u_data_memory.mem[5], u_top.u_data_memory.mem[4]});

    // Verify Results
    if (u_top.u_register_file.regs[3] !== 32'd13)  test_passed = 0;
    if (u_top.u_register_file.regs[4] !== 32'd7)   test_passed = 0;
    if (u_top.u_register_file.regs[5] !== 32'd2)   test_passed = 0;
    if (u_top.u_register_file.regs[6] !== 32'd11)  test_passed = 0;
    if (u_top.u_register_file.regs[7] !== 32'd9)   test_passed = 0;
    if (u_top.u_register_file.regs[8] !== 32'd24)  test_passed = 0;
    if (u_top.u_register_file.regs[9] !== 32'd1)   test_passed = 0;
    if (u_top.u_register_file.regs[10] !== 32'd1)  test_passed = 0;
    if (u_top.u_register_file.regs[11] !== 32'd1)  test_passed = 0;
    if ({u_top.u_data_memory.mem[3], u_top.u_data_memory.mem[2], u_top.u_data_memory.mem[1], u_top.u_data_memory.mem[0]} !== 32'd13)             test_passed = 0;
    if ({u_top.u_data_memory.mem[7], u_top.u_data_memory.mem[6], u_top.u_data_memory.mem[5], u_top.u_data_memory.mem[4]} !== 32'd7)              test_passed = 0;

    if (test_passed) begin
      $display("RESULT: TEST 1 PASSED");
    end else begin
      $display("RESULT: TEST 1 FAILED");
    end

    $finish;
  end

  final begin
    $dumpflush;
  end
endmodule
