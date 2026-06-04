`timescale 1ns/1ps

module fetch #(
  parameter RESET_PC = 32'h0000
)(
  input  logic        clk,
  input  logic        reset_n,
  input  logic [31:0] next_pc,
  input  logic [31:0] instruction_memory_read_data,
  output logic        instruction_memory_request,
  output logic [31:0] instruction_memory_address,
  output logic [31:0] current_pc,
  output logic [31:0] current_pc_plus4,
  output logic [31:0] fetched_instruction
);

  logic fetch_request_registered;

  pc_register #(
    .RESET_PC (RESET_PC)
  ) u_pc_register (
    .clk      (clk),
    .reset_n  (reset_n),
    .next_pc  (next_pc),
    .pc       (current_pc)
  );

  always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n)
      fetch_request_registered <= 1'b0;
    else
      fetch_request_registered <= 1'b1;
  end

  assign current_pc_plus4            = current_pc + 32'd4;
  assign instruction_memory_request  = fetch_request_registered;
  assign instruction_memory_address  = current_pc;
  assign fetched_instruction         = instruction_memory_read_data;

endmodule
