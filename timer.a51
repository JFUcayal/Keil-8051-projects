#include <REG51F380.H>


//ESTADOS
S_READY EQU 0
S_INCREMENTA EQU 1
S_DECREMENTA EQU 2
S_PISCA EQU 3	


//ENTRADAS
K_SET EQU P0.6
K_LOAD EQU P0.7

//SAÍDAS
DISPLAY EQU P2
	
//VARIÁVEIS
INDICE EQU R6

BSEG AT 0H
	FLAG_PISCA: DBIT 1		;posição 0 da memória de dados endereçável ao bit--> 20.0h	

DSEG AT 30H
	STATE: DS 1				;posição 30h da memoria de dados direta
	N_STATE: DS 1			;posição 31h da memoria de dados direta



//RESPOSTA AO RESET
CSEG AT 0H
	SJMP INIT

CSEG AT 30H
	INIT:
		MOV PCA0MD, #0		;desativar WDT
		MOV XBR1, #40H		;ativar portos
		MOV FLSCL, #09H		;48 Mhz
		MOV CLKSEL, #3		;Não há divisão
		MOV SP, #225		;reservar 30 bytes para a stack no topo da memória de dados  
		
		//INICIALIZAÇÃO DAS VARIÁVEIS
		CLR FLAG_PISCA
		MOV STATE, #S_READY
		MOV N_STATE, #S_READY
		MOV INDICE, #0
		ACALL ROT_DISPLAY
	

	

;=========================================
;ROTINA CONTROL DE ESTADOS
;=========================================		
CTRL_FSM:
	MOV STATE, N_STATE
	ACALL ENCODE_FSM
	SJMP CTRL_FSM
	
ENCODE_FSM:	
	MOV A, STATE
	RL A
	MOV DPTR, #STATE_TABLE
	JMP @A+DPTR
	
STATE_TABLE:
	AJMP ROT_READY
	AJMP ROT_INCREMENTAR
	AJMP ROT_DECREMENTAR
	AJMP ROT_PISCAR
	
	
	
;=========================================
;ROTINA DE INCREMENTAR
;=========================================		
ROT_INCREMENTAR:
	INC INDICE 
	CJNE INDICE, #10, RINC_CONT 
	
	;--ALTERNATIVA AO CJNE--
	;MOV A, INDICE
	;CLR C
	;SUBB A, #10
	;JNZ RINC_CONT
	;-----------------------
	
	SETB FLAG_PISCA
	MOV INDICE, #0
RINC_CONT:	
	ACALL ROT_DISPLAY
	MOV N_STATE, #S_READY
	RET 					;retorna para o ctrl_fsm
	
	
;=========================================
;ROTINA DE DECREMENTAR
;=========================================	
ROT_DECREMENTAR:
	DEC INDICE
	CJNE INDICE, #255, RDEC_CONT
	MOV INDICE, #9
	SETB FLAG_PISCA
RDEC_CONT:
	ACALL ROT_DISPLAY
	MOV N_STATE, #S_READY
	RET						;retorna para o ctrl_fsm
	
	
;=========================================
;ROTINA DE ESPERA
;=========================================	
ROT_READY:
	JB FLAG_PISCA, JMP_PISCA
	JNB	K_SET, JMP_INCREMENTA
	JNB K_LOAD, JMP_DECREMENTA
	SJMP ROT_READY

JMP_INCREMENTA:
	JNB K_SET, $
	MOV N_STATE, #S_INCREMENTA	
	RET						;retorna para o ctrl_fsm

JMP_DECREMENTA:
	JNB K_LOAD, $
	MOV N_STATE, #S_DECREMENTA
	RET						;retorna para o ctrl_fsm
	
JMP_PISCA:
	MOV N_STATE, #S_PISCA
	RET						;retorna para o ctrl_fsm
	
	
	
;=========================================
;ROTINA DE DISPLAY
;=========================================	
ROT_DISPLAY:
	MOV DPTR, #NUM_ARRAY
	MOV A, INDICE 
	MOVC A, @A+DPTR
	MOV DISPLAY, A
	RET						;retorna para a rot_decrementa ou para a rot_incrementa


;=========================================
;ROTINA DE PISCAR
;=========================================
ROT_PISCAR:
	CLR FLAG_PISCA
	MOV A, DISPLAY
	MOV R5, #3
