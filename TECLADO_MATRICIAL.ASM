;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*               DISPLAY DE 7 SEGUIMENTOS (CODE5)                  *
;*                          UTFPR              		               *
;*         DESENVOLVIDO POR	JEFFERSON GUND				           *
;*   VERS�O: 1.0                           DATA: 14/11/2013        *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                     DESCRI��O DO ARQUIVO                        *
;*-----------------------------------------------------------------  *
;* C�DIGO PARA PIC 16F877 DA DISCIPLINA "MICROCONTROLADORES".         *

;ESTE C�DIGO FAZ A VAREDURA DE UM TECLADO MATRICIAL 4 X 4 E MOSTRA OS
;CORRESPONDENTE VALORES NO DISPLAY DE 7 SEGMENTOS, DE 0 A F.




;* 			
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                CONFIGURA��O PARA GRAVA��O (FUSES)			   *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
__CONFIG _WDT_OFF & _XT_OSC & _LVP_OFF & _DEBUG_ON & _BODEN_OFF

;_CP_OFF 	==> MEM�RIA DE PROGRAMA DESPROTEGIDA CONTRA LEITURA.
;_WRT_OFF 	==> SEM PERMISS�O PARA ESCREVER NA MEM�RIA DE PROGRAMA
;				DURANTE EXECU��O DO PROGRAMA.
;_DEBUG_ON	==> DEBUG ATIVADO.
;_CPD_OFF 	==> MEM�RIA EEPROM PROTEGIDA CONTRA LEITURA.
;_LVP_OFF 	==> PROGRAMA��O EM BAIXA TENS�O DESABILITADA.
;_WDT_OFF 	==> WDT DESATIVADO.
;_BODEN_OFF	==> BROWN-OUT DESATIVADO. 
;_PWRTE_ON 	==> POWER-ON RESET ATIVADO.
;_XT_OSC 	==> OSCILADOR CRISTAL (4MHz).

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                     ARQUIVOS DE DEFINI��ES                      *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
#INCLUDE <P16F877.INC>	;ARQUIVO PADR�O MICROCHIP PARA 16F877

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                    PAGINA��O DE MEM�RIA                         *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

; DEFINI��O DE COMANDOS DE USU�RIO PARA ALTERA��O DA P�GINA DE
; MEM�RIA.

BANK0	MACRO					;SELECIONA BANK0 DE MEM�RIA.
				bcf STATUS,RP1
				bcf	STATUS,RP0
		ENDM					;FIM DA MACRO BANK0.

BANK1	MACRO					;SELECIONA BANK1 DE MEM�RIA.
				bcf STATUS,RP1
				bsf	STATUS,RP0
		ENDM					;FIM DA MACRO BANK1.

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                         VARI�VEIS                               *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; DEFINI��O DOS NOMES E ENDERE�OS DE TODAS AS VARI�VEIS UTILIZADAS 
; PELO SISTEMA
	CBLOCK	0x20	;ENDERE�O INICIAL DA MEM�RIA DE
					;USU�RIO.
		W_TEMP		;REGISTRADORES TEMPOR�RIOS PARA USO
		STATUS_TEMP	;JUNTO �S INTERRUP��ES.
		
			;NOVAS VARI�VEIS

		FLAGS
		TEMPO1
		TEMPO2
		LINHA
		LINHA_
		NUM
		COLUNA
		COLUNA_

	ENDC			;FIM DO BLOCO DE MEM�RIA.

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                        FLAGS INTERNOS                           *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;REGISTRADOR FLAGS:
;x = DEFINIDO EM OUTRO LUGAR DA TABELA.
;* =  DEFINIDO COMO MOSTRADO (0/1).


;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                         CONSTANTES                              *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; DEFINI��O DE TODAS AS CONSTANTES UTILIZADAS PELO SISTEMA

TEMPO_DELAY	EQU	.125

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                           ENTRADAS                              *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;PINOS QUE SER�O UTILIZADOS COMO ENTRADA:

;LEITURA DA CHAVE	==> RB0.



;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                           SA�DAS                                *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;PINOS QUE SERAO UTILIZADOS COMO ENTRADA:

