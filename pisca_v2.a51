#include <REG51F380.H>

CSEG AT 0H
    SJMP INIT
CSEG AT 50H
INIT:
    MOV PCA0MD, #0
    MOV XBR1, #40H
    MOV FLSCL, #90H
    MOV CLKSEL, #3
    MOV R7, #0FEH

ROT_DELAY1S:
    MOV CKCON, #2
    MOV TMOD, #1
    MOV A, #1
    CLR TF0
    SETB TR0

MLOOP_DELAY1:
    MOV TL0, #LOW(-20000)
    MOV TH0, #HIGH(-20000)
DELAY_CONT:
    MOV P2, R7
    ACALL ROT_DELAY5
    MOV P2, #0FFH
    ACALL ROT_DELAY5

    JNB TF0, DELAY_CONT
    CLR TF0

    DEC A
    JNZ MLOOP_DELAY1   

    ACALL ROT_LEFT
    SJMP ROT_DELAY1S

ROT_DELAY5:
    PUSH ACC
    PUSH PSW

    MOV TMR2L,#LOW(-40000)
    MOV TMR2H,#HIGH(-40000)
    MOV TMR2RLL,#LOW(-40000)
    MOV TMR2RLH,#HIGH(-40000)
    CLR TF2H
    SETB TR2
    MOV R4, #40  //205 ---255+1=0 +CARRY
	
MLOOP_DELAY5:
    JNB TF2H,$
    CLR TF2H
    DJNZ R4, MLOOP_DELAY5
    CLR TR2

    POP PSW
    POP ACC
    RET

ROT_LEFT:
    MOV A, R7
    RL A
    MOV R7, A

    CLR C
    SUBB A, #0BFH
    JZ LEFT_CONT
    RET
	
LEFT_CONT:
    MOV R7, #0FEH 
    RET

END