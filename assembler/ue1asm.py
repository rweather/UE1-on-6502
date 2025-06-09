#!/usr/bin/python3
#
# Very simple UE1 assembler in Python.
#
# Usage: python3 ue1asm.py input.asm output.bin

import sys
import re
import struct

listing = False

opcodes = {
    'NOP0': 0,
    'LD': 1,
    'ADD': 2,
    'SUB': 3,
    'ONE': 4,
    'NAND': 5,
    'OR': 6,
    'XOR': 7,
    'STO': 8,
    'STOC': 9,
    'IEN': 10,
    'OEN': 11,
    'IOC': 12,
    'RTN': 13,
    'SKZ': 14,
    'NOPF': 15,
    'HLT': 15       # Pseudo-opcode.
}
operands = {
    'SR0': 0,
    'SR1': 1,
    'SR2': 2,
    'SR3': 3,
    'SR4': 4,
    'SR5': 5,
    'SR6': 6,
    'SR7': 7,
    'RR': 8,
    'IR1': 9,
    'IR2': 10,
    'IR3': 11,
    'IR4': 12,
    'IR5': 13,
    'IR6': 14,
    'IR7': 15,
    'OR0': 8,
    'OR1': 9,
    'OR2': 10,
    'OR3': 11,
    'OR4': 12,
    'OR5': 13,
    'OR6': 14,
    'OR7': 15
}

histogram = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
instruction_count = 0

# Assemble a line of UE1 assembly code.
def assemble_line(outfile,address,num,line):
    global opcodes
    global operands
    global listing
    global histogram
    global instruction_count

    # Split out the opcode and operand names.
    if len(line) == 0 or line[0] == ';':
        return False
    insn = line.split(';')[0].strip()
    fields = re.split(r' +', insn)
    opcode = fields[0].upper()
    if len(fields) > 1:
        operand = fields[1].upper()
    else:
        operand = "SR0"

    # Convert the instruction into binary and write it to the output file.
    val = opcodes[opcode] * 16 + operands[operand]
    outfile.write(struct.pack('B', val))
    if listing:
        print("%04X: %02X        %-8d%s" % (address, val, num, sline))
    histogram[int(val / 16)] = histogram[int(val / 16)] + 1
    instruction_count = instruction_count + 1
    return True

# Print histogram details for an instruction.
def print_histogram(name, count):
    global instruction_count
    print("%-5s: %5d, %5.2f%%" % (name, count, 100 * count / instruction_count))

# Check that we have the needed command-line options.
if len(sys.argv) < 3:
    print("Usage: python3 ue1asm.py input.asm output.bin")
    sys.exit(1)

# Open the output binary file.
with open(sys.argv[2], 'wb') as outfile:
    # Read the input assembly file and process the lines.
    with open(sys.argv[1]) as infile:
        address = 0
        num = 1
        for line in infile:
            sline = line.strip()
            if assemble_line(outfile, address, num, sline):
                address = address + 1
            elif listing:
                print("                %-8d%s" % (num, sline))
            num = num + 1

# Print the histogram of instruction usage.
if instruction_count != 0:
    print_histogram('NOP0', histogram[0])
    print_histogram('LD', histogram[1])
    print_histogram('ADD', histogram[2])
    print_histogram('SUB', histogram[3])
    print_histogram('ONE', histogram[4])
    print_histogram('NAND', histogram[5])
    print_histogram('OR', histogram[6])
    print_histogram('XOR', histogram[7])
    print_histogram('STO', histogram[8])
    print_histogram('STOC', histogram[9])
    print_histogram('IEN', histogram[10])
    print_histogram('OEN', histogram[11])
    print_histogram('IOC', histogram[12])
    print_histogram('RTN', histogram[13])
    print_histogram('SKZ', histogram[14])
    print_histogram('NOPF', histogram[15])
    print("Total: %5d" % instruction_count)
