;------------------------------------------------------------------------------
;Archivo: Lab4
;Microcontrolador: PIC16F887
;Autor: Andy Bonilla
;Programa: Interrupt on change y Pull-up y TM0
;Descripcion: incremento de PortA cada 500ms con T0IE
;Hardware: 
;------------------------------------------------------------------------------

;---------libreras a emplementar-----------------------------------------------
PROCESSOR 16F887
#include <xc.inc>
    
;----------------------bits de configuraciÃ³n-----------------------------------
;------configuration word 1----------------------------------------------------
CONFIG  FOSC=INTRC_NOCLKOUT ;se declara osc interno
CONFIG  WDTE=OFF            ; Watchdog Timer apagado
CONFIG  PWRTE=ON            ; Power-up Timer prendido
CONFIG  MCLRE=OFF           ; MCLRE apagado
CONFIG  CP=OFF              ; Code Protection bit apagado
CONFIG  CPD=OFF             ; Data Code Protection bit apagado

CONFIG  BOREN=OFF           ; Brown Out Reset apagado
CONFIG  IESO=OFF            ; Internal External Switchover bit apagado
CONFIG  FCMEN=OFF           ; Fail-Safe Clock Monitor Enabled bit apagado
CONFIG  LVP=ON		    ; low voltaje programming prendido

;------configuration word 2-------------------------------------------------
CONFIG BOR4V=BOR40V	    ;configuraciÃ³n de brown out reset
CONFIG WRT = OFF	    ;apagado de auto escritura de cÃƒÂ³digo

    
;---------------------- configuración de macros -------------------------------   
reset_timer	macro	    ; lo que anteriormente fue subrutina, se hizo macro
    banksel	PORTA	    ; nos aseguramos que es el PortA
    movlw	81	    ; dada la configuración del prescaler
    movwf	TMR0	    ; se guarda en timer0
    bsf		T0IF	    ; bandera cuando no hay overflow
    endm     

PSECT udata_bank0	    ; 
    cont:	DS 1 ; variable de contador 2 byte
    segmentos:	DS 1

PSECT udata_shr	    ; variable en memoria común
    W_TEMP:	    DS 1 ; variable 
    STATUS_TEMP:    DS 1 ; variable    
    
PSECT resetVect, class=CODE, abs, delta=2 ; ubicación de resetVector 2bytes
;----------------------- reset vector -----------------------------------------
ORG 00h
    PAGESEL main
    goto main
    
PSECT intVect, class=CODE, abs, delta=2 ; ubicación de resetVector 2bytes
;--------------- vector de interrupciones -------------------------------------
ORG 04h		     ; ubicación inicial de interrupción
push:				   
    movwf	W_TEMP		; variable se almacena en f
    swapf	STATUS, W	; se dan vuelta nibble
    movf	STATUS_TEMP	; se almacena en status_temp
    
isr:
    btfsc	T0IF		    ; se evalua si se hizo la interrupción
    call	interruption_tm0    ; se llama a la interrupción
    btfsc	RBIF		    ; se evalua si se hizo la interrupción  
    call	interruption_oc	    ; 
    call	suma_portd
    
pop:
    swapf	STATUS_TEMP, W	    ; se da vuelta a variable anterior
    movwf	STATUS		    ; se almacena en status
    swapf	W_TEMP, F	    ; se da vuelta a variable anterior
    swapf	W_TEMP, W
    retfie	
     
;-------------------------- subrutinas de interrupción ------------------------
interruption_tm0:
    reset_timer		; solo de 50ms
    incf	cont
    bcf		T0IF	; bajar bandera para que salg de la interrupcion
    return

interruption_oc:
    banksel	PORTB	;
    btfss	PORTB, 0
    incf	PORTA
    btfss	PORTB, 7
    decf	PORTA
    bcf		RBIF
    return

