;
; Copyright (C) 2025 Rhys Weatherley
;
; Permission is hereby granted, free of charge, to any person obtaining a
; copy of this software and associated documentation files (the "Software"),
; to deal in the Software without restriction, including without limitation
; the rights to use, copy, modify, merge, publish, distribute, sublicense,
; and/or sell copies of the Software, and to permit persons to whom the
; Software is furnished to do so, subject to the following conditions:
;
; The above copyright notice and this permission notice shall be included
; in all copies or substantial portions of the Software.
;
; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
; OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
; FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
; DEALINGS IN THE SOFTWARE.
;

;
; UE-1 emulator for Ben Eater's 6502 Breadboard Computer.
;
; Assemble using VASM as follows:
;
; vasm6502_oldstyle -dotdir -Fbin -o UE1_6502.bin UE1_6502.s
;
; Then program the EEPROM with the contents of "UE1-6502.bin".
;
; VASM can be obtained from here: http://sun.hasenbraten.de/vasm/
;

        .org    $8000

;
; UE-1 opcodes, aligned in the high nibble.
;
OP_NOP0 .equ    $00
OP_LD   .equ    $10
OP_ADD  .equ    $20
OP_SUB  .equ    $30
OP_ONE  .equ    $40
OP_NAND .equ    $50
OP_OR   .equ    $60
OP_XOR  .equ    $70
OP_STO  .equ    $80
OP_STOC .equ    $90
OP_IEN  .equ    $A0
OP_OEN  .equ    $B0
OP_IOC  .equ    $C0
OP_RTN  .equ    $D0
OP_SKZ  .equ    $E0
OP_NOPF .equ    $F0

;
; UE-1 memory addresses, aligned in the low nibble.
;
MEM_SR0 .equ    $00
MEM_SR1 .equ    $01
MEM_SR2 .equ    $02
MEM_SR3 .equ    $03
MEM_SR4 .equ    $04
MEM_SR5 .equ    $05
MEM_SR6 .equ    $06
MEM_SR7 .equ    $07
MEM_OR0 .equ    $08
MEM_OR1 .equ    $09
MEM_OR2 .equ    $0A
MEM_OR3 .equ    $0B
MEM_OR4 .equ    $0C
MEM_OR5 .equ    $0D
MEM_OR6 .equ    $0E
MEM_OR7 .equ    $0F
MEM_RR  .equ    $08
MEM_IR1 .equ    $09
MEM_IR2 .equ    $0A
MEM_IR3 .equ    $0B
MEM_IR4 .equ    $0C
MEM_IR5 .equ    $0D
MEM_IR6 .equ    $0E
MEM_IR7 .equ    $0F

;
; Special instruction that means "wrap around to the start of the tape".
; This is placed at the end of the program image in RAM.
;
OP_WRAP .equ    $FF

;
; Zero page locations.
;
TEMP    .equ    $10         ; Temporary 16-bit register.
SERRD   .equ    $12         ; Serial RX buffer read pointer.
SERWR   .equ    $13         ; Serial RX buffer write pointer.
FAST    .equ    $14         ; Non-zero for fast mode (no screen updates).
STEP    .equ    $15         ; Non-zero for single-step mode.
MARKER  .equ    $16         ; Cold start / warm start marker.
JMPPTR  .equ    $18         ; Jump table pointer for executing opcodes.
PC      .equ    $1A         ; Program counter address.
SKP     .equ    $1C         ; Skip register.
IEN     .equ    $1D         ; Input enable register.
OEN     .equ    $1E         ; Output enable register.
CAR     .equ    $1F         ; Carry register.
SR0     .equ    $20         ; Scratch register bit 0.
SR1     .equ    $21         ; Scratch register bit 1.
SR2     .equ    $22         ; Scratch register bit 2.
SR3     .equ    $23         ; Scratch register bit 3.
SR4     .equ    $24         ; Scratch register bit 4.
SR5     .equ    $25         ; Scratch register bit 5.
SR6     .equ    $26         ; Scratch register bit 6.
SR7     .equ    $27         ; Scratch register bit 7.
RR      .equ    $28         ; Result register.
IR1     .equ    $29         ; Input register bit 1.
IR2     .equ    $2A         ; Input register bit 2.
IR3     .equ    $2B         ; Input register bit 3.
IR4     .equ    $2C         ; Input register bit 4.
IR5     .equ    $2D         ; Input register bit 5.
IR6     .equ    $2E         ; Input register bit 6.
IR7     .equ    $2F         ; Input register bit 7.
OR0     .equ    $30         ; Output register bit 0.
OR1     .equ    $31         ; Output register bit 1.
OR2     .equ    $32         ; Output register bit 2.
OR3     .equ    $33         ; Output register bit 3.
OR4     .equ    $34         ; Output register bit 4.
OR5     .equ    $35         ; Output register bit 5.
OR6     .equ    $36         ; Output register bit 6.
OR7     .equ    $37         ; Output register bit 7.
FLAG0   .equ    $38         ; Value of the FLAG0 flag.
FLAGF   .equ    $39         ; Value of the FLAGF flag.
WRT     .equ    $3A         ; Value of the WRT flag.
IOC     .equ    $3B         ; Value of the IOC flag.
RTN     .equ    $3C         ; Value of the RTN flag.
PFLAGF  .equ    $3D         ; Value of the FLAGF flag in the previous loop.
TOKEN   .equ    $40         ; Buffer to hold the next assembler token.

