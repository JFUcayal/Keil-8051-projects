#include <REG51F380.H>

CSEG AT 0
	SJMP INIT
CSEG AT 30H
	INIT:
		MOV PCA0MD,#0 ;desliga o watch dog timer
		MOV XBR1,#40H ;ativa os portos- inicialmente em IDLE
	MAIN:
		MOV P2,#255
		CLR C
		MOV A,P2
	M_LOOP:
		RLC A
		MOV P2,A
		SJMP M_LOOP
END