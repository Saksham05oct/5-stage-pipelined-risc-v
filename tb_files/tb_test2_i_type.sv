`timescale 1ns/1ps
import risc_pkg::*;

module tb_test2_i_type;
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
    $dumpfile("tb_test2_i_type.vcd");
    $dumpvars(0, tb_test2_i_type);

    // Initialize test program instructions directly using inline byte concatenation
    {u_top.u_instruction_memory.mem[0],  u_top.u_instruction_memory.mem[1],  u_top.u_instruction_memory.mem[2],  u_top.u_instruction_memory.mem[3]}  = 32'hfff00093; // addi x1, x0, -1
    {u_top.u_instruction_memory.mem[4],  u_top.u_instruction_memory.mem[5],  u_top.u_instruction_memory.mem[6],  u_top.u_instruction_memory.mem[7]}  = 32'h00f0f113; // andi x2, x1, 15     (-1 & 15 = 15)
    {u_top.u_instruction_memory.mem[8],  u_top.u_instruction_memory.mem[9],  u_top.u_instruction_memory.mem[10], u_top.u_instruction_memory.mem[11]} = 32'h00806193; // ori  x3, x0, 8      (0 | 8 = 8)
    {u_top.u_instruction_memory.mem[12], u_top.u_instruction_memory.mem[13], u_top.u_instruction_memory.mem[14], u_top.u_instruction_memory.mem[15]} = 32'h0031c213; // xori x4, x3, 3      (8 ^ 3 = 11)
    {u_top.u_instruction_memory.mem[16], u_top.u_instruction_memory.mem[17], u_top.u_instruction_memory.mem[18], u_top.u_instruction_memory.mem[19]} = 32'h00219293; // slli x5, x3, 2      (8 << 2 = 32)
    {u_top.u_instruction_memory.mem[20], u_top.u_instruction_memory.mem[21], u_top.u_instruction_memory.mem[22], u_top.u_instruction_memory.mem[23]} = 32'h0012d313; // srli x6, x5, 1      (32 >> 1 = 16)
    {u_top.u_instruction_memory.mem[24], u_top.u_instruction_memory.mem[25], u_top.u_instruction_memory.mem[26], u_top.u_instruction_memory.mem[27]} = 32'h4010d393; // srai x7, x1, 1      (-1 >> 1 arithmetic = -1)
    {u_top.u_instruction_memory.mem[28], u_top.u_instruction_memory.mem[29], u_top.u_instruction_memory.mem[30], u_top.u_instruction_memory.mem[31]} = 32'h0010a413; // slti x8, x1, 1      (-1 < 1 signed = 1)
    {u_top.u_instruction_memory.mem[32], u_top.u_instruction_memory.mem[33], u_top.u_instruction_memory.mem[34], u_top.u_instruction_memory.mem[35]} = 32'h00202023; // sw x2, 0(x0)
    {u_top.u_instruction_memory.mem[36], u_top.u_instruction_memory.mem[37], u_top.u_instruction_memory.mem[38], u_top.u_instruction_memory.mem[39]} = 32'h00702223; // sw x7, 4(x0)

    // Pad remaining instruction memory with NOPs
    for (int i = 40; i < 128; i = i + 4) begin
      {u_top.u_instruction_memory.mem[i], u_top.u_instruction_memory.mem[i+1], u_top.u_instruction_memory.mem[i+2], u_top.u_instruction_memory.mem[i+3]} = 32'h00000013; // nop
    end

    // Reset sequence
    reset_n = 0;
    repeat(3) @(posedge clk);
    reset_n = 1;
    $display("Test 2: I-Type ALU And Shift Immediates started");

    // Run 25 cycles
    while (cycle_count < 25) begin
      @(posedge clk);
      cycle_count++;
    end

    $display("--- Registers ---");
    $display("x1 (addi) = %d (exp -1)", $signed(u_top.u_register_file.regs[1]));
    $display("x2 (andi) = %d (exp 15)", u_top.u_register_file.regs[2]);
    $display("x3 (ori)  = %d (exp 8)",  u_top.u_register_file.regs[3]);
    $display("x4 (xori) = %d (exp 11)", u_top.u_register_file.regs[4]);
    $display("x5 (slli) = %d (exp 32)", u_top.u_register_file.regs[5]);
    $display("x6 (srli) = %d (exp 16)", u_top.u_register_file.regs[6]);
    $display("x7 (srai) = %d (exp -1)", $signed(u_top.u_register_file.regs[7]));
    $display("x8 (slti) = %d (exp 1)",  u_top.u_register_file.regs[8]);
    $display("--- Data Memory ---");
    $display("mem[0]    = %d (exp 15)", {u_top.u_data_memory.mem[3], u_top.u_data_memory.mem[2], u_top.u_data_memory.mem[1], u_top.u_data_memory.mem[0]});
    $display("mem[4]    = %d (exp -1)", $signed({u_top.u_data_memory.mem[7], u_top.u_data_memory.mem[6], u_top.u_data_memory.mem[5], u_top.u_data_memory.mem[4]}));

    // Verify Results
    if ($signed(u_top.u_register_file.regs[1]) !== -32'd1)  test_passed = 0;
    if (u_top.u_register_file.regs[2] !== 32'd15)           test_passed = 0;
    if (u_top.u_register_file.regs[3] !== 32'd8)            test_passed = 0;
    if (u_top.u_register_file.regs[4] !== 32'd11)           test_passed = 0;
    if (u_top.u_register_file.regs[5] !== 32'd32)           test_passed = 0;
    if (u_top.u_register_file.regs[6] !== 32'd16)           test_passed = 0;
    if ($signed(u_top.u_register_file.regs[7]) !== -32'd1)  test_passed = 0;
    if (u_top.u_register_file.regs[8] !== 32'd1)            test_passed = 0;
    if ({u_top.u_data_memory.mem[3], u_top.u_data_memory.mem[2], u_top.u_data_memory.mem[1], u_top.u_data_memory.mem[0]} !== 32'd15)                       test_passed = 0;
    if ($signed({u_top.u_data_memory.mem[7], u_top.u_data_memory.mem[6], u_top.u_data_memory.mem[5], u_top.u_data_memory.mem[4]}) !== -32'd1)              test_passed = 0;

    if (test_passed) begin
      $display("RESULT: TEST 2 PASSED");
    end else begin
      $display("RESULT: TEST 2 FAILED");
    end

    $finish;
  end

  final begin
    $dumpflush;
  end
endmodule
