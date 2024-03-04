#include <REG51F380.H>

ARRAY EQU 80H
ALEN EQU 2

K_LOAD EQU P0.7
K_SET EQU P0.6
	
CSEG AT 0H
	SJMP INIT
CSEG AT 30H
	
INIT:
	MOV PCA0MD,#0
	MOV XBR1,#41H
	
	MOV R0,#ARRAY
	MOV @R0,#0
	MOV SP,#55H
	MOV P2,#0FFH
	
	MOV R0,#0
	MOV R7,#0
	MOV R5,#0
	
M_LOOP:
	JNB K_LOAD,SR_CLICK_LOAD	
	JNB K_SET,SR_CLICK_SET
	
;--------------------------------------------	
SR_CLICK_LOAD:
	JNB K_LOAD,$
	JNB K_LOAD,M_LOOP_CONT
	SJMP SR_CLICK_LOAD
	
SR_CLICK_SET:
	JNB K_SET,$
	JNB K_SET,C_LOOP
	SJMP SR_CLICK_SET
;--------------------------------------------	

M_LOOP_CONT:
	MOV R0,#ARRAY
	MOV R7,P1
	ACALL ROT_1
	CJNE R7,#ALEN,M_LOOP
	CLR P2.7
	MOV R0,#ARRAY
	ACALL ROT_2
C_LOOP:
	SETB P2.7
	MOV R0,#ARRAY
	MOV @R0,#0
	JMP M_LOOP

;--------------------------------------------

ROT_1:
;	MOV @SP,R0
	INC @R0
	CLR A
	MOV A,@R0
	ADD A,R7
	MOV R7,A
	CLR A
;	MOV R0,@SP
	MOV A,R7
	MOV A,@R0
	MOV R7,A
	RET	
	
ROT_2:
	INC R0
	CLR C
R_LOOP:
;	MOV @SP,R0
	INC @R0
	ADD A,@R0
	MOV @R0,A
	CLR A
	INC R0
	ADDC A,@R0
	MOV @R0,A
;	MOV R0,@SP
	JNC R_LOOP
	RET
	

	
END