;GND DA CHAVE	==> RC0.
;GND DO LED		==> RD0.

							
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                       VETOR DE RESET                            *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	ORG	0x00		;ENDERE�O INICIAL DE PROCESSAMENTO.
	goto	INICIO
	
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                    IN�CIO DA INTERRUP��O                        *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; ENDERE�O DE DESVIO DAS INTERRUP��ES. A PRIMEIRA TAREFA � SALVAR OS
; VALORES DE "W" E "STATUS" PARA RECUPERA��O FUTURA

	ORG	0x04			;ENDERE�O INICIAL DA INTERRUP��O.
	movwf	W_TEMP		;COPIA W PARA W_TEMP.
	swapf	STATUS,W
	movwf	STATUS_TEMP	;COPIA STATUS PARA STATUS_TEMP.

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                    ROTINA DE INTERRUP��O                        *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; ROTINAS DE RECONHECIMENTO E TRATAMENTO DAS INTERRUP��ES



;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                 ROTINA DE SA�DA DA INTERRUP��O                  *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; OS VALORES DE "W" E "STATUS" DEVEM SER RECUPERADOS ANTES DE 
; RETORNAR DA INTERRUP��O

SAI_INT
	swapf	STATUS_TEMP,W
	movwf	STATUS		;MOVE STATUS_TEMP PARA STATUS.
	swapf	W_TEMP,F
	swapf	W_TEMP,W	;MOVE W_TEMP PARA W.
	retfie

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*	            	 ROTINAS E SUBROTINAS                      	   *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; CADA ROTINA OU SUBROTINA DEVE POSSUIR A DESCRI��O DE FUNCIONAMENTO
; E UM NOME COERENTE �S SUAS FUN��ES.


DELAY

	movlw	TEMPO_DELAY
	movwf	TEMPO1

	movlw	TEMPO_DELAY
	movwf	TEMPO2
	decfsz	TEMPO2,F	
	goto	$-1			;RETORNA � LINHA ANTERIOR E DECREMENTA O CONTADOR TEMPO1
	decfsz	TEMPO1,F
	goto	$-5			;RETORNA � LINHA ANTERIOR E DECREMENTA O CONTADOR TEMPO2

	return




;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                     IN�CIO DO PROGRAMA                          *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	
INICIO
	clrf	PORTA
	clrf	PORTB
	clrf	PORTC
	clrf	PORTD
	clrf	PORTE


;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*             	CONFIGURA��O DO MICROCONTROLADOR                   *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	BANK1				;ALTERA PARA O BANCO 1.

	movlw	B'00000000'
	movwf	TRISA		;TODA A PORTA � SA�DA.
	movlw	B'00001111'
	movwf	TRISB		;RB0 E RB1 S�O ENTRADAS.
	movlw	B'11110000' ;RC0 E RC1 S�O TERRA DO TECLADO.
	movwf	TRISC		;
	movlw	B'00000000'
	movwf	TRISD		;TODOS BITS DO PORTD S�O SA�DAS.
	movlw	B'00000000'
	movwf	TRISE		;TODA A PORTE � SA�DA.





	movlw	B'01011111'
	movwf	OPTION_REG	;DEFINE OP��ES DE OPERA��O.
						;PULL-UPS HABILITADOS </RBPU>.
						;INT. NA BORDA DE SUBIDA EM RB0 <INTEDG>.
						;TIMER0 INCR. PELO CICLO DE M�QUINA <TOCS>.
						;PRESCALER APLICADO AO WDT <PSA>.
						;WDT 1:128, TMR0 1:1 <PS2:PS0>.
	
	movlw	B'00000000'
	movwf	INTCON		;TODAS AS INTERRUP��ES DESABILITADAS.
	
	movlw	B'00000111'
	movwf	ADCON1		;CONFIGURA CONVERSOR A/D.
						;CONFIGURA PORTA E PORTE COMO I/O DIGITAL.

	BANK0				;RETORNA PARA O BANCO 0.

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                      INICIALIZA��O DA RAM                       *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;  LIMPEZA DE TODA A RAM DO BANC0 0, INDO DE 0X20 A 0X7F.

	movlw	0x20
	movwf	FSR				;APONTA O ENDERE�AMENTO INDIRETO PARA
							;A PRIMEIRA POSI��O DA RAM.