;
; I/O ports on the 6551 Asynchronous Communications Interface Adapter
; https://www.westerndesigncenter.com/wdc/documentation/w65c51n.pdf
;
ACIA_DATA           .equ    $5000
ACIA_STATUS         .equ    $5001
ACIA_CMD            .equ    $5002
ACIA_CTRL           .equ    $5003
;
; Bits of interest in the ACIA registers.
;
ACIA_IRQ            .equ    %10000000   ; ACIA_STATUS register.
ACIA_DSR            .equ    %01000000
ACIA_DCDB           .equ    %00100000
ACIA_TDRE           .equ    %00010000
ACIA_RDRF           .equ    %00001000
ACIA_OVRN           .equ    %00000100
ACIA_FE             .equ    %00000010
ACIA_PE             .equ    %00000001
ACIA_ERR            .equ    %00000111   ; Error bits.
ACIA_SBN            .equ    %10000000   ; ACIA_CTRL register.
ACIA_WL1            .equ    %01000000
ACIA_WL0            .equ    %00100000
ACIA_RCS            .equ    %00010000
ACIA_BPS_115200     .equ    %00000000
ACIA_BPS_300        .equ    %00000110
ACIA_BPS_1200       .equ    %00001000
ACIA_BPS_2400       .equ    %00001010
ACIA_BPS_9600       .equ    %00001110
ACIA_BPS_19200      .equ    %00001111
ACIA_PMC1           .equ    %10000000   ; ACIA_CMD register.
ACIA_PMC0           .equ    %01000000
ACIA_PME            .equ    %00100000
ACIA_REM            .equ    %00010000
ACIA_TIC1           .equ    %00001000
ACIA_TIC0           .equ    %00000100
ACIA_IRD            .equ    %00000010
ACIA_DTR            .equ    %00000001

;
; Other definitions.
;
KEYBUF  .equ    $0200       ; Keyboard input buffer.
SERBUF  .equ    $0300       ; Serial RX buffer.
PROGRAM .equ    $0400       ; Start of tape program storage in RAM.
PROGEND .equ    $3FFF       ; End of tape program storage in RAM.

;
; Reset vector for the ROM.
;
reset:
        sei                 ; Disable interrupts.
        cld                 ; Make sure that D is off.
        ldx     #$FF        ; Set up the initial stack pointer.
        txs
;
; Wait for the voltage rails on the daughter chips to settle at reset time.
;
        lda     #0
        tay
reset_delay:
        adc     #1
        bne     reset_delay
        dey
        bne     reset_delay
;
; Is this a cold or a warm start?  On a cold start we need to
; initialise the machine and set the program to empty.
;
        lda     MARKER
        eor     MARKER+1
        cmp     #$FF
        beq     warm_start
        lda     #$EA
        sta     MARKER
        eor     #$FF
        sta     MARKER+1
;
; Initialise the UE-1 interpreter on a cold start.
;
cold_start:
        lda     #>HANDLERS
        sta     JMPPTR+1
;
; Copy the default program into RAM.
;
        ldx     #(default_program_end-default_program)
copy_default_program:
        lda     default_program-1,x
        sta     PROGRAM-1,x
        dex
        bne     copy_default_program
;
; Safe all UE-1 registers by making sure that they are 0 or 1.  We don't
; care if they are random on a cold start, but we do need them to be 0 or 1.
;
        ldx     #RTN-SKP
safe_registers:
        lda     SKP,x
        and     #1
        sta     SKP,x
        dex
        bpl     safe_registers
;
; Input registers are safed to 0, indicating nothing is selected.
;
        lda     #0
        ldx     #IR7-IR1-1
clear_input_registers:
        sta     IR1,x
        dex
        bpl     clear_input_registers
;
; Warm start - reset the program counter and CPU flags but leave
; everything else as it was before the reset button was pressed.
;
warm_start:
        lda     #<PROGRAM
        sta     PC
        lda     #>PROGRAM
        sta     PC+1
        jsr     clear_flags     ; Clear the CPU flags FLAG0, FLAGF, WRT, IOC.
        sty     SKP             ; Clear the SKP and RTN registers.
        sty     RTN
        sty     FAST            ; Disable fast mode.
        sty     STEP            ; Disable single-step mode.
        lda     #1              ; Start in the halt state.
        sta     FLAGF
