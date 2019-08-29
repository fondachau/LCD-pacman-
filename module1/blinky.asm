; Blinky.asm: toggles an LED attached to pin 17 (P3.7)
$MODLP52

org 0000H
    ljmp myprogram

org 001BH
	ljmp 0x181b

; When using a 22.1184MHz crystal in fast mode
; one cycle takes 1.0/22.1184MHz = 45.21123 ns
WaitHalfSec:
    mov R2, #89
L3: mov R1, #250
L2: mov R0, #166
L1: djnz R0, L1 ; 3 cycles->3*45.21123ns*166=22.51519us
    djnz R1, L2 ; 22.51519us*250=5.629ms
    djnz R2, L3 ; 5.629ms*89=0.5s (approximately)
    ret

;---------------------------------;
; Wait 'R2' milliseconds          ;
;---------------------------------;
Wait_Milli_Seconds mac
	push AR2
	mov R2, %0
	lcall ?Wait_Milli_Seconds
	pop AR2
endmac

?Wait_Milli_Seconds:
	push AR0
	push AR1
q3: mov R1, #45
q2: mov R0, #166
q1: djnz R0, q1 ; 3 cycles->3*45.21123ns*166=22.51519us
    djnz R1, q2 ; 22.51519us*45=1.013ms
    djnz R2, q3 ; number of millisecons to wait passed in R2
    pop AR1
    pop AR0
    ret
	
myprogram:
    mov SP, #7FH
    mov PMOD, #0 ; Configure all ports in bidirectional mode
M0:
	setb P0.0
	wait_milli_seconds(#1)
	clr P0.0
	wait_milli_seconds(#19)
	jb P2.4, M0
	jnb P2.4, $
	wait_milli_seconds(#50)
M1:
	setb P0.0
	wait_milli_seconds(#3)
	clr P0.0
	wait_milli_seconds(#17)
    jb P2.4, M1
    jnb P2.4, $
    wait_milli_seconds(#50)
    sjmp M0
END