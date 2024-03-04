#include <REG51F380.H>

DIGIT_ARRAY EQU 2000H

KEY_TABLE		EQU 80H
SECRET_TABLE	EQU 88H

OUTPUT	EQU P1.0		
BUZZER  EQU P1.7
K_SET	EQU P0.6
K_LOAD	EQU P0.7

S_RECOVER  EQU 0
S_LOCKED   EQU 1
S_DECRYPT  EQU 2
S_FAIL	   EQU 3
S_OPEN	   EQU 4
S_ENCRYPT  EQU 5
S_BLOCKED  EQU 6

MAX_TRIES  EQU 5

BSEG AT 0H
NOT_EQUAL:		DBIT 1
FLAG_TIMEOUT:	DBIT 1
FLAG_VALID:		DBIT 1
FLAG_EXAUSTED:	DBIT 1
FLAG_K_LOAD:	DBIT 1

DSEG AT 30H	
STATE:		DS 1
NEXT_STATE: DS 1
N_SELECTED:	DS 1
ATTEMPTS:	DS 1
TIME_INDEX:	DS 1
KEY_SIZE:	DS 1
KEY_INDEX:	DS 1
COUNTER:	DS 1

CSEG AT 13H
	LJMP INTERRUPT_K_LOAD
CSEG AT 0
	SJMP INIT
CSEG AT 30H
	
INIT:
	MOV PCA0MD,#0
	MOV XBR1,#40H
	MOV FLSCL, #09H		
	MOV CLKSEL, #3
	
	MOV IE,#082H					;INTERRUPT
	MOV IT01CF,#76H
	
	MOV KEY_SIZE,#4					;define o tamanho da chave
	MOV KEY_INDEX,KEY_SIZE
	
	MOV N_SELECTED,#0				
	MOV ATTEMPTS,#0
	MOV TIME_INDEX,#0
	MOV COUNTER,#0
	
	CLR FLAG_K_LOAD
	
	MOV R2,#0
	MOV R3,#0
	MOV R4,#0
	MOV R5,#0
	MOV R6,#0
	MOV R7,#0

	MOV R0,#SECRET_TABLE
	MOV @R0,#0
	MOV R0,#KEY_TABLE
	MOV @R0,#0

	MOV STATE,#S_RECOVER
	MOV NEXT_STATE,#S_RECOVER

	SJMP MAIN	
	
MAIN:
	CLR P2.7
;----------------------------------------------------------------------------------------------------
CTR_FSM:
	MOV STATE,#S_LOCKED
	
CTR_L2:
	JB K_LOAD,CTR_L2
	
CTR_L3:
	JNB K_LOAD,CTR_L3
	MOV STATE,NEXT_STATE
	
JT_FSM:
	MOV A,STATE
	RL A
	MOV DPTR,#STATE_JUMP
	JMP @A+DPTR
	
STATE_JUMP:
	AJMP STATE_RECOVER
	AJMP STATE_LOCKED
	AJMP STATE_DECRYPT  
	AJMP STATE_FAIL	   
	AJMP STATE_OPEN  
	AJMP STATE_ENCRYPT  
	AJMP STATE_BLOCKED
;------------------------------------------------------
STATE_RECOVER:
	MOV DPTR,#SECRET_KEY
	MOV R0,#SECRET_TABLE
	MOV A,N_SELECTED
	MOVC A,@A+DPTR
	MOV N_SELECTED,A
	ACALL SR_INSERT_KEY
	MOV A,KEY_SIZE
	CLR C
	SUBB A,N_SELECTED
	JNZ STATE_RECOVER
	MOV NEXT_STATE,#S_LOCKED
	AJMP CTR_L3
;------------------------------------------------------
STATE_LOCKED:
	MOV P2,#0C7H	
	SETB OUTPUT					;TENSAO BLOQUEIO NA SAIDA->P1.0	
	
	MOV COUNTER,#0
	
	MOV NEXT_STATE,#S_DECRYPT
	AJMP CTR_FSM	
