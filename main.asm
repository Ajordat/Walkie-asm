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
HORIZ EQU 0x06
LEDS_HZ EQU 0x07
RIGHT_NOTLEFT EQU 0x08
BLINK EQU 0x09
N_CHAR EQU 0x0A
DIV EQU 0x0B
 
;*************
;* CONSTANTS *
;*************
INIT_FSR0H EQU 0x00
INIT_FSR0L EQU 0x80
F_10HZ EQU 0x13
F_5HZ EQU 0x27
F_20HZ EQU 0x06
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
    call INIT_TMR
    incf TIMES, 1, 0
    incf LEDS_HZ, 1, 0
    retfie FAST

;*********
;* INITS *
;*********
	
INIT_VARS
    clrf SIZEH, 0
    clrf SIZEL, 0
    
    clrf HORIZ, 0   ;HORIZ
    
    ;movlw F_5HZ
    ;movwf BLINK, 0  ;BLINK
    clrf BLINK, 0
    
    clrf RIGHT_NOTLEFT, 0
    clrf LEDS_HZ, 0
    return
	
INIT_PORTS
    bsf TRISC, 7, 0
    bsf TRISC, 6, 0
    bsf TRISC, 1, 0
    bsf TRISC, 0, 0
    bcf TRISB, 1, 0
    bcf TRISB, 0, 0
    clrf TRISD, 0
    ;movlw 0x03
    ;movwf LATD, 0   ;HORIZ
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
    goto BUCLE
    
LEDS_HORIZ
    movlw F_20HZ
    cpfsgt LEDS_HZ
    goto BUCLE
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
    goto BUCLE
    
MOVE_RIGHT
    setf RIGHT_NOTLEFT
    btfsc PORTD, 0, 0
    goto MOVE_LEFT
    rrcf LATB, 1, 0
    rrcf LATD, 1, 0
    clrf LEDS_HZ, 0
    goto BUCLE
    
LEDS_BLINK
    movlw BLINK
    cpfsgt LEDS_HZ
    goto BUCLE
    tstfsz PORTD, 0
    goto LEDS_OFF
    setf LATD, 0
    setf LATB, 0
    clrf LEDS_HZ, 0
    goto BUCLE

LEDS_OFF
    clrf LATD, 0
    clrf LATB, 0
    clrf LEDS_HZ, 0
    goto BUCLE
    
DIV_10
    movf N_CHAR, 0, 0
    addlw 0x01
    btfsc STATUS, C, 0
    addlw 0xFF
    mullw 0x33
    rrcf PRODH, 0, 0
    movwf DIV, 0
    
RX_PC
    movf RCREG, 0, 0
    comf HORIZ, 1, 0
    movlw 0x03
    btfss HORIZ, 0, 0
    movlw 0x00
    movwf LATD, 0
    clrf LATB, 0
    goto BUCLE
    
WAIT
    goto WAIT

;*******
;* END *
;*******
    END