#!/usr/bin/env python3
"""Generate machine_code.mem for the Fibonacci sequence program."""


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
def add(rd, rs1, rs2): return r_type(0x00, rs2, rs1, 0x0, rd)
def slli(rd, rs1, shamt): return i_type(shamt, rs1, 0x1, rd, 0x13)
def bge(rs1, rs2, offset): return b_type(offset, rs2, rs1, 0x5)
def jal(rd, offset): return j_type(offset, rd)
def nop(): return addi(0, 0, 0)


# Register aliases used in the screenshot.
x0 = 0
x10 = 10  # base address
x11 = 11  # fib_0
x12 = 12  # fib_1
x13 = 13  # loop index i
x14 = 14  # number of terms
x15 = 15  # fib_n
x16 = 16  # byte offset
x17 = 17  # memory address

instructions = []

# STEP 0: Set x10 = data memory base address 0x00000000.
instructions.append(lui(x10, 0x00000))       # 0x0000
instructions.append(addi(x10, x10, 0))       # 0x0004

# STEP 1: Initialize first two Fibonacci values.
instructions.append(addi(x11, x0, 0))        # 0x0008: fib_0 = 0
instructions.append(addi(x12, x0, 1))        # 0x000C: fib_1 = 1

# STEP 2: Store fib[0] and fib[1] into memory.
instructions.append(sw(x11, 0, x10))         # 0x0010: mem[0] = 0
instructions.append(sw(x12, 4, x10))         # 0x0014: mem[1] = 1

# STEP 3: Loop setup.
instructions.append(addi(x13, x0, 2))        # 0x0018: i = 2

# loop_cond at 0x001C.
instructions.append(addi(x14, x0, 10))       # 0x001C: number of terms = 10

# done at 0x0044, offset = 0x0044 - 0x0020 = 36.
instructions.append(bge(x13, x14, 36))       # 0x0020: if i >= 10, jump to done

# STEP 4: Compute fib[i] = fib_0 + fib_1 and store it.
instructions.append(add(x15, x11, x12))      # 0x0024: fib_n = fib_0 + fib_1
instructions.append(slli(x16, x13, 2))       # 0x0028: byte offset = i * 4
instructions.append(add(x17, x10, x16))      # 0x002C: address = base + offset
instructions.append(sw(x15, 0, x17))         # 0x0030: mem[i] = fib_n

# STEP 5: Update previous two Fibonacci values.
instructions.append(add(x11, x12, x0))       # 0x0034: fib_0 = fib_1
instructions.append(add(x12, x15, x0))       # 0x0038: fib_1 = fib_n

# STEP 6: Increment loop index and repeat.
instructions.append(addi(x13, x13, 1))       # 0x003C: i++

# loop_cond at 0x001C, offset = 0x001C - 0x0040 = -36.
instructions.append(jal(x0, -36))            # 0x0040: jump to loop_cond

# STEP 7: Done.
instructions.append(nop())                   # 0x0044: halt-style NOP

# Pad the 128-byte instruction memory with NOPs.
while len(instructions) < 32:
    instructions.append(nop())

for i, inst in enumerate(instructions):
    addr = i * 4
    print(f"0x{addr:04X}: 0x{inst:08X}")

with open("machine_code.mem", "w") as f:
    for inst in instructions:
        b3 = (inst >> 24) & 0xFF
        b2 = (inst >> 16) & 0xFF
        b1 = (inst >> 8) & 0xFF
        b0 = inst & 0xFF
        f.write(f"{b3:02X}\n{b2:02X}\n{b1:02X}\n{b0:02X}\n")

print(f"\nGenerated {len(instructions)} instructions ({len(instructions) * 4} bytes)")
print("Written to machine_code.mem")
