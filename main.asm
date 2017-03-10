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

SIZEH EQU 0x00	;DUES VARIABLES PER SABER QUANTES LLETRES TENIM
SIZEL EQU 0x01
WORD EQU 0x02	;VARIABLE PER A LLEGIR LA TRANSMISSIÓ REBUDA
TIMES EQU 0x03	;VARIABLE PER A CONTROLAR EL REBOT DELS POLSADORS
 
;VARIABLES LEDS
HORIZ EQU 0x04		;QUAN ESTÀ ACTIVA REALITZA LA RUTINA DE "ROTACIÓ" DELS LEDS
LEDS_HZ EQU 0x05	;VARIABLE PER A CONTROLAR LA FREQÜÈNCIA DELS LEDS
RIGHT_NOTLEFT EQU 0x06	;INDICA EL SENTIT DE LA ROTACIÓ DELS LEDS 
BLINK EQU 0x07		;VARIABLE PER A CONTROLAR LA FREQÜÈNCIA DELS LEDS
RES_DIV EQU 0x08	;EMMAGATZEMEM EL RESULTAT DE LA DIVISIÓ PER 10
SEG_L EQU 0x12		;DUES VARIABLES PER A SABER EL TEMPS DELS 10 SEGONS
SEG_H EQU 0x13
LEDS_10S EQU 0x14	;FLAG PER A SABER SI HEM D'ESTAR PENDENTS DELS 10 SEGONS
 
WAIT EQU 0x09	;FLAG PER A ESPERAR A LA INTERRUPCIÓ PER LA TRANSMISSIÓ RF

;VARIABLES BOTONS
F_REBOTS_LOAD EQU 0x0A	;FLAG PELS REBOTS DEL BOTÓ DE LOAD
F_REBOTS_SEND EQU 0x0B	;FLAG PELS REBOTS DEL BOTÓ DE SEND
LOADED EQU 0x0C	    ;FLAG PER SABER SI S'HA FET L'ACCIÓ DE CARREGAR 
SENT EQU 0x0D	    ;FLAG PER SABER SI S'HA FET L'ACCIÓ D'ENVIAR 
 
N_SIZEL EQU 0x0E    ;DUES VARIABLES PER A SABER QUANTES LLETRES PORTEM ENVIADES
N_SIZEH EQU 0x0F    
INDEX EQU 0x10	    ;VARIABLE PER SABER QUANTS BITS D'UNA PARAULA HEM ENVIAT
N_LEDS EQU 0x11	    ;VARIABLE PER SABER QUAN HEM D'ACTIVAR UN NOU LED DURANT LA TX DE RF

 
;*************
;* CONSTANTS *
;*************
INIT_FSR0H EQU 0x00 ;VALOR DE FSR0H A L'INICI DE L'ARRAY 
INIT_FSR0L EQU 0x80 ;VALOR DE FSR0L A L'INICI DE L'ARRAY
F_5HZ EQU 0x27	    ;NOMBRE DE COPS QUE HA DE SALTAR LA INTERRUPCIÓ PER A QUE HAGI PASSAT UN PERÍODE DE 5HZ
F_10HZ EQU 0x13	    ;NOMBRE DE COPS QUE HA DE SALTAR LA INTERRUPCIÓ PER A QUE HAGI PASSAT UN PERÍODE DE 10HZ
F_20HZ EQU 0x06	    ;NOMBRE DE COPS QUE HA DE SALTAR LA INTERRUPCIÓ PER A QUE HAGI PASSAT UN PERÍODE DE 20HZ
LOAD_BYTE EQU 0xAA  ;BYTE QUE S'ENVIA DEL PC A LA PIC PER A INDICAR QUE S'HA DE CARREGAR A LA RAM. EQUIVALENT A UN SYN.
SEND_BYTE EQU 0xEE  ;BYTE QUE S'ENVIA DE LA PIC AL PC PER A DEMANAR UN BYTE MÉS DE LA CADENA. EQUIVALENT A UN ACK.
END_BYTE EQU 0xFF   ;BYTE QUE S'ENVIA DEL PC A LA PIC PER A INDICAR QUE JA S'HA ENVIAT TOTA LA CADENA. EQUIVALENT A UN FIN.
SEG_10_H EQU 0x07   ;NOMBRE DE COPS QUE HA DE SALTAR LA INTERRUPCIÓ PER A QUE PASSIN 10 SEGONS (PART ALTA)
SEG_10_L EQU 0xD0   ;NOMBRE DE COPS QUE HA DE SALTAR LA INTERRUPCIÓ PER A QUE PASSIN 10 SEGONS (PART BAIXA)
 
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

    ;* 
    ; *   A LA INTERRUPCIÓ TORNEM A INICIAR EL TIMER PER A QUE TORNI A SALTAR AQUESTA, FIQUEM A 0 EL FLAG WAIT I 
    ; *   INCREMENTEM ELS COMPTADORS QUE S'UTILITZEN A LES SEGÜENTS FUNCIONALITATS: CONTROLAR ELS REBOTS, CONTROLAR LA
    ; *   FREQÜÈNCIA DELS LEDS I ESPERAR 10 SEGONS
    ; */
