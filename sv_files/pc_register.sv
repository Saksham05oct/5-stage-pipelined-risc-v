`timescale 1ns/1ps

module pc_register #(
  parameter RESET_PC = 32'h0000
)(
  input  logic        clk,
  input  logic        reset_n,
  input  logic [31:0] next_pc,
  output logic [31:0] pc
);

  logic reset_seen;

  always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n)
      reset_seen <= 1'b0;
    else
      reset_seen <= 1'b1;
  end

  always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n)
      pc <= RESET_PC;
    else if (reset_seen)
      pc <= next_pc;
  end

endmodule
