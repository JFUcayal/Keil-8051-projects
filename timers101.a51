#include <REG51F380.H>

CSEG AT 0
	SJMP INIT
CSEG AT 30H

INIT:
	MOV PCA0MD, #0		;desativar WDT
	MOV XBR1, #40H		;ativar portos
	MOV FLSCL, #09H		;48 Mhz
	MOV CLKSEL, #3		;Não há divisão

	MOV R4,#0
	MOV R5,#0
	MOV R6,#0
	MOV R7,#0
	
MAIN:
/*
	CPL P2.7
	MOV R4,#10	
	ACALL SR_REPEAT500
	JMP MAIN

	CPL P2.0
	MOV R6,#2
	ACALL SR_REPEAT10
	JMP MAIN
*/
	CPL P2.0
	;MOV R6,#2
	ACALL SR_DELAY_BUZZER
	JMP MAIN
;---------------------------------------------------------
SR_DELAY_BUZZER:
	PUSH ACC
	PUSH PSW
	
	MOV CKCON,#2
	MOV TMOD,#2
	CLR TF0
	MOV TL0,#(-0FAH)
	MOV TH0,#(-0FAH)
	SETB TR0
LOOP_DELAY_BUZZER:
	JNB TF0,$
	CLR TF0
	
	POP PSW
	POP ACC
	RET
;---------------------------------------------------------
SR_REPEAT10:
	ACALL SR_DELAY10
	DJNZ R6,SR_REPEAT10
	RET
	
SR_DELAY10:
	PUSH ACC
	PUSH PSW
	
	MOV CKCON,#2
	MOV TMOD,#10H
	MOV R5,#100
	
LOOP_DELAY10:
	CLR TF1
	MOV TL1,#LOW(-50000)
	MOV TH1,#HIGH(-50000)
	SETB TR1
	JNB TF1,$
	CLR TR1 
	DJNZ R5,LOOP_DELAY10
	
	POP PSW
	POP ACC
	RET
	
;---------------------------------------------------------
SR_REPEAT500:
	ACALL SR_DELAY500
	DJNZ R4,SR_REPEAT500
	RET
;---------------------------------------------------------	
SR_DELAY500:
	PUSH ACC
	PUSH PSW

	MOV TMR2L,#LOW(-20000)
	MOV TMR2H,#HIGH(-20000)
	MOV TMR2RLL,#LOW(-20000)
	MOV TMR2RLH,#HIGH(-20000)
	CLR TF2H
	SETB TR2
	MOV R7,#100
	
LOOP_DELAY500:
	JNB TF2H,$
	CLR TF2H
	DJNZ R7,LOOP_DELAY500
	CLR TR2
	POP PSW
	POP ACC
	RET	
;---------------------------------------------------------
END