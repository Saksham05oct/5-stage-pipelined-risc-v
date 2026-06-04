`timescale 1ns/1ps
import risc_pkg::*;

module tb_MaxArray;
  // Clock & Reset
  logic clk;
  logic reset_n;

  // 10ns clock period (100 MHz)
  initial clk = 0;
  always #5 clk = ~clk;

  // DUT Instantiation
  top #(.RESET_PC(32'h0000)) u_top (
    .clk     (clk),
    .reset_n (reset_n)
  );

  // Test Sequence
  integer cycle_count;
  logic program_done;

  initial begin
    // GTKWave waveform dump. Compile Verilator with --trace to generate this VCD.
    $dumpfile("tb_MaxArray.vcd");
    $dumpvars(0, tb_MaxArray);

    // Reset sequence
    reset_n = 0;
    repeat(3) @(posedge clk);
    reset_n = 1;
    $display(" Find Maximum in Array - Testbench");
    $display("[%0t] Reset released", $time);

    // Run until program reaches the NOP halt (PC = 0x006C)
    // or timeout after 300 cycles
    program_done = 0;
    cycle_count = 0;

    while (!program_done && cycle_count < 300) begin
      @(posedge clk);
      cycle_count = cycle_count + 1;

      // The halt NOP is at 0x006C. After fetching it, PC
      // advances to 0x0070 and stays there (reading garbage/NOPs).
      // We detect this to know the program is done, then let
      // the pipeline drain.
      if (u_top.current_pc == 32'h0070) begin
        repeat(5) @(posedge clk);
        cycle_count = cycle_count + 5;
        program_done = 1;
      end
    end

    if (!program_done) begin
      $display("[%0t] ERROR: Program did not complete within 300 cycles!", $time);
      $display("       Last PC = 0x%08X", u_top.current_pc);
      $finish;
    end

    $display("[%0t] Program completed in %0d cycles", $time, cycle_count);
    $display("");

    // Verify array values in data memory using inline byte concatenation
    $display("--- Data Memory Contents ---");
    $display("  A[0] = %0d (expected 8)",   $signed({u_top.u_data_memory.mem[3], u_top.u_data_memory.mem[2], u_top.u_data_memory.mem[1], u_top.u_data_memory.mem[0]}));
    $display("  A[1] = %0d (expected -21)",  $signed({u_top.u_data_memory.mem[7], u_top.u_data_memory.mem[6], u_top.u_data_memory.mem[5], u_top.u_data_memory.mem[4]}));
    $display("  A[2] = %0d (expected 15)",   $signed({u_top.u_data_memory.mem[11], u_top.u_data_memory.mem[10], u_top.u_data_memory.mem[9], u_top.u_data_memory.mem[8]}));
    $display("  A[3] = %0d (expected -3)",   $signed({u_top.u_data_memory.mem[15], u_top.u_data_memory.mem[14], u_top.u_data_memory.mem[13], u_top.u_data_memory.mem[12]}));
    $display("  A[4] = %0d (expected 42)",   $signed({u_top.u_data_memory.mem[19], u_top.u_data_memory.mem[18], u_top.u_data_memory.mem[17], u_top.u_data_memory.mem[16]}));
    $display("  A[5] = %0d (expected 17)",   $signed({u_top.u_data_memory.mem[23], u_top.u_data_memory.mem[22], u_top.u_data_memory.mem[21], u_top.u_data_memory.mem[20]}));
    $display("  A[6] = %0d (expected 42, the maximum)", $signed({u_top.u_data_memory.mem[27], u_top.u_data_memory.mem[26], u_top.u_data_memory.mem[25], u_top.u_data_memory.mem[24]}));
    $display("");

    // Verify key register values
    $display("--- Register File ---");
    $display("  x10 (base)  = 0x%08X", u_top.u_register_file.regs[10]);
    $display("  x11 (max)   = %0d",    $signed(u_top.u_register_file.regs[11]));
    $display("  x12 (i)     = %0d",    u_top.u_register_file.regs[12]);
    $display("  x13 (N)     = %0d",    u_top.u_register_file.regs[13]);
    $display("");

    // Final pass/fail check
    if ($signed({u_top.u_data_memory.mem[27], u_top.u_data_memory.mem[26], u_top.u_data_memory.mem[25], u_top.u_data_memory.mem[24]}) == 42) begin
      $display(" TEST PASSED: Maximum value = 42 stored at A[6]");
    end else begin
      $display(" TEST FAILED: Expected 42 at A[6], got %0d",
               $signed({u_top.u_data_memory.mem[27], u_top.u_data_memory.mem[26], u_top.u_data_memory.mem[25], u_top.u_data_memory.mem[24]}));
    end

    $finish;
  end

  final begin
    $dumpflush;
  end

endmodule
