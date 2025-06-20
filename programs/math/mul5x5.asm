;
; Multiply a 5-bit number by a 5-bit number to give a 10-bit result.
;
; Usage:
;   1. Program initialises and then halts waiting for the first 4-bit
;      number to be entered on IR5..IR1.
;   2. Resume and then the program halts again waiting for the second
;      5-bit number to be entered on IR5..IR1.
;   3. Resume and the answer will eventually be written to SR1,SR0,OR7..OR0.
;
; Algorithm:
;
;   First value, A = A4, A3, A2, A1, A0
;   Second value, B = B4, B3, B2, B1, B0
;   Result = 0
;   if A0 != 0:
;       Result = B
;   if A1 != 0
;       Result += B * 2
;   if A2 != 0
;       Result += B * 4
;   if A3 != 0
;       Result += B * 8
;   if A4 != 0
;       Result += B * 16
;
; This program technically needs 10 bits to hold the input values and
; another 10 bits to hold the intermediate calculations.  There are some
; tricks that can we can use:
;
;   1. Leave B in the input register so it doesn't take up any RAM.
;   2. Each time we use a bit of A we can reclaim it for other uses.
;   3. The low bits of the result are shifted to the output register as we go.
;

;
; Initialize the machine.
;
ONE  SR0
IEN  RR
OEN  RR
;
; Set the output register with the low 8 bits of the result to all zeroes.
;
STOC OR0
STOC OR1
STOC OR2
STOC OR3
STOC OR4
STOC OR5
STOC OR6
STOC OR7
;
; Prompt for A on the input switches.
;
IOC  SR0
NOPF SR0
NOP0 SR0        ; NOP0's to wait for the motor to spin down.
NOP0 SR0
NOP0 SR0
NOP0 SR0
NOP0 SR0 
NOP0 SR0 
NOP0 SR0 
NOP0 SR0 
NOP0 SR0 
NOP0 SR0 
NOP0 SR0 
NOP0 SR0 
NOP0 SR0 
NOP0 SR0 
NOP0 SR0 
NOP0 SR0 
;
; Read A from IR5, IR4, IR3, IR2, IR1 (MSB to LSB) and put it into
; SR7, SR6, SR5, SR4, SR3 (MSB to LSB).
;
LD   IR5
STO  SR7
LD   IR4
STO  SR6
LD   IR3
STO  SR5
LD   IR2
STO  SR4
LD   IR1
STO  SR3
;
; Prompt for B on the input switches.
;
IOC  SR0
NOPF SR0
NOP0 SR0        ; NOP0's to wait for the motor to spin down.
NOP0 SR0
NOP0 SR0
NOP0 SR0
NOP0 SR0 
NOP0 SR0 
NOP0 SR0 
NOP0 SR0 
NOP0 SR0 
NOP0 SR0 
NOP0 SR0 
NOP0 SR0 
NOP0 SR0 
NOP0 SR0 
NOP0 SR0 
NOP0 SR0 
;
; B is currently in IR5, IR4, IR3, IR2, IR1 (MSB to LSB).  We leave it on the
; input switches, effectively using them as 5 bits of extra RAM.
;
; Note: Changing the input switches while the remaining code runs will
; modify the result in unexpected ways.  Don't do that!
;
; If A0 is zero, set the intermediate result to 0.  If A0 is one,
; then set the intermediate result to B.  The intermediate result will
; end up in SR3, SR2, SR1, SR0, OR0.
;
IEN  SR3        ; Test A0 (SR3) for non-zero and set IEN accordingly.
LD   IR1        ; Copy B to SR3, SR2, SR1, SR0, OR0.
STO  OR0        ; IEN will force the value to zero if SR3 was zero.
LD   IR2
STO  SR0
LD   IR3
STO  SR1
LD   IR4
STO  SR2
LD   IR5
STO  SR3
ONE  SR0        ; Turn IEN back on.
IEN  RR
;
; SR7, SR6, SR5, SR4 = A4, A3, A2, A1  (A0 can now be discarded)
; 0, SR3, SR2, SR1, SR0, OR0 is the intermediate result.  There is an
; implicit carry out of 0 from the previous step that we account for below.
;
; Deal with A1 next.
;
OEN  SR4        ; Test A1 (SR4) for non-zero and set OEN accordingly.
LD   SR0        ; Add B to SR4, SR3, SR2, SR1, SR0.
ADD  IR1
STO  SR0        ; Result will be in SR0, SR4, SR3, SR2, SR1, OR1, OR0.
LD   SR1
ADD  IR2
STO  SR1
LD   SR2
ADD  IR3
STO  SR2
LD   SR3
ADD  IR4
STO  SR3
XOR  RR         ; Turn OEN back on and move SR0 to OR1, while preserving CAR.
NAND RR
OEN  RR
LD   SR0
STO  OR1
XOR  RR         ; Shift CAR to RR, and it with SR4, and then store it to SR0.
ADD  RR
NAND SR4        ; We AND with SR4 to cancel out the carry if A1 was zero.
STOC SR0
ONE  SR0        ; Force CAR to zero.
LD   IR5        ; Compute SR4 = (IR5 AND SR4) + SR0 for the next to
NAND SR4        ; highest bit of the intermediate result.
NAND RR
ADD  SR0
STO  SR4
XOR  RR         ; Shift CAR to RR and store it to SR0 again.
ADD  RR
STO  SR0
;
; SR7, SR6, SR5 = A4, A3, A2  (A1 can now be discarded)
; SR0, SR4, SR3, SR2, SR1, OR1, OR0 is the intermediate result.
;
; Deal with A2 next.
;
OEN  SR5        ; Turn off OEN if A2 is zero, turn it on if A2 is one.
LD   SR1        ; Add B to SR0, SR4, SR3, SR2, SR1.
ADD  IR1
STO  SR1        ; Result will be SR5, SR0, SR4, SR3, SR2, OR2, OR1, OR0.
LD   SR2
ADD  IR2
STO  SR2
LD   SR3
ADD  IR3
STO  SR3
LD   SR4
ADD  IR4
STO  SR4
LD   SR0
ADD  IR5
STO  SR0
XOR  RR         ; Turn OEN back on while preserving CAR.
NAND RR
OEN  RR
NAND RR         ; Shift CAR to RR, AND it with SR5 and then store to SR5.
ADD  RR
NAND SR5
STOC SR5
LD   SR1        ; Shift SR1 out to OR2.
STO  OR2
;
; SR7, SR6 = A4, A3  (A2 can now be discarded)
; SR5, SR0, SR4, SR3, SR2, OR2, OR1, OR0 is the intermediate result.
; Unused: SR1
;
; Deal with A3 next.
;
ONE  SR0
STOC SR1        ; Clear the next carry out.
OEN  SR6        ; Turn off OEN if A3 is zero, turn it on if A3 is one.
LD   SR2        ; Add B to SR5, SR0, SR4, SR3, SR2.
ADD  IR1
STO  SR2        ; Result will be SR1, SR5, SR0, SR4, SR3, OR3, OR2, OR1, OR0.
LD   SR3
ADD  IR2
STO  SR3
LD   SR4
ADD  IR3
STO  SR4
LD   SR0
ADD  IR4
STO  SR0
LD   SR5
ADD  IR5
STO  SR5
XOR  RR         ; Account for the carry.
ADD  RR
STO  SR1
ONE  SR0        ; Set RR to one.
OEN  RR         ; Turn OEN back on again.
LD   SR2        ; Shift SR2 out to OR3.
STO  OR3
;
; SR7 = A4  (A3 can now be discarded)
; SR1, SR5, SR0, SR4, SR3, OR3, OR2, OR1, OR0 is the intermediate result.
; Unused: SR2, SR6
;
; Deal with A4 next.
;
ONE  SR0
STOC SR2        ; Clear the next carry out.
OEN  SR7        ; Turn off OEN if A4 is zero, turn it on if A4 is one.
LD   SR3        ; Add B to SR1, SR5, SR0, SR4, SR3.
ADD  IR1
STO  SR3        ; Result will be SR2, SR1, SR5, SR0, SR4, OR3, OR2, OR1, OR0.
LD   SR4
ADD  IR2
STO  SR4
LD   SR0
ADD  IR3
STO  SR0
LD   SR5
ADD  IR4
STO  SR5
LD   SR1
ADD  IR5
STO  SR1
XOR  RR         ; Account for the carry.
ADD  RR
STO  SR2
ONE  SR0        ; Set RR to one.
OEN  RR         ; Turn OEN back on again.
LD   SR3        ; Shift SR3 out to OR4.
STO  OR4
;
; SR2, SR1, SR5, SR0, SR4, OR4, OR3, OR2, OR1, OR0 is the intermediate result.
; Unused: SR3, SR6, SR7
;
; Copy SR5, SR0, SR4 to OR7, OR6, OR5.
;
LD   SR4
STO  OR5
LD   SR0
STO  OR6
LD   SR5
STO  OR7
;
; Copy SR2, SR1 to SR1, SR0 and zero the rest of SR.  The 10-bit result is
; now in SR1, SR0, OR7, OR6, OR5, OR4, OR3, OR2, OR1, OR0.
;
LD   SR1
STO  SR0
LD   SR2
STO  SR1
ONE  SR0
STOC SR2
STOC SR3
STOC SR4
STOC SR5
STOC SR6
STOC SR7
;
; Ring the bell and halt.
;
IOC  SR0
NOPF SR0
