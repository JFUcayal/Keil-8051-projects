#include <REG51F380.H>

CSEG  AT 0					;Coloca a prox. instrução no endereço 0H da memoria de código->ROM
	JMP INIT				
CSEG AT 50H					;Coloca a prox. instrução no endereço 50H da memoria de código->ROM
	INIT:
		MOV XBR1,#40H		;Ativa os ports que inicialmente se encontram em IDLE
		MOV PCA0MD,#0		;Desliga o watch dog timer
		JMP MAIN			
	MAIN:
	BA1:
		MOV R1,#20H			;inicialização do array em que o endereço-apontador R1 toma o primeiro valor de 20H
		MOV 20H,#0C0H		;20H = 0
		MOV 21H,#0F9H		;21H = 1
		MOV 22H,#0A4H		;22H = 2
		MOV 23H,#0B0H		;23H = 3
		MOV 24H,#99H		;24H = 4
		MOV 25H,#92H		;25H = 5
		MOV 26H,#82H		;26H = 6
		MOV 27H,#0D8H		;27H = 7
		MOV 28H,#80H		;28H = 8
		MOV 29H,#90H		;29H = 9
		MOV 2AH,#88H		;2AH = A
		MOV 2BH,#80H		;2BH = B
		MOV 2CH,#0C6H		;2CH = C
		MOV 2DH,#0C0H		;2DH = D
		MOV 2EH,#86H		;2EH = E
		MOV 2FH,#8EH		;2FH = F
	BA2:
		MOV P2,@R1			;update no display-P2 que passa por endereço indireto o valor de R1 
	BD1:
		JNB P0.6,BD3		;se o bit 6 de P0 estiver a 0 entao salta para o BD3-bloco de decisao 3
		JMP BD1				;saltar para o BD1 se a condição anterior nao se verificar
	BD3:
		JNB P0.6,BD3		
		JMP BA3				;saltar para o BA3-bloco de atribuição 3 se a condição anterior nao se verificar
	BA3:
		INC R1				;incrementar R1 <=> ADD R1,#1
	BD2:
		MOV A,R1			;passar o valor de R1 para o acumulador
		CLR C				;limpar o carry
		SUBB A,#30H			;subtrair 30H=17 ao valor do acumulador 
		JZ BA4				;se a subtração der 0 flag->JUMP ZERO salta para o BA4
		JMP BA2				;saltar para o BA2 se a condição anterior nao se verificar
	BA4:
		MOV R1,#20H			;dá reset ao array e faz com que o apontador R1 volte para a posição 0->20H  
		JMP BA2				;salta par o BA2->dar update no display
END	
		