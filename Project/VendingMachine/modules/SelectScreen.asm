; COMP2121
; Project - Vending Machine
;	
; Select Screen
;
; - screenFlag = SELECT
; -  
; - 
; - 


selectScreen:
	push temp
	in temp, SREG
	push temp

	do_lcd_command 0b00000001 		; clear display
    do_lcd_command 0b00000110 		; increment, no display shift
    do_lcd_command 0b00001110 		; Cursor on, bar, no blink
	
	do_lcd_data_i 'S' 
  	do_lcd_data_i 'e' 
	do_lcd_data_i 'l' 
  	do_lcd_data_i 'e' 
  	do_lcd_data_i 'c' 
  	do_lcd_data_i 't' 
  	do_lcd_data_i ' ' 
  	do_lcd_data_i 'i' 
  	do_lcd_data_i 't' 
  	do_lcd_data_i 'e' 
  	do_lcd_data_i 'm' 
  	do_lcd_data_i ' ' 
  	do_lcd_data_i ' '   
  	do_lcd_data_i ' ' 



  	EndSelect:
  	pop temp
  	out SREG, temp
  	pop temp
	ret