;
; Initialise the ACIA.
;
        lda     ACIA_STATUS     ; Clear spurious status bits.
        lda     ACIA_DATA       ; Empty the receive buffer.
        ldy     #0
        sty     ACIA_STATUS     ; Force the ACIA to reset itself.
        lda     #(ACIA_BPS_19200 | ACIA_RCS)
        sta     ACIA_CTRL
        lda     #(ACIA_TIC1 | ACIA_DTR)
        sta     ACIA_CMD
        sty     SERRD           ; Clear the read/write buffer pointers.
        sty     SERWR
        cli                     ; Re-enable interrupts.

;
; Print the main screen.
;
main_screen:
        lda     FLAGF           ; Force the run/halt state to be printed.
        eor     #1
        sta     PFLAGF
;
        ldy     #<screen_layout
        lda     #>screen_layout
        jsr     print_string
;
        jsr     print_machine_state
;
        jmp     instruction_loop

;
; Handle a command character.
;
handle_char:
        jmp     handle_command

;
; Main instruction loop for the UE-1 interpreter.
;
instruction_store:
        lda     #1              ; Set the WRT flag when a STO or STOC
        sta     WRT             ; instruction is executed.
instruction_loop:
;
; If the current instruction is "OP_WRAP", then skip it as we have
; reached the end of the tape.  Rewind automatically to the start.
;
        ldy     #0
        lda     (PC),y
        cmp     #OP_WRAP
        bne     print_state
        lda     #<PROGRAM
        sta     PC
        lda     #>PROGRAM
        sta     PC+1
;
; Print the current machine state.  Skip this for fast mode unless halted.
;
print_state:
        lda     FAST
        beq     update_state
        lda     FLAGF
        beq     wait_for_keyboard
update_state:
        jsr     print_machine_state
;
; Process keyboard input.  If the processor is halted, then wait for a
; key before proceeding.
;
wait_for_keyboard:
        jsr     read_char
        bcs     handle_char
        lda     FLAGF           ; FLAGF = 1 when the processor is halted.
        bne     wait_for_keyboard
        lda     STEP            ; STEP = 1 when in single-step mode.
        bne     wait_for_keyboard
;
; Execute the next instruction.
;
continue_execution:
        jsr     clear_flags     ; Clear the CPU flags FLAG0, FLAGF, WRT, IOC.
        lda     SKP             ; Is the skip flag set?
        beq     fetch           ; If no, then fetch the instruction.
        tya                     ; If yes, load an opcode of "NOP0".
        sta     SKP             ; Clear the skip and return flags.
        sta     RTN
        beq     increment_pc
fetch:
        lda     (PC),y          ; Fetch the next instruction.
increment_pc:
        inc     PC              ; Increment the program counter.
        bne     pc_incremented
        inc     PC+1
pc_incremented:
        pha
        and     #$0F            ; Extract the memory adress into X.
        tax
        pla
        and     #$F0            ; Extract the opcode bits into A
        sta     JMPPTR          ; and construct a jump address.
        lda     SR0,x           ; Load the input memory operand into A.
        jmp     (JMPPTR)        ; Jump to the instruction handler.

;
; Execute a UE-1 instruction.  The code is carefully arranged on
; addresses that are multiples of 16 so that we can jump directly
; to the right instruction handler after loading opcode bits 4..7.
;
; Each instruction handler can assume that A contains the input bit
; from the designated memory address, that X is the memory address,
; and that Y is set to zero.
;
HANDLERS .equ   $8100
        .org    HANDLERS
I_NOP0:
        lda     #1
        sta     FLAG0
        jmp     instruction_loop
;
        .org    HANDLERS+OP_LD
I_LD:
        ldx     IEN
        beq     no_input
        sta     RR
        jmp     instruction_loop
;
        .org    HANDLERS+OP_ADD
I_ADD:
        ldx     IEN
        beq     no_input
        clc
        adc     RR
        adc     CAR
        jmp     finish_add_or_sub
;
        .org    HANDLERS+OP_SUB
I_SUB:
        ldx     IEN
        beq     no_input
        eor     #1              ; Invert the incoming value.
        clc
        adc     RR
        adc     CAR
        jmp     finish_add_or_sub
;
        .org    HANDLERS+OP_ONE
I_ONE:
        ldx     #1
        stx     RR
        dex
        stx     CAR
no_input:
        jmp     instruction_loop
;
        .org    HANDLERS+OP_NAND
I_NAND:
        ldx     IEN
        beq     no_input
        and     RR
        eor     #1
        sta     RR
        jmp     instruction_loop
;
        .org    HANDLERS+OP_OR
I_OR:
        ldx     IEN
        beq     no_input
        ora     RR
        sta     RR
        jmp     instruction_loop
;
        .org    HANDLERS+OP_XOR
I_XOR:
        ldx     IEN
        beq     no_input
        eor     RR
        sta     RR
        jmp     instruction_loop
;
        .org    HANDLERS+OP_STO
I_STO:
        ldy     OEN
        beq     no_output
        lda     RR