HIGH_INT
    call INIT_TMR
    incf TIMES, 1, 0
    incf LEDS_HZ, 1, 0
    clrf WAIT, 0
    incf SEG_L, 1, 0
    btfsc STATUS, C, 0
    incf SEG_H, 1, 0
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
    bsf TRISC, 7, 0 ;SIO_RX	INPUT
    bsf TRISC, 6, 0 ;SIO_TX	INPUT
    bcf TRISC, 2, 0 ;RF		OUTPUT
    bsf TRISC, 1, 0 ;LOAD_BTN	INPUT
    bsf TRISC, 0, 0 ;SEND_BTN	INPUT
    bcf TRISB, 1, 0 ;LEDS[9]	OUTPUT
    bcf TRISB, 0, 0 ;LEDS[8]	OUTPUT
    clrf TRISD, 0   ;LEDS[7..0]	OUTPUT
    
    clrf LATD, 0    ;APAGUEM ELS LEDS
    clrf LATB, 0
    
    return
    
INIT_INTS
    bcf RCON, IPEN, 0	;ACTIVEM NOMÉS LA INTERRUPCIÓ DEL TIMER0
    movlw 0xA0
    movwf INTCON, 0
    movlw 0x88
    movwf T0CON, 0
    return
    
INIT_EUSART	    ;INICIALITZEM L'EUSART
    movlw 0x26
    movwf TXSTA, 0
    movlw 0x90
    movwf RCSTA, 0
    movlw 0x81
    movwf SPBRG, 0
    clrf BAUDCON, 0
    return
    
    ;INTERRUPCIÓ CADA 5ms
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
    ;COMPROVEM SI HEM REBUT UN BYTE DES DE L'ORDINADOR
    btfsc PIR1, RCIF, 0
    goto RX_PC
    ;COMPROVEM SI HEM DE MOURE ELS LEDS EN HORITZONTAL (COCHE FANTASTICO)
    tstfsz HORIZ
    goto LEDS_HORIZ
    ;COMPROVEM SI HEM DE PARPALLEJAR ELS LEDS
    tstfsz BLINK
    goto LEDS_BLINK
    ;COMPROVEM SI HEM DE COMPROVAR ELS 10 SEGONS
    tstfsz LEDS_10S
    goto LEDS_SEG
    
CHECK_LOAD_BTN
    ;COMPROVEM SI EL POLSADOR DE LOAD ESTÀ ACTIU
    btfsc PORTC, 1, 0
    goto LOAD_BTN
    ;SI NO ESTÀ ACTIU, BAIXEM EL FLAG QUE INDICA QUE JA HEM FET LA TASCA DE CARREGAR
    clrf LOADED, 0
    ;goto CHECK_SEND_BTN ?
    
CHECK_LOAD_FLAG
    ;COMPROVEM SI JA HEM FET LA TASCA DE CARREGAR
    tstfsz LOADED, 0
    goto CHECK_SEND_BTN	
    ;EN CAS QUE NO HO HAGUEM FET, MIREM SI ESTEM EN "ZONA" DE REBOTS
    tstfsz F_REBOTS_LOAD
    goto CHECK_LOAD_15MS    ;SI HO ESTEM, MIREM SI JA HA PASSAT
    goto CHECK_SEND_BTN	    ;SI NO HO ESTEM, COMPROVEM EL POLSADOR DE SEND
    
