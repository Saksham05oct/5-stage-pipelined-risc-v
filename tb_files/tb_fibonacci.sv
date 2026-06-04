`timescale 1ns/1ps
import risc_pkg::*;

module tb_fibonacci;
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

  integer cycle_count;
  integer i;
  logic program_done;
  logic test_passed;
  logic [31:0] expected_fib [0:9];

  initial begin
    expected_fib[0] = 32'd0;
    expected_fib[1] = 32'd1;
    expected_fib[2] = 32'd1;
    expected_fib[3] = 32'd2;
    expected_fib[4] = 32'd3;
    expected_fib[5] = 32'd5;
    expected_fib[6] = 32'd8;
    expected_fib[7] = 32'd13;
    expected_fib[8] = 32'd21;
    expected_fib[9] = 32'd34;

    // GTKWave waveform dump. Compile Verilator with --trace to generate this VCD.
    $dumpfile("tb_fibonacci.vcd");
    $dumpvars(0, tb_fibonacci);

    reset_n = 0;
    repeat(3) @(posedge clk);
    reset_n = 1;

    $display(" Fibonacci Sequence - Testbench");
    $display("[%0t] Reset released", $time);

    program_done = 0;
    cycle_count = 0;

    while (!program_done && cycle_count < 500) begin
      @(posedge clk);
      cycle_count = cycle_count + 1;

      if (u_top.current_pc == 32'h0048) begin
        repeat(5) @(posedge clk);
        cycle_count = cycle_count + 5;
        program_done = 1;
      end
    end

    if (!program_done) begin
      $display("[%0t] ERROR: Fibonacci program did not complete within 500 cycles!", $time);
      $display("       Last PC = 0x%08X", u_top.current_pc);
      $finish;
    end

    $display("[%0t] Program completed in %0d cycles", $time, cycle_count);
    $display("");

    test_passed = 1'b1;

    $display("--- Fibonacci Data Memory Contents ---");
    for (i = 0; i < 10; i = i + 1) begin
      $display("  fib[%0d] = %0d (expected %0d)",
               i,
               read_dmem_word(i * 4),
               expected_fib[i]);

      if (read_dmem_word(i * 4) !== expected_fib[i])
        test_passed = 1'b0;
    end

    $display("");
    $display("--- Register File ---");
    $display("  x10 (base)  = 0x%08X", u_top.u_register_file.regs[10]);
    $display("  x11 (fib_0) = %0d",    u_top.u_register_file.regs[11]);
    $display("  x12 (fib_1) = %0d",    u_top.u_register_file.regs[12]);
    $display("  x13 (i)     = %0d",    u_top.u_register_file.regs[13]);
    $display("  x14 (N)     = %0d",    u_top.u_register_file.regs[14]);
    $display("  x15 (fib_n) = %0d",    u_top.u_register_file.regs[15]);
    $display("");

    if (test_passed &&
        (u_top.u_register_file.regs[10] == 32'd0) &&
        (u_top.u_register_file.regs[11] == 32'd21) &&
        (u_top.u_register_file.regs[12] == 32'd34) &&
        (u_top.u_register_file.regs[13] == 32'd10) &&
        (u_top.u_register_file.regs[14] == 32'd10) &&
        (u_top.u_register_file.regs[15] == 32'd34)) begin
      $display(" TEST PASSED: Fibonacci sequence generated");
    end
    else begin
      $display(" TEST FAILED: Fibonacci result mismatch");
    end

    $finish;
  end

  final begin
    $dumpflush;
  end

endmodule