check_store_address:
        cpx     #8
        bcs     store_to_output_register
store_to_ram:
        sta     SR0,x
no_output:
        jmp     instruction_store
;
        .org    HANDLERS+OP_STOC
I_STOC:
        ldy     OEN
        beq     no_output
        lda     RR
        eor     #1
        bpl     check_store_address ; Unconditional jump.
store_to_output_register:
        sta     OR0-8,x
        jmp     instruction_store
;
        .org    HANDLERS+OP_IEN
I_IEN:
        sta     IEN
        jmp     instruction_loop
;
        .org    HANDLERS+OP_OEN
I_OEN:
        sta     OEN
        jmp     instruction_loop
;
        .org    HANDLERS+OP_IOC
I_IOC:
        lda     #1
        sta     IOC
        lda     #8
        jsr     print_char
        jmp     instruction_loop
;
        .org    HANDLERS+OP_RTN
I_RTN:
        lda     #1
        sta     SKP
        sta     RTN
        jmp     instruction_loop
;
        .org    HANDLERS+OP_SKZ
I_SKZ:
        lda     RR
        eor     #1
        sta     SKP
        jmp     instruction_loop
;
; "NOPF" is used as the "halt" instruction in the UE-1.  But we also
; need a marker to indicate "end of program, loop around".
;
; Use $FF or "NOPF IR7" to indicate the end of the program and all
; others $F0 to $FE to indicate "halt".  When the program is loaded,
; we transparently modify $FF into $F0 to avoid problems.
;
        .org    HANDLERS+OP_NOPF
I_NOPF:
        cpx     #$0F
        bne     halt_program
        lda     #<PROGRAM
        sta     PC
        lda     #>PROGRAM
        sta     PC+1
        jmp     instruction_loop

;
; Rewind the tape to the start of the program.
;
rewind_tape:
        lda     #<PROGRAM
        sta     PC
        lda     #>PROGRAM
        sta     PC+1
        jmp     instruction_loop
;
; Toggle fast mode.  In fast mode we don't print instructions or the
; machine state.  Run instructions as fast as humanly/machinely possible.
;
toggle_fast_mode:
        lda     FAST
        eor     #1
        sta     FAST
        beq     end_fast_mode
        jsr     erase_machine_state
        jmp     instruction_loop
end_fast_mode:
        jsr     print_machine_state
        jmp     instruction_loop

;
; Handle a character that was typed while the processor was running or halted.
;
handle_command:
        jsr     to_upper        ; Convert the character to upper case.
        cmp     #'R'            ; Rewind?
        beq     rewind_tape
        cmp     #'F'            ; Toggle Fast Mode?
        beq     toggle_fast_mode
        cmp     #'H'            ; Halt?
        beq     halt_program
        cmp     #'G'            ; Go?
        beq     resume_program
        cmp     #'S'            ; Single Step?
        beq     single_step
        cmp     #'L'            ; Load program?
        beq     load_program
        cmp     #'1'            ; Toggle Input 1-7?
        bcc     not_a_command
        cmp     #'8'
        bcs     not_a_command
        sec
        sbc     #'1'
        tax
        lda     IR1,x
        eor     #1
        sta     IR1,x
not_a_command:
        jmp     instruction_loop

;
; Halt the program.
;
halt_program:
        lda     FLAGF
        bne     already_halted
        lda     #1
        sta     FLAGF
        ldy     #<halted_state
        lda     #>halted_state
        jsr     print_string
        ldy     #<goto_resting
        lda     #>goto_resting
        jsr     print_string
already_halted:
        jmp     instruction_loop

;
; Resume the program.
;
resume_program:
        ldy     #0
        sty     STEP                ; Disable single-step mode.
        lda     FLAGF
        beq     already_resumed
        sty     FLAGF               ; Turn off FLAGF/HLT.
        ldy     #<running_state
        lda     #>running_state
        jsr     print_string
        ldy     #<goto_resting
        lda     #>goto_resting
        jsr     print_string
already_resumed:
        jmp     instruction_loop

;
; Perform a single step.
;
single_step:
        lda     #1
        sta     STEP
        lda     #0
        sta     FLAGF               ; Turn off FLAGF/HLT.
        ldy     #<running_state
        lda     #>running_state
        jsr     print_string
        ldy     #<goto_resting
        lda     #>goto_resting
        jsr     print_string
        jmp     continue_execution
;
; Load a new program into memory.
;
load_program:
;
; Print the program loading instructions.
;
        ldy     #<load_instructions
        lda     #>load_instructions
        jsr     print_string
;
        lda     #<PROGRAM
        sta     PC
        lda     #>PROGRAM
        sta     PC+1
        ldy     #0
;
; Prompt for lines of text and assemble them into memory.
;
load_next_line:
        jsr     read_line       ; Read a line of text into KEYBUF.
;
; Skip whitespace at the start of the line.
;
        ldy     #0