CHECK_LOAD_15MS
    ;MIREM SI JA HA PASSAT PROU TEMPS PER SALTAR ELS REBOTS
    movlw 0x02
    cpfsgt TIMES, 0
    goto CHECK_SEND_BTN
    ;SI JA HA PASSAT EL TEMPS TORNEM A MIRAR SI DESPRÉS DELS REBOTS EL POLSADOR SEGUEIX ACTIU O NO
    ;SI NO HO ESTÀ, ES TRACTAVA D'UN REBOT, ALTRAMENT ENS HAVIEN PITJAT
    clrf F_REBOTS_LOAD, 0
    btfss PORTC, 1, 0
    goto CHECK_SEND_BTN
    ;COM QUE ES TRACTA D'UNA INSTRUCCIÓ DE CARREGAR:
    ;ENVIEM UNA PETICIÓ DE CADENA A L'ORDINADOR
    movlw SEND_BYTE
    movwf TXREG, 0
    ;ACTIVEM EL FLAG QUE INDICA QUE HEM D'ESPERAR 10 SEGONS
    setf LEDS_10S, 0
    ;RESETEJEM EL COMPTADOR DELS 10 SEGONS
    clrf SEG_L, 0
    clrf SEG_H, 0
    ;DESACTIVEM QUALSEVOL ACTIVITAT DELS LEDS
    clrf BLINK, 0
    clrf HORIZ, 0
    ;ACTIVEM EL FLAG QUE INDICA QUE JA HEM FET LA FUNCIONALITAT DE CARREGAR
    setf LOADED, 0
    goto CHECK_SEND_BTN
        
LOAD_BTN
    ;COMPROVEM SI JA HEM FET LA CARREGA DE CADENA
    tstfsz LOADED, 0
    goto CHECK_SEND_BTN
    ;SI NO L'HEM FET MIREM SI ESTEM EN ESPAI DE REBOTS
    tstfsz F_REBOTS_LOAD
    ;SI HI ESTEM, COMPROVEM SI JA HI HAURIEM DE SORTIR
    goto CHECK_LOAD_15MS
    ;SI NO HO ESTEM, HI ENTREM
    clrf TIMES, 0
    setf F_REBOTS_LOAD, 0
    goto CHECK_SEND_BTN
    
CHECK_SEND_BTN
    ;COMPROVEM SI EL POLSADOR DE SEND ESTÀ ACTIU
    btfsc PORTC, 0, 0
    goto SEND_BTN
    ;SI NO ESTÀ ACTIU, BAIXEM EL FLAG QUE INDICA QUE JA HEM FET LA TASCA D'ENVIAR
    clrf SENT, 0
    ;goto BUCLE ?
    
CHECK_SEND_FLAG
    ;COMPROVEM SI JA HEM FET LA TASCA D'ENVIAR
    tstfsz SENT, 0
    goto BUCLE
    ;EN CAS QUE NO HO HAGUEM FET, MIREM SI ESTEM EN "ZONA" DE REBOTS
    tstfsz F_REBOTS_SEND
    goto CHECK_SEND_15MS    ;SI HO ESTEM, MIREM SI JA HA PASSAT
    goto BUCLE		    ;SI NO HO ESTEM, TORNEM A L'INICI DEL BUCLE

CHECK_SEND_15MS
    ;MIREM SI JA HA PASSAT PROU TEMPS PER SALTAR ELS REBOTS
    movlw 0x02
    cpfsgt TIMES, 0
    goto BUCLE
    ;SI JA HA PASSAT EL TEMPS TORNEM A MIRAR SI DESPRÉS DELS REBOTS EL POLSADOR SEGUEIX ACTIU O NO
    ;SI NO HO ESTÀ, ES TRACTAVA D'UN REBOT, ALTRAMENT ENS HAVIEN PITJAT
    clrf F_REBOTS_SEND, 0
    btfss PORTC, 0, 0
    goto BUCLE
    ;EN CAS QUE HAGUEM D'ENVIAR, ACTIVEM EL FLAG DE QUE JA HO HEM FET I HO FEM
    setf SENT, 0
    goto SEND_RF
        
