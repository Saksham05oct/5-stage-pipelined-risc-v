#!/usr/bin/env python3
"""Generate machine_code.mem for the Find Maximum in Array program."""

def r_type(funct7, rs2, rs1, funct3, rd):
    return (funct7 << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | 0x33

def i_type(imm, rs1, funct3, rd, opcode=0x13):
    imm = imm & 0xFFF
    return (imm << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | opcode

def s_type(imm, rs2, rs1, funct3=0x2):
    imm = imm & 0xFFF
    imm_11_5 = (imm >> 5) & 0x7F
    imm_4_0 = imm & 0x1F
    return (imm_11_5 << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | (imm_4_0 << 7) | 0x23

def b_type(imm, rs2, rs1, funct3):
    imm = imm & 0x1FFF
    bit12 = (imm >> 12) & 1
    bit11 = (imm >> 11) & 1
    bits10_5 = (imm >> 5) & 0x3F
    bits4_1 = (imm >> 1) & 0xF
    return (bit12 << 31) | (bits10_5 << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | (bits4_1 << 8) | (bit11 << 7) | 0x63

def j_type(imm, rd):
    imm = imm & 0x1FFFFF
    bit20 = (imm >> 20) & 1
    bits10_1 = (imm >> 1) & 0x3FF
    bit11 = (imm >> 11) & 1
    bits19_12 = (imm >> 12) & 0xFF
    return (bit20 << 31) | (bits10_1 << 21) | (bit11 << 20) | (bits19_12 << 12) | (rd << 7) | 0x6F

def lui(rd, imm_upper):
    return (imm_upper << 12) | (rd << 7) | 0x37

def addi(rd, rs1, imm): return i_type(imm, rs1, 0x0, rd, 0x13)
def sw(rs2, offset, rs1): return s_type(offset, rs2, rs1, 0x2)
def lw(rd, offset, rs1): return i_type(offset, rs1, 0x2, rd, 0x03)
def add(rd, rs1, rs2): return r_type(0x00, rs2, rs1, 0x0, rd)
def slli(rd, rs1, shamt): return i_type(shamt, rs1, 0x1, rd, 0x13)
def bge(rs1, rs2, offset): return b_type(offset, rs2, rs1, 0x5)
def blt(rs1, rs2, offset): return b_type(offset, rs2, rs1, 0x4)
def jal(rd, offset): return j_type(offset, rd)
def nop(): return addi(0, 0, 0)

# Register aliases
x0, x10, x11, x12, x13, x14, x15, x16 = 0, 10, 11, 12, 13, 14, 15, 16

instructions = []

# 0x0000: lui x10, 0x00000
instructions.append(lui(x10, 0x00000))
# 0x0004: addi x10, x10, 0
instructions.append(addi(x10, x10, 0))

# Initialize array
instructions.append(addi(x11, x0, 8))       # 0x0008
instructions.append(sw(x11, 0, x10))         # 0x000C
instructions.append(addi(x11, x0, -21))      # 0x0010
instructions.append(sw(x11, 4, x10))         # 0x0014
instructions.append(addi(x11, x0, 15))       # 0x0018
instructions.append(sw(x11, 8, x10))         # 0x001C
instructions.append(addi(x11, x0, -3))       # 0x0020
instructions.append(sw(x11, 12, x10))        # 0x0024
instructions.append(addi(x11, x0, 42))       # 0x0028
instructions.append(sw(x11, 16, x10))        # 0x002C
instructions.append(addi(x11, x0, 17))       # 0x0030
instructions.append(sw(x11, 20, x10))        # 0x0034

# Initialize loop
instructions.append(lw(x11, 0, x10))         # 0x0038: max = A[0]
instructions.append(addi(x12, x0, 1))        # 0x003C: i = 1
instructions.append(addi(x13, x0, 6))        # 0x0040: N = 6

# loop_cond at 0x0044
# done at 0x0068, offset = 0x0068 - 0x0044 = 36
instructions.append(bge(x12, x13, 36))       # 0x0044: bge x12, x13, done

instructions.append(slli(x15, x12, 2))       # 0x0048: x15 = i * 4
instructions.append(add(x16, x10, x15))      # 0x004C: x16 = &A[i]
instructions.append(lw(x14, 0, x16))         # 0x0050: x14 = A[i]

# update_max at 0x005C, offset = 0x005C - 0x0054 = 8
instructions.append(blt(x11, x14, 8))        # 0x0054: blt x11, x14, update_max

# skip_update at 0x0060, offset = 0x0060 - 0x0058 = 8
instructions.append(jal(x0, 8))              # 0x0058: jal x0, skip_update

# update_max:
instructions.append(add(x11, x14, x0))       # 0x005C: max = A[i]

# skip_update:
instructions.append(addi(x12, x12, 1))       # 0x0060: i++

# loop_cond at 0x0044, offset = 0x0044 - 0x0064 = -32
# -32 in two's complement 13-bit = 0x1FE0
instructions.append(jal(x0, -32 & 0x1FFFFF)) # 0x0064: jal x0, loop_cond

# done:
instructions.append(sw(x11, 24, x10))        # 0x0068: store max at A[6]
instructions.append(nop())                    # 0x006C: halt

# Pad the rest of instruction memory with NOPs so $readmemh fills the ROM.
while len(instructions) < 32:
    instructions.append(nop())

# Print disassembly for verification
for i, inst in enumerate(instructions):
    addr = i * 4
    print(f"0x{addr:04X}: 0x{inst:08X}")

# Write to machine_code.mem (byte-per-line, big-endian order)
with open("machine_code.mem", "w") as f:
    for inst in instructions:
        b3 = (inst >> 24) & 0xFF  # MSB
        b2 = (inst >> 16) & 0xFF
        b1 = (inst >> 8) & 0xFF
        b0 = inst & 0xFF          # LSB
        f.write(f"{b3:02X}\n{b2:02X}\n{b1:02X}\n{b0:02X}\n")

print(f"\nGenerated {len(instructions)} instructions ({len(instructions)*4} bytes)")
print("Written to machine_code.mem")
