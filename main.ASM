;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*            		  	PWM				            		       *
;*       UTFPR - CAMPUS TOLEDO   |    ENGENHARIA ELETR�NICA    	   *
;*         							         JEFFERSON GUND 	   *
;*   VERS�O: 1.0                           DATA: 20/01/2014        *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                     DESCRI��O DO ARQUIVO                        *
;*-----------------------------------------------------------------*
;* C�DIGO PARA PIC 16F877 DA DISCIPLINA "MICROCONTROLADORES".      *

;ESTE C�DIGO FAZ O USO DO CONVERSOR A/D PARA LEITURA DE TENS�O EM UM
;POT�NCI�METRO LINEAR E COM ESTA ENTRADA ANAL�GICA, CONTROLA O PULSO 
;PWM QUE ACIONA UMA L�MPADA. O CONVERSOR EST� CONFIGURADO PARA JUSTIFICAR
;� DIREITA OS BITS AMOSTRADOS.


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
#INCLUDE <P16F877.INC>	


;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                CONFIGURA��O PARA GRAVA��O (FUSES)		       *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

__CONFIG _WDT_OFF & _LVP_OFF & _BODEN_OFF & _XT_OSC & _CP_OFF & _PWRTE_ON & _CPD_OFF & _DEBUG_ON

;__CONFIG _WDT_OFF & _XT_OSC & _LVP_OFF & _DEBUG_ON & _BODEN_OFF

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

;REGISTRADORES TEMPOR�RIOS PARA USO JUNTO �S INTERRUP��ES
	W_TEMP		
	STATUS_TEMP		

;REGISTRADORES AUXILIARES PARA ROTINA DE DELAY E ESCRITA NO DISPLAY LCD
	TEMPO1
	TEMPO2
	DELAY0
	DELAY1
	DELAY2
	NIBLE
	COUNT1

;REGISTRADORES AUXILIARES PARA ROTINA DE DIVIS�O
	QUOCIENTE_H
	QUOCIENTE_L
	DIVIDENDO_L
	DIVIDENDO_H
	RESTOTMP_L
	RESTOTMP_H
	DIVISOR_H
	DIVISOR_L
	RESTO_L
	RESTO_H

;REGISTRADORES AUXILIARES PARA ROTINA DE MULTIPLICA��O
	MULT_2
	MULT_TEMP
	PRODUTO_H
	PRODUTO_L
	MULT1_H
	MULT1_L
	
;REGISTRADORES AUXILIARES PARA A ROTINA DO CONVERSOR AD
	UNIDADE
	DEZENA
	CENTENA
	MILHAR
	MILHAO

;REGISTRADORES AUXILIARES PARA A ROTINA DE LEITURA DO TECLADO MATRICIAL
	AUX
	FLAGS
	LINHA
	LINHA_
	NUM
	COLUNA
	COLUNA_
	CARACTER
;REGISTRADORES AUXILIARES PARA O MAIN
	CONFIRMA
	OPCAO_INSERIDA
	ETAPA_CONFIG	;INDICA EM QUE PONTO DA CONFIGURA��O
						;O MICROCONTROLADOR EST�.
;REGISTRADORES AUXILIARES PARA LEITURA/ESCRITA NA EEPROM
ENDERECO
DADO

ENDC			;FIM DO BLOCO DE MEM�RIA.

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                         CONSTANTES                              *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; DEFINI��O DE TODAS AS CONSTANTES UTILIZADAS PELO SISTEMA


;DEFINI��ES DO LCD

#DEFINE		ENABLE		PORTE,1
#DEFINE		RS			PORTE,0
#DEFINE		RW			PORTE,2
#DEFINE		DISPLAY		PORTD


;CONSTANTES UTILIZADAS PELO SISTEMA.

#DEFINE		T240 			.100
#DEFINE		T6				.3
;CONSTANTE UTILIZADA PELA ROTINA DE LEITURA DO TECLADO MATRICIAL
TEMPO_DELAY	EQU	.125

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

