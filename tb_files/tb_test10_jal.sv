`timescale 1ns/1ps
import risc_pkg::*;

module tb_test10_jal;
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
    $dumpfile("tb_test10_jal.vcd");
    $dumpvars(0, tb_test10_jal);

    // Initialize test program instructions directly using inline byte concatenation
    {u_top.u_instruction_memory.mem[0],  u_top.u_instruction_memory.mem[1],  u_top.u_instruction_memory.mem[2],  u_top.u_instruction_memory.mem[3]}  = 32'h008002ef; // jal   x5, +8        (jumps to 0x08, saves PC+4 = 0x04 in x5)
    {u_top.u_instruction_memory.mem[4],  u_top.u_instruction_memory.mem[5],  u_top.u_instruction_memory.mem[6],  u_top.u_instruction_memory.mem[7]}  = 32'h063000d3; // addi  x1, x0, 99    (should be flushed / skipped!)
    {u_top.u_instruction_memory.mem[8],  u_top.u_instruction_memory.mem[9],  u_top.u_instruction_memory.mem[10], u_top.u_instruction_memory.mem[11]} = 32'h01600113; // addi  x2, x0, 22    (target: x2 = 22)
    {u_top.u_instruction_memory.mem[12], u_top.u_instruction_memory.mem[13], u_top.u_instruction_memory.mem[14], u_top.u_instruction_memory.mem[15]} = 32'h00502023; // sw    x5, 0(x0)     (store link register to address 0)
    {u_top.u_instruction_memory.mem[16], u_top.u_instruction_memory.mem[17], u_top.u_instruction_memory.mem[18], u_top.u_instruction_memory.mem[19]} = 32'h00202223; // sw    x2, 4(x0)     (store x2 to address 4)

    // Pad remaining instruction memory with NOPs
    for (int i = 20; i < 128; i = i + 4) begin
      {u_top.u_instruction_memory.mem[i], u_top.u_instruction_memory.mem[i+1], u_top.u_instruction_memory.mem[i+2], u_top.u_instruction_memory.mem[i+3]} = 32'h00000013; // nop
    end

    // Reset sequence
    reset_n = 0;
    repeat(3) @(posedge clk);
    reset_n = 1;
    $display("Test 10: JAL Link And Redirect started");

    // Run 20 cycles
    while (cycle_count < 20) begin
      @(posedge clk);
      cycle_count++;
    end

    $display("--- Registers ---");
    $display("x5 (link) = 0x%08X (exp 0x00000004)", u_top.u_register_file.regs[5]);
    $display("x2 (target)= %d (exp 22)", u_top.u_register_file.regs[2]);
    $display("x1 (skipped)= %d (exp 0)", u_top.u_register_file.regs[1]);
    $display("--- Data Memory ---");
    $display("mem[0]    = 0x%08X (exp 0x00000004)", {u_top.u_data_memory.mem[3], u_top.u_data_memory.mem[2], u_top.u_data_memory.mem[1], u_top.u_data_memory.mem[0]});
    $display("mem[4]    = %d (exp 22)", {u_top.u_data_memory.mem[7], u_top.u_data_memory.mem[6], u_top.u_data_memory.mem[5], u_top.u_data_memory.mem[4]});

    // Verify Results
    if (u_top.u_register_file.regs[5] !== 32'h00000004) test_passed = 0;
    if (u_top.u_register_file.regs[2] !== 32'd22)       test_passed = 0;
    if (u_top.u_register_file.regs[1] !== 32'd0)        test_passed = 0;
    if ({u_top.u_data_memory.mem[3], u_top.u_data_memory.mem[2], u_top.u_data_memory.mem[1], u_top.u_data_memory.mem[0]} !== 32'h00000004)             test_passed = 0;
    if ({u_top.u_data_memory.mem[7], u_top.u_data_memory.mem[6], u_top.u_data_memory.mem[5], u_top.u_data_memory.mem[4]} !== 32'd22)                  test_passed = 0;

    if (test_passed) begin
      $display("RESULT: TEST 10 PASSED");
    end else begin
      $display("RESULT: TEST 10 FAILED");
    end

    $finish;
  end

  final begin
    $dumpflush;
  end
endmodule
