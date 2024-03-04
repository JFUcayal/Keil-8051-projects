#include <REG51F380.H>

DSEG AT 30H
	VAR_DELAY0: DS 1
	VAR_DELAY1: DS 1
	VAR_DELAY2: DS 1
	VAR_DELAY3: DS 1
		
	VAR_PISCAR0: DS 1
	VAR_PISCAR1: DS 1
		
BSEG AT 0H
	BUZZER_ON: 	 DBIT 1
	DELAY_START: DBIT 1
	PISCAR_ON:	 DBIT 1
	LIGAR:		 DBIT 1

CSEG AT 0H
	JMP INIT

; interrupt service routine timer 0
CSEG AT 0BH
	JMP ISR_TIMER0

CSEG AT 100H
INIT:
	;SYSCLK 48MHz
	MOV FLSCL,#90H	; ligar a flash sempre
	MOV CLKSEL,#3
	
	;WDT off e ligar Portos de I/O
	MOV PCA0MD,#0
	MOV XBR1,#40H
	
MAIN:
	;inicializar Stack
	MOV SP,#(0FFH-32)
	
	;inicializar as variáveis
	MOV VAR_DELAY0,#0
	MOV VAR_DELAY1,#0
	MOV VAR_DELAY2,#0
	MOV VAR_DELAY3,#0
	
	CLR BUZZER_ON
	CLR DELAY_START
	CLR PISCAR_ON
	CLR LIGAR
	
	; inicializar temporizador 0 - 8-bit autoreload
	MOV TMOD,#02H
	; T0M=0 e SCA[1:0]=10 => SYSCLK/48
	MOV CKCON,#2	;00000010B
	
	MOV TH0,#-250
	MOV TL0,#-250
	
	; permitir interrupção Timer 0
	SETB ET0		;enable interrupção timer 0 (TF0)
	SETB EA
MAINLOOP:
	;esperar que K_LOAD seja pressionado
	JB P0.7,$
	JNB P0.7,$
	CLR P2.7	;ligar dot point
	SETB TR0
	SETB BUZZER_ON
	
	;esperar que K_LOAD seja pressionado
	JB P0.7,$
	;esperar que K_LOAD seja libertado
	JNB P0.7,$
		
	SETB P2.7
	CLR BUZZER_ON
	
	MOV P2,#83H
	;esperar que K_LOAD seja pressionado
	JB P0.7,$
	;esperar que K_LOAD seja libertado
	JNB P0.7,$
	
	MOV VAR_DELAY0,#0C0H
	MOV VAR_DELAY1,#063H
	MOV VAR_DELAY2,#0FFH
	MOV VAR_DELAY3,#0FFH
	SETB DELAY_START
	
	SETB PISCAR_ON
	
	MOV VAR_PISCAR0,#030H
	MOV VAR_PISCAR1,#0F8H
	
	;esperar por fim do delay
	JB DELAY_START,$
	; passaram 20seg
	MOV P2,#0FFH
	CLR PISCAR_ON
	JMP $
	
	
	
	
	
ISR_TIMER0:
	;como só há uma flag nesta interrupção (TF0) ela é limpa por hardware (controlador de interrupções)
	USING 0
	PUSH ACC
	PUSH PSW
	
	JNB BUZZER_ON,ISR_TIMER0_CONT0
	CPL P1.0
	
ISR_TIMER0_CONT0:	
	JNB PISCAR_ON, ISR_TIMER0_CONT1
	
	MOV A, VAR_PISCAR0
	ADD A,#1
	MOV VAR_PISCAR0,A
	
	MOV A,VAR_PISCAR1
	ADDC A,#0
	MOV VAR_PISCAR1,A
	
	JNC ISR_TIMER0_CONT1
	
	MOV VAR_PISCAR0,#30H
	MOV VAR_PISCAR1,#0F8H
	CPL LIGAR
	JNB LIGAR, ISR_TIMER0_ESCREVER_B
	;apagar display
	MOV P2,#0FFH
	JMP ISR_TIMER0_CONT1
ISR_TIMER0_ESCREVER_B:
	MOV P2,#83H

ISR_TIMER0_CONT1:
	JNB DELAY_START, ISR_TIMER0_FIM
	
	MOV A,VAR_DELAY0
	ADD A,#1
	MOV VAR_DELAY0,A
	
	MOV A,VAR_DELAY1
	ADDC A,#0
	MOV VAR_DELAY1,A
	
	MOV A,VAR_DELAY2
	ADDC A,#0
	MOV VAR_DELAY2,A
	
	MOV A,VAR_DELAY3
	ADDC A,#0
	MOV VAR_DELAY3,A
	
	JNC ISR_TIMER0_FIM
	CLR DELAY_START
	
ISR_TIMER0_FIM:
	POP PSW
	POP ACC
	RETI
	
	
END