;------------------------------------------------------
STATE_DECRYPT: 
	MOV R7,#0					;RESET AO ARRAY	DISPLAY
SR_DISPLAY_NUMS:
	JNB K_LOAD,$
	MOV DPTR,#DIGIT_ARRAY
	MOV A,R7
	MOVC A,@A+DPTR
	MOV P2,A
	
SR_CLICK:
	JNB K_SET,SR_ARRAY_INC
	JNB K_LOAD,SR_SELECT
	SJMP SR_CLICK
	
SR_ARRAY_INC:
	JNB K_SET,$	
	INC R7
	CJNE R7,#16,SR_DISPLAY_NUMS
	
SR_RESET_ARRAY:
	MOV R7,#0
	JMP SR_DISPLAY_NUMS
	
;INSERT	 KEY
SR_SELECT:
	MOV R0,#KEY_TABLE
	MOV N_SELECTED,R7
	ACALL SR_INSERT_KEY
	DJNZ KEY_INDEX,STATE_DECRYPT
	
;DECRYPT PASS
	
;COMPARE KEYS
	ACALL SR_COMP_KEYS
	MOV KEY_INDEX,KEY_SIZE		;reset ao valor de index de selecao da chave
	
SR_RESET_KEY:					;RESET DA CHAVE DO UTILIZADOR
	MOV R0,#KEY_TABLE	
SR_RESET_POS:	
	MOV @R0,#0
	INC R0
	DJNZ KEY_INDEX,SR_RESET_POS
	
	MOV KEY_INDEX,KEY_SIZE		;reset ao valor de index de selecao da chave
	JB NOT_EQUAL,SR_INVALID
    ;JNB NOT_EQUAL,SR_VALID
	
SR_VALID:
	MOV NEXT_STATE,#S_OPEN
	AJMP CTR_FSM
SR_INVALID:
	MOV NEXT_STATE,#S_FAIL
	AJMP CTR_FSM
;------------------------------------------------------
STATE_FAIL:
	MOV P2,#8EH					;'F' no display
	
	;TIME_ARRAY->2/4/6/8/10	;10-20-30-40-50
	ACALL SR_ADD_10				;rot +10s 

	INC ATTEMPTS				;max tentativas->5
	CLR C
	MOV A,#MAX_TRIES			;definido na linha 21
	SUBB A,ATTEMPTS
	JZ SR_EXAUSTED
	CLR A
	
SR_NOT_EXAUSTED:
	MOV NEXT_STATE,#S_DECRYPT
	AJMP CTR_L3					;nao queremos controlo de k_load->automatico
	
SR_EXAUSTED:
	MOV TIME_INDEX,#0
	SETB FLAG_EXAUSTED
	MOV NEXT_STATE,#S_BLOCKED
	AJMP CTR_L3					
;------------------------------------------------------
STATE_OPEN:
	MOV ATTEMPTS,#0				;Quando o cofre abrir as tentativas voltam a 0
	MOV TIME_INDEX,#0			;A rotina de espera do fail volta a 10s

	MOV P2,#40H					;'0.' no display
	CLR OUTPUT					;desliga a tensao de bloqueio
	
	ACALL SR_DELAY500			;BLINK	
								;INTERRUPT PARA O INTERVALO DE 15s 
	
	JNB FLAG_TIMEOUT,SR_LOAD_AND_TIME
	
SR_LOAD_LOCK:
	MOV NEXT_STATE,#S_LOCKED
	AJMP CTR_L3
SR_LOAD_AND_TIME:
	MOV NEXT_STATE,#S_ENCRYPT
	AJMP CTR_L3
;------------------------------------------------------
STATE_ENCRYPT:
	MOV P2,#86H					;'E' no display
	;DEFINIR NOVA PASS
	;ENCRYPT -> XRL
	MOV NEXT_STATE,#S_LOCKED
	AJMP CTR_FSM
;------------------------------------------------------
STATE_BLOCKED:
	SETB OUTPUT					;tensao bloqueio
	;INTERRUPT