skip_whitespace:
        lda     KEYBUF,y
        iny
        cmp     #$20
        beq     skip_whitespace
        dey
;
; Skip the line if it is empty or a comment.
;
        lda     KEYBUF,y
        beq     load_next_line
        cmp     #';'
        beq     load_next_line
;
; Check for "." on a line of its own to terminate the loading process.
;
        cmp     #'.'
        bne     assemble_line
        lda     KEYBUF+1,y
        beq     load_done
;
; Assemble the line into UE1 machine code.
;
assemble_line:
        ldx     #0
        lda     #16
        jsr     lexer
        bcs     load_next_line
        asl     a
        asl     a
        asl     a
        asl     a
        sta     TOKEN+8
        ldx     #64
        lda     #32
        jsr     lexer
        bcs     load_next_line
        ora     TOKEN+8
;
; We now have an instruction.  Store it to the program and increment PC.
;
        ldy     #0
        sta     (PC),y
        inc     PC
        bne     assemble_next
        inc     PC+1
assemble_next:
        lda     PC              ; Has the program overflowed?
        cmp     #<PROGEND
        bne     assemble_next_2
        lda     PC+1
        cmp     #>PROGEND
        bne     assemble_next_2
;
        ldy     #<program_too_big_msg
        lda     #>program_too_big_msg
        jsr     print_string
        lda     #OP_NOPF        ; Set the program to empty.
        sta     PROGRAM
        lda     #OP_WRAP
        sta     PROGRAM+1
;
assemble_next_2:
        jmp     load_next_line
;
; Make sure that the program is terminated by a "WRAP" instruction to
; cause the tape to wrap around to the start when we run off the end.
;
; If the program is empty, then also insert a "NOPF SR0" / "HLT" instruction.
;
load_done:
        ldy     #0
        lda     PC
        cmp     #<PROGRAM
        bne     not_empty
        lda     PC+1
        cmp     #>PROGRAM
        bne     not_empty
        lda     #OP_NOPF
        sta     (PC),y
        iny
not_empty:
        lda     #OP_WRAP
        sta     (PC),y
;
; Halt the machine, reset the PC, and then redraw the main screen.
;
        lda     #1
        sta     FLAGF
        lda     #0
        sta     STEP
        lda     #<PROGRAM
        sta     PC
        lda     #>PROGRAM
        sta     PC+1
        jmp     main_screen
;
; Lexical analysis.  Look up the current symbol on the input line.
;
lexer:
        sta     TEMP
        stx     TEMP+1
;
; Copy the next word into TOKEN.
;
        ldx     #0
copy_word:
        lda     KEYBUF,y
        beq     end_word
        cmp     #$20
        beq     end_word
        sta     TOKEN,x
        iny
        inx
        cpx     #5
        bcc     copy_word
;
syntax_error:
        ldy     #<syntax_error_msg
        lda     #>syntax_error_msg
        jsr     print_string
        sec
        rts
;
end_word:
        lda     #$20            ; Pad the word with spaces.
        sta     TOKEN,x
        inx
        cpx     #5
        bcc     end_word
;
skip_whitespace_in_lexer:
        lda     KEYBUF,y        ; Skip whitespace after the word.
        iny
        cmp     #$20
        beq     skip_whitespace_in_lexer
        dey
;
        ldx     TEMP+1
find_word:
        lda     insn_names,x    ; Check the token against the next word
        cmp     TOKEN           ; in the opcode/operand name table.
        bne     find_next_word
        lda     insn_names+1,x
        cmp     TOKEN+1
        bne     find_next_word
        lda     insn_names+2,x
        cmp     TOKEN+2
        bne     find_next_word
        lda     insn_names+3,x
        cmp     TOKEN+3
        bne     find_next_word
        txa                     ; Convert the table index into an opcode or
        lsr     a               ; operand code between 0 and 15.
        lsr     a
        and     #$0F
        clc
        rts
find_next_word:                 ; Advance to the next word in the table.
        inx
        inx
        inx
        inx
        dec     TEMP            ; Have we run out of words yet?
        bne     find_word
        beq     syntax_error
;
syntax_error_msg:
        .db     "SYNTAX ERROR",$0D,$0A,0
program_too_big_msg:
        .db     "PROGRAM IS TOO LARGE",$0D,$0A,0

;
; Finish off an "ADD" or "SUB" instruction by splitting the 2-bit
; result into RR and CAR.
;
finish_add_or_sub:
        pha
        and     #1
        sta     RR
        pla
        lsr     a
        and     #1
        sta     CAR
        jmp     instruction_loop

;
; Clear the CPU flags.  Side-effect is to set Y to zero.
;
clear_flags:
        ldy     #0
        sty     FLAG0
        sty     FLAGF
        sty     WRT
        sty     IOC
        rts

;
; Convert the character in A to upper case.
;
to_upper:
        cmp     #$61
        bcc     to_upper_done
        cmp     #$7B
        bcs     to_upper_done
        and     #$5F
