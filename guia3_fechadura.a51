#include <REG51F380.H>

DIGIT_ARRAY EQU 2000H

OUTPUT	EQU P1.0
BUZZER  EQU P1.7
K_SET	EQU P0.6
K_LOAD	EQU P0.7

S_RECOVERY EQU 0
S_LOCKED   EQU 1
S_DECRYPT  EQU 2
S_FAIL	   EQU 3
S_OPEN	   EQU 4
S_ENCRYPT  EQU 5
S_BLOCKED  EQU 6

DSEG AT 30H
	
STATE:		DS 1
NEXT_STATE: DS 1
ATTEMPTS:	DS 1		
DIGIT_0:	DS 1
DIGIT_1:	DS 1
DIGIT_2:	DS 1
DIGIT_3:	DS 1

CSEG AT 0
	SJMP INIT
CSEG AT 30H
	
INIT:
	MOV PCA0MD,#0
	MOV XBR1,#40H
	MOV FLSCL, #09H		
	MOV CLKSEL, #3		
	
	MOV DIGIT_0,#0
	MOV DIGIT_1,#0
	MOV DIGIT_2,#0
	MOV DIGIT_3,#0
	MOV ATTEMPTS,#0
	
	MOV R3,#0
	MOV R4,#0
	MOV R5,#0
	MOV R6,#0
	MOV R7,#0

	MOV STATE,#S_LOCKED
	MOV NEXT_STATE,#S_LOCKED

	SJMP MAIN
	
MAIN:
	
;------------------------------------------------------------------------------
;LOCKED
SR_LOCKED:
	MOV P2,#0C7H	
	SETB OUTPUT							;TENSAO BLOQUEIO NA SAIDA->P1.0
	JNB K_LOAD,SR_SELECT_NUM
	SJMP SR_LOCKED	

;------------------------------------------------------------------------------
;DECRYPT
	
SR_SELECT_NUM:
	JNB K_LOAD,$
	MOV DPTR,#DIGIT_ARRAY
	MOV A,R7
	MOVC A,@A+DPTR
	MOV P2,A
	
SR_CLICK:
	JNB K_SET,SR_ARRAY_INC
	JNB K_LOAD,SR_CLICK_LOAD
	SJMP SR_CLICK
	
SR_CLICK_LOAD:
	JNB K_LOAD,$
	MOV R5,A
	MOV A,R6
	RL A
	MOV DPTR,#DIGIT_JUMP
	JMP @A+DPTR

DIGIT_JUMP:
	AJMP SR_DIGIT_0
	AJMP SR_DIGIT_1
	AJMP SR_DIGIT_2
	AJMP SR_DIGIT_3
	
SR_ARRAY_INC:
	JNB K_SET,$	
	INC R7
	CJNE R7,#16,SR_SELECT_NUM

SR_RESET_ARRAY:
	MOV R7,#0
	JMP SR_SELECT_NUM
		
SR_DIGIT_0:
	MOV DIGIT_0,R5
	INC R6
	MOV R7,#0
	AJMP SR_SELECT_NUM
SR_DIGIT_1:
	MOV DIGIT_1,R5
	INC R6
	MOV R7,#0
	AJMP SR_SELECT_NUM
SR_DIGIT_2:
	MOV DIGIT_2,R5
	INC R6
	MOV R7,#0
	AJMP SR_SELECT_NUM
SR_DIGIT_3:
	MOV DIGIT_3,R5
	MOV R6,#0
	MOV P2,#89H				;INDICAR O FIM DO CODIGO 4 DIGITS
	;VERIFICAR O CODIGO 4 DIGITOS
	;JMP
;------------------------------------------------------------------------------
;OPEN
	MOV P2,#0C0H
	;15s p definir nova pass
;------------------------------------------------------------------------------
;ENCRYPT
	;XRL ENCRYPT
;------------------------------------------------------------------------------
;FAIL
SR_FAIL:
								;aumentar t+10s por tentativa
	INC ATTEMPTS				;max tentativas->5
	CLR C
	MOV A,#5
	SUBB A,ATTEMPTS
	JZ SR_CHAR_B
	CLR A
	
	MOV P2,#8EH					;'F' no display
	MOV R6,#2
	ACALL SR_REPEAT10
	JMP SR_LOCKED
;------------------------------------------------------------------------------
;BLOCKED
	SETB OUTPUT					;tensao bloqueio
SR_BUZZER:						;5 tentativas->gerar onda quadrada->alarme(2KHz) num pino do porto 1
	CPL BUZZER
	ACALL SR_DELAY_BUZZER
	JMP SR_BUZZER
	
SR_CHAR_B:						;aparecer o 'b' a piscar no display a um ritmo de 0.5s
	MOV P2,#0FFH
	ACALL SR_DELAY500
	MOV P2,#83H
	ACALL SR_DELAY500
	JMP SR_CHAR_B
;------------------------------------------------------------------------------
;RECOVERY
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
;BLINK-500mS
SR_BLINK:
	CPL P2.7
	ACALL SR_DELAY500
	SJMP SR_BLINK
;------------------------------------------------------------------------------
;DELAY ROUTINES	
;------------------------------------------------------------------------------
;ROT t_buzzer
;------------------------------------
SR_DELAY_BUZZER:
	PUSH ACC
	PUSH PSW
	
	MOV CKCON,#2
	MOV TMOD,#2
	CLR TF0
	MOV TL0,#(-0FAH)				;250=0FAH
	MOV TH0,#(-0FAH)
	SETB TR0
LOOP_DELAY_BUZZER:
	JNB TF0,$
	CLR TF0
	
	POP PSW
	POP ACC
	RET

;------------------------------------
;ROT 500ms
;------------------------------------
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
	MOV R7,#0
	RET		
;------------------------------------
;ROT 10s
SR_REPEAT10:
	ACALL SR_DELAY10
	DJNZ R6,SR_REPEAT10
	RET
	
SR_DELAY10:
	PUSH ACC
	PUSH PSW
	
	MOV CKCON,#2				;SYSCLK/48 -> f=1MHz
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
	
	MOV R5,#0
	POP PSW
	POP ACC
	RET
;------------------------------------
;ROT 15s
;------------------------------------
SR_REPEAT15:
	ACALL SR_DELAY500
	;R4<-10
	DJNZ R4,SR_REPEAT15
	RET
;------------------------------------
SR_DELAY15:
	PUSH ACC
	PUSH PSW
	MOV TMR2L,#LOW(-60000)
	MOV TMR2H,#HIGH(-60000)
	MOV TMR2RLL,#LOW(-60000)
	MOV TMR2RLH,#HIGH(-60000)
	CLR TF2H
	SETB TR2
	MOV R7,#100
	
LOOP_DELAY15:
	JNB TF2H,$
	CLR TF2H
	DJNZ R7,LOOP_DELAY15	
	CLR TR2
	POP PSW
	POP ACC
	MOV R7,#0
	RET		
;------------------------------------------------------------------------------
CSEG AT DIGIT_ARRAY
	DB 0C0H,0F9H,0A4H,0B0H,99H,92H,82H,0D8H,80H,90H,88H,80H,0C6H,0C0H,86H,8EH

END