LIMPA_RAM
	clrf	INDF			;LIMPA A POSI��O ATUAL.
	incf	FSR,F			;INCREMENTA PONTEIRO P/ A PR�X. POS.
	movf	FSR,W
	xorlw	0x80			;COMPARA PONTEIRO COM A �LT. POS. +1.
	btfss	STATUS,Z		;J� LIMPOU TODAS AS POSI��ES?
	goto	LIMPA_RAM		;N�O, LIMPA A PR�XIMA POSI��O.
							;SIM, CONTINUA O PROGRAMA.

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*             INICIALIZA��O DAS VARI�VEIS E SFRs	               *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; ATRIBUI��O DE VALORES INICIAIS �S VARI�VEIS CRIADAS NA RAM E 
; RESGISTRADORES ESPECIAIS.
	

	movlw	TEMPO_DELAY				
	movwf	TEMPO1		; CARREGA TEMPO1 = TEMPO
	bcf		INTCON,GIE


;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                     ROTINA PRINCIPAL                            *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *



MAIN:

	GOTO	LEITURA

	


;ABAIXO � REALIZADA A VARREDURA DO TECLADO:


LEITURA

	BCF		FLAGS,0		;LIMPA O BIT DE TESTE.
	BSF		STATUS,0	;SETA O BIT DO CARRY VERIFICANDO O QUE OCORREU COM O DESLOCAMENTO	

	MOVLW	B'11110111'	
	MOVWF	LINHA
	MOVWF	PORTC	

	CALL	COLUNA_PRESS
	BTFSS	FLAGS,0 	;TESTA O BIT SINALIZADOR: SE FLGAGS,0 = 1 � POR QUE HOUVE UMA TECLA PRESSIONADA.
	GOTO	$+2		
	CALL	ESCREVE_DIGITO
	RRF		LINHA		;ROTACIONA BITS PARA A DIREIRA DO REGISTRADOR. SE A OPERA��O DE COMPARA��O DOS BITS DE MAPEAMENTO COM OS BITS DO PORTC FOR DIFERENTE, ROTACIONA O BIT PARA A DIREITA E L� A PR�XIMA COLUNA.
	MOVF	LINHA,W
	MOVWF	PORTC

	CALL	COLUNA_PRESS
	BTFSS	FLAGS,0  	;TESTA O BIT SINALIZADOR: SE FLGAGS,0 = 1 � POR QUE HOUVE UMA TECLA PRESSIONADA.
	GOTO	$+2			;ROTACIONA BITS PARA A DIREIRA DO REGISTRADOR. SE A OPERA��O DE COMPARA��O DOS BITS DE MAPEAMENTO COM OS BITS DO PORTC FOR DIFERENTE, ROTACIONA O BIT PARA A DIREITA E L� A PR�XIMA COLUNA.
	CALL	ESCREVE_DIGITO
	RRF		LINHA		;ROTACIONA BITS PARA A DIREIRA DO REGISTRADOR. SE A OPERA��O DE COMPARA��O DOS BITS DE MAPEAMENTO COM OS BITS DO PORTC FOR DIFERENTE, ROTACIONA O BIT PARA A DIREITA E L� A PR�XIMA COLUNA.
	MOVF	LINHA,W
	MOVWF	PORTC

	CALL	COLUNA_PRESS
	BTFSS	FLAGS,0  	;TESTA O BIT SINALIZADOR: SE FLGAGS,0 = 1 � POR QUE HOUVE UMA TECLA PRESSIONADA.
	GOTO	$+2			;ROTACIONA BITS PARA A DIREIRA DO REGISTRADOR. SE A OPERA��O DE COMPARA��O DOS BITS DE MAPEAMENTO COM OS BITS DO PORTC FOR DIFERENTE, ROTACIONA O BIT PARA A DIREITA E L� A PR�XIMA COLUNA.
	CALL	ESCREVE_DIGITO
	RRF		LINHA		;ROTACIONA BITS PARA A DIREIRA DO REGISTRADOR. SE A OPERA��O DE COMPARA��O DOS BITS DE MAPEAMENTO COM OS BITS DO PORTC FOR DIFERENTE, ROTACIONA O BIT PARA A DIREITA E L� A PR�XIMA COLUNA.
	MOVF	LINHA,W
	MOVWF	PORTC	

	CALL	COLUNA_PRESS
	BTFSS	FLAGS,0  	;TESTA O BIT SINALIZADOR: SE FLGAGS,0 = 1 � POR QUE HOUVE UMA TECLA PRESSIONADA.
	GOTO	$+2			;ROTACIONA BITS PARA A DIREIRA DO REGISTRADOR. SE A OPERA��O DE COMPARA��O DOS BITS DE MAPEAMENTO COM OS BITS DO PORTC FOR DIFERENTE, ROTACIONA O BIT PARA A DIREITA E L� A PR�XIMA COLUNA.
	CALL	ESCREVE_DIGITO
	RRF		LINHA		;ROTACIONA BITS PARA A DIREIRA DO REGISTRADOR. SE A OPERA��O DE COMPARA��O DOS BITS DE MAPEAMENTO COM OS BITS DO PORTC FOR DIFERENTE, ROTACIONA O BIT PARA A DIREITA E L� A PR�XIMA COLUNA.
	MOVF	LINHA,W
	MOVWF	PORTC
	
	GOTO	LEITURA

		
