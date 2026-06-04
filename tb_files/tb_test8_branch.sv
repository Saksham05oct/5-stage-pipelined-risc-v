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
    $dumpfile("tb_test8_branch.vcd");
    $dumpvars(0, tb_test8_branch);

    // Initialize test program instructions
    write_instruction(32'h00, 32'h005000d3); // addi x1, x0, 5
    write_instruction(32'h04, 32'h00500113); // addi x2, x0, 5
    write_instruction(32'h08, 32'h00208463); // beq  x1, x2, +8    (taken, jumps to 0x10)
    write_instruction(32'h0C, 32'h06300193); // addi x3, x0, 99   (should be flushed / skipped!)
    write_instruction(32'h10, 32'h00700193); // addi x3, x0, 7    (label_taken: target of beq)
    write_instruction(32'h14, 32'h00209463); // bne  x1, x2, +8    (not taken: continues to 0x18)
    write_instruction(32'h18, 32'h00b00213); // addi x4, x0, 11   (should be executed!)
    write_instruction(32'h1C, 32'h00302023); // sw   x3, 0(x0)     (store x3)
    write_instruction(32'h20, 32'h00402223); // sw   x4, 4(x0)     (store x4)

    // Pad remaining instruction memory with NOPs
    for (int i = 36; i < 128; i = i + 4) begin
      write_instruction(i, 32'h00000013); // nop
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
    $display("mem[0] = %d (exp 7)",  read_dmem_word(0));
    $display("mem[4] = %d (exp 11)", read_dmem_word(4));

    // Verify Results
    if (u_top.u_register_file.regs[3] !== 32'd7)  test_passed = 0;
    if (u_top.u_register_file.regs[4] !== 32'd11) test_passed = 0;
    if (read_dmem_word(0) !== 32'd7)             test_passed = 0;
    if (read_dmem_word(4) !== 32'd11)            test_passed = 0;

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
