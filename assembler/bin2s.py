#!/usr/bin/python3
#
# Convert binary files into 6502 assembly code data blocks.
#
# Usage: python3 bin2s.py input.bin output.s

import sys

# Check that we have the needed command-line options.
if len(sys.argv) < 3:
    print("Usage: python3 bin2s.py input.bin output.s")
    sys.exit(1)

# Open the output assembly file.
with open(sys.argv[2], 'w') as outfile:
    # Read the input binary file.
    with open(sys.argv[1], 'rb') as infile:
        offset = 0
        byte = infile.read(1)
        while byte != b'':
            if offset == 0:
                outfile.write("        .db $%02X" % ord(byte))
                offset = 1
            else:
                outfile.write(", $%02X" % ord(byte))
                offset = offset + 1
                if offset >= 8:
                    outfile.write("\n")
                    offset = 0
            byte = infile.read(1)
        outfile.write("\n")
