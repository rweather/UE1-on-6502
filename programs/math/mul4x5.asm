;
; Multiply a 4-bit number by a 5-bit number to give a 9-bit result.
;
; Usage:
;   1. Program initialises and then halts waiting for the first 4-bit
;      number to be entered on IR4..IR1.
;   2. Resume and then the program halts again waiting for the second
;      5-bit number to be entered on IR5..IR1.
;   3. Resume and the answer will eventually be written to SR0,OR7..OR0.
;
; Algorithm:
;
;   First value, A = A3, A2, A1, A0
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
;
; This program technically needs 9 bits to hold the input values and
; another 9 bits to hold the intermediate calculations.  There are some
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
; Read A from IR4, IR3, IR2, IR1 (MSB to LSB) and put it into
; SR7, SR6, SR5, SR4 (MSB to LSB).
;
LD   IR4
STO  SR7
LD   IR3
STO  SR6
LD   IR2
STO  SR5
LD   IR1
STO  SR4
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
; end up in SR4, SR3, SR2, SR1, SR0, OR0.
;
IEN  SR4        ; Test A0 (SR4) for non-zero and set IEN accordingly.
LD   IR1        ; Copy B to SR3, SR2, SR1, SR0, OR0.
STO  OR0        ; IEN will force the value to zero if SR4 was zero.
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
STOC SR4        ; Carry out in SR4 is currently zero.
;
; SR7, SR6, SR5 = A3, A2, A1  (A0 can now be discarded)
; SR4, SR3, SR2, SR1, SR0, OR0 is the intermediate result.
;
; Deal with A1 next.
;
OEN  SR5        ; Turn off OEN if A1 is zero, turn it on if A1 is one.
LD   SR0        ; Add B to SR4, SR3, SR2, SR1, SR0.
ADD  IR1
STO  SR0        ; Result will be in SR5, SR4, SR3, SR2, SR1, OR1, OR0.
LD   SR1
ADD  IR2
STO  SR1
LD   SR2
ADD  IR3
STO  SR2
LD   SR3
ADD  IR4
STO  SR3
LD   SR4
ADD  IR5
STO  SR4
;
; We are very short on scratch registers, so it is a delicate dance to
; turn the carry out into a new value in SR5 while making sure that the
; carry out is forced to zero if SR5/A1 was originally zero.
;
XOR  RR         ; Set RR to zero, preserving CAR.
NAND RR         ; Invert RR to get one.
OEN  RR         ; Turn OEN back on again.
XOR  RR         ; Move CAR to RR.
ADD  RR
NAND SR5        ; CAR needs to be forced to zero if SR5 was zero.
STOC SR5        ; NAND SR5, STOC SR5 sets SR5 = CAR AND SR5.
LD   SR0        ; Shift SR0 out to OR1.
STO  OR1
;
; SR7, SR6 = A3, A2  (A1 can now be discarded)
; SR5, SR4, SR3, SR2, SR1, OR1, OR0 is the intermediate result.
; Unused: SR0
;
; Deal with A2 next.
;
ONE  SR0
STOC SR0        ; Clear the next carry out.
OEN  SR6        ; Turn off OEN if A2 is zero, turn it on if A2 is one.
LD   SR1        ; Add B to SR5, SR4, SR3, SR2, SR1.
ADD  IR1
STO  SR1        ; Result will be SR0, SR5, SR4, SR3, SR2, OR2, OR1, OR0.
LD   SR2
ADD  IR2
STO  SR2
LD   SR3
ADD  IR3
STO  SR3
LD   SR4
ADD  IR4
STO  SR4
LD   SR5
ADD  IR5
STO  SR5
XOR  RR         ; Account for the carry.
ADD  RR
STO  SR0
ONE  SR0        ; Set RR to one.
OEN  RR         ; Turn OEN back on again.
LD   SR1        ; Shift SR1 out to OR2.
STO  OR2
;
; SR7 = A3  (A2 can now be discarded)
; SR0, SR5, SR4, SR3, SR2, OR2, OR1, OR0 is the intermediate result.
; Unused: SR1, SR6
;
; Deal with A3 next.
;
ONE  SR0
STOC SR1        ; Clear the next carry out.
OEN  SR7        ; Turn off OEN if A3 is zero, turn it on if A3 is one.
LD   SR2        ; Add B to SR0, SR5, SR4, SR3, SR2.
ADD  IR1
STO  SR2        ; Result will be SR1, SR0, SR5, SR4, SR3, OR3, OR2, OR1, OR0.
LD   SR3
ADD  IR2
STO  SR3
LD   SR4
ADD  IR3
STO  SR4
LD   SR5
ADD  IR4
STO  SR5
LD   SR0
ADD  IR5
STO  SR0
XOR  RR         ; Account for the carry.
ADD  RR
STO  SR1
ONE  SR0        ; Set RR to one.
OEN  RR         ; Turn OEN back on again.
LD   SR2        ; Shift SR2 out to OR3.
STO  OR3
;
; SR1, SR0, SR5, SR4, SR3, OR3, OR2, OR1, OR0 is the intermediate result.
; Unused: SR2, SR6, SR7
;
; Copy SR0, SR5, SR4, SR3 to OR7, OR6, OR5, OR4.
;
LD   SR3
STO  OR4
LD   SR4
STO  OR5
LD   SR5
STO  OR6
LD   SR0
STO  OR7
;
; Copy SR1 to SR0 and zero the rest of SR.  The 9-bit result is now in
; SR0, OR7, OR6, OR5, OR4, OR3, OR2, OR1, OR0.
;
LD   SR1
STO  SR0
ONE  SR0
STOC SR1
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
