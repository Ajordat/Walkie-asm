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

	


;*************
;* CONSTANTS *
;*************


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
	

;*******
;* END *
;*******
	END