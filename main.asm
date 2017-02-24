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
WORD EQU 0x02
TIMES EQU 0x03
 
;VARIABLES LEDS
HORIZ EQU 0x04
LEDS_HZ EQU 0x05
RIGHT_NOTLEFT EQU 0x06
BLINK EQU 0x07
RES_DIV EQU 0x08
PAPANATES_L EQU 0x12
PAPANATES_H EQU 0x13
LEDS_10S EQU 0x14
 
WAIT EQU 0x09	    ;TEMPORAL

;VARIABLES BOTONS
F_REBOTS_LOAD EQU 0x0A
F_REBOTS_SEND EQU 0x0B
LOADED EQU 0x0C
SENT EQU 0x0D
 
N_SIZEL EQU 0x0E
N_SIZEH EQU 0x0F
INDEX EQU 0x10
N_LEDS EQU 0x11

 
;*************
;* CONSTANTS *
;*************
INIT_FSR0H EQU 0x00
INIT_FSR0L EQU 0x80
F_5HZ EQU 0x27
F_10HZ EQU 0x13
F_20HZ EQU 0x06
LOAD_BYTE EQU 0xAA
SEND_BYTE EQU 0xEE
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
    call INIT_TMR
    incf TIMES, 1, 0
    incf LEDS_HZ, 1, 0
    clrf WAIT, 0
    incf PAPANATES_L, 1, 0
    btfsc STATUS, C, 0
    incf PAPANATES_H, 1, 0
    retfie FAST

;*********
;* INITS *
;*********
	
INIT_VARS
    clrf SIZEH, 0
    clrf SIZEL, 0
    
    clrf HORIZ, 0
    clrf BLINK, 0
    
    clrf RIGHT_NOTLEFT, 0
    clrf LEDS_HZ, 0
    return
	
INIT_PORTS
    bsf TRISC, 7, 0
    bsf TRISC, 6, 0
    bcf TRISC, 2, 0
    bsf TRISC, 1, 0
    bsf TRISC, 0, 0
    bcf TRISB, 1, 0
    bcf TRISB, 0, 0
    clrf TRISD, 0
    clrf LATD, 0
    clrf LATB, 0
    return
    
INIT_INTS
    bcf RCON, IPEN, 0
    movlw 0xA0
    movwf INTCON, 0
    movlw 0x88
    movwf T0CON, 0
    return
    
INIT_EUSART
    movlw 0x26
    movwf TXSTA, 0
    movlw 0x90
    movwf RCSTA, 0
    movlw 0x81
    movwf SPBRG, 0
    clrf BAUDCON, 0
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
    call INIT_EUSART
    call INIT_TMR
	
BUCLE
    btfsc PIR1, RCIF, 0
    goto RX_PC
    tstfsz HORIZ
    goto LEDS_HORIZ
    tstfsz BLINK
    goto LEDS_BLINK
    tstfsz LEDS_10S
    goto LEDS_SEG
    
CHECK_LOAD_BTN
    btfsc PORTC, 1, 0
    goto LOAD_BTN
    clrf LOADED, 0
    
CHECK_LOAD_FLAG
    tstfsz LOADED, 0
    goto CHECK_SEND_BTN	
    tstfsz F_REBOTS_LOAD
    goto CHECK_LOAD_15MS
    goto CHECK_SEND_BTN

CHECK_LOAD_15MS
    movlw 0x02
    cpfsgt TIMES, 0
    goto CHECK_SEND_BTN
    clrf F_REBOTS_LOAD, 0
    btfss PORTC, 1, 0
    goto END_ALT_LOAD	    ;TEMP
    ;FES COSES CÀRREGA DE FRASE
    movlw SEND_BYTE
    movwf TXREG, 0
    setf LEDS_10S, 0
    clrf PAPANATES_L, 0
    clrf PAPANATES_H, 0
    clrf BLINK, 0
    ;FICOSES
    setf LOADED, 0
    goto CHECK_SEND_BTN
    
END_ALT_LOAD	    ;TEMP
    clrf LATD, 0    ;TEMP
    goto CHECK_SEND_BTN	;TEMP
        
