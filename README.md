# RV32I 5-Stage Pipelined Processor

This project implements a fully functional **5-stage pipelined RV32I RISC-V processor** in SystemVerilog. The processor supports a subset of the RV32I instruction set, featuring hazard detection and data forwarding to optimize performance and prevent instruction hazards.

---

## 1. Processor Architecture

The processor implements the standard RISC-V 5-stage pipelined architecture:

1. **Instruction Fetch (IF):** Fetches instructions from the Instruction Memory (ROM) using the Program Counter (PC). Includes branch/jump target selection.
2. **Instruction Decode (ID):** Decodes the instruction, reads operands from the Register File, and extracts immediate values.
3. **Execute (EX):** Performs ALU operations, evaluates branch conditions, and computes memory/jump target addresses.
4. **Memory Access (MEM):** Reads from or writes to the Data Memory (RAM) for load and store instructions.
5. **Write Back (WB):** Writes the final ALU result or loaded memory data back into the Register File.

### Datapath & Control Schematic
Below is the architectural schematic of our 5-stage pipelined processor, including the control unit, registers, ALU, memory, and hazard unit:

![RISC-V 5-Stage Pipelined Architecture](assets/riscv_architecture.png)

---

## 2. RV32I Base Instruction Set

### Instruction Formats
| Format | bits 31:25 | bits 24:20 | bits 19:15 | bits 14:12 | bits 11:7 | bits 6:0 | Type |
|---|---|---|---|---|---|---|---|
| **R-type** | funct7 | rs2 | rs1 | funct3 | rd | opcode | Register-Register |
| **I-type** | imm[11:0] | | rs1 | funct3 | rd | opcode | Register-Immediate |
| **S-type** | imm[11:5] | rs2 | rs1 | funct3 | imm[4:0] | opcode | Store |
| **B-type (SB)** | imm[12\|10:5] | rs2 | rs1 | funct3 | imm[4:1\|11] | opcode | Branch |
| **U-type** | imm[31:12] | | | | rd | opcode | Upper Immediate |
| **J-type (UJ)** | imm[20\|10:1\|11\|19:12] | | | | rd | opcode | Jump |