SEND_BTN
    ;COMPROVEM SI JA HEM FET L'ENVIAMENT
    tstfsz SENT, 0
    goto BUCLE	
    ;SI NO L'HEM FET MIREM SI ESTEM EN ESPAI DE REBOTS
    tstfsz F_REBOTS_SEND
    ;SI HI ESTEM, COMPROVEM SI JA HI HAURIEM DE SORTIR
    goto CHECK_SEND_15MS
    ;SI NO HO ESTEM, HI ENTREM
    clrf TIMES, 0
    setf F_REBOTS_SEND, 0
    goto BUCLE
    
    ;SITUACIÓ EN LA QUE HEM REBUT UN BYTE PER LA SIO
RX_PC
    ;ATUREM EL COMPTADOR DELS 10 SEGONS I EL MOVIMENT HORITZONTAL
    clrf LEDS_10S, 0
    clrf HORIZ, 0
    ;ENS SITUEM A L'INICI DE LA CADENA
    movlw INIT_FSR0L
    movwf FSR0L, 0
    movlw INIT_FSR0H
    movwf FSR0H, 0
    ;LLEGIM EL BYTE REBUT I MIREM SI ES TRACTA DEL CAS DE CARREGAR UNA CADENA A LA RAM O BÉ
    ;S'HA D'ENVIAR PER RF EL CONTINGUT
    movff RCREG, WORD
    movlw LOAD_BYTE
    cpfseq WORD, 0
    ;S'HA DE TRANSMETRE PER RF
    goto SEND_MESSAGE
    ;S'HA DE CARREGAR UNA CADENA 
    ;FIQUEM A ZERO EL COMPTADOR DE LLETRES DE LA CADENA
    clrf SIZEL, 0
    clrf SIZEH, 0
    
    ;COM QUE UTILITZEM UN PROTOCOL ORIENTAT A CONNEXIÓ, S'ESTABLEIX UN DIALEG, AIXÍ QUE PER ASSEGURAR QUE NO 
    ;ES PERDRÀ CAP BYTE L'ORDINADOR S'HA D'ESPERAR A QUE LA PIC LI CONTESTI
DEMANA_CHAR
    ;TRANSMETEM A L'ORDINADOR EL BYTE SEND_BYTE QUE VOL DIR QUE LI DEMANEM UN ALTRE CARÀCTER DE LA CADENA
    movlw SEND_BYTE
    movwf TXREG, 0
    ;ESPEREM QUE L'ORDINADOR ENS CONTESTI
    btfss PIR1, RCIF, 0
    goto $-2
    ;LLEGIM EL BYTE REBUT I EL COMPAREM AMB EL BYTE QUE INDICA UN FINAL DE CADENA.
    movff RCREG, WORD
    movlw END_BYTE
    cpfseq WORD, 0
    ;SI ENCARA NO S'HA ACABAT LA CADENA, GUARDEM EL CARÀCTER REBUT A LA RAM
    goto GUARDA_CHAR
    ;SI S'HA ACABAT LA CÀRREGA FEM PARPALLEJAR ELS LEDS A 5HZ
    movlw F_5HZ
    movwf BLINK, 0
    clrf LATD, 0
    clrf LATB, 0
    ;INDIQUEM A L'ORDINADOR QUE HEM REBUT EL FINAL DE CADENA
    movlw END_BYTE
    movwf TXREG, 0
    ;setf TXREG, 0
    goto BUCLE
    
GUARDA_CHAR
    ;PER CADA BYTE QUE REBEM INCREMENTEM EL COMPTADOR DE MIDA DE LA CADENA
    incf SIZEL, 1, 0
    btfsc STATUS, C, 0
    incf SIZEH, 1, 0
    ;I ESCRIVIM EL NOU BYTE A LA RAM
    movff WORD, POSTINC0
    goto DEMANA_CHAR
    
    ;SITUACIÓ EN LA QUE HEM DE TRANSMETRE EL CONTINGUT DE LA RAM PER RF
SEND_MESSAGE
    ;SI HEM REBUT L'INSTRUCCIÓ DE TRANSMISSIÓ PER LA SIO LI HEM DE CONTESTAR
    movlw SEND_BYTE
    movwf TXREG, 0
    
SEND_RF
    ;ELIMINEM L'ACTIVITAT DELS LEDS
    clrf LEDS_10S, 0
    clrf HORIZ, 0
    ;MIREM SI PODEM TRANSMETRE (TENIM CARREGAT UN MISSATGE)
    tstfsz SIZEL, 0
    goto RF_OK
    tstfsz SIZEH, 0
    goto RF_OK
    