to_upper_done:
        rts

;
; Print the machine state to the serial port.
;
; Timing is important here.  At 19200 bps, at most 1920 characters can be
; printed per second.  This fixes the clock rate of the UE-1 emulator.
;
; If we print 100 characters each time an instruction is executed, the
; absolute best we can achieve is 1920 / 100 = 19.2Hz.
;
; The code below can print the state in 55 characters, or a theoretical
; maximum of 34.9Hz.  With other overheads, it is probably 33Hz-ish.
;
; At 115200 bps, it would theoretically be possible to achieve over 200Hz.
;
print_machine_state:
        ldy     #<goto_machine_state
        lda     #>goto_machine_state
        jsr     print_string
;
        lda     CAR
        jsr     print_bit
        lda     RR
        jsr     print_bit
;
        lda     #$20
        jsr     print_char
;
        lda     IEN
        jsr     print_bit
        lda     OEN
        jsr     print_bit
        lda     IOC
        jsr     print_bit
        lda     WRT
        jsr     print_bit
        lda     SKP
        jsr     print_bit
        lda     RTN
        jsr     print_bit
        lda     FLAG0
        jsr     print_bit
        lda     FLAGF
        jsr     print_bit
;
        lda     #$20
        jsr     print_char
;
        lda     SR7
        jsr     print_bit
        lda     SR6
        jsr     print_bit
        lda     SR5
        jsr     print_bit
        lda     SR4
        jsr     print_bit
        lda     SR3
        jsr     print_bit
        lda     SR2
        jsr     print_bit
        lda     SR1
        jsr     print_bit
        lda     SR0
        jsr     print_bit
;
        lda     #$20
        jsr     print_char
;
        lda     OR7
        jsr     print_bit
        lda     OR6
        jsr     print_bit
        lda     OR5
        jsr     print_bit
        lda     OR4
        jsr     print_bit
        lda     OR3
        jsr     print_bit
        lda     OR2
        jsr     print_bit
        lda     OR1
        jsr     print_bit
        lda     OR0
        jsr     print_bit
;
        lda     #$20
        jsr     print_char
;
        lda     IR7
        jsr     print_bit
        lda     IR6
        jsr     print_bit
        lda     IR5
        jsr     print_bit
        lda     IR4
        jsr     print_bit
        lda     IR3
        jsr     print_bit
        lda     IR2
        jsr     print_bit
        lda     IR1
        jsr     print_bit
        lda     #$20
        jsr     print_char
;
; Disassemble and print the next instruction.
;
        ldy     #0
        lda     (PC),y
        pha
        lsr     a
        lsr     a
        and     #$3C
        tay
        lda     insn_names,y
        jsr     print_char
        lda     insn_names+1,y
        jsr     print_char
        lda     insn_names+2,y
        jsr     print_char
        lda     insn_names+3,y
        jsr     print_char
        lda     #$20
        jsr     print_char
        pla
        pha
        and     #$F0
        cmp     #OP_STO
        beq     print_store_instruction
        cmp     #OP_STOC
        beq     print_store_instruction
        pla
        asl     a
        asl     a
        and     #$3C
        tay
        lda     input_names,y
        jsr     print_char
        lda     input_names+1,y
        jsr     print_char
        lda     input_names+2,y
        jsr     print_char
;
        ldy     #<goto_resting
        lda     #>goto_resting
        jsr     print_string
;
        jmp     print_running_or_halted
;
print_store_instruction:
        pla
        asl     a
        asl     a
        and     #$3C
        tay
        lda     output_names,y
        jsr     print_char
        lda     output_names+1,y
        jsr     print_char
        lda     output_names+2,y
        jsr     print_char
;
        ldy     #<goto_resting
        lda     #>goto_resting
        jsr     print_string
;
        jmp     print_running_or_halted
;
; Erase the machine state by drawing X's over it.  Used in fast mode.
;
erase_machine_state:
        ldy     #<erase_state
        lda     #>erase_state
        jsr     print_string
        ; Fall through to the next subroutine.
;
; Print the Running/Halted state if it has changed.
;
print_running_or_halted:
        lda     FLAGF
        cmp     PFLAGF
        beq     no_run_halt_change
        sta     PFLAGF
        ora     #0
        bne     print_halted
        ldy     #<running_state
        lda     #>running_state
        jmp     print_string
print_halted:
        ldy     #<halted_state
        lda     #>halted_state
        jmp     print_string
no_run_halt_change:
        rts