/*	
SR_BUZZER:						;5 tentativas->gerar onda quadrada->alarme(2KHz) num pino do porto 1
	CPL BUZZER
	ACALL SR_DELAY_BUZZER
	JMP SR_BUZZER
*/	
SR_CHAR_B:						;aparecer o 'b' a piscar no display a um ritmo de 0.5s
	;INTERRUPT
	;MOV NEXT_STATE,#S_RECOVER
	;AJMP CTR_FSM
	
	MOV P2,#0FFH
	ACALL SR_DELAY500
	MOV P2,#83H
	ACALL SR_DELAY500
	JMP SR_CHAR_B
	
;----------------------------------------------------------------------------------------------------
;FUNCTIONS
;------------------------------------
INTERRUPT_K_LOAD:
	JNB K_LOAD,$
	MOV R7,#1					;PARA FICAR A 0 DPS DO DJNZ DO INTERRUPT
	CLR TR2
	SETB FLAG_K_LOAD
	SETB TF2H
	
	CLR C
	MOV A,COUNTER
	SUBB A,#30
	JC SR_CY_1
	JNC SR_CY_0 
	
SR_CY_0:
	CLR FLAG_TIMEOUT
	RETI	
SR_CY_1:
	SETB FLAG_TIMEOUT
	RETI
	
;------------------------------------
;INSERT KEY
;------------------------------------
SR_INSERT_KEY:
	USING 0
	PUSH AR0 
	INC	@R0
	MOV A,@R0
	ADD A,R0
	MOV R0,A
	MOV A,N_SELECTED
	MOV @R0,A
	POP AR0
	MOV A,@R0
	MOV N_SELECTED,A
	RET

;------------------------------------
;COMPARE KEY
;------------------------------------
SR_COMP_KEYS:
	MOV R0,#KEY_TABLE
	MOV R1,#SECRET_TABLE
	PUSH ACC 
	USING 0
	PUSH AR2
	CLR NOT_EQUAL
	MOV A,KEY_SIZE		;TESTE
	MOV R2,A			;TESTE
	;MOV R2,KEY_SIZE
	
SR_COMP_LOOP:
	MOV A,@R0
	XRL A,@R1
	JZ SR_COMP_ZERO
	SETB NOT_EQUAL
	JMP SR_COMP_FIM

SR_COMP_ZERO:
	INC R0
	INC R1
	DJNZ R2,SR_COMP_LOOP
	
SR_COMP_FIM:
	POP AR2
	POP ACC
	RET
;----------------------------------------------------------------------------------------------------
;TIME ROUTINES
;------------------------------------------------------
;ROT t_buzzer
;------------------------------------
SR_DELAY_BUZZER:
	PUSH ACC
	PUSH PSW
	
	MOV CKCON,#2
	MOV TMOD,#2
	CLR TF0
	MOV TL0,#(-0FAH)			;250=0FAH
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
	SETB EX1						;ATIVA INTERRUPT
	
LOOP_DELAY500:
	JNB TF2H,$
	CLR TF2H
	DJNZ R7,LOOP_DELAY500
	CPL P2.7
	POP PSW
	POP ACC	
	
	MOV R7,#100
	INC COUNTER
	JNB FLAG_K_LOAD,LOOP_DELAY500
	RET		
;------------------------------------
;ROT 10s
;------------------------------------
SR_ADD_10:
	MOV DPTR,#TIME_ARRAY
	MOV A,TIME_INDEX
	MOVC A,@A+DPTR
	MOV	R6,A
	
SR_REPEAT10:
	ACALL SR_DELAY10
	DJNZ R6,SR_REPEAT10
	INC TIME_INDEX
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
	DJNZ R4,SR_REPEAT15
	RET
;------------------------------------------------------
SECRET_KEY:
	DB 1,0,0,0

TIME_ARRAY:
	DB 2,4,6,8,0AH

CSEG AT DIGIT_ARRAY
	DB 0C0H,0F9H,0A4H,0B0H,99H,92H,82H,0D8H,80H,90H,88H,80H,0C6H,0C0H,86H,8EH

END