RF_KO
    ;SI NO PODEM TRANSMETRE PER RF INICIEM EL MOVIMENT HORITZONTAL DELS LEDS
    movlw 0x03
    movwf LATD, 0
    clrf LATB, 0
    setf HORIZ, 0
    clrf BLINK, 0
    goto BUCLE
    
RF_OK
    ;EN CAS QUE SI QUE PODEM TRANSMETRE:
    ;PER A ENCENDRE DE MANERA PROGRESSIVA ELS 10 LEDS NECESSITEM EL RESULTAT DE LA MIDA DE LA CADENA ENTRE 10
    ;DIVIDIM ENTRE 10 I APAGUEM ELS LEDS
    call DIV_10
    clrf LATD, 0
    clrf LATB, 0
    clrf N_LEDS, 0
    
SEND_RAM
    ;SITUEM EL PUNTER A L'INICI DE LA CADENA
    movlw INIT_FSR0H
    movwf FSR0H, 0
    movlw INIT_FSR0L
    movwf FSR0L, 0
    ;LLEGIM LA PARAULA A TRANSMETRE
    movff POSTINC0, WORD
    ;ENVIEM UN FLANC POSITIU (L'HAUREM D'ENVIAR SI O SI, JA SIGUI PER LA PRIMERA PART L'UN 1 O LA SEGONA D'UN 0)
    call RF_1
    ;ROTEM LA PARAULA A ENVIAR CAP A L'ESQUERRA (TRANSMETEM DE MÉS A MENYS PES)
    rlcf WORD, 1, 0
    btfsc STATUS, C, 0
    ;SI EL PRIMER BIT ÉS UN 1 JA PODEM TRANSMETRE LA RESTA DE PARAULES
    goto ENVIA_TRAMA
    ;SI EL PRIMER BIT ÉS UN 0 ENVIEM UN 0 ABANS DE TRANSMETRE LA RESTA DE PARAULES
    call RF_0
    
ENVIA_TRAMA
    ;INICIALITZEM L'ÍNDEX DELS BITS DE LA PARAULA A 1 PERQUÈ JA HEM ENVIAT EL PRIMER
    movlw 0x01
    movwf INDEX, 0
    ;INICIALITZEM L'ÍNDEX DE LES PARAULES A TRANSMETRE A 0. LA TRANSMISSIÓ ACABARÀ QUAN AQUEST COMPTADOR VALGUI
    ;EL MATEIX QUE LA MIDA DE LA CADENA
    clrf N_SIZEL, 0
    clrf N_SIZEH, 0
    
CHECK_SIZE
    ;COMPAREM SI JA HEM TRANSMÈS TOTES LES LLETRES
    movf SIZEH, 0, 0
    cpfseq N_SIZEH, 0
    goto BUCLE_WORD
    movf SIZEL, 0, 0
    cpfslt N_SIZEL, 0
    ;SI L'ÍNDEX HA SOBREPASSAT LA MIDA DEL MISSATGE VOL DIR QUE JA HEM ACABAT.
    goto END_ENVIA_TRAMA
    
BUCLE_WORD
    ;SI NO HEM ACABAT DE TRANSMETRE UNA PARAULA ENVIEM EL SEGÜENT BIT
    rlcf WORD, 1, 0
    btfss STATUS, C, 0
    ;SI ES TRACTA D'UN 0, PRIMER ENVIEM UN NIVELL A 5V I DESPRÉS UN A 0V
    goto SEND_0
    
    ;SI ES TRACTA D'UN 1, PRIMER ENVIEM UN NIVELL A 0V I DESPRÉS UN A 5V
SEND_1
    call RF_0
    call RF_1
    goto CHECK_WORD
    
SEND_0
    call RF_1
    call RF_0
    
    ;COMPROVEM SI JA HEM ENVIAT TOTS ELS BITS D'UNA PARAULA
