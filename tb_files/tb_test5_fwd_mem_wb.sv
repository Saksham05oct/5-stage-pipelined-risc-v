`timescale 1ns/1ps
import risc_pkg::*;

module tb_test5_fwd_mem_wb;
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
    $dumpfile("tb_test5_fwd_mem_wb.vcd");
    $dumpvars(0, tb_test5_fwd_mem_wb);

    // Initialize test program instructions
    write_instruction(32'h00, 32'h004000d3); // addi x1, x0, 4
    write_instruction(32'h04, 32'h00900113); // addi x2, x0, 9
    write_instruction(32'h08, 32'h002081b3); // add  x3, x1, x2    (Requires MEM/WB forwarding for x1, EX/MEM for x2)
    write_instruction(32'h0C, 32'h00100213); // addi x4, x0, 1
    write_instruction(32'h10, 32'h004182b3); // add  x5, x3, x4    (Requires MEM/WB forwarding for x3)
    write_instruction(32'h14, 32'h00502023); // sw   x5, 0(x0)     (store result)

    // Pad remaining instruction memory with NOPs
    for (int i = 24; i < 128; i = i + 4) begin
      write_instruction(i, 32'h00000013); // nop
    end

    // Reset sequence
    reset_n = 0;
    repeat(3) @(posedge clk);
    reset_n = 1;
    $display("Test 5: MEM/WB Forwarding started");

    // Run 18 cycles
    while (cycle_count < 18) begin
      @(posedge clk);
      cycle_count++;
    end

    $display("--- Registers ---");
    $display("x3 = %d (exp 13)", u_top.u_register_file.regs[3]);
    $display("x5 = %d (exp 14)", u_top.u_register_file.regs[5]);
    $display("--- Data Memory ---");
    $display("mem[0] = %d (exp 14)", read_dmem_word(0));

    // Verify Results
    if (u_top.u_register_file.regs[3] !== 32'd13) test_passed = 0;
    if (u_top.u_register_file.regs[5] !== 32'd14) test_passed = 0;
    if (read_dmem_word(0) !== 32'd14)            test_passed = 0;

    if (test_passed) begin
      $display("RESULT: TEST 5 PASSED");
    end else begin
      $display("RESULT: TEST 5 FAILED");
    end

    $finish;
  end

  final begin
    $dumpflush;
  end
endmodule