RPISCAR_CONT:
	MOV DISPLAY, #0FFH
	ACALL ROT_DELAY500
	MOV DISPLAY, A
	ACALL ROT_DELAY500
	DJNZ R5, RPISCAR_CONT
	MOV N_STATE, #S_READY
	RET						;retorna para o ctrl_fsm
	
	
	
/*	
;===================================================
;ROTINA DE DELAY DE 0.5 SEGUNDOS ->> versão timer 2
;===================================================
ROT_DELAY500:
	;guardar na stack o valor do acumulador e do psw pois durante esta rotina eles podem sofrer alterações
	PUSH ACC
	PUSH PSW

	;inicializar o valor de começo do timer 2
	MOV TMR2L, #LOW(-50000)
	MOV TMR2H, #HIGH(-50000)
	
	;inicilaizar o valor de reload do timer 2
	MOV TMR2RLL, #LOW(-50000)
	MOV TMR2RLH, #HIGH(-50000)
	
	MOV A, #0
	CLR TF2H	;limpar "overflow" do timer
	SETB TR2	;ativar o timer
DELAY_LOOP:
	JNB TF2H, $	;espera que o timer deia overflow
	CLR TF2H	;limpar "overflow" do timer
	INC A
	CJNE A, #40, DELAY_LOOP
	CLR TR2		;após o timer dar 40 reloads, é desativado

	;repor os valores do acumulador e do psw que estavam na stack
	POP PSW
	POP ACC
	RET			;retorna para a rot_piscar




;=====================================================================================
;ROTINA DE DELAY DE 0.5 SEGUNDOS ->> versão timer 1 no modo de 16 bits sem autoreload
;=====================================================================================
ROT_DELAY500:
	PUSH ACC
	PUSH PSW
	
	ORL CKCON, #00000010B
	MOV TMOD, #10H
	MOV A, #-10
	CLR C
DELAY_CONT:	
	CLR TF1
	MOV TL1, #LOW(-50000)
	MOV TH1, #HIGH(-50000)
	SETB TR1
	JNB TF1, $
	CLR TR1
	ADD A, #1
	JNC DELAY_CONT
	
	POP PSW
	POP ACC
	RET	



;=====================================================================================
;ROTINA DE DELAY DE 0.5 SEGUNDOS ->> versão timer 0 no modo de 8 bits com auto reload
;=====================================================================================
ROT_DELAY500:
	PUSH ACC
	PUSH PSW
	
	ORL CKCON, #2
	MOV TMOD, #2
	CLR TF0
	MOV TH0, #(-0FAH)
	MOV TL0, #(-0FAH)
	
	MOV R2, #7H
	MOV R3, #0D0H
	SETB TR0
	
DELAY_CONT:
	JNB TF0, $
	CLR TF0	

DEC_R3:
	MOV A, R3
	CLR C
	SUBB A, #1
	JC DEC_R2
	MOV R3, A
	JNC DELAY_CONT

DEC_R2:
	MOV R3, #0D0H
	MOV A, R2
	CLR C
	SUBB A, #1
	JC TERMINA_TIMER
	MOV R2, A
	JNC DELAY_CONT1
	
TERMINA_TIMER:
	CLR TR0
	
	POP PSW
	POP ACC
	RET*/
	

;=====================================================================================
;ROTINA DE DELAY DE 0.5 SEGUNDOS ->> versão timer 3 no modo de 16 bits com auto reload
;=====================================================================================
ROT_DELAY500:
	PUSH ACC
	PUSH PSW
	
	MOV R1, #50

	ANL TMR3CN, #00110110B
	MOV TMR3L, #LOW(-40000)
	MOV TMR3H, #HIGH(-40000)
	MOV TMR3RLL, #LOW(-40000)
	MOV TMR3RLH, #HIGH(-40000)
	ORL TMR3CN, #4
DELAY_CONT:
	MOV A, TMR3CN
	JNB ACC.7, DELAY_CONT    //NÃO É POSSÍVEL USAR O $
	ANL TMR3CN, #00111111B	
	DJNZ R1, DELAY_CONT
	ANL TMR3CN, #11111011B
	
	POP PSW
	POP ACC
	RET
	
	

;ARRAY DE NÚMEROS A APARECER NO DISPLAY
NUM_ARRAY: DB 0C0H, 0F9H, 0A4H, 0B0H, 99H, 92H, 82H, 0F8H, 80H, 98H

		
END	