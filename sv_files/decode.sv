`timescale 1ns/1ps

import risc_pkg::*;

module decode(
  input  logic [31:0]  instruction,  // 32-bit instruction from IF stage

  // Decoded fields
  output logic [4:0]   rs1_addr,
  output logic [4:0]   rs2_addr,
  output logic [4:0]   rd_addr,
  output logic [6:0]   opcode,
  output logic [2:0]   funct3,
  output logic [6:0]   funct7,
  output logic         r_type,
  output logic         i_type,
  output logic         s_type,
  output logic         b_type,
  output logic         u_type,
  output logic         j_type,
  output logic         uses_rs1,
  output logic         uses_rs2
);

  assign opcode = instruction[6:0];
  assign rd_addr = instruction[11:7];
  assign funct3 = instruction[14:12];
  assign rs1_addr = instruction[19:15];
  assign rs2_addr = instruction[24:20];
  assign funct7 = instruction[31:25];

  always_comb begin
	r_type = 1'b0;
	s_type = 1'b0;
	b_type = 1'b0;
	u_type = 1'b0;
	i_type = 1'b0;
	j_type = 1'b0;

	case(opcode)
	  OPCODE_R_TYPE: r_type = 1'b1;
	  OPCODE_I_LOAD,
	  OPCODE_I_ALU,
	  OPCODE_I_JALR: i_type = 1'b1;
	  OPCODE_S_TYPE: s_type = 1'b1;
	  OPCODE_B_TYPE: b_type = 1'b1;
	  OPCODE_LUI,
	  OPCODE_AUIPC: u_type = 1'b1;
	  OPCODE_JAL: j_type = 1'b1;
	  default: begin
	    r_type = 1'b0;
	    s_type = 1'b0;
	    b_type = 1'b0;
	    u_type = 1'b0;
	    i_type = 1'b0;
	    j_type = 1'b0;
	  end
	endcase
  end

  assign uses_rs1 = r_type | i_type | s_type | b_type;
  assign uses_rs2 = r_type | s_type | b_type;

endmodule
