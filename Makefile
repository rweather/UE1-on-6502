
VASM = vasm6502_oldstyle
VASM_OPTIONS = -quiet -dotdir -Fbin
PYTHON = python3

all: UE1_6502.bin UE1_APPLE2.bin UE1_DSECAT.bin

UE1_6502.bin: UE1_6502.s
	$(VASM) $(VASM_OPTIONS) -DEATER -L UE1_6502.lst -o UE1_6502.bin UE1_6502.s

UE1_APPLE2.bin: UE1_6502.s
	$(VASM) $(VASM_OPTIONS) -DAPPLE2 -DBRUN_HEADER -L UE1_APPLE2.lst -o UE1_APPLE2.bin UE1_6502.s

UE1_DSECAT.bin: UE1_6502.s dsecat/build-rom.py dsecat/loader.bin
	$(VASM) $(VASM_OPTIONS) -DAPPLE2 -L UE1_DSECAT.lst -o UE1_DSECAT_in.bin UE1_6502.s
	$(PYTHON) dsecat/build-rom.py UE1_DSECAT.bin 2000 UE1_DSECAT_in.bin dsecat/loader.bin

clean:
	rm -f UE1_6502.bin UE1_6502.lst
	rm -f UE1_APPLE2.bin UE1_APPLE2.lst
	rm -f UE1_DSECAT.bin UE1_DSECAT_in.bin UE1_DSECAT.lst
