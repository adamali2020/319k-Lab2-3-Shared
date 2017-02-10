;****************** main.s ***************
; Program written by: ***Your Names**update this***
; Date Created: 2/4/2017
; Last Modified: 2/4/2017
; Brief description of the program
;   The LED toggles at 8 Hz and a varying duty-cycle
; Hardware connections (External: One button and one LED)
;  PE1 is Button input  (1 means pressed, 0 means not pressed)
;  PE0 is LED output (1 activates external9 LED on protoboard)
;  PF4 is builtin button SW1 on Launchpad (Internal) 
;        Negative Logic (0 means pressed, 1 means not pressed)
; Overall functionality of this system is to operate like this
;   1) Make PE0 an output and make PE1 and PF4 inputs.
;   2) The system starts with the the LED toggling at 8Hz,
;      which is 8 times per second with a duty-cycle of 20%.
;      Therefore, the LED is ON for (0.2*1/8)th of a second
;      and OFF for (0.8*1/8)th of a second.
;   3) When the button on (PE1) is pressed-and-released increase
;      the duty cycle by 20% (modulo 100%). Therefore for each
;      press-and-release the duty cycle changes from 20% to 40% to 60%
;      to 80% to 100%(ON) to 0%(Off) to 20% to 40% so on
;   4) Implement a "breathing LED" when SW1 (PF4) on the Launchpad is pressed:
;      a) Be creative and play around with what "breathing" means.
;         An example of "breathing" is most computers power LED in sleep mode
;         (e.g., https://www.youtube.com/watch?v=ZT6siXyIjvQ).
;      b) When (PF4) is released while in breathing mode, resume blinking at 8Hz.
;         The duty cycle can either match the most recent duty-
;         cycle or reset to 20%.
;      TIP: debugging the breathing LED algorithm and feel on the simulator is impossible.
; PortE device registers
GPIO_PORTE_DATA_R  EQU 0x400243FC
GPIO_PORTE_DIR_R   EQU 0x40024400
GPIO_PORTE_AFSEL_R EQU 0x40024420
GPIO_PORTE_DEN_R   EQU 0x4002451C
; PortF device registers
GPIO_PORTF_DATA_R  EQU 0x400253FC
GPIO_PORTF_DIR_R   EQU 0x40025400
GPIO_PORTF_AFSEL_R EQU 0x40025420
GPIO_PORTF_PUR_R   EQU 0x40025510
GPIO_PORTF_DEN_R   EQU 0x4002551C
initial EQU 0x7A120				;16000 for 1ms when P = 3

SYSCTL_RCGCGPIO_R  EQU 0x400FE608
       IMPORT  TExaS_Init
       AREA    |.text|, CODE, READONLY, ALIGN=2
       THUMB
       EXPORT  Start
Start
 ; TExaS_Init sets bus clock at 80 MHz
      BL  TExaS_Init ; voltmeter, scope on PD3
      CPSIE  I    ; TExaS voltmeter, scope runs on interrupts
	LDR	R0,=SYSCTL_RCGCGPIO_R		;enable the clock
	LDR	R1,[R0]
	ORR	R1,#0x30
	STR	R1,[R0]
	NOP
	NOP
	NOP
	NOP
	LDR	R0,=GPIO_PORTE_DIR_R	;enable direction
	LDR	R2,[R0]
	MOV	R1,#0x01					;ports E0 and F4 are outputs
	ORR R2,R1
	MOV	R1,#0xFFFFFFFD
	AND	R2,R1
	STR	R2,[R0]
	LDR	R0,=GPIO_PORTF_DIR_R
	LDR	R1,[R0]
	MOV R2,#0xFEF
	AND	R1,R2
	STR	R1,[R0]
	LDR	R0,=GPIO_PORTF_PUR_R	;enable pull up resistors for PF4
	LDR	R1,[R0]
	MOV	R2,#0x010
	ORR	R1,R2
	STR	R1,[R0]
	LDR	R0,=GPIO_PORTF_DEN_R	;enable data for port PF4
	LDR	R1,[R0]
	MOV	R2,#0x010
	ORR	R1,R2
	STR	R1,[R0]
	LDR	R0,=GPIO_PORTE_DEN_R	;enable data for PE0 and PE1
	LDR	R1,[R0]
	MOV	R2,#0xFF
	ORR	R1,R2
	STR	R1,[R0]
	LDR	R0,=GPIO_PORTF_AFSEL_R	;clears AFSEL
	MOV	R1,#0x0
	STR R1,[R0]
	LDR	R0,=GPIO_PORTE_AFSEL_R	;clears AFSEL
	MOV	R1,#0x0
	STR R1,[R0]
	MOV R4, #1
	MOV R7, #0
	MOV R1,#0
	LDR	R2,=wasPushed
	STR	R1,[R2]