;
; Main screen layout for the emulator.
;
screen_layout:
        .db     $1B,"[H",$1B,"[0m",$1B,"[J"     ; Clear the screen.
        .db     $0D,$0A
        .db     $1B,"[33;1mUE1 Emulator for 6502",$0D,$0A
        .db     $0D,$0A
        .db     $1B,"[0m",$1B,"[33mCR IOBWSRFH 7  SR  0 7  OR  0 7 IR  1   Insn",$0D,$0A
        .db     $1B,"[32m-- -------- -------- -------- ------- --------",$0D,$0A
        .db     $0D,$0A
        .db     $1B,"[33mLegend:",$0D,$0A
        .db     $1B,"[0mC = CAR, R = RR, I = IEN, O = OEN, B = IOC/BEL, W = WRT, S = SKP",$0D,$0A
        .db     "R = RTN, F = FLAG0, H = FLAGF/HLT, SR = Scratch Register",$0D,$0A
        .db     "OR = Output Register, IR = Input Register",$0D,$0A
        .db     $0D,$0A
        .db     $1B,"[33mCommands:",$0D,$0A
        .db     $1B,"[0mH = Halt, G = Go, S = Single Step, 1-7 = Toggle Input",$0D,$0A
        .db     "L = Load Program, R = Rewind Tape, F = Toggle Fast Execution",$0D,$0A
        .db     $1B,"[32m"
        .db     0
;
; Strings for moving about the screen and printing things.
;
goto_machine_state:
        .db     $1B,"[5;1H",0       ; Update the machine state.
goto_resting:
        .db     $1B,"[H",0          ; Move the cursor to its resting position.
running_state:
        .db     $1B,"[5;48H",$1B,"[33;1mRunning",$1B,"[0m",$1B,"[32m",0
halted_state:
        .db     $1B,"[5;48H",$1B,"[31;1mHalted ",$1B,"[0m",$1B,"[32m",0
erase_state:
        .db     $1B,"[5;1H-- -------- -------- -------- ------- --------",0
;
; Instructions for loading a program into memory.
;
load_instructions:
        .db     $1B,"[H",$1B,"[0m",$1B,"[J"     ; Clear the screen.
        .db     $0D,$0A
        .db     "Enter the assembly code for the program one line at a time.",$0D,$0A
        .db     "Enter '.' on a line of its own to end the loading process.",$0D,$0A
        .db     $0D,$0A,0

;
; Instruction and operand names for the assembler and disassembler.
;
insn_names:
        .db     "NOP0"
        .db     "LD  "
        .db     "ADD "
        .db     "SUB "
        .db     "ONE "
        .db     "NAND"
        .db     "OR  "
        .db     "XOR "
        .db     "STO "
        .db     "STOC"
        .db     "IEN "
        .db     "OEN "
        .db     "IOC "
        .db     "RTN "
        .db     "SKZ "
        .db     "NOPF"
input_names:
        .db     "SR0 "
        .db     "SR1 "
        .db     "SR2 "
        .db     "SR3 "
        .db     "SR4 "
        .db     "SR5 "
        .db     "SR6 "
        .db     "SR7 "
        .db     "RR  "
        .db     "IR1 "
        .db     "IR2 "
        .db     "IR3 "
        .db     "IR4 "
        .db     "IR5 "
        .db     "IR6 "
        .db     "IR7 "
output_names:
        .db     "SR0 "
        .db     "SR1 "
        .db     "SR2 "
        .db     "SR3 "
        .db     "SR4 "
        .db     "SR5 "
        .db     "SR6 "
        .db     "SR7 "
        .db     "OR0 "
        .db     "OR1 "
        .db     "OR2 "
        .db     "OR3 "
        .db     "OR4 "
        .db     "OR5 "
        .db     "OR6 "
        .db     "OR7 "

;
; Default program to load on a cold start - UE1FIBO.
;
default_program:
        .db $40, $a8, $b8, $58, $80, $81, $82, $83
        .db $84, $85, $86, $87, $88, $89, $8a, $8b
        .db $8c, $8d, $8e, $8f, $90, $98, $40, $58
        .db $10, $24, $80, $11, $25, $81, $12, $26
        .db $82, $13, $27, $83, $10, $88, $11, $89
        .db $12, $8a, $13, $8b, $40, $58, $10, $24
        .db $84, $11, $25, $85, $12, $26, $86, $13
        .db $27, $87, $14, $88, $15, $89, $16, $8a
        .db $17, $8b, $40, $58, $10, $24, $80, $11
        .db $25, $81, $12, $26, $82, $13, $27, $83
        .db $10, $88, $11, $89, $12, $8a, $13, $8b
        .db $40, $58, $10, $24, $84, $11, $25, $85
        .db $12, $26, $86, $13, $27, $87, $14, $88
        .db $15, $89, $16, $8a, $17, $8b, $40, $58
        .db $10, $24, $80, $11, $25, $81, $12, $26
        .db $82, $13, $27, $83, $10, $88, $11, $89
        .db $12, $8a, $13, $8b, $40, $58, $10, $24
        .db $84, $11, $25, $85, $12, $26, $86, $13
        .db $27, $87, $14, $88, $15, $89, $16, $8a
        .db $17, $8b, $40, $58, $10, $24, $80, $11
        .db $25, $81, $12, $26, $82, $13, $27, $83
        .db $10, $88, $11, $89, $12, $8a, $13, $8b
        .db $40, $58, $10, $24, $84, $11, $25, $85
        .db $12, $26, $86, $13, $27, $87, $28, $8c
        .db $14, $88, $15, $89, $16, $8a, $17, $8b
        .db $c0, $f0
        .db OP_WRAP