CHECK_WORD
    incf INDEX, 1, 0
    movlw 0x08
    cpfseq INDEX, 0
    ;SI NO HEM ACABAT AMB LA PARAULA ANEM A TRANSMETRE EL SEGÜENT BIT
    goto BUCLE_WORD
    ;SI HEM ACABAT RESETEJEM L'ÍNDEX DELS BITS D'UN BYTE I AUGMENTEM L'ÍNDEX DE LLETRES TRANSMESES
    clrf INDEX, 0
    incf N_SIZEL, 1, 0
    btfsc STATUS, C, 0
    incf N_SIZEH, 1, 0
    movff POSTINC0, WORD
    ;LEDS
    ;AUGMENTEM TAMBÉ L'ÍNDEX DE LA PROPORCIÓ DE LLETRES TRANSMESES.
    ;QUAN AQUEST ÍNDEX ARRIBA AL RESULTAT DE LA DIVISIÓ VOL DIR QUE HEM D'ENCENDRE UN LED MÉS
    incf N_LEDS, 1, 0
    movf N_LEDS, 0, 0
    cpfseq RES_DIV, 0
    ;SI NO HEM D'ENCENDRE UN ALTRE LED TORNEM A AGAFAR UN NOU BYTE DE LA RAM
    goto CHECK_SIZE    
    ;SI EL BIT DE MÉS PES DEL PORTD ESTÀ ACTIU VOL DIR QUE JA HEM OMPLERT UN REGISTRE, AIXÍ QUE HEM DE MOURE 
    ;DEL SEGON REGISTRE DE LEDS (PORTB)
    btfss PORTD, 7, 0
    ;SI NO HEM OMPLERT EL PORTD
    goto NEXT_LED
    ;SI JA HEM OMPLERT EL PORTD
    bsf LATB, 7, 0
    rlncf LATB, 1, 0
    
NEXT_LED
    ;PER A ENCENDRE PROGRESSIVAMENT ELS LEDS ACTIVEM EL BIT DE MÉS PES I ROTEM SENSE CARRY CAP A L'ESQUERRA
    bsf LATD, 7, 0
    rlncf LATD, 1, 0
    clrf N_LEDS, 0
    goto CHECK_SIZE
    
END_ENVIA_TRAMA
    ;SI JA HEM ACABAT DE TRANSMETRE L'ÚLTIM BIT DE L'ÚLTIM BYTE ENS ESPEREM A QUE AQUEST ESTIGUI EL SEU TEMPS EN
    ;L'ESTAT PERTINENT I DESPRÉS BAIXEM EL SENYAL DE TRANSMISSIÓ
    call RF_0
    ;JA HEM ENVIAT TOTS ELS BITS, AIXÒ IMPLICA EL 100% DE CARÀCTERS ENVIATS, AIXÍ QUE ACTIVEM TOTS ELS LEDS
    ;(REALMENT UNA MICA INNECESSARI JA QUE DE SEGUIDA VA AL BUCLE I INICIA EL PARPALLEIG)
    setf LATB, 0
    setf LATD, 0
    ;ACTIVA EL PARPALLEIG A 10HZ
    movlw F_10HZ
    movwf BLINK, 0
    goto BUCLE
    
RF_0
    ;FUNCIÓ QUE S'ESPERA A QUE SALTI UNA INTERRUPCIÓ I DESPRÉS FICA A 0 LA TRANSMISSIÓ RF
    setf WAIT, 0
    tstfsz WAIT, 0
    goto $-2
    bcf LATC, 2, 0
    return
    
RF_1
    ;FUNCIÓ QUE S'ESPERA A QUE SALTI UNA INTERRUPCIÓ I DESPRÉS FICA A 1 LA TRANSMISSIÓ RF
    setf WAIT, 0
    tstfsz WAIT, 0
    goto $-2
    bsf LATC, 2, 0
    return
    
LEDS_HORIZ
    ;ARRIBEM EN AQUEST CAS SI HEM DE MOURE HORITZONTALMENT ELS LEDS
    movlw F_20HZ
    cpfsgt LEDS_HZ
    ;SI NO HA PASSAT PROU TEMPS COM PER CANVIAR L'ESTAT DELS LEDS ANEM AL SEGÜENT CONDICIONAL DEL BUCLE
    goto CHECK_LOAD_BTN
    tstfsz RIGHT_NOTLEFT
    ;MOVIMENT A LA DRETA
    goto MOVE_RIGHT
    
    ;MOVIMENT A L'ESQUERRA
