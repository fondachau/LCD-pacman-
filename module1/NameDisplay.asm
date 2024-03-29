; LCD_test_4bit.asm: Initializes and uses an LCD in 4-bit mode
; using the most common procedure found on the internet.
$NOLIST
$MODLP52
$LIST

org 0000H
    ljmp myprogram

org 001bH
    ljmp 181bH

; These 'equ' must match the hardware wiring
LCD_RS equ P1.4
LCD_RW equ P1.5 ; Not used in this code
LCD_E  equ P1.6
LCD_D4 equ P3.2
LCD_D5 equ P3.3
LCD_D6 equ P3.4
LCD_D7 equ P3.5

; When using a 22.1184MHz crystal in fast mode
; one cycle takes 1.0/22.1184MHz = 45.21123 ns

;---------------------------------;
; Wait 40 microseconds            ;
;---------------------------------;
Wait40uSec:
    push AR0
    mov R0, #177
L0:
    nop
    nop
    djnz R0, L0 ; 1+1+3 cycles->5*45.21123ns*177=40us
    pop AR0
    ret

;---------------------------------;
; Wait 'R2' milliseconds          ;
;---------------------------------;
WaitmilliSec:
    push AR0
    push AR1
L3: mov R1, #45
L2: mov R0, #166
L1: djnz R0, L1 ; 3 cycles->3*45.21123ns*166=22.51519us
    djnz R1, L2 ; 22.51519us*45=1.013ms
    djnz R2, L3 ; number of millisecons to wait passed in R2
    pop AR1
    pop AR0
    ret

;---------------------------------;
; Toggles the LCD's 'E' pin       ;
;---------------------------------;
LCD_pulse:
    setb LCD_E
    lcall Wait40uSec
    clr LCD_E
    ret

;---------------------------------;
; Writes data to LCD              ;
;---------------------------------;
WriteData:
    setb LCD_RS
    ljmp LCD_byte

;---------------------------------;
; Writes command to LCD           ;
;---------------------------------;
WriteCommand:
    clr LCD_RS
    ljmp LCD_byte

;---------------------------------;
; Writes acc to LCD in 4-bit mode ;
;---------------------------------;
LCD_byte:
    ; Write high 4 bits first
    mov c, ACC.7
    mov LCD_D7, c
    mov c, ACC.6
    mov LCD_D6, c
    mov c, ACC.5
    mov LCD_D5, c
    mov c, ACC.4
    mov LCD_D4, c
    lcall LCD_pulse

    ; Write low 4 bits next
    mov c, ACC.3
    mov LCD_D7, c
    mov c, ACC.2
    mov LCD_D6, c
    mov c, ACC.1
    mov LCD_D5, c
    mov c, ACC.0
    mov LCD_D4, c
    lcall LCD_pulse
    ret

;---------------------------------;
; Configure LCD in 4-bit mode     ;
;---------------------------------;
LCD_4BIT:
    clr LCD_E   ; Resting state of LCD's enable is zero
    clr LCD_RW  ; We are only writing to the LCD in this program

    ; After power on, wait for the LCD start up time before initializing
    ; NOTE: the preprogrammed power-on delay of 16 ms on the AT89LP52
    ; seems to be enough.  That is why these two lines are commented out.
    ; Also, commenting these two lines improves simulation time in Multisim.
    ; mov R2, #40
    ; lcall WaitmilliSec

    ; First make sure the LCD is in 8-bit mode and then change to 4-bit mode
    mov a, #0x33
    lcall WriteCommand
    mov a, #0x33
    lcall WriteCommand
    mov a, #0x32 ; change to 4-bit mode
    lcall WriteCommand

    ; Configure the LCD
    mov a, #0x28
    lcall WriteCommand
    mov a, #0x0c
    lcall WriteCommand
    mov a, #0x01 ;  Clear screen command (takes some time)
    lcall WriteCommand

    ;Wait for clear screen command to finish. Usually takes 1.52ms.
    mov R2, #2
    lcall WaitmilliSec
    ret

