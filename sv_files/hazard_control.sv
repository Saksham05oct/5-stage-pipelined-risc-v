`timescale 1ns/1ps

import risc_pkg::*;

module hazard_control (
  input  logic [4:0]  id_rs1_addr,
  input  logic [4:0]  id_rs2_addr,
  input  logic        id_uses_rs1,
  input  logic        id_uses_rs2,
  input  logic [31:0] id_ex_rs1_data,
  input  logic [31:0] id_ex_rs2_data,
  input  logic [4:0]  id_ex_rs1_addr,
  input  logic [4:0]  id_ex_rs2_addr,
  input  logic [4:0]  id_ex_rd_addr,
  input  logic        id_ex_dmem_req,
  input  logic        id_ex_dmem_wr_en,
  input  logic        id_ex_rf_wr_en,
  input  logic        id_ex_pc_sel,
  input  logic [31:0] ex_mem_alu_res,
  input  logic [31:0] ex_mem_immediate,
  input  logic [31:0] ex_mem_pc_plus4,
  input  logic [4:0]  ex_mem_rd_addr,
  input  wb_src_t     ex_mem_rf_wr_data_sel,
  input  logic        ex_mem_dmem_req, // it is a memory instruction.
  input  logic        ex_mem_rf_wr_en, // The older instruction writes a register.
  input  logic [31:0] wb_wr_data,
  input  logic [4:0]  mem_wb_rd_addr,
  input  logic        mem_wb_rf_wr_en,
  input  logic        ex_branch_taken,
  input  logic [31:0] ex_branch_target,
  input  logic [31:0] pc,
  input  logic [31:0] next_seq_pc,
  output logic [31:0] ex_rs1_fwd_data,
  output logic [31:0] ex_rs2_fwd_data,
  output logic        load_use_stall,
  output logic        ex_take_pc,
  output logic [31:0] next_pc
);

  logic [31:0] ex_mem_fwd_data;

  always_comb begin
    case (ex_mem_rf_wr_data_sel)
      WB_SRC_ALU: ex_mem_fwd_data = ex_mem_alu_res;
      WB_SRC_IMM: ex_mem_fwd_data = ex_mem_immediate;
      WB_SRC_PC:  ex_mem_fwd_data = ex_mem_pc_plus4;
      default:    ex_mem_fwd_data = 32'd0;
    endcase
  end

  always_comb begin
    // By default:
    // don't forward anything.
    // Use register file values.
    ex_rs1_fwd_data = id_ex_rs1_data;
    ex_rs2_fwd_data = id_ex_rs2_data;

    if (ex_mem_rf_wr_en && !ex_mem_dmem_req && (ex_mem_rd_addr != 5'd0) &&
        (ex_mem_rd_addr == id_ex_rs1_addr)) begin
      ex_rs1_fwd_data = ex_mem_fwd_data;
    end
    else if (mem_wb_rf_wr_en && (mem_wb_rd_addr != 5'd0) &&
             (mem_wb_rd_addr == id_ex_rs1_addr)) begin
      ex_rs1_fwd_data = wb_wr_data;
    end

    if (ex_mem_rf_wr_en && !ex_mem_dmem_req && (ex_mem_rd_addr != 5'd0) &&
        (ex_mem_rd_addr == id_ex_rs2_addr)) begin
      ex_rs2_fwd_data = ex_mem_fwd_data;
    end
    else if (mem_wb_rf_wr_en && (mem_wb_rd_addr != 5'd0) &&
             (mem_wb_rd_addr == id_ex_rs2_addr)) begin
      ex_rs2_fwd_data = wb_wr_data;
    end
  end

  assign load_use_stall =
      id_ex_dmem_req && !id_ex_dmem_wr_en && id_ex_rf_wr_en &&
      (id_ex_rd_addr != 5'd0) &&
      (((id_ex_rd_addr == id_rs1_addr) && id_uses_rs1) || 
       ((id_ex_rd_addr == id_rs2_addr) && id_uses_rs2));

  assign ex_take_pc = ex_branch_taken | id_ex_pc_sel;

  assign next_pc = ex_take_pc     ? ex_branch_target :
                   load_use_stall ? pc :
                                    next_seq_pc;

endmodule