default_program_end:

;
; Read a line of text into KEYBUF, allowing some basic backspacing and editing.
;
read_line:
        lda     #'>'            ; Print the prompt for the line.
        jsr     print_char
        ldy     #0
next_char:
        jsr     wait_char
        cmp     #$0D            ; CR or LF ends the line.
        beq     end_read_line
        cmp     #$0A
        beq     end_read_line
        cmp     #$08            ; Backspace?
        beq     backspace
        cmp     #$20
        blt     next_char       ; Unknown control character.
        cmp     #$7F            ; DEL is the same as backspace.
        beq     backspace
        bcs     next_char       ; High bit set in the character - ignore.
        cpy     #255            ; Check the maximum line length.
        bcs     next_char
        jsr     print_char      ; Echo the character.
        jsr     to_upper        ; Convert to upper case before storing.
        sta     KEYBUF,y        ; Store the character to the buffer.
        iny                     ; Advance to the next buffer position.
        jmp     next_char       ; Go around again.
backspace:
        cpy     #0              ; Are we at the start of the line?
        beq     next_char
        dey                     ; Go back one character.
        lda     #$08            ; Print backspace, space, backspace.
        jsr     print_char
        lda     #$20
        jsr     print_char
        lda     #$08
        jsr     print_char
        jmp     next_char       ; Go around for the next character.
end_read_line:
        lda     #0              ; Terminate the line with a NUL.
        sta     KEYBUF,y
        lda     #$0D            ; Print a CRLF.
        jsr     print_char
        lda     #$0A
        jmp     print_char

;
; Read a character from the serial port.  Sets carry if a character
; was received or clears carry if no character is available at present.
; Returns the character in A.  Destroys X.  Preserves Y.
;
read_char:
        ldx     SERRD           ; Are the read and write pointers different?
        cpx     SERWR
        beq     read_char_none
serial_read:
        lda     SERBUF,x        ; Get the next character from the buffer.
        pha
        inc     SERRD           ; Advance the read pointer.
        lda     SERWR           ; Should we turn receive interrupts back on?
        sec
        sbc     SERRD 
        cmp     #224
        bcs     read_char_done
        lda     #(ACIA_TIC1 | ACIA_DTR)
        sta     ACIA_CMD
read_char_done:
        pla
        sec
        rts
read_char_none:
        lda     #0
        clc
        rts

;
; Wait for a character from the serial port.
;
wait_char:
        jsr     read_char
        bcc     wait_char
        rts

;
; Print a $00 or $80 flag in A.  Destroys A and X.  Preserves Y.
;
print_flag:
        asl     a
        rol     a
        ; Fall through to the next subroutine.

;
; Print a single 0 or 1 bit in A.  Destroys A and X.  Preserves Y.
;
print_bit:
        ora     #$30
        ; Fall through to the next subroutine.

;
; Print a character to the serial port.  Destroys X.  Preserves A and Y.
;
print_char:
        sta     ACIA_DATA
        ldx     #$68
print_char_delay:
        dex
        bne     print_char_delay
        rts

;
; Print a NUL-terminated string to the serial port.  A:Y points to the
; string on entry.  Destroys A and Y.
;
print_string:
        sty     TEMP
        sta     TEMP+1
        ldy     #0
print_string_loop:
        lda     (TEMP),y
        beq     print_string_done
        jsr     print_char
        iny
        bne     print_string_loop
        inc     TEMP+1
        jmp     print_string_loop
print_string_done:
        rts

;
; NMI handler.  Not used.
;
nmi_handler:
        rti

;
; IRQ handler.
;
irq_handler:
        pha                     ; Save A and X on the stack.
        txa
        pha
;
        lda     ACIA_STATUS     ; Did the serial interrupt fire off?
        bpl     end_irq
        and     #ACIA_RDRF      ; Did we receive a byte?
        beq     end_irq
        lda     ACIA_DATA       ; Get the received byte into A.
        ldx     SERWR           ; Get the serial buffer write pointer.
        sta     SERBUF,x        ; Store A into the serial buffer.
        inc     SERWR           ; Increment the write pointer.
        lda     SERWR           ; Is the buffer almost full?
        sec
        sbc     SERRD
        cmp     #240
        bcc     end_irq         ; If not, then leave interrupts on for now.
        lda     #ACIA_DTR       ; Disable serial receive interrupts.
        sta     ACIA_CMD
;
end_irq:
        pla                     ; Restore A and X and return.
        tax
        pla
        rti

;
; Interrupt and reset vectors at the end of ROM.
;
        .org    $FFFA
        .dw     nmi_handler
        .dw     reset
        .dw     irq_handler
