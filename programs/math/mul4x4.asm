;
; Multiply two 4-bit numbers to give an 8-bit result.
;
; Usage:
;   1. Program initialises and then halts waiting for the first 4-bit
;      number to be entered on IR4..IR1.
;   2. Resume and then the program halts again waiting for the second
;      4-bit number to be entered on IR4..IR1.
;   3. Resume and the answer will eventually be written to OR7..OR0.
;
; Algorithm:
;
;   First value, A = A3, A2, A1, A0
;   Second value, B = B3, B2, B1, B0
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
; This program technically needs 8 bits to hold the input values and
; another 8 bits to hold the intermediate calculations.  However,
; each time we use a bit of A, we can reclaim that bit for storing one
; bit of the result.  And by leaving B in the input register, we can
; reduce the memory requirements further.
;

;
; Initialize the machine.
;
ONE  SR0
IEN  RR
OEN  RR
;
; Set the output register with the result to all zeroes.
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
; B is currently in IR4, IR3, IR2, IR1 (MSB to LSB).  We leave it on the
; input switches, effectively using them as 4 bits of extra RAM.
;
; Note: Changing the input switches while the remaining code runs will
; modify the result in unexpected ways.  Don't do that!
;
; If A0 is zero, set the intermediate result to 0.  If A0 is one,
; then set the intermediate result to B.  The intermediate result will
; end up in SR3, SR2, SR1, SR0, OR0.
;
IEN  SR4        ; Test A0 (SR4) for non-zero and set IEN accordingly.
LD   IR1        ; Copy B to SR2, SR1, SR0, OR0.
STO  OR0        ; IEN will force the value to zero if SR4 was zero.
LD   IR2
STO  SR0
LD   IR3
STO  SR1
LD   IR4
STO  SR2
ONE  SR0        ; Turn IEN back on.
IEN  RR
STOC SR3        ; Carry out in SR3 is currently zero.
;
; SR7, SR6, SR5 = A3, A2, A1  (A0 can now be discarded)
; SR3, SR2, SR1, SR0, OR0 is the intermediate result.
; Unused: SR4
;
; Deal with A1 next.
;
STOC SR4        ; Clear the next carry out.
OEN  SR5        ; Turn off OEN if A1 is zero, turn it on if A1 is one.
LD   SR0        ; Add B to SR3, SR2, SR1, SR0.
ADD  IR1
STO  SR0        ; Result will be in SR4, SR3, SR2, SR1, OR1, OR0.
LD   SR1
ADD  IR2
STO  SR1
LD   SR2
ADD  IR3
STO  SR2
LD   SR3
ADD  IR4
STO  SR3
XOR  RR         ; Account for the carry.
ADD  RR
STO  SR4
ONE  SR0        ; Set RR to one.
OEN  RR         ; Turn OEN back on again.
LD   SR0        ; Shift SR0 out to OR1.
STO  OR1
;
; SR7, SR6 = A3, A2  (A1 can now be discarded)
; SR4, SR3, SR2, SR1, OR1, OR0 is the intermediate result.
; Unused: SR0, SR5
;
; Deal with A2 next.
;
ONE  SR0
STOC SR0        ; Clear the next carry out.
OEN  SR6        ; Turn off OEN if A2 is zero, turn it on if A2 is one.
LD   SR1        ; Add B to SR4, SR3, SR2, SR1.
ADD  IR1
STO  SR1        ; Result will be SR0, SR4, SR3, SR2, OR2, OR1, OR0.
LD   SR2
ADD  IR2
STO  SR2
LD   SR3
ADD  IR3
STO  SR3
LD   SR4
ADD  IR4
STO  SR4
XOR  RR         ; Account for the carry.
ADD  RR
STO  SR0
ONE  SR0        ; Set RR to one.
OEN  RR         ; Turn OEN back on again.
LD   SR1        ; Shift SR1 out to OR2.
STO  OR2
;
; SR7 = A3  (A2 can now be discarded)
; SR0, SR4, SR3, SR2, OR2, OR1, OR0 is the intermediate result.
; Unused: SR1, SR5, SR6
;
; Deal with A3 next.
;
ONE  SR0
STOC SR1        ; Clear the next carry out.
OEN  SR7        ; Turn off OEN if A3 is zero, turn it on if A3 is one.
LD   SR2        ; Add B to SR0, SR4, SR3, SR2.
ADD  IR1
STO  SR2        ; Result will be SR1, SR0, SR4, SR3, OR3, OR2, OR1, OR0.
LD   SR3
ADD  IR2
STO  SR3
LD   SR4
ADD  IR3
STO  SR4
LD   SR0
ADD  IR4
STO  SR0
XOR  RR         ; Account for the carry.
ADD  RR
STO  SR1
ONE  SR0        ; Set RR to one.
OEN  RR         ; Turn OEN back on again.
LD   SR2        ; Shift SR2 out to OR3.
STO  OR3
;
; SR1, SR0, SR4, SR3, OR3, OR2, OR1, OR0 is the intermediate result.
; Unused: SR2, SR5, SR6, SR7
;
; Copy SR1, SR0, SR4, SR3 to OR7, OR6, OR5, OR4.
;
LD   SR3
STO  OR4
LD   SR4
STO  OR5
LD   SR0
STO  OR6
LD   SR1
STO  OR7
;
; Clear the scratch register.
;
ONE  SR0
STOC SR0
STOC SR1
STOC SR2
STOC SR3
STOC SR4
STOC SR5
STOC SR6
STOC SR7
;
; Ring the bell and stop.
;
IOC  SR0
NOPF SR0
