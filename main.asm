    LIST P=18F4321, F=INHX32
    #include <P18F4321.INC>	

;******************
;* CONFIGURACIONS *
;******************
    CONFIG OSC = HSPLL          
    CONFIG PBADEN = DIG
    CONFIG WDT = OFF

;*************
;* VARIABLES *
;*************

SIZEH EQU 0x00
SIZEL EQU 0x01
LOADED EQU 0x02
SENT EQU 0x03
WORD EQU 0x04
TIMES EQU 0x05

;*************
;* CONSTANTS *
;*************
INIT_FSR0H EQU 0x00
INIT_FSR0L EQU 0x80
F_10HZ EQU 0x14
F_5HZ EQU 0x28
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
    incf TIMES, 1, 0
    
    retfie FAST

;*********
;* INITS *
;*********
	
INIT_VARS
    clrf SIZEH, 0
    clrf SIZEL, 0
    return
	
INIT_PORTS
    bsf TRISC, 7, 0
    bsf TRISC, 6, 0
    bsf TRISC, 1, 0
    bsf TRISC, 0, 0
    bcf TRISB, 1, 0
    bcf TRISB, 0, 0
    clrf TRISD, 0
    clrf LATD, 0
    return
    
INIT_INTS
    ;bcf RCON, IPEN, 0
    ;movlw 0xA0
    ;movwf INTCON, 0
    ;movlw 0x88
    ;movwf T0CON, 0
    movlw 0x26
    movwf TXSTA, 0
    movlw 0x90
    movwf RCSTA, 0
    clrf BAUDCON, 0
    bsf BAUDCON, 1, 0
    movlw 0x81
    movwf SPBRG, 0
    clrf LATD, 0
    return
    
INIT_TMR
    movlw 0x3C
    movwf TMR0H, 0
    movlw 0xB0
    movwf TMR0L, 0
    bcf INTCON, TMR0IF
    return
	
;********
;* MAIN *
;********

MAIN
    call INIT_VARS
    call INIT_PORTS
    call INIT_INTS
    ;call INIT_TMR
	
BUCLE
    btfsc PIR1, RCIF, 0
    goto RX_PC
    goto BUCLE	;ADDED
WAIT
    goto WAIT
    
    ;COM CONY ESTAN SOLDATS ELS POLSADORS??
CHECK_LOAD_BTN
    btfsc PORTC, 1, 0
    ;goto LOAD_BTN
    setf LATD, 0
    clrf LOADED, 0
    goto BUCLE
    
CHECK_SEND_BTN
    btfsc PORTC, 0, 0
    ;goto SEND_BTN
    clrf LATD, 0
    clrf SENT, 0
    goto BUCLE	;AQUÍ FALTA EL TRACTAMENT DELS LEDS
    
CHECK_LEDS
    movlw F_10HZ
    cpfsgt TIMES, 0
    goto BUCLE
    movlw F_5HZ
    cpfsgt TIMES, 0
    goto LEDS_10HZ
    goto LEDS_5HZ
    
LEDS_10HZ
    
LEDS_5HZ
    
RX_PC
    ;setf LATD, 0
    movff RCREG, LATD
    goto BUCLE
    
    movlw LOAD_CONST
    
    cpfseq WORD, 0
    ;goto SEND_MESSAGE
    goto BUCLE ;ADDED
    goto LOAD_MESSAGE
    
SEND_BTN
    
SEND_MESSAGE
    
LOAD_BTN
    
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
    goto READ_MESSAGE
    movff RCREG, WORD
    
    movlw END_BYTE
    cpfseq WORD, 0
    goto CONT
    goto BUCLE

CONT
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