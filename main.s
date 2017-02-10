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
initial EQU 0x7A120
eigth EQU 0x2625A0

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
	MOV	R1,#0x01					;ports E1 and F4 are outputs
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

loop2
	LDR R0, =GPIO_PORTF_DATA_R
	LDR R1, [R0]
	AND R1, R1, #0x10	; Isolate PF4
	BNE	flash
						; Breathing LED
flash	
	MOV	R4, #1
	LDR R0, =GPIO_PORTE_DATA_R
	LDR R5, [R1]
	AND	R5, R5, #0x2	; Mask PORTE_DATA so that only PE1(button) is kept
	BEQ	not0			; Takes branch if button has not been pressed
	ADD R4, R4, #1		; Increments 
	SUBS R5, R4, #6
	BNE not0			; Checks to see if buton has been pressed 5 times meaning it should be at 0%
	AND R4, R4, #0		; R4 has the multiplier for %20 incrememnts of the led time on

not0	LDR R1, =initial	;1/40th of a second
	MUL R1, R1, R4
	LDR R2, =eigth
	SUB R2, R2, R1			; Puts 20%*R4 in R1 and subtracts it from eigth of a second >> R2
wait
	SUBS R2,#1		
	BNE	wait		;delay loop
	LDR	R2,[R0]		;load data into R2
	MOV	R3,#0x01
	BIC	R2,R3
	ORR	R2,R3
	STR	R2,[R0]		; Turns on the LED
wait2
	SUBS R1,#1
	BNE	wait2		;delay loop
	LDR	R2,[R0]		;load datat into R2
	MOV	R1,#0xFFE
	AND	R2,R1
	STR	R2,[R0]
	B loop2


loop  

	  B    loop

      ALIGN      ; make sure the end of this section is aligned
      END        ; end of file

