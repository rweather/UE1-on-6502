
UE1ASM = python3 ../../assembler/ue1asm.py

all: mul4x4.bin mul4x5.bin mul5x5.bin \
	div7x3.bin div7x4.bin div8x4.bin ue1emulator

mul4x4.bin: mul4x4.asm
	$(UE1ASM) mul4x4.asm mul4x4.bin

mul4x5.bin: mul4x5.asm
	$(UE1ASM) mul4x5.asm mul4x5.bin

mul5x5.bin: mul5x5.asm
	$(UE1ASM) mul5x5.asm mul5x5.bin

div7x3.bin: div7x3.asm
	$(UE1ASM) div7x3.asm div7x3.bin

div7x4.bin: div7x4.asm
	$(UE1ASM) div7x4.asm div7x4.bin

div8x4.bin: div8x4.asm
	$(UE1ASM) div8x4.asm div8x4.bin

ue1emulator: ue1emulator.c
	$(CC) -o ue1emulator -Wall ue1emulator.c

check: all
	./ue1emulator mul4x4.bin 4 4
	./ue1emulator mul4x5.bin 4 5
	./ue1emulator mul5x5.bin 5 5
	./ue1emulator div7x3.bin 3 7 div
	./ue1emulator div7x4.bin 4 7 div
	./ue1emulator div8x4.bin 4 8 div

clean:
	rm -f mul4x4.bin mul4x5.bin mul5x5.bin
	rm -f div7x3.bin div7x4.bin div8x4.bin
	rm -f ue1emulator