;AS INTERRUP��ES N�O SER�O UTILIZADAS.

	ORG		0x04				;ENDERE�O INICIAL DA INTERRUP��O.
	movwf	W_TEMP				;COPIA W PARA W_TEMP.
	swapf	STATUS,W
	movwf	STATUS_TEMP			;COPIA STATUS PARA STATUS_TEMP.


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
;*                  CONFIGURA��O DO MICROCONTROLADOR               *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	
INICIO
	
	BANK1	;ALTERA P/ BANCO1
	MOVLW	B'00001000'	;DEFINE RA3 COMO ENTRADA E DEMAIS PINOS COMO SAIDA
	MOVWF	TRISA
	movlw	B'00001111'
	movwf	TRISB		;RB0 E RB1 S�O ENTRADAS.
	movlw	B'11110000' ;RC0 E RC1 S�O TERRA DO TECLADO.
	movwf	TRISC		
	MOVLW   B'00000000'
	MOVWF	TRISD
	MOVLW	B'00000000'
	MOVWF	TRISE
;	MOVLW	B'10000111' 
;	MOVWF	OPTION_REG	;PRESCALER 1:32 NO TMR0
	
	MOVLW	B'00000000' ;CHAVE GERAL DE INTERRUP��O DESLIGADA.
	MOVWF 	INTCON		;DEMAIS BITS IRRELEVANTES
	movlw	B'01011111'
	movwf	OPTION_REG	;DEFINE OP��ES DE OPERA��O.
						;PULL-UPS HABILITADOS </RBPU>.
						;INT. NA BORDA DE SUBIDA EM RB0 <INTEDG>.
						;TIMER0 INCR. PELO CICLO DE M�QUINA <TOCS>.
						;PRESCALER APLICADO AO WDT <PSA>.
						;WDT 1:128, TMR0 1:1 <PS2:PS0>.

;	MOVLW	B'00001001'
;	MOVWF	ADCON1		;DEFINE A3 COMO ENTRADA ANAL�GICA.

	movlw	B'00000111'
	movwf	ADCON1		;CONFIGURA CONVERSOR A/D.
						;CONFIGURA PORTA E PORTE COMO I/O DIGITAL.

	BANK0


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
							
;*******************************************************************
;					INICIALIZA��O DAS VARI�VEIS					   *
;*******************************************************************

	CLRF	PORTA	;LIMPA PORTA
	CLRF	PORTB	;LIMPA PORTB
	CLRF	PORTC	;LIMPA PORTC
	CLRF	PORTD	;LIMPA PORTD
	CLRF	PORTE	;LIMPA PORTE

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                     INICIALIZA��O DO DISPLAY                    *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

INICIALIZACAO_DISPLAY:

;ENABLE = PORTE,1 . RS = PORTE,0 . RW = PORTE,2 .	

	MOVLW 	.75
	CALL 	DELAY_2 	; DELAY DE 15mS

	BCF		ENABLE		 
	BCF 	RS 				; SELECIONA O DISPLAY P/ COMANDOS
	BCF 	RW
	
	MOVLW 	.20
	CALL 	DELAY_2 	; DELAY DE 3mS
	MOVLW	B'00110000'		;INICIALIZA O DISPLAY.
	CALL 	ESCREVE_ni

	MOVLW 	.20
	CALL 	DELAY_2 	; DELAY DE ~4mS
	MOVLW	B'00110000'		;INICIALIZA O DISPLAY.
	CALL 	ESCREVE_ni

	MOVLW 	.20
	CALL 	DELAY_2 	; DELAY DE 3mS
	MOVLW	B'00110000'		;INICIALIZA O DISPLAY.
	CALL 	ESCREVE_ni

	MOVLW 	.20
	CALL 	DELAY_2	; DELAY DE 3mS
	MOVLW	B'00100000'		;COMANDO PARA INTERFACE DE 4 BITS.
	CALL 	ESCREVE_ni

	MOVLW 	.20
	CALL 	DELAY_2 	; DELAY DE 3mS
	MOVLW	B'00101000'		;COMANDO PARA INTERFACE DE 4 BITS.
	CALL 	ESCREVE

	MOVLW 	.20
	CALL 	DELAY_2	; DELAY DE 3mS
	MOVLW	B'00001111' 	; ESCREVE COMANDO PARA LIGAR O DISPLAY E ATIVAR O CURSOR PISCANDO.
	CALL	ESCREVE 		; 

	MOVLW 	.20
	CALL 	DELAY_2 	; DELAY DE 3mS
	MOVLW	B'00000110' 	; ESCREVE COMANDO PARA LIGAR O DISPLAY E ATIVAR O CURSOR PISCANDO.
	CALL	ESCREVE 		; 

	MOVLW 	.20
	CALL 	DELAY_2 	; DELAY DE 3mS
	MOVLW	B'00000001' 	; ESCREVE COMANDO PARA
	CALL	ESCREVE 		; LIMPAR TODO O DISPLAY
	
	MOVLW 	.20
	CALL 	DELAY_2	; DELAY DE 3mS
	MOVLW	B'00001110' 	; ESCREVE COMANDO PARA DESATIVAR CURSOR PISCANTE.
	CALL	ESCREVE

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                     INICIALIZA PWM			                   *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *





	
;ESTA ROTINA CONFIGURA E ATIVA O CONVERSOR A/D 

	
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                     INICIALIZA CONVERSOR		                   *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