LOAD_BTN
    tstfsz LOADED, 0
    goto CHECK_SEND_BTN	
    tstfsz F_REBOTS_LOAD
    goto CHECK_LOAD_15MS
    clrf TIMES, 0
    setf F_REBOTS_LOAD, 0
    goto CHECK_SEND_BTN
    
CHECK_SEND_BTN
    btfsc PORTC, 0, 0
    goto SEND_BTN
    clrf SENT, 0
    
CHECK_SEND_FLAG
    tstfsz SENT, 0
    goto BUCLE
    tstfsz F_REBOTS_SEND
    goto CHECK_SEND_15MS
    goto BUCLE

CHECK_SEND_15MS
    movlw 0x02
    cpfsgt TIMES, 0
    goto BUCLE
    clrf F_REBOTS_SEND, 0
    btfss PORTC, 0, 0
    goto END_ALT_SEND	;TEMP
    ;FES COSES ENVIAMENT DE FRASE
    setf LATD, 0
    ;FICOSES
    setf SENT, 0
    goto SEND_RF
    ;goto BUCLE
    
END_ALT_SEND	    ;TEMP
    clrf LATD, 0    ;TEMP
    goto BUCLE	    ;TEMP
        
SEND_BTN
    tstfsz SENT, 0
    goto BUCLE	
    tstfsz F_REBOTS_SEND
    goto CHECK_SEND_15MS
    clrf TIMES, 0
    setf F_REBOTS_SEND, 0
    goto BUCLE
    
RX_PC
    clrf LEDS_10S, 0
    clrf HORIZ, 0
    movlw INIT_FSR0L
    movwf FSR0L, 0
    movlw INIT_FSR0H
    movwf FSR0H, 0
    movff RCREG, WORD
    movlw LOAD_BYTE
    cpfseq WORD, 0
    goto SEND_MESSAGE
    clrf SIZEL, 0
    clrf SIZEH, 0

DEMANA_CHAR
    movlw SEND_BYTE
    movwf TXREG, 0	;DEMANEM MÉS CARÀCTERS
    btfss PIR1, RCIF, 0	;ESPEREM MÉS CARÀCTERS
    goto $-2
    
    movff RCREG, WORD
    movlw 0xFF
    cpfseq WORD, 0
    goto GUARDA_CHAR
    tstfsz BLINK    ;TEMPORAL
    goto END_ALT    ;TEMPORAL
    movlw F_5HZ
    movwf BLINK, 0
    clrf LATD, 0
    clrf LATB, 0
    setf TXREG, 0
    goto BUCLE
    
END_ALT		    ;TEMPORAL
    clrf LATD, 0    ;TEMPORAL
    clrf LATB, 0    ;TEMPORAL
    clrf BLINK, 0   ;TEMPORAL
    setf TXREG, 0   ;TEMPORAL
    goto BUCLE	    ;TEMPORAL
    
GUARDA_CHAR
    incf SIZEL, 1, 0
    btfsc STATUS, C, 0
    incf SIZEH, 1, 0
    movff WORD, POSTINC0
    goto DEMANA_CHAR
    
    
    ;comf HORIZ, 1, 0
    ;movlw 0x03
    ;btfss HORIZ, 0, 0
    ;movlw 0x00
    ;movwf LATD, 0
    ;clrf LATB, 0
    ;goto BUCLE
    
SEND_MESSAGE
    movlw SEND_BYTE
    movwf TXREG, 0	;ACK
    
SEND_RF
    tstfsz SIZEL, 0
    goto RF_OK
    tstfsz SIZEH, 0
    goto RF_OK
RF_KO
    movlw 0x03
    movwf LATD, 0
    clrf LATB, 0
    setf HORIZ, 0
    clrf BLINK, 0
    goto BUCLE
    
RF_OK
    call DIV_10
    clrf LATD, 0
    clrf LATB, 0
    clrf N_LEDS, 0
    ;goto BUCLE
    
SEND_RAM
    movlw INIT_FSR0H
    movwf FSR0H, 0
    movlw INIT_FSR0L
    movwf FSR0L, 0
    movff POSTINC0, WORD
    call RF_1
    rlcf WORD, 1, 0
    btfsc STATUS, C, 0
    goto ENVIA_TRAMA
    call RF_0
    
