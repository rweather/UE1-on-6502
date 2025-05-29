
VASM = vasm6502_oldstyle
VASM_OPTIONS = -quiet -dotdir -Fbin

all: UE1_6502.bin

UE1_6502.bin: UE1_6502.s
	$(VASM) $(VASM_OPTIONS) -L UE1_6502.lst -o UE1_6502.bin UE1_6502.s

clean:
	rm -f UE1_6502.bin UE1_6502.lst
