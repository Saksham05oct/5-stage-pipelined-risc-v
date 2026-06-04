`timescale 1ns/1ps
import risc_pkg::*;

module tb_test6_load_use_stall;
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
  bit stall_detected = 0;
  logic test_passed = 1'b1;

  initial begin
    $dumpfile("tb_test6_load_use_stall.vcd");
    $dumpvars(0, tb_test6_load_use_stall);

    // Initialize test program instructions
    write_instruction(32'h00, 32'h019000d3); // addi x1, x0, 25
    write_instruction(32'h04, 32'h00102023); // sw   x1, 0(x0)     (store 25 at address 0)
    write_instruction(32'h08, 32'h00002103); // lw   x2, 0(x0)     (load from address 0)
    write_instruction(32'h0C, 32'h00710193); // addi x3, x2, 7      (Depends on load; must trigger load-use stall)
    write_instruction(32'h10, 32'h00302223); // sw   x3, 4(x0)     (store result at address 4)

    // Pad remaining instruction memory with NOPs
    for (int i = 20; i < 128; i = i + 4) begin
      write_instruction(i, 32'h00000013); // nop
    end

    // Reset sequence
    reset_n = 0;
    repeat(3) @(posedge clk);
    reset_n = 1;
    $display("Test 6: Load-Use Stall started");

    // Run 20 cycles and monitor stall signal
    while (cycle_count < 20) begin
      @(posedge clk);
      cycle_count++;
      #1; // Wait a moment after clock edge for signals to settle
      if (u_top.stall_for_load_use_hazard) begin
        stall_detected = 1;
        $display("[%0t] Stall detected! PC = 0x%08X", $time, u_top.current_pc);
      end
    end

    $display("--- Registers ---");
    $display("x2 = %d (exp 25)", u_top.u_register_file.regs[2]);
    $display("x3 = %d (exp 32)", u_top.u_register_file.regs[3]);
    $display("--- Data Memory ---");
    $display("mem[0] = %d (exp 25)", read_dmem_word(0));
    $display("mem[4] = %d (exp 32)", read_dmem_word(4));
    $display("Stall detected during execution: %b (exp 1)", stall_detected);

    // Verify Results
    if (u_top.u_register_file.regs[2] !== 32'd25) test_passed = 0;
    if (u_top.u_register_file.regs[3] !== 32'd32) test_passed = 0;
    if (read_dmem_word(0) !== 32'd25)            test_passed = 0;
    if (read_dmem_word(4) !== 32'd32)            test_passed = 0;
    if (!stall_detected)                         test_passed = 0;

    if (test_passed) begin
      $display("RESULT: TEST 6 PASSED");
    end else begin
      $display("RESULT: TEST 6 FAILED");
    end

    $finish;
  end

  final begin
    $dumpflush;
  end
endmodule