ENVIA_TRAMA
    movlw 0x01
    movwf INDEX, 0
    clrf N_SIZEL, 0
    clrf N_SIZEH, 0
    
CHECK_SIZE
    movf SIZEH, 0, 0
    cpfseq N_SIZEH, 0
    goto BUCLE_WORD
    movf SIZEL, 0, 0
    cpfslt N_SIZEL, 0
    goto END_ENVIA_TRAMA
    
BUCLE_WORD
    rlcf WORD, 1, 0
    btfss STATUS, C, 0
    goto SEND_0
    call RF_0
    call RF_1
    goto CHECK_WORD
    
SEND_0
    call RF_1
    call RF_0
    
CHECK_WORD
    incf INDEX, 1, 0
    movlw 0x08
    cpfseq INDEX, 0
    goto BUCLE_WORD
    clrf INDEX, 0
    incf N_SIZEL, 1, 0
    btfsc STATUS, C, 0
    incf N_SIZEH, 1, 0
    movff POSTINC0, WORD
    
    ;LEDS
    incf N_LEDS, 1, 0
    movf N_LEDS, 0, 0
    cpfseq RES_DIV, 0
    goto CHECK_SIZE
    btfss PORTD, 7, 0
    goto NEXT_LED
    bsf LATB, 7, 0
    rlncf LATB, 1, 0
    
NEXT_LED
    bsf LATD, 7, 0
    rlncf LATD, 1, 0
    clrf N_LEDS, 0
    ;FILEDS
    
    goto CHECK_SIZE
    
END_ENVIA_TRAMA
    call RF_0
    setf LATB, 0
    setf LATD, 0
    movlw F_10HZ
    movwf BLINK, 0
    goto BUCLE
    
RF_0
    setf WAIT, 0
    tstfsz WAIT, 0
    goto $-2
    bcf LATC, 2, 0
    return
    
RF_1
    setf WAIT, 0
    tstfsz WAIT, 0
    goto $-2
    bsf LATC, 2, 0
    return
    
LEDS_HORIZ
    movlw F_20HZ
    cpfsgt LEDS_HZ
    goto CHECK_LOAD_BTN
    tstfsz RIGHT_NOTLEFT
    goto MOVE_RIGHT

MOVE_LEFT
    clrf RIGHT_NOTLEFT
    btfsc PORTB, 1, 0
    goto MOVE_RIGHT
    rlcf LATD, 1, 0
    btfsc STATUS, C, 0
    rlcf LATB, 1, 0
    clrf LEDS_HZ, 0
    goto CHECK_LOAD_BTN
    
MOVE_RIGHT
    setf RIGHT_NOTLEFT
    btfsc PORTD, 0, 0
    goto MOVE_LEFT
    rrcf LATB, 1, 0
    rrcf LATD, 1, 0
    clrf LEDS_HZ, 0
    goto CHECK_LOAD_BTN
    
LEDS_BLINK
    movf BLINK, 0, 0
    cpfsgt LEDS_HZ
    goto CHECK_LOAD_BTN
    comf LATD, 1, 0
    comf LATB, 1, 0
    clrf LEDS_HZ, 0
    goto CHECK_LOAD_BTN
    
LEDS_SEG
    movlw 0xD0
    cpfseq PAPANATES_L, 0
    goto CHECK_LOAD_BTN
    movlw 0x07
    cpfseq PAPANATES_H, 0
    goto CHECK_LOAD_BTN
    clrf LEDS_10S, 0
    movlw 0x03
    movwf LATD, 0
    clrf LATB, 0
    setf HORIZ, 0
    clrf BLINK, 0
    goto CHECK_LOAD_BTN
    
DIV_10
    movf SIZEL, 0, 0
    addlw 0x02
    btfsc STATUS, C, 0
    incf SIZEH, 1, 0
    mullw 0x33
    movf PRODH, 0, 0
    btfsc SIZEH, 0, 0
    addlw 0x33
    movwf RES_DIV, 0
    rrcf RES_DIV, 1, 0
    return
    

;*******
;* END *
;*******
    END