;---------------------------------;
; Main loop.  Initialize stack,   ;
; ports, LCD, and displays a      ;
; letter on the LCD              ;
;---------------------------------;
myprogram:
    mov SP, #7FH
    mov PMOD, #0 ; Configure all ports in bidirectional mode
    lcall LCD_4BIT
    lcall SetPACMAN ; set the pacman into CGRAM

GO:
    MOV a, #0x80
    LCALL WriteCommand
    MOV DPTR, #MyName
    lcall GetName ;PRINT FONDA CHAU

    MOV a, #0xC0
    LCALL WriteCommand
    MOV DPTR, #MYSTUDENTNUMBER
    lcall GetName ;PRINT 15954143
    JB p1.0,$
    JNB p1.0, $
    lcall WaitHalfSec
	mov R5, #0x80 ;pacman line one start position
	mov R6, #0xA ;number of times pacman eats
GOPACMAN1:
	lcall Eat 
	inc R5  ;R5=R5+1
    djnz R6, GOPACMAN1 ;if not done R6 times, then go do again
    mov R5, #0xC0 ;reseting pacman for line 2
    mov R6, #0x8 ;number of times pacman eats
GOPACMAN2:
	lcall Eat
	inc R5 ;R5=R5+1
    djnz R6, GOPACMAN2 ;if not done R6 times, then go do again
	ljmp GO    ;reseting name and eating again

forever:
    sjmp forever

WaitHalfSec:
    mov R2, #89
LA: mov R1, #250
LB: mov R0, #166
LC: djnz R0, LC ; 3 cycles->3*45.21123ns*166=22.51519us
    djnz R1, LB ; 22.51519us*250=5.629ms
    djnz R2, LA ; 5.629ms*89=0.5s (approximately)
cpl P3.7
    ret

Eat:
	mov a, R5 ; Move cursor 
    lcall WriteCommand
    
	mov a, #0x0 ;setpacman
    lcall WriteData
    lcall WaitHalfSec
	    
	mov a, R5 ; Move cursor 
    lcall WriteCommand
    
	mov a, #0x1 ;set pacman eating it
    lcall WriteData
    lcall WaitHalfSec
	
	mov a, R5 ; Move cursor 
    lcall WriteCommand
    
	mov a, #0x2 ;clear because pacman already ate it
    lcall WriteData
    lcall WaitHalfSec
ret    

SetPACMAN:
	mov a, #0x40 ;pacman face
    lcall WriteCommand
    mov a, #0x0e
    lcall WriteData  
    mov a, #0x1f
    lcall WriteData 
    mov a, #0x1e 
    lcall WriteData
    mov a, #0x1c
    lcall WriteData 
    mov a, #0x1e
    lcall WriteData
    mov a, #0x1f 
    lcall WriteData
    mov a, #0x0e   
    lcall WriteData
    mov a, #0x00
    lcall WriteData
    
    mov a, #0x0e ;pacman eating face
    lcall WriteData  
    mov a, #0x1f
    lcall WriteData 
    mov a, #0x1f 
    lcall WriteData
    mov a, #0x1f
    lcall WriteData 
    mov a, #0x1f
    lcall WriteData
    mov a, #0x1f 
    lcall WriteData
    mov a, #0x0e
    lcall WriteData 
    mov a, #0x00
    lcall WriteData 
     
    mov a, #0x00 ; clear
    lcall WriteData 
    mov a, #0x00 
    lcall WriteData
    mov a, #0x00
    lcall WriteData 
    mov a, #0x00
    lcall WriteData
    mov a, #0x00 
    lcall WriteData
    mov a, #0x00
    lcall WriteData 
    mov a, #0x00
    lcall WriteData 
    mov a, #0x00
    lcall WriteData 
	ret
MyName:
	DB 'FONDA CHAU', 0
MYSTUDENTNUMBER:
	DB '15954143',0

GetName:
	CLR a
	MOVC a, @a+dptr
	jz DONE1
	LCALL WriteData
	INC DPTR
	SJMP GetName
	
DONE1: ret

END
