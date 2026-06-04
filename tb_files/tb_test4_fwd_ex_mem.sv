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
    $dumpfile("tb_test4_fwd_ex_mem.vcd");
    $dumpvars(0, tb_test4_fwd_ex_mem);

    // Initialize test program instructions
    write_instruction(32'h00, 32'h005000d3); // addi x1, x0, 5
    write_instruction(32'h04, 32'h00308113); // addi x2, x1, 3     (Depends on x1 in EX stage)
    write_instruction(32'h08, 32'h001101b3); // add  x3, x2, x1    (Depends on x2 in EX stage and x1 in MEM stage)
    write_instruction(32'h0C, 32'h00302023); // sw   x3, 0(x0)     (store result)

    // Pad remaining instruction memory with NOPs
    for (int i = 16; i < 128; i = i + 4) begin
      write_instruction(i, 32'h00000013); // nop
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
    $display("mem[0] = %d (exp 13)", read_dmem_word(0));

    // Verify Results
    if (u_top.u_register_file.regs[1] !== 32'd5)  test_passed = 0;
    if (u_top.u_register_file.regs[2] !== 32'd8)  test_passed = 0;
    if (u_top.u_register_file.regs[3] !== 32'd13) test_passed = 0;
    if (read_dmem_word(0) !== 32'd13)            test_passed = 0;

    // Check if there was any stall (forwarding should prevent stalls)
    // We can probe u_top.stall_for_load_use_hazard. It should have remained 0.
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
