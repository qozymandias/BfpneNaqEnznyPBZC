.equ inStart =  1
.equ inSelect = 2
.equ inCoin = 3
.equ inEmpty = 4
.equ inDeliver = 5

.def currFlag = r5
.def oldFlag = r6
.def keyPress = r7
.def keyID = r8
.def ledVal = r9

.def row = r16
.def col = r17
.def rmask = r18                ; mask for row
.def cmask = r19                ; mask for column
.def temp = r20
.def temp1 = r21

								;we have up to and including r25

.dseg 
LEDCounter:
    .byte 2             ; Temporary counter. Counts milliseconds
DisplayCounter:
    .byte 2             ; counts number of milliseconds for displays.
Inventory:
	.byte 9
Cost:
	.byte 9	

.cseg
.org 0x0000
   jmp RESET
   jmp DEFAULT          ; No handling for IRQ0.
   jmp DEFAULT          ; No handling for IRQ1.
.org OVF0addr
   jmp Timer0OVF        ; Jump to the interrupt handler for timer 0


jmp DEFAULT          ; default service for all other interrupts.
DEFAULT:  reti          ; no service

.include "m2560def.inc"
.include "modules/macros.asm"
.include "modules/lcd.asm"
.include "modules/timer0.asm"
.include "modules/keypad.asm"


RESET: 

	ldi temp1, high(RAMEND) 		; Initialize stack pointer
	out SPH, temp1
	ldi temp1, low(RAMEND)
	out SPL, temp1
	ldi temp1, PORTLDIR
	sts DDRL, temp1				; sets lower bits as input and upper as output

	rcall InitArrays				; initializes the Cost & Inventory arrays with appropriate values

	ser temp1 					; set Port C,G & D as output - reset all bits to 0 (ser = set all bits in register)
	out DDRC, temp1 
	out DDRG, temp1 
	out DDRD, temp1 

    ldi temp, PORTLDIR
    sts DDRL, temp            		; sets lower bits as input and upper as output

    ser r16
    out DDRF, r16
    out DDRA, r16
    clr r16
    out PORTF, r16
    out PORTA, r16              	; setting PORTA & PORTF as output

	ser temp 						; set Port C as output - reset all bits to 0 (ser = set all bits in register)
	out DDRC, temp 

    do_lcd_command 0b00111000 		; 2x5x7 (2 lines, 5x7 is the font)
    rcall sleep_5ms
    do_lcd_command 0b00111000 		; 2x5x7
    rcall sleep_1ms
    do_lcd_command 0b00111000 		; 2x5x7
    do_lcd_command 0b00111000 		; 2x5x7
    do_lcd_command 0b00001000 		; display off?
    do_lcd_command 0b00000001 		; clear display
    do_lcd_command 0b00000110 		; increment, no display shift
    do_lcd_command 0b00001110 		; Cursor on, bar, no blink

	set_reg currFlag, inStart
	clr oldFlag
	clear DisplayCounter

    ldi temp, 0b00000000
    out TCCR0A, temp
    ldi temp, 0b00000010
    out TCCR0B, temp        ; Prescaling value=8
    ldi temp, 1<<TOIE0      ; = 128 microseconds
    sts TIMSK0, temp        ; T/C0 interrupt enable
	sei

	//rcall initArrays


main:

	cp currFlag, oldFlag
	brne update				; screen update needed 
	
	ldi temp, 0xFF
	cp keyPress, temp
	brne end				; if key not pressed no update needed 
							; else if is pressed then one of the screens might need updating
	update:
	mov oldFlag, currFlag	; update flags

	mov temp, currFlag
	out PORTC, currFlag

	cpi temp, inStart		; checking which screen to update to
	brne checkSelect
	rcall startScreen
checkSelect:
	cpi temp, inSelect
	brne checkEmpty
	rcall selectScreen		; TODO tell Oscar to add stuff to it 
checkEmpty:
	cpi temp, inEmpty
	brne checkCoin
	rcall emptyScreen
checkCoin:
	cpi temp, inCoin
	brne end
	rcall coinScreen

checkDeliver:				; !!!  untested - deliver screen  !!!
	cpi temp, inDeliver
	brne end
	rcall deliverScreen
	
end:
	rjmp init_loop

start_to_select:
    push temp
    in temp, SREG
    push temp

    mov temp, currFlag
    cpi temp, inStart              ; checking whether the start screen is open
    brne endF 
                                ; not in start screen, so keep going
    
    set_reg currFlag, inSelect
	clr_reg keyPress					; ignore this key press
	rjmp endF

empty_to_select:
    push temp
    in temp, SREG
    push temp

    mov temp, currFlag
    cpi temp, inEmpty              ; checking whether the empty screen is open
    brne endF 
									; not in empty screen, so keep going
    
    set_reg currFlag, inSelect
	clr_reg keyPress					; ignore this key press

    endF:
    pop temp
    out SREG, temp
    pop temp
    ret 


deliver_to_select:
	push temp
    in temp, SREG
    push temp

    mov temp, currFlag
    cpi temp, inDeliver		; checks whether in deliver screen
    brne endF 
									
    set_reg currFlag, inSelect	; change screens
	    
    mov temp, 0
    out PORTE, temp 		; turn off moter 

    endF:
    pop temp
    out SREG, temp
    pop temp
    ret 


.include "modules/AdminScreen.asm"
.include "modules/CoinReturn.asm"
.include "modules/CoinScreen.asm"
.include "modules/DeliverScreen.asm"
.include "modules/EmptyScreen.asm"
.include "modules/SelectScreen.asm"
.include "modules/StartScreen.asm"

testArray:
	ldi r24, 1
    ldi temp1, 0
    set_element r24,Inventory, temp1
	ldi r24, 2
    ldi temp1, 0
    set_element r24,Inventory, temp1
	ldi r24, 3
    ldi temp1, 0
    set_element r24,Inventory, temp1
	ldi r24, 4
    ldi temp1, 0
    set_element r24,Inventory, temp1
	ldi r24, 5
    ldi temp1, 0
    set_element r24,Inventory, temp1
	ldi r24, 6
    ldi temp1, 0
    set_element r24,Inventory, temp1
	ldi r24, 7
    ldi temp1, 7
    set_element r24,Inventory, temp1
	ldi r24, 8
    ldi temp1, 8
    set_element r24,Inventory, temp1
	ldi r24, 9
    ldi temp1, 9
    set_element r24,Inventory, temp1
	ret

initArrays:
	push temp
	in temp, SREG
	push temp
	push temp1
	
	ldi temp1, 1

	loop:
	cpi temp1, 10
	breq endLoop
	mov r16, temp1
	set_element temp1 ,Inventory, r16
	rcall odd_or_even
	set_element temp1 ,Cost, temp
	inc temp1
	rjmp loop

	endLoop:
	pop temp1
	pop temp
	out SREG, temp
	pop temp
	ret


odd_or_even:
    push temp1
    in temp, SREG
    //push temp

    /*
        9 ->       1 0 0 1
        1 ->     & 0 0 0 1
                   -------
                   0 0 0 1

        14 ->      1 1 1 0
        1 ->     & 0 0 0 1
                   -------
                   0 0 0 0          
    */
                
    andi temp1, 1                   
    cpi temp1, 0
    breq even
    cpi temp1, 1
    breq odd

    even:
        ldi temp, 2
        rjmp endOop
    odd: 
        ldi temp, 1

	endOop:
    //pop temp
    out SREG, temp
    pop temp1
	ret








