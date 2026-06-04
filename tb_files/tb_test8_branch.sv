`timescale 1ns/1ps
import risc_pkg::*;

module tb_test8_branch;
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
    $dumpfile("tb_test8_branch.vcd");
    $dumpvars(0, tb_test8_branch);

    // Initialize test program instructions directly using inline byte concatenation
    {u_top.u_instruction_memory.mem[0],  u_top.u_instruction_memory.mem[1],  u_top.u_instruction_memory.mem[2],  u_top.u_instruction_memory.mem[3]}  = 32'h005000d3; // addi x1, x0, 5
    {u_top.u_instruction_memory.mem[4],  u_top.u_instruction_memory.mem[5],  u_top.u_instruction_memory.mem[6],  u_top.u_instruction_memory.mem[7]}  = 32'h00500113; // addi x2, x0, 5
    {u_top.u_instruction_memory.mem[8],  u_top.u_instruction_memory.mem[9],  u_top.u_instruction_memory.mem[10], u_top.u_instruction_memory.mem[11]} = 32'h00208463; // beq  x1, x2, +8    (taken, jumps to 0x10)
    {u_top.u_instruction_memory.mem[12], u_top.u_instruction_memory.mem[13], u_top.u_instruction_memory.mem[14], u_top.u_instruction_memory.mem[15]} = 32'h06300193; // addi x3, x0, 99   (should be flushed / skipped!)
    {u_top.u_instruction_memory.mem[16], u_top.u_instruction_memory.mem[17], u_top.u_instruction_memory.mem[18], u_top.u_instruction_memory.mem[19]} = 32'h00700193; // addi x3, x0, 7    (label_taken: target of beq)
    {u_top.u_instruction_memory.mem[20], u_top.u_instruction_memory.mem[21], u_top.u_instruction_memory.mem[22], u_top.u_instruction_memory.mem[23]} = 32'h00209463; // bne  x1, x2, +8    (not taken: continues to 0x18)
    {u_top.u_instruction_memory.mem[24], u_top.u_instruction_memory.mem[25], u_top.u_instruction_memory.mem[26], u_top.u_instruction_memory.mem[27]} = 32'h00b00213; // addi x4, x0, 11   (should be executed!)
    {u_top.u_instruction_memory.mem[28], u_top.u_instruction_memory.mem[29], u_top.u_instruction_memory.mem[30], u_top.u_instruction_memory.mem[31]} = 32'h00302023; // sw   x3, 0(x0)     (store x3)
    {u_top.u_instruction_memory.mem[32], u_top.u_instruction_memory.mem[33], u_top.u_instruction_memory.mem[34], u_top.u_instruction_memory.mem[35]} = 32'h00402223; // sw   x4, 4(x0)     (store x4)

    // Pad remaining instruction memory with NOPs
    for (int i = 36; i < 128; i = i + 4) begin
      {u_top.u_instruction_memory.mem[i], u_top.u_instruction_memory.mem[i+1], u_top.u_instruction_memory.mem[i+2], u_top.u_instruction_memory.mem[i+3]} = 32'h00000013; // nop
    end

    // Reset sequence
    reset_n = 0;
    repeat(3) @(posedge clk);
    reset_n = 1;
    $display("Test 8: Branch Taken And Not Taken started");

    // Run 25 cycles
    while (cycle_count < 25) begin
      @(posedge clk);
      cycle_count++;
    end

    $display("--- Registers ---");
    $display("x3 = %d (exp 7)",  u_top.u_register_file.regs[3]);
    $display("x4 = %d (exp 11)", u_top.u_register_file.regs[4]);
    $display("--- Data Memory ---");
    $display("mem[0] = %d (exp 7)",  {u_top.u_data_memory.mem[3], u_top.u_data_memory.mem[2], u_top.u_data_memory.mem[1], u_top.u_data_memory.mem[0]});
    $display("mem[4] = %d (exp 11)", {u_top.u_data_memory.mem[7], u_top.u_data_memory.mem[6], u_top.u_data_memory.mem[5], u_top.u_data_memory.mem[4]});

    // Verify Results
    if (u_top.u_register_file.regs[3] !== 32'd7)  test_passed = 0;
    if (u_top.u_register_file.regs[4] !== 32'd11) test_passed = 0;
    if ({u_top.u_data_memory.mem[3], u_top.u_data_memory.mem[2], u_top.u_data_memory.mem[1], u_top.u_data_memory.mem[0]} !== 32'd7)             test_passed = 0;
    if ({u_top.u_data_memory.mem[7], u_top.u_data_memory.mem[6], u_top.u_data_memory.mem[5], u_top.u_data_memory.mem[4]} !== 32'd11)            test_passed = 0;

    if (test_passed) begin
      $display("RESULT: TEST 8 PASSED");
    end else begin
      $display("RESULT: TEST 8 FAILED");
    end

    $finish;
  end

  final begin
    $dumpflush;
  end
endmodule