loop2
	LDR R0, =GPIO_PORTF_DATA_R
	LDR R1, [R0]
	ANDS R1, R1, #0x10	; Isolate PF4
	BEQ Breathe
;Main Routine******************************************	
	LDR R1, =GPIO_PORTE_DATA_R
	LDR R0, [R1]
	ANDS R0, R0, #0x2
	BEQ skip
	ADDS R7, R7, #0
;	LDR R1, =wasPushed
;	LDR R0, [R1]
;	ADD R0, R0, #0
	BNE skip
	MOV R7, #1
;	MOV R0, #1
;	STR R0, [R1]
skip
	MOV R2, #5
	SUB R2, R2, R4
	MOV R1, #25
	MUL R6, R2, R1
	BL DelaySubroutine
	LDR R0, =GPIO_PORTE_DATA_R
	LDR	R2,[R0]		;load data into R2
	MOV	R3,#0x01
	BIC	R2,R3
	ORR	R2,R3
	STR	R2,[R0]		; Turns on the LED

	MOV R1, #25
	MUL R6, R4, R1
	BL DelaySubroutine
	LDR	R2,[R0]		;load data into R2
	MOV	R1,#0xFFE
	AND	R2,R1
	STR	R2,[R0]
					;Check if button has been pushed and if it has then check if it has been released
;	LDR R1, =wasPushed
;	LDR R0, [R1]
;	ADD R0, R0, #0
	ADDS R7, R7, #0
	BEQ loop2
	LDR R1, =GPIO_PORTE_DATA_R
	LDR R0, [R1]
	ANDS R0, R0, #0x2
	BNE loop2
;	LDR R1, =wasPushed
;	MOV R0, #0
;	STR R0, [R1]
	AND R7, R7, #0
	ADD R4, R4, #1
	MOV R1, #6
	SUBS R5, R1, R4
	BNE loop2
	AND R4, R4, #0
	B loop2

;*******************************************************************************
;Delay subroutine, punt number of ms to delay in R6, uses R6 and R9
DelaySubroutine
	ADDS	R6,#0
	BNE	delaySkip
	BX	LR
delaySkip	
	SUBS R6,#1
delayLoop1
	MOV	R9,#16000
delayLoop2
	SUBS	R9,#1
	BNE	delayLoop2
	SUBS	R6,R6,#1
	BNE	delayLoop1
	BX	LR
;*****************************************************************************************
;Breating subroutine
Breathe	
	LDR	R0,=GPIO_PORTE_DATA_R	;R0 has address of port e data
	MOV R1,#100			;R1 has the ammount of time for the On delay
	MOV	R2,#0			;R2 has the ammount of time for the Off delay
	MOV	R3,#0			;R3 has 0 if the on time should be decreasing and 1 if on time should be increasing
;delay 1, on delay	
	MOV	R6,R1
	BL	BreatheDelay
	LDR	R5,[R0]		;load data into R5
	MOV	R3,#0x01
	BIC	R5,R3
	ORR	R5,R3
	STR	R5,[R0]
;delay 2, off delay
	MOV	R6,R2
	BL	BreatheDelay
	LDR	R5,[R0]		;load datat into R5
	MOV	R3,#0xFFE
	AND	R5,R3
	STR	R5,[R0]
;check to see if on time should be increasing of decreasing and change R3 accorsingly
	CMP	R2,#0
	BNE	BrtSkip1
	MOV	R3,#0
BrtSkip1
	CMP	R1,#0
	BNE	BrtSkip2
	MOV	R3,#1
BrtSkip2
;check R3 to see if R1 or R2 should increase
	ADDS	R3,#0
	BNE	IncOnTime
	ADD	R2,#1
	SUB	R1,#1
IncOnTime
	ADD	R1,#1
	SUB	R2,#1
	B	loop2
	



;for later, make a register you use to determine if you are adding to the on or off register (R5), make a way to flip that determining register from a 1 or 0
;make a loop that subtracts from R1 and adds to R2 if R5 is 1 or 0 and visa versa


;*****************************************************************************
;Breathing DelaySubroutine, delays R6*something seconds, uses R6 and R9
BreatheDelay
	ADDS	R6,#0
	BNE	BDelaySkip
	BX	LR
BDelaySkip	
	SUBS R6,#1
BDelayLoop1
	MOV	R9,#160
BDelayLoop2
	SUBS	R9,#1
	BNE	BDelayLoop2
	SUBS	R6,R6,#1
	BNE	BDelayLoop1
	BX	LR


wasPushed SPACE 4

loop  

	  B    loop


      ALIGN      ; make sure the end of this section is aligned
      END        ; end of file

