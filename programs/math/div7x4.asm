;
; Divide a 7-bit number by a 4-bit number to give a 7-bit quotient and a
; 4-bit remainder.
;
; by Rhys Weatherley
;
; Usage:
;   1. Program initialises and then halts waiting for the 4-bit divisor
;      to be entered on IR4, IR3, IR2, IR1.  Note: The divisor is entered first.
;   2. Resume and then the program halts again waiting for the 7-bit
;      dividend to be entered on IR7..IR1.
;   3. Resume and the quotient will eventually be written to OR6..OR0.
;      The remainder will be in SR3, SR2, SR1, SR0.
;
; If division by zero occurs, then all of OR6..OR0 will be set to 1.
; That is a quotient of 127, which is the closest the program can get to
; representing x / 0 = infinity.
;
; Algorithm:
;
;   Set the 5-bit working register W to zero.
;   For each bit of the dividend, working from MSB to LSB:
;       Shift W left, shifting in the next bit of the dividend.
;       Compare W with the divisor D.
;       If W >= D, then set the next quotient bit to 1, else 0.
;       If W >= D, then subtract D from W.
;   At the end, W is the remainder.
;

;
; Initialize the machine.
;
ONE  SR0
IEN  RR
OEN  RR
;
; Set the output register with the result quotient to all zeroes.
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
; Set the 5-bit working register in SR4..SR7 to all zeroes.  This is the
; partial remainder after each round.  The fifth bit is virtual; it is
; created and discarded each round.
;
STOC SR4
STOC SR5
STOC SR6
STOC SR7
;
; Prompt for the 4-bit divisor on the input switches.
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
; Read the divisor from IR4, IR3, IR2, IR1 (MSB to LSB) and put it into
; SR3, SR2, SR1, SR0 (MSB to LSB).
;
LD   IR4
STO  SR3
LD   IR3
STO  SR2
LD   IR2
STO  SR1
LD   IR1
STO  SR0
;
; Prompt for the dividend on the input switches.
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
; The dividend is currently in IR7..IR1 (MSB to LSB).  We leave it on the
; input switches, effectively using them as 7 bits of extra RAM.
;
; Note: Changing the input switches while the remaining code runs will
; modify the result in unexpected ways.  Don't do that!
;
; Round 1, quotient result bit in OR6.
;
; Working register W = SR7, SR6, SR5, SR4, IR7.
;
ONE  SR0        ; Set CAR to 1 and subtract the divisor from W.
ADD  RR         ; We throw the result away because we only care about the
LD   IR7        ; carry/borrow out for the comparison.
SUB  SR0
LD   SR4
SUB  SR1
LD   SR5
SUB  SR2
LD   SR6
SUB  SR3
XOR  RR         ; Shift CAR into RR and OR it with SR7.  If SR7 is
ADD  RR         ; non-zero, then W is definitely larger than the divisor.
OR   SR7
STO  OR6        ; Set the quotient bit for this round.
;
ADD  RR         ; Shift RR back into CAR to save it.
LD   IR7        ; Shift IR7 into the working register.
STO  SR7        ; SR7 now becomes the next-to-LSB of W for the next round.
;
XOR  RR         ; Shift CAR back into RR.
ADD  RR
OEN  RR         ; Turn off OEN if W < divisor.
ONE  SR0        ; Set CAR to 1 for the next subtraction.
ADD  RR
;
LD   SR7        ; Subtract the divisor from W if OEN is 1.
SUB  SR0        ; This reduces the value in W when the quotient bit is 1.
STO  SR7
LD   SR4
SUB  SR1
STO  SR4
LD   SR5
SUB  SR2
STO  SR5
LD   SR6
SUB  SR3
STO  SR6
;
ONE  SR0        ; Turn OEN back on again.
OEN  RR
;
; Round 2, quotient result bit in OR5.
;
; Working register W = SR6, SR5, SR4, SR7, IR6.
;
ONE  SR0        ; Set CAR to 1 and subtract the divisor from W.
ADD  RR         ; We throw the result away because we only care about the
LD   IR6        ; carry/borrow out for the comparison.
SUB  SR0
LD   SR7
SUB  SR1
LD   SR4
SUB  SR2
LD   SR5
SUB  SR3
XOR  RR         ; Shift CAR into RR and OR it with SR6.  If SR6 is
ADD  RR         ; non-zero, then W is definitely larger than the divisor.
OR   SR6
STO  OR5        ; Set the quotient bit for this round.
;
ADD  RR         ; Shift RR back into CAR to save it.
LD   IR6        ; Shift IR6 into the working register.
STO  SR6        ; SR6 now becomes the next-to-LSB of W for the next round.
;
XOR  RR         ; Shift CAR back into RR.
ADD  RR
OEN  RR         ; Turn off OEN if W < divisor.
ONE  SR0        ; Set CAR to 1 for the next subtraction.
ADD  RR
;
LD   SR6        ; Subtract the divisor from W if OEN is 1.
SUB  SR0        ; This reduces the value in W when the quotient bit is 1.
STO  SR6
LD   SR7
SUB  SR1
STO  SR7
LD   SR4
SUB  SR2
STO  SR4
LD   SR5
SUB  SR3
STO  SR5
;
ONE  SR0        ; Turn OEN back on again.
OEN  RR
;
; Round 3, quotient result bit in OR4.
;
; Working register W = SR5, SR4, SR7, SR6, IR5.
;
ONE  SR0        ; Set CAR to 1 and subtract the divisor from W.
ADD  RR         ; We throw the result away because we only care about the
LD   IR5        ; carry/borrow out for the comparison.
SUB  SR0
LD   SR6
SUB  SR1
LD   SR7
SUB  SR2
LD   SR4
SUB  SR3
XOR  RR         ; Shift CAR into RR and OR it with SR5.  If SR5 is
ADD  RR         ; non-zero, then W is definitely larger than the divisor.
OR   SR5
STO  OR4        ; Set the quotient bit for this round.
;
ADD  RR         ; Shift RR back into CAR to save it.
LD   IR5        ; Shift IR5 into the working register.
STO  SR5        ; SR5 now becomes the next-to-LSB of W for the next round.
;
XOR  RR         ; Shift CAR back into RR.
ADD  RR
OEN  RR         ; Turn off OEN if W < divisor.
ONE  SR0        ; Set CAR to 1 for the next subtraction.
ADD  RR
;
LD   SR5        ; Subtract the divisor from W if OEN is 1.
SUB  SR0        ; This reduces the value in W when the quotient bit is 1.
STO  SR5
LD   SR6
SUB  SR1
STO  SR6
LD   SR7
SUB  SR2
STO  SR7
LD   SR4
SUB  SR3
STO  SR4
;
ONE  SR0        ; Turn OEN back on again.
OEN  RR
;
; Round 4, quotient result bit in OR3.
;
; Working register W = SR4, SR7, SR6, SR5, IR4.
;
ONE  SR0        ; Set CAR to 1 and subtract the divisor from W.
ADD  RR         ; We throw the result away because we only care about the
LD   IR4        ; carry/borrow out for the comparison.
SUB  SR0
LD   SR5
SUB  SR1
LD   SR6
SUB  SR2
LD   SR7
SUB  SR3
XOR  RR         ; Shift CAR into RR and OR it with SR4.  If SR4 is
ADD  RR         ; non-zero, then W is definitely larger than the divisor.
OR   SR4
STO  OR3        ; Set the quotient bit for this round.
;
ADD  RR         ; Shift RR back into CAR to save it.
LD   IR4        ; Shift IR4 into the working register.
STO  SR4        ; SR4 now becomes the next-to-LSB of W for the next round.
;
XOR  RR         ; Shift CAR back into RR.
ADD  RR
OEN  RR         ; Turn off OEN if W < divisor.
ONE  SR0        ; Set CAR to 1 for the next subtraction.
ADD  RR
;
LD   SR4        ; Subtract the divisor from W if OEN is 1.
SUB  SR0        ; This reduces the value in W when the quotient bit is 1.
STO  SR4
LD   SR5
SUB  SR1
STO  SR5
LD   SR6
SUB  SR2
STO  SR6
LD   SR7
SUB  SR3
STO  SR7
;
ONE  SR0        ; Turn OEN back on again.
OEN  RR
;
; Round 5, quotient result bit in OR2.
;
; Working register W = SR7, SR6, SR5, SR4, IR3.
;
ONE  SR0        ; Set CAR to 1 and subtract the divisor from W.
ADD  RR         ; We throw the result away because we only care about the
LD   IR3        ; carry/borrow out for the comparison.
SUB  SR0
LD   SR4
SUB  SR1
LD   SR5
SUB  SR2
LD   SR6
SUB  SR3
XOR  RR         ; Shift CAR into RR and OR it with SR7.  If SR7 is
ADD  RR         ; non-zero, then W is definitely larger than the divisor.
OR   SR7
STO  OR2        ; Set the quotient bit for this round.
;
ADD  RR         ; Shift RR back into CAR to save it.
LD   IR3        ; Shift IR3 into the working register.
STO  SR7        ; SR7 now becomes the next-to-LSB of W for the next round.
;
XOR  RR         ; Shift CAR back into RR.
ADD  RR
OEN  RR         ; Turn off OEN if W < divisor.
ONE  SR0        ; Set CAR to 1 for the next subtraction.
ADD  RR
;
LD   SR7        ; Subtract the divisor from W if OEN is 1.
SUB  SR0        ; This reduces the value in W when the quotient bit is 1.
STO  SR7        ; SR7 now becomes the next-to-LSB of W for the next round.
LD   SR4
SUB  SR1
STO  SR4
LD   SR5
SUB  SR2
STO  SR5
LD   SR6
SUB  SR3
STO  SR6
;
ONE  SR0        ; Turn OEN back on again.
OEN  RR
;
; Round 6, quotient result bit in OR1.
;
; Working register W = SR6, SR5, SR4, SR7, IR2.
;
ONE  SR0        ; Set CAR to 1 and subtract the divisor from W.
ADD  RR         ; We throw the result away because we only care about the
LD   IR2        ; carry/borrow out for the comparison.
SUB  SR0
LD   SR7
SUB  SR1
LD   SR4
SUB  SR2
LD   SR5
SUB  SR3
XOR  RR         ; Shift CAR into RR and OR it with SR6.  If SR6 is
ADD  RR         ; non-zero, then W is definitely larger than the divisor.
OR   SR6
STO  OR1        ; Set the quotient bit for this round.
;
ADD  RR         ; Shift RR back into CAR to save it.
LD   IR2        ; Shift IR2 into the working register.
STO  SR6        ; SR6 now becomes the next-to-LSB of W for the next round.
;
XOR  RR         ; Shift CAR back into RR.
ADD  RR
OEN  RR         ; Turn off OEN if W < divisor.
ONE  SR0        ; Set CAR to 1 for the next subtraction.
ADD  RR
;
LD   SR6        ; Subtract the divisor from W if OEN is 1.
SUB  SR0        ; This reduces the value in W when the quotient bit is 1.
STO  SR6        ; SR6 now becomes the next-to-LSB of W for the next round.
LD   SR7
SUB  SR1
STO  SR7
LD   SR4
SUB  SR2
STO  SR4
LD   SR5
SUB  SR3
STO  SR5
;
ONE  SR0        ; Turn OEN back on again.
OEN  RR
;
; Round 7, quotient result bit in OR0.
;
; Working register W = SR5, SR4, SR7, SR6, IR1.
;
ONE  SR0        ; Set CAR to 1 and subtract the divisor from W.
ADD  RR         ; We throw the result away because we only care about the
LD   IR1        ; carry/borrow out for the comparison.
SUB  SR0
LD   SR6
SUB  SR1
LD   SR7
SUB  SR2
LD   SR4
SUB  SR3
XOR  RR         ; Shift CAR into RR and OR it with SR5.  If SR5 is
ADD  RR         ; non-zero, then W is definitely larger than the divisor.
OR   SR5
STO  OR0        ; Set the quotient bit for this round.
;
ADD  RR         ; Shift RR back into CAR to save it.
LD   IR1        ; Shift IR1 into the working register.
STO  SR5        ; SR5 now becomes the next-to-LSB of W for the next round.
;
XOR  RR         ; Shift CAR back into RR.
ADD  RR
OEN  RR         ; Turn off OEN if W < divisor.
ONE  SR0        ; Set CAR to 1 for the next subtraction.
ADD  RR
;
LD   SR5        ; Subtract the divisor from W if OEN is 1.
SUB  SR0        ; This reduces the value in W when the quotient bit is 1.
STO  SR5
LD   SR6
SUB  SR1
STO  SR6
LD   SR7
SUB  SR2
STO  SR7
LD   SR4
SUB  SR3
STO  SR4
;
ONE  SR0        ; Turn OEN back on again.
OEN  RR
;
; Copy SR4, SR7, SR6, SR5 to SR3, SR2, SR1, SR0 for the 4-bit remainder.
;
LD   SR4
STO  SR3
LD   SR7
STO  SR2
LD   SR6
STO  SR1
LD   SR5
STO  SR0
;
; Clear the rest the scratch register to all zeroes.
;
ONE  SR0
STOC SR4
STOC SR5
STOC SR6
STOC SR7
;
; Ring the bell and stop.
;
IOC  SR0
NOPF SR0
