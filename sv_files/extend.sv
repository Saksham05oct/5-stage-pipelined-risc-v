`timescale 1ns/1ps

module extend (
  input  logic [31:0] instruction,
  input  logic        r_type,
  input  logic        i_type,
  input  logic        s_type,
  input  logic        b_type,
  input  logic        u_type,
  output logic [31:0] immediate
);

  logic [31:0] imm_i_type;
  logic [31:0] imm_s_type;
  logic [31:0] imm_b_type;
  logic [31:0] imm_u_type;
  logic [31:0] imm_j_type;

  assign imm_i_type = {{20{instruction[31]}}, instruction[31:20]};
  assign imm_s_type = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};
  assign imm_b_type = {{19{instruction[31]}}, instruction[31], instruction[7], instruction[30:25], instruction[11:8], 1'b0};
  assign imm_u_type = {instruction[31:12], 12'b0};
  assign imm_j_type = {{11{instruction[31]}}, instruction[31], instruction[19:12], instruction[20], instruction[30:21], 1'b0};

  assign immediate = r_type ? 32'd0 :
                     i_type ? imm_i_type :
                     s_type ? imm_s_type :
                     b_type ? imm_b_type :
                     u_type ? imm_u_type :
                              imm_j_type;

endmodule