COLUNA_PRESS
	BCF		FLAGS,0		;LIMPA O BIT DE TESTE.
	MOVF	PORTB,W
	MOVWF	COLUNA

	IORLW	B'11110000'	;MASCARA OS BITS PARA FAZER A OPERA��O OU-EXCLUSIVA, ISTO POR QUE OS BITS DE 4 A 7 DO PORTB EST�O EM ZERO POIS N�O S�O USADOS.
	XORLW	B'11111111'

	BTFSC	STATUS,2	;SE O BIT Z FOR SETADO PRA 1 � POR QUE NENHUMA TECLA EST� PRESSIONADA.
	RETURN
	CALL	DELAY

	MOVF	PORTB,W
	MOVWF	COLUNA

	IORLW	B'11110000'
	XORLW	B'11111111'

	BTFSC	STATUS,2	;PULA A LINHA SE  ESTIVER PRESSIONADO.
	BCF		FLAGS,0
	BSF		FLAGS,0

	;FICA LENDO O PORTD ENQUANTO A TECLA N�O � SOLTA
	MOVF	PORTB,W
	IORLW	B'11110000'
	XORLW	B'11111111'
	BTFSS	STATUS,2
	GOTO	$-7
	RETURN


ESCREVE_DIGITO			;ESTA ROTINA RASTREIA O BIT E CHAMA UMA SUBROTINA PARA
						;DECODIFICAR O D�GITO E ESCREVER NO DISPLAY.


	;BSF		STATUS,0	;INICIALIZA O BIT DO CARRY PARA ALOCAR O BIT 1 NO REGISTRADOR COLUNA QUANDO OCORRER A ROTA��O DE BITS.	
	
	
	
	BTFSC	LINHA,0		;TESTA QUAL O BIT DA TECLA PRESSIONADA.
	GOTO 	$+5
	CALL	NUMERO_0

	CALL	DECODIFICA_COLUNA

	CALL	RETORNA_DIGITO

	MOVWF	PORTD


	BTFSC	LINHA,1		;TESTA QUAL O BIT DA TECLA PRESSIONADA.
	GOTO 	$+5
	CALL	NUMERO_1
	

	CALL	DECODIFICA_COLUNA


	CALL	RETORNA_DIGITO

	MOVWF	PORTD


	BTFSC	LINHA,2		;TESTA QUAL O BIT DA TECLA PRESSIONADA.
	GOTO 	$+5
	CALL	NUMERO_2
	

	CALL	DECODIFICA_COLUNA


	CALL	RETORNA_DIGITO

	MOVWF	PORTD

	BTFSC	LINHA,3		;TESTA QUAL O BIT DA TECLA PRESSIONADA.
	GOTO 	$+5
	CALL	NUMERO_3
	

	CALL	DECODIFICA_COLUNA


	CALL	RETORNA_DIGITO
	

	MOVWF	PORTD

	RETURN
	

