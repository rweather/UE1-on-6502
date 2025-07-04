
VASM = vasm6502_oldstyle
VASM_OPTIONS = -quiet -dotdir -Fbin
PYTHON = python3

all: UE1_6502.bin UE1_APPLE2.bin UE1_DSECAT.bin

UE1_6502.bin: UE1_6502.s UE1_DIAPER1.s UE1_DIAPER2.s
	$(VASM) $(VASM_OPTIONS) -DEATER -L UE1_6502.lst -o UE1_6502.bin UE1_6502.s

UE1_APPLE2.bin: UE1_6502.s UE1_DIAPER1.s UE1_DIAPER2.s
	$(VASM) $(VASM_OPTIONS) -DAPPLE2 -DBRUN_HEADER -L UE1_APPLE2.lst -o UE1_APPLE2.bin UE1_6502.s

UE1_DSECAT.bin: UE1_6502.s UE1_DIAPER1.s UE1_DIAPER2.s dsecat/build-rom.py dsecat/loader.bin
	$(VASM) $(VASM_OPTIONS) -DAPPLE2 -L UE1_DSECAT.lst -o UE1_DSECAT_in.bin UE1_6502.s
	$(PYTHON) dsecat/build-rom.py UE1_DSECAT.bin 2000 UE1_DSECAT_in.bin dsecat/loader.bin

UE1_DIAPER1.s: diaper/UE1_DIAPER1_V2.BIN assembler/bin2s.py
	$(PYTHON) assembler/bin2s.py diaper/UE1_DIAPER1_V2.BIN UE1_DIAPER1.s

diaper/UE1_DIAPER1_V2.BIN: diaper/UE1_DIAPER1_V2.ASM assembler/ue1asm.py
	$(PYTHON) assembler/ue1asm.py diaper/UE1_DIAPER1_V2.ASM diaper/UE1_DIAPER1_V2.BIN

UE1_DIAPER2.s: diaper/UE1_DIAPER2_V1.BIN assembler/bin2s.py
	$(PYTHON) assembler/bin2s.py diaper/UE1_DIAPER2_V1.BIN UE1_DIAPER2.s

diaper/UE1_DIAPER2_V1.BIN: diaper/UE1_DIAPER2_V1.ASM assembler/ue1asm.py
	$(PYTHON) assembler/ue1asm.py diaper/UE1_DIAPER2_V1.ASM diaper/UE1_DIAPER2_V1.BIN

clean:
	rm -f UE1_6502.bin UE1_6502.lst
	rm -f UE1_APPLE2.bin UE1_APPLE2.lst
	rm -f UE1_DSECAT.bin UE1_DSECAT_in.bin UE1_DSECAT.lst
	rm -f diaper/UE1_DIAPER1_V2.BIN UE1_DIAPER1.s
	rm -f diaper/UE1_DIAPER2_V1.BIN UE1_DIAPER2.s
