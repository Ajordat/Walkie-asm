	LIST P=18F4321, F=INHX32
	#include <P18F4321.INC>	

;******************
;* CONFIGURACIONS *
;******************
	CONFIG	OSC = HSPLL          
	CONFIG	PBADEN = DIG
	CONFIG	WDT = OFF

;*************
;* VARIABLES *
;*************

    SIZEH EQU 0x00
    SIZEL EQU 0x01


;*************
;* CONSTANTS *
;*************
    INIT_FSR0H EQU 0x00
    INIT_FSR0L EQU 0x80
    LOAD_CONST EQU 0xFF
    SEND_BYTE EQU 0xFF
    END_BYTE EQU 0xFF

;*********************************
; VECTORS DE RESET I INTERRUPCIÓ *
;*********************************
	ORG 0x000000
RESET_VECTOR
	goto MAIN		

	ORG 0x000008
HI_INT_VECTOR
	goto HIGH_INT	

	ORG 0x000018
LOW_INT_VECTOR
	retfie FAST	

;***********************************
;* RUTINES DE SERVEI D'INTERRUPCIÓ *
;***********************************
HIGH_INT
	;codi de interrupció
	retfie	FAST

;********
;* MAIN *
;********

MAIN
	call INIT_VARS
	call INIT_PORTS
	call INIT_INTS
	
BUCLE
	btfsc PIR1, RCIF, 0
	goto RX
	
CHECK_LOAD_BTN
    btfsc PORTC, 1, 0
    goto LOAD_BTN
    CLRF LOADED, 0
    
CHECK_SEND_BTN
    btfsc PORTC, 0, 0
    goto SEND_BTN
    clrf SENT, 0
    goto BUCLE	;AQUÍ FALTA EL TRACTAMENT DELS LEDS
    
RX
    movff RCREG, WORD
    movlw LOAD_CONST
    cpfseq WORD, 0
    goto SEND_MESSAGE
    goto LOAD_MESSAGE
    
SEND_MESSAGE
    
LOAD_MESSAGE
    movlw INIT_FSR0H
    movwf FSR0H, 0
    movlw INIT_FSR0L
    movwf FSR0L, 0
    
    clrf SIZEH, 0
    clrf SIZEL, 0
    
    movlw SEND_BYTE
    movwf TXREG, 0
    
READ_MESSAGE
    btfss PIR1, RCIF, 0
    goto $-2
    movff RCREG, WORD
    
    movlw END_BYTE
    cpfseq WORD, 0
    goto $+6
    goto BUCLE
    
    incf SIZEL, 1, 0
    btfsc STATUS, C, 0
    incf SIZEH, 1, 0
    
    movff WORD, POSTINC0
    movlw SEND_BYTE
    movwf TXREG, 0
    goto READ_MESSAGE
    

;*******
;* END *
;*******
	END