DECODIFICA_COLUNA

	MOVF	NUM,W
	MOVWF	LINHA_	;PASSA O CONTE�DO DO D�GITO CORRESPONDENTE PARA O REGISTRADOR LINHA.
	CLRF	NUM		;LIMPA O REGISTRADOR NUM.


	BTFSC	COLUNA,0		;TESTA QUAL O BIT DA TECLA PRESSIONADA.
	GOTO 	$+4
	CALL	NUMERO_0
	
	MOVF	NUM,W
	MOVWF	COLUNA_
	
	BTFSS	COLUNA,0		;TESTA QUAL O BIT DA TECLA PRESSIONADA.
	RETURN



	BTFSC	COLUNA,1		;TESTA QUAL O BIT DA TECLA PRESSIONADA.
	GOTO 	$+4
	CALL	NUMERO_1
	

	MOVF	NUM,W
	MOVWF	COLUNA_
	
	BTFSS	COLUNA,1		;TESTA QUAL O BIT DA TECLA PRESSIONADA.
	RETURN




	BTFSC	COLUNA,2		;TESTA QUAL O BIT DA TECLA PRESSIONADA.
	GOTO 	$+4
	CALL	NUMERO_2
	
	MOVF	NUM,W
	MOVWF	COLUNA_
	
	BTFSS	COLUNA,2		;TESTA QUAL O BIT DA TECLA PRESSIONADA.
	RETURN


	BTFSC	COLUNA,3		;TESTA QUAL O BIT DA TECLA PRESSIONADA.
	GOTO 	$+4
	CALL	NUMERO_3

	MOVF	NUM,W
	MOVWF	COLUNA_
	
	BTFSS	COLUNA,2		;TESTA QUAL O BIT DA TECLA PRESSIONADA.
	RETURN

	
RETURN



;***********************************************************************
NUMERO_0
	
	MOVLW	B'00000000' ;MOVE O N�MERO 0 PARA O REGISTRADOR LINHA_.
	MOVWF	NUM

RETURN

NUMERO_1

	MOVLW	B'00000001' ;MOVE O N�MERO 0 PARA O REGISTRADOR LINHA_.
	MOVWF	NUM

RETURN

NUMERO_2

	MOVLW	B'00000010' ;MOVE O N�MERO 0 PARA O REGISTRADOR LINHA_.
	MOVWF	NUM

RETURN

NUMERO_3

	MOVLW	B'00000011' ;MOVE O N�MERO 0 PARA O REGISTRADOR LINHA_.
	MOVWF	NUM

RETURN

;***********************************************************************


RETORNA_DIGITO

;4*LINHA + COLUNA.
	
	MOVF	LINHA_,W
	ADDWF	LINHA_,W
	ADDWF	LINHA_,W
	ADDWF	LINHA_,W
	ADDWF	COLUNA_,W

;	MOVF	TECLA,W
	ADDWF	PCL,f		;E AP�S SOMA COM O CONTADOR DE LINHA DE PROGRAMA QUE PULA PARA A LINHA CORRESPONDENTE AO D�GITO QUE SER� MOSTRADO
						;NO DISPLAY.

	RETLW	B'00000011'	; 	0
	RETLW	B'10011111'	;	1
	RETLW	B'00100101'	;	2
	RETLW	B'00001101'	;	3
	RETLW	B'10011001'	;	4
	RETLW	B'01001001'	;	5
	RETLW	B'01000001'	;	6
	RETLW	B'00011111'	;	7
	RETLW	B'00000001'	;	8
	RETLW	B'00001001'	;	9
	RETLW	B'00010001'	;	A
	RETLW	B'11000001'	;	B
	RETLW	B'01100011'	;	C
	RETLW	B'10000101'	;	D
	RETLW	B'01100001'	;	E
	RETLW	B'01110001'	;	F

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                       FIM DO PROGRAMA                           *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	END		;OBRIGAT�RIO.