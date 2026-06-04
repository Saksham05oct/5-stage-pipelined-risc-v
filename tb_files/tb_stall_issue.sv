`timescale 1ns/1ps
import risc_pkg::*;

module tb_stall_issue;
  logic clk;
  logic reset_n;

  // 10ns clock
  initial clk = 0;
  always #5 clk = ~clk;

  // Instantiate top-level design
  top #(.RESET_PC(32'h0000)) u_top (
    .clk     (clk),
    .reset_n (reset_n)
  );

  int cycle_count = 0;
  bit stall_occurred = 0;

  initial begin
    // 1. Manually initialize instruction memory to isolate the test case
    // Program:
    // 0x00: lw x5, 0(x2)       -> 32'h00012283
    // 0x04: addi x3, x4, 5     -> 32'h00520193
    // 0x08: nop (addi x0,x0,0) -> 32'h00000013
    // 0x0C: nop                -> 32'h00000013
    // 0x10: nop                -> 32'h00000013
    
    // Instruction 0 (PC=0x00): lw x5, 0(x2)
    u_top.u_instruction_memory.mem[0] = 8'h00;
    u_top.u_instruction_memory.mem[1] = 8'h01;
    u_top.u_instruction_memory.mem[2] = 8'h22;
    u_top.u_instruction_memory.mem[3] = 8'h83;

    // Instruction 1 (PC=0x04): addi x3, x4, 5
    u_top.u_instruction_memory.mem[4] = 8'h00;
    u_top.u_instruction_memory.mem[5] = 8'h52;
    u_top.u_instruction_memory.mem[6] = 8'h01;
    u_top.u_instruction_memory.mem[7] = 8'h93;

    // Pad remaining instruction memory with NOPs
    for (int i = 8; i < 128; i = i + 4) begin
      u_top.u_instruction_memory.mem[i]   = 8'h00;
      u_top.u_instruction_memory.mem[i+1] = 8'h00;
      u_top.u_instruction_memory.mem[i+2] = 8'h00;
      u_top.u_instruction_memory.mem[i+3] = 8'h13;
    end

    // 2. Perform Reset
    reset_n = 0;
    #15;
    reset_n = 1;
    $display("\n=======================================================");
    $display("   Load-Use Stall Issue Testbench Started");
    $display("=======================================================");

    // 3. Monitor pipeline behavior for 8 cycles
    while (cycle_count < 8) begin
      @(posedge clk);
      cycle_count++;
      
      // Sample hazard control signals right after the active clock edge
      #1; 
      $display("Cycle %0d | PC=%08h | ID_Instr=%08h | EX_rd=%0d | Stall=%0b",
               cycle_count,
               u_top.current_pc,
               u_top.if_id_instruction,
               u_top.execute_rd_addr,
               u_top.stall_for_load_use_hazard);

      if (u_top.stall_for_load_use_hazard) begin
        stall_occurred = 1;
        $display("  --> [STALL DETECTED] Hazard unit stalled the pipeline!");
        $display("      ID_rs1=%0d, ID_rs2=%0d (decoded from imm), EX_rd=%0d", 
                 u_top.decoded_rs1_addr, u_top.decoded_rs2_addr, u_top.execute_rd_addr);
      end
    end

    $display("=======================================================");
    if (stall_occurred) begin
      $display(" RESULT: UNNECESSARY STALL DETECTED (TEST FAILED/BUG ACTIVE)");
    end else begin
      $display(" RESULT: NO UNNECESSARY STALL (TEST PASSED/BUG FIXED)");
    end
    $display("=======================================================\n");

    $finish;
  end

endmodule