MOVE_LEFT
    ;EL MOVIMENT FUNCIONA DE LA SEGÜENT MANERA: SI HEM ARRIBAT AL BIT RB1 VOL DIR QUE HEM DE CANVIAR DE DIRECCIÓ.
    ;EN CAS CONTRARI ROTEM AMB CARRY CAP A L'ESQUERRA EL REGISTRE LATD. SI HI HA CARRY ROTEM EL LATB.
    clrf RIGHT_NOTLEFT
    btfsc PORTB, 1, 0
    goto MOVE_RIGHT
    rlcf LATD, 1, 0
    btfsc STATUS, C, 0
    rlcf LATB, 1, 0
    ;RESETEJEM EL COMPTADOR DE FREQÜÈNCIA DELS LEDS
    clrf LEDS_HZ, 0
    goto CHECK_LOAD_BTN
    
MOVE_RIGHT
    ;EL MOVIMENT FUNCIONA DE LA SEGÜENT MANERA: SI HEM ARRIBAT AL BIT RD0 VOL DIR QUE HEM DE CANVIAR DE DIRECCIÓ.
    ;EN CAS CONTRARI ROTEM AMB CARRY CAP A LA DRETA EL REGISTRE LATB I EL LATD.
    setf RIGHT_NOTLEFT
    btfsc PORTD, 0, 0
    goto MOVE_LEFT
    rrcf LATB, 1, 0
    rrcf LATD, 1, 0
    ;RESETEJEM EL COMPTADOR DE FREQÜÈNCIA DELS LEDS
    clrf LEDS_HZ, 0
    goto CHECK_LOAD_BTN
    
LEDS_BLINK
    ;SI VOLEM PARPELLEJAR ELS LEDS ESCRIVIM A BLINK LA FREQÜÈNCIA A LA QUE VOLEM FER-HO.
    movf BLINK, 0, 0
    cpfsgt LEDS_HZ
    ;SI NO HA PASSAT PROU TEMPS COM PER CANVIAR L'ESTAT DELS LEDS ANEM AL SEGÜENT CONDICIONAL DEL BUCLE
    goto CHECK_LOAD_BTN
    ;NEGUEM ELS LEDS, RESETEJEM LA VARIABLE DE FRQÜÈNCIA DELS LEDS I ANEM AL SEGÜENT CONDICIONAL DEL BUCLE
    comf LATD, 1, 0
    comf LATB, 1, 0
    clrf LEDS_HZ, 0
    goto CHECK_LOAD_BTN
    
LEDS_SEG
    ;MIREM SI JA HAN PASSAT 10 SEGONS
    movlw SEG_10_L
    cpfseq SEG_L, 0
    goto CHECK_LOAD_BTN
    movlw SEG_10_H
    cpfseq SEG_H, 0
    goto CHECK_LOAD_BTN
    ;SI JA HAN PASSAT DESACTIVEM EL FLAG PER A COMPTAR 10 SEGONS I ACTIVEM EL MOVIMENT HORITZONTAL
    clrf LEDS_10S, 0
    movlw 0x03
    movwf LATD, 0
    clrf LATB, 0
    setf HORIZ, 0
    clrf BLINK, 0
    goto CHECK_LOAD_BTN
    
DIV_10
    ;FUNCIÓ PER A DIVIDIR SIZE ENTRE 10 I DEIXAR EL RESULTAT A RES_DIV. EL PROCEDIMENT PER A OBTENIR EL RESULTAT ÉS
    ;EL SEGÜENT:
    ;SUMEM DOS AL VALOR DE LA PART BAIXA DE SIZE
    movf SIZEL, 0, 0
    addlw 0x02
    ;EN CAS QUE ES DONI OVERFLOW AUGMENTEM LA PART ALTA DE SIZE
    btfsc STATUS, C, 0
    incf SIZEH, 1, 0
    ;MULTIPLIQUEM (SIZEL+2) PER 51
    mullw 0x33
    ;DEL RESULTAT NOMÉS ENS INTERESSA LA PART ALTA
    movf PRODH, 0, 0
    ;SI LA PART ALTA DE SIZE ÉS DIFERENT A 0 SUMEM 51 AL RESULTAT
    btfsc SIZEH, 0, 0
    addlw 0x33
    movwf RES_DIV, 0
    ;DIVIDEM EL RESULTAT OBTINGUT FINS EL MOMENT ENTRE 2
    rrcf RES_DIV, 1, 0
    return
    

;*******
;* END *
;*******
    END