suma_portd:
    reset_timer		; solo de 50ms
    incf	cont
    movf	cont, W
    sublw	128
    btfss	STATUS, 2
    goto	return_timer0
    clrf	cont
    incf	PORTD
    bsf		T0IF
return_timer0:
    return
;---------------------- configuración de programa -----------------------------
PSECT code, delta=2, abs    ; se ubica el cÃ³digo de 2 bytes
ORG 100h    

 tabla:
    clrf    PCLATH	    ; asegurarase de estar en seccion
    bsf	    PCLATH, 0 	    ; 
    andlw   0fh		    ; se eliminan los 4 MSB y se dejan los 4 LSB
    addwf   PCL, F	    ; se guarda en F
    retlw   0x3F	    ; 0
    retlw   0x06	    ; 1
    retlw   0x5B	    ; 2
    retlw   0x4F	    ; 3
    retlw   0x66	    ; 4
    retlw   0x6D	    ; 5 
    retlw   0x7D	    ; 6
    retlw   0x07	    ; 7
    retlw   0x7F	    ; 8
    retlw   0x6F	    ; 9
    retlw   01110111B	    ; A
    retlw   01111111B	    ; B
    retlw   00111001B	    ; C
    retlw   01011110B	    ; D
    retlw   01111001B	    ; E
    retlw   01110001B	    ; F
  
main:
    call	io_config	; rutina de configuración in/out
    call	reloj_config	; rutina de configuración de reloj
    call	timer_config	; rutina de configuración de relok
    call	interruption_config	; rutina de configuración de interrumpciones
    banksel	PORTA
          
;-------------------- loop principal de programa ------------------------------
loop:
    ; de momento no hay loops
    goto	loop
        
;-------------------- subrutinas de programa ----------------------------------
io_config:
    banksel	ANSEL
    clrf	ANSEL	    ; aseguramos que sea digital
    clrf        ANSELH	    ; configuraciÃ³n de pin analÃ³gico
    
    banksel	TRISA
    clrf	TRISA	    ; PortA se configura como salida
    bsf		TRISB, 0    ; entraba RB0
    bsf		TRISB, 7    ; entrada RB7
    clrf	TRISC	    ; portC como salida
    clrf	TRISD	    ; portD como salida
    
    bcf		OPTION_REG, 7  ; set
    bsf		WPUB, 0	    ; weak pull-up PortB, 0
    bsf		WPUB, 7	    ;
    
    bsf		IOCB, 0	    ; activación de interrupción al cambio 1->0
    bsf		IOCB, 7	    ; activación de interrupción al cambio 1->0
    
    banksel	PORTA	    ; selección
    clrf	PORTA	    ; PortA se configura como salida
    clrf	PORTB	    ; PortB como salida
    clrf	PORTC	    ; PortC como salida
    clrf	PORTD	    ; PortD como salida
    return
    
reloj_config:
    banksel	OSCCON
    bcf		IRCF2	    ; set, configuraciÃ³n de frecuencia a 4MkHz (110)
    bcf		IRCF1	    ; set, configuraciÃ³n de frecuencia a 4MHz (110)
    bsf		IRCF0	    ; clear, configuraciÃ³n de frecuencia a 4MHz (110)
    return

timer_config:
    banksel	TRISC	    ; asegurarse de estar en el banco
    bcf		T0CS	    ; Internal instruction cycle clock = 0
    bcf		PSA	    ; estos PS son el preescaler
    bsf		PS2	    ; prescaler 001
    bsf		PS1	    ; prescaler 001
    bsf		PS0	    ; prescaler 00  1 
    reset_timer		    ; se reinicia el contador
    return
         
interruption_config:
    bsf		GIE	    ; activación de Global Enable Bit
    bsf		T0IE	    ; activación de Timer0 Overflow Interrupt
    bcf		T0IF	    ; desactivar Timer0 overflow interruption flag
    bsf		RBIE
    bcf		RBIF
    return   
    
END      