;ATIVA_CONVERSOR_AD

;	MOVLW	B'10010000' ;CHAVE GERAL DE INTERRUP��O E TIMER0 LIGADO.
;	MOVWF 	INTCON		

	;BANK1	
;	MOVLW	B'10000100' ;JUSTIFICADO � DIREITA.
;	MOVWF	ADCON1
	

;	BANK0
;	MOVLW	B'10011001' 
;	MOVWF	ADCON0	;FREQ OSC/32 
					;CANAL 0 SELECIONADO <A0>
					;MODULO A/D LIGADO <0>
;	GOTO 	MAIN


;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                       	MAIN		                           *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;ROTINA PRINCIPAL DO PROGRAMA 



MAIN
	CLRF	ENDERECO

ETAPA1

	CALL	NIVEL_SABAO  		;ESCREVE "N�VEL DE SAB�O:"
	MOVLW	.1
	MOVWF	ETAPA_CONFIG	
	GOTO	LEITURA	

ETAPA2

	CALL	NIVEL_AGUA  		;ESCREVE AS OP��ES DE LAVAGEM DA M�QUINA.	
	MOVLW	.2
	MOVWF	ETAPA_CONFIG
	GOTO	LEITURA

ETAPA3

	CALL	NIVEL_AMACIANTE  		;ESCREVE AS OP��ES DE LAVAGEM DA M�QUINA.
	MOVLW	.3
	MOVWF	ETAPA_CONFIG
	GOTO	LEITURA


ETAPA4

	CALL	TIPO_ROUPA  		;ESCREVE AS OP��ES DE LAVAGEM DA M�QUINA.
	MOVLW	.4
	MOVWF	ETAPA_CONFIG
	GOTO	LEITURA

ETAPA5

	MOVLW	.5
	MOVWF	ETAPA_CONFIG
	MOVLW	.0
	MOVWF	OPCAO_INSERIDA
	CALL	TIPO_SUJEIRA		;->POUCO SUJA->SUJA->MUITO SUJA->
	GOTO	LEITURA
ETAPA6
	MOVLW	.6
	MOVWF	ETAPA_CONFIG
	
	;CALL	LEITURA_SENSOR_NIVEL		;INICIACONVERS�O AD E OBTEM OS VALORES PARA CENTENAS, DEZENAS, UNIDADES, ETC..


;	CALL	LAVAGEM				;EXECUTA A LAVAGEM, DE ACORDO COM AS OP��ES INSERIDAS.

;	CALL	GERA_MENSAGEM	;ARMAZENA NA MEMORIA RAM (POSI��ES 0X20 A 0X40) "Van = 'VALOR' V"
;	CALL 	ATUALIZA_LCD	;ESCREVE A SEGUNDA PARTE DA MENSAGEM NO DISPLAY: "Van = 'VALOR' V"

GOTO	MAIN


;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                       INCLUDES		                           *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *


#INCLUDE	"LCD_4BITS_JG.INC"
#INCLUDE	"MULTI_10X8.INC"
#INCLUDE	"div_16X16.INC"
#INCLUDE	"INICIALIZACAO.INC"
#INCLUDE	"TECLADO_MATRICIAL.INC"
#INCLUDE	"TRATA_DADOS_CONVERSAO.INC"


;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                       FIM DO PROGRAMA                           *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

END		;OBRIGAT�RIO.