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
    $dumpfile("tb_test2_i_type.vcd");
    $dumpvars(0, tb_test2_i_type);

    // Initialize test program instructions
    write_instruction(32'h00, 32'hfff00093); // addi x1, x0, -1
    write_instruction(32'h04, 32'h00f0f113); // andi x2, x1, 15     (-1 & 15 = 15)
    write_instruction(32'h08, 32'h00806193); // ori  x3, x0, 8      (0 | 8 = 8)
    write_instruction(32'h0C, 32'h0031c213); // xori x4, x3, 3      (8 ^ 3 = 11)
    write_instruction(32'h10, 32'h00219293); // slli x5, x3, 2      (8 << 2 = 32)
    write_instruction(32'h14, 32'h0012d313); // srli x6, x5, 1      (32 >> 1 = 16)
    write_instruction(32'h18, 32'h4010d393); // srai x7, x1, 1      (-1 >> 1 arithmetic = -1)
    write_instruction(32'h1C, 32'h0010a413); // slti x8, x1, 1      (-1 < 1 signed = 1)
    write_instruction(32'h20, 32'h00202023); // sw x2, 0(x0)
    write_instruction(32'h24, 32'h00702223); // sw x7, 4(x0)

    // Pad remaining instruction memory with NOPs
    for (int i = 44; i < 128; i = i + 4) begin
      write_instruction(i, 32'h00000013); // nop
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
    $display("mem[0]    = %d (exp 15)", read_dmem_word(0));
    $display("mem[4]    = %d (exp -1)", $signed(read_dmem_word(4)));

    // Verify Results
    if ($signed(u_top.u_register_file.regs[1]) !== -32'd1)  test_passed = 0;
    if (u_top.u_register_file.regs[2] !== 32'd15)           test_passed = 0;
    if (u_top.u_register_file.regs[3] !== 32'd8)            test_passed = 0;
    if (u_top.u_register_file.regs[4] !== 32'd11)           test_passed = 0;
    if (u_top.u_register_file.regs[5] !== 32'd32)           test_passed = 0;
    if (u_top.u_register_file.regs[6] !== 32'd16)           test_passed = 0;
    if ($signed(u_top.u_register_file.regs[7]) !== -32'd1)  test_passed = 0;
    if (u_top.u_register_file.regs[8] !== 32'd1)            test_passed = 0;
    if (read_dmem_word(0) !== 32'd15)                       test_passed = 0;
    if ($signed(read_dmem_word(4)) !== -32'd1)              test_passed = 0;

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