### RV32I Instruction Set Map
| Instruction | bits 31:25 | bits 24:20 | bits 19:15 | bits 14:12 | bits 11:7 | bits 6:0 | Assembly Syntax |
|---|---|---|---|---|---|---|---|
| **LUI** | imm[31:12] | | | | rd | 0110111 | `LUI rd, imm` |
| **AUIPC** | imm[31:12] | | | | rd | 0010111 | `AUIPC rd, imm` |
| **JAL** | imm[20\|10:1\|11\|19:12] | | | | rd | 1101111 | `JAL rd, imm` |
| **JALR** | imm[11:0] | | rs1 | 000 | rd | 1100111 | `JALR rd, rs1, imm` |
| **BEQ** | imm[12\|10:5] | rs2 | rs1 | 000 | imm[4:1\|11] | 1100011 | `BEQ rs1, rs2, imm` |
| **BNE** | imm[12\|10:5] | rs2 | rs1 | 001 | imm[4:1\|11] | 1100011 | `BNE rs1, rs2, imm` |
| **BLT** | imm[12\|10:5] | rs2 | rs1 | 100 | imm[4:1\|11] | 1100011 | `BLT rs1, rs2, imm` |
| **BGE** | imm[12\|10:5] | rs2 | rs1 | 101 | imm[4:1\|11] | 1100011 | `BGE rs1, rs2, imm` |
| **BLTU** | imm[12\|10:5] | rs2 | rs1 | 110 | imm[4:1\|11] | 1100011 | `BLTU rs1, rs2, imm` |
| **BGEU** | imm[12\|10:5] | rs2 | rs1 | 111 | imm[4:1\|11] | 1100011 | `BGEU rs1, rs2, imm` |
| **LB** | imm[11:0] | | rs1 | 000 | rd | 0000011 | `LB rd, rs1, imm` |
| **LH** | imm[11:0] | | rs1 | 001 | rd | 0000011 | `LH rd, rs1, imm` |
| **LW** | imm[11:0] | | rs1 | 010 | rd | 0000011 | `LW rd, rs1, imm` |
| **LBU** | imm[11:0] | | rs1 | 100 | rd | 0000011 | `LBU rd, rs1, imm` |
| **LHU** | imm[11:0] | | rs1 | 101 | rd | 0000011 | `LHU rd, rs1, imm` |
| **SB** | imm[11:5] | rs2 | rs1 | 000 | imm[4:0] | 0100011 | `SB rs1, rs2, imm` |
| **SH** | imm[11:5] | rs2 | rs1 | 001 | imm[4:0] | 0100011 | `SH rs1, rs2, imm` |
| **SW** | imm[11:5] | rs2 | rs1 | 010 | imm[4:0] | 0100011 | `SW rs1, rs2, imm` |
| **ADDI** | imm[11:0] | | rs1 | 000 | rd | 0010011 | `ADDI rd, rs1, imm` |
| **SLTI** | imm[11:0] | | rs1 | 010 | rd | 0010011 | `SLTI rd, rs1, imm` |
| **SLTIU** | imm[11:0] | | rs1 | 011 | rd | 0010011 | `SLTIU rd, rs1, imm` |
| **XORI** | imm[11:0] | | rs1 | 100 | rd | 0010011 | `XORI rd, rs1, imm` |
| **ORI** | imm[11:0] | | rs1 | 110 | rd | 0010011 | `ORI rd, rs1, imm` |
| **ANDI** | imm[11:0] | | rs1 | 111 | rd | 0010011 | `ANDI rd, rs1, imm` |
| **SLLI** | 0000000 | shamt | rs1 | 001 | rd | 0010011 | `SLLI rd, rs1, shamt` |
| **SRLI** | 0000000 | shamt | rs1 | 101 | rd | 0010011 | `SRLI rd, rs1, shamt` |
| **SRAI** | 0100000 | shamt | rs1 | 101 | rd | 0010011 | `SRAI rd, rs1, shamt` |
| **ADD** | 0000000 | rs2 | rs1 | 000 | rd | 0110011 | `ADD rd, rs1, rs2` |
| **SUB** | 0100000 | rs2 | rs1 | 000 | rd | 0110011 | `SUB rd, rs1, rs2` |
| **SLL** | 0000000 | rs2 | rs1 | 001 | rd | 0110011 | `SLL rd, rs1, rs2` |
| **SLT** | 0000000 | rs2 | rs1 | 010 | rd | 0110011 | `SLT rd, rs1, rs2` |
| **SLTU** | 0000000 | rs2 | rs1 | 011 | rd | 0110011 | `SLTU rd, rs1, rs2` |
| **XOR** | 0000000 | rs2 | rs1 | 100 | rd | 0110011 | `XOR rd, rs1, rs2` |
| **SRL** | 0000000 | rs2 | rs1 | 101 | rd | 0110011 | `SRL rd, rs1, rs2` |
| **SRA** | 0100000 | rs2 | rs1 | 101 | rd | 0110011 | `SRA rd, rs1, rs2` |
| **OR** | 0000000 | rs2 | rs1 | 110 | rd | 0110011 | `OR rd, rs1, rs2` |
| **AND** | 0000000 | rs2 | rs1 | 111 | rd | 0110011 | `AND rd, rs1, rs2` |

---

## 3. Immediate Generation Logic

RISC-V instructions use structured layouts where immediate bits are strategically placed to minimize multiplexer complexity. The sign bit (bit 31) is always in the same position across all formats.

The immediate generator (`sv_files/extend.sv`) reconstructs 32-bit sign-extended immediates based on the instruction type:

*   **I-Type (Loads, ALU Immediates):** Reconstructed as `{{20{inst[31]}}, inst[31:20]}`.
*   **S-Type (Stores):** Reconstructed as `{{20{inst[31]}}, inst[31:25], inst[11:7]}`.
*   **B-Type (Branches):** Reconstructed as `{{19{inst[31]}}, inst[31], inst[7], inst[30:25], inst[11:8], 1'b0}`.
*   **U-Type (LUI, AUIPC):** Reconstructed as `{inst[31:12], 12'b0}`.
*   **J-Type (Unconditional Jumps):** Reconstructed as `{{11{inst[31]}}, inst[31], inst[19:12], inst[20], inst[30:21], 1'b0}`.

### RISC-V Immediate Formats
The layout of bits for each immediate format is shown below:

![RISC-V Immediate Generation Logic](assets/immediate_logic.png)

---

## 3. Directory Structure

*   `sv_files/`: Core SystemVerilog RTL modules.
    *   `top.sv`: Top-level processor block.
    *   `fetch.sv`, `decode.sv`, `control.sv`, `extend.sv`, `alu.sv`, `register_file.sv`, `data_memory.sv`, `instruction_memory.sv`, `hazard_control.sv`, `branch_control.sv`.
*   `tb_files/`: Testbenches for verification.
    *   `tb_MaxArray.sv`: General top-level testbench finding the maximum in an array.
    *   `tb_stall_issue.sv`: Testbench demonstrating the conservative load-use stall issue.
*   `assets/`: Diagrams and documentation assets.
