;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*               DISPLAY DE 7 SEGUIMENTOS (CODE5)                  *
;*                          UTFPR              		               *
;*         DESENVOLVIDO POR	JEFFERSON GUND				           *
;*   VERSÃO: 1.0                           DATA: 14/11/2013        *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                     DESCRIÇÃO DO ARQUIVO                        *
;*-----------------------------------------------------------------  *
;* CÓDIGO PARA PIC 16F877 DA DISCIPLINA "MICROCONTROLADORES".         *

;ESTE CÓDIGO FAZ A VAREDURA DE UM TECLADO MATRICIAL 4 X 4 E MOSTRA OS
;CORRESPONDENTE VALORES NO DISPLAY DE 7 SEGMENTOS, DE 0 A F.




;* 			
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                CONFIGURAÇÃO PARA GRAVAÇÃO (FUSES)			   *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
__CONFIG _WDT_OFF & _XT_OSC & _LVP_OFF & _DEBUG_ON & _BODEN_OFF

;_CP_OFF 	==> MEMÓRIA DE PROGRAMA DESPROTEGIDA CONTRA LEITURA.
;_WRT_OFF 	==> SEM PERMISSÃO PARA ESCREVER NA MEMÓRIA DE PROGRAMA
;				DURANTE EXECUÇÃO DO PROGRAMA.
;_DEBUG_ON	==> DEBUG ATIVADO.
;_CPD_OFF 	==> MEMÓRIA EEPROM PROTEGIDA CONTRA LEITURA.
;_LVP_OFF 	==> PROGRAMAÇÃO EM BAIXA TENSÃO DESABILITADA.
;_WDT_OFF 	==> WDT DESATIVADO.
;_BODEN_OFF	==> BROWN-OUT DESATIVADO. 
;_PWRTE_ON 	==> POWER-ON RESET ATIVADO.
;_XT_OSC 	==> OSCILADOR CRISTAL (4MHz).

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                     ARQUIVOS DE DEFINIÇÕES                      *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
#INCLUDE <P16F877.INC>	;ARQUIVO PADRÃO MICROCHIP PARA 16F877

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                    PAGINAÇÃO DE MEMÓRIA                         *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

; DEFINIÇÃO DE COMANDOS DE USUÁRIO PARA ALTERAÇÃO DA PÁGINA DE
; MEMÓRIA.

BANK0	MACRO					;SELECIONA BANK0 DE MEMÓRIA.
				bcf STATUS,RP1
				bcf	STATUS,RP0
		ENDM					;FIM DA MACRO BANK0.

BANK1	MACRO					;SELECIONA BANK1 DE MEMÓRIA.
				bcf STATUS,RP1
				bsf	STATUS,RP0
		ENDM					;FIM DA MACRO BANK1.

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                         VARIÁVEIS                               *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; DEFINIÇÃO DOS NOMES E ENDEREÇOS DE TODAS AS VARIÁVEIS UTILIZADAS 
; PELO SISTEMA
	CBLOCK	0x20	;ENDEREÇO INICIAL DA MEMÓRIA DE
					;USUÁRIO.
		W_TEMP		;REGISTRADORES TEMPORÁRIOS PARA USO
		STATUS_TEMP	;JUNTO ÀS INTERRUPÇÕES.
		
			;NOVAS VARIÁVEIS

		FLAGS
		TEMPO1
		TEMPO2
		LINHA
		LINHA_
		NUM
		COLUNA
		COLUNA_

	ENDC			;FIM DO BLOCO DE MEMÓRIA.

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                        FLAGS INTERNOS                           *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;REGISTRADOR FLAGS:
;x = DEFINIDO EM OUTRO LUGAR DA TABELA.
;* =  DEFINIDO COMO MOSTRADO (0/1).


;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                         CONSTANTES                              *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; DEFINIÇÃO DE TODAS AS CONSTANTES UTILIZADAS PELO SISTEMA

TEMPO_DELAY	EQU	.125

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                           ENTRADAS                              *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;PINOS QUE SERÃO UTILIZADOS COMO ENTRADA:

;LEITURA DA CHAVE	==> RB0.



;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                           SAÍDAS                                *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;PINOS QUE SERAO UTILIZADOS COMO ENTRADA:

;GND DA CHAVE	==> RC0.
;GND DO LED		==> RD0.

							
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                       VETOR DE RESET                            *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	ORG	0x00		;ENDEREÇO INICIAL DE PROCESSAMENTO.
	goto	INICIO
	
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                    INÍCIO DA INTERRUPÇÃO                        *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; ENDEREÇO DE DESVIO DAS INTERRUPÇÕES. A PRIMEIRA TAREFA É SALVAR OS
; VALORES DE "W" E "STATUS" PARA RECUPERAÇÃO FUTURA

	ORG	0x04			;ENDEREÇO INICIAL DA INTERRUPÇÃO.
	movwf	W_TEMP		;COPIA W PARA W_TEMP.
	swapf	STATUS,W
	movwf	STATUS_TEMP	;COPIA STATUS PARA STATUS_TEMP.

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                    ROTINA DE INTERRUPÇÃO                        *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; ROTINAS DE RECONHECIMENTO E TRATAMENTO DAS INTERRUPÇÕES



;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                 ROTINA DE SAÍDA DA INTERRUPÇÃO                  *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; OS VALORES DE "W" E "STATUS" DEVEM SER RECUPERADOS ANTES DE 
; RETORNAR DA INTERRUPÇÃO

SAI_INT
	swapf	STATUS_TEMP,W
	movwf	STATUS		;MOVE STATUS_TEMP PARA STATUS.
	swapf	W_TEMP,F
	swapf	W_TEMP,W	;MOVE W_TEMP PARA W.
	retfie

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*	            	 ROTINAS E SUBROTINAS                      	   *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; CADA ROTINA OU SUBROTINA DEVE POSSUIR A DESCRIÇÃO DE FUNCIONAMENTO
; E UM NOME COERENTE ÀS SUAS FUNÇÕES.


DELAY

	movlw	TEMPO_DELAY
	movwf	TEMPO1

	movlw	TEMPO_DELAY
	movwf	TEMPO2
	decfsz	TEMPO2,F	
	goto	$-1			;RETORNA À LINHA ANTERIOR E DECREMENTA O CONTADOR TEMPO1
	decfsz	TEMPO1,F
	goto	$-5			;RETORNA À LINHA ANTERIOR E DECREMENTA O CONTADOR TEMPO2

	return




;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                     INÍCIO DO PROGRAMA                          *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	
INICIO
	clrf	PORTA
	clrf	PORTB
	clrf	PORTC
	clrf	PORTD
	clrf	PORTE


;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*             	CONFIGURAÇÃO DO MICROCONTROLADOR                   *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	BANK1				;ALTERA PARA O BANCO 1.

	movlw	B'00000000'
	movwf	TRISA		;TODA A PORTA É SAÍDA.
	movlw	B'00001111'
	movwf	TRISB		;RB0 E RB1 SÃO ENTRADAS.
	movlw	B'11110000' ;RC0 E RC1 SÃO TERRA DO TECLADO.
	movwf	TRISC		;
	movlw	B'00000000'
	movwf	TRISD		;TODOS BITS DO PORTD SÃO SAÍDAS.
	movlw	B'00000000'
	movwf	TRISE		;TODA A PORTE É SAÍDA.





	movlw	B'01011111'
	movwf	OPTION_REG	;DEFINE OPÇÕES DE OPERAÇÃO.
						;PULL-UPS HABILITADOS </RBPU>.
						;INT. NA BORDA DE SUBIDA EM RB0 <INTEDG>.
						;TIMER0 INCR. PELO CICLO DE MÁQUINA <TOCS>.
						;PRESCALER APLICADO AO WDT <PSA>.
						;WDT 1:128, TMR0 1:1 <PS2:PS0>.
	
	movlw	B'00000000'
	movwf	INTCON		;TODAS AS INTERRUPÇÕES DESABILITADAS.
	
	movlw	B'00000111'
	movwf	ADCON1		;CONFIGURA CONVERSOR A/D.
						;CONFIGURA PORTA E PORTE COMO I/O DIGITAL.

	BANK0				;RETORNA PARA O BANCO 0.

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                      INICIALIZAÇÃO DA RAM                       *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;  LIMPEZA DE TODA A RAM DO BANC0 0, INDO DE 0X20 A 0X7F.

	movlw	0x20
	movwf	FSR				;APONTA O ENDEREÇAMENTO INDIRETO PARA
							;A PRIMEIRA POSIÇÃO DA RAM.
LIMPA_RAM
	clrf	INDF			;LIMPA A POSIÇÃO ATUAL.
	incf	FSR,F			;INCREMENTA PONTEIRO P/ A PRÓX. POS.
	movf	FSR,W
	xorlw	0x80			;COMPARA PONTEIRO COM A ÚLT. POS. +1.
	btfss	STATUS,Z		;JÁ LIMPOU TODAS AS POSIÇÕES?
	goto	LIMPA_RAM		;NÃO, LIMPA A PRÓXIMA POSIÇÃO.
							;SIM, CONTINUA O PROGRAMA.

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*             INICIALIZAÇÃO DAS VARIÁVEIS E SFRs	               *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; ATRIBUIÇÃO DE VALORES INICIAIS ÀS VARIÁVEIS CRIADAS NA RAM E 
; RESGISTRADORES ESPECIAIS.
	

	movlw	TEMPO_DELAY				
	movwf	TEMPO1		; CARREGA TEMPO1 = TEMPO
	bcf		INTCON,GIE


;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                     ROTINA PRINCIPAL                            *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *



MAIN:

	GOTO	LEITURA

	


;ABAIXO É REALIZADA A VARREDURA DO TECLADO:


LEITURA

	BCF		FLAGS,0		;LIMPA O BIT DE TESTE.
	BSF		STATUS,0	;SETA O BIT DO CARRY VERIFICANDO O QUE OCORREU COM O DESLOCAMENTO	

	MOVLW	B'11110111'	
	MOVWF	LINHA
	MOVWF	PORTC	

	CALL	COLUNA_PRESS
	BTFSS	FLAGS,0 	;TESTA O BIT SINALIZADOR: SE FLGAGS,0 = 1 É POR QUE HOUVE UMA TECLA PRESSIONADA.
	GOTO	$+2		
	CALL	ESCREVE_DIGITO
	RRF		LINHA		;ROTACIONA BITS PARA A DIREIRA DO REGISTRADOR. SE A OPERAÇÃO DE COMPARAÇÃO DOS BITS DE MAPEAMENTO COM OS BITS DO PORTC FOR DIFERENTE, ROTACIONA O BIT PARA A DIREITA E LÊ A PRÓXIMA COLUNA.
	MOVF	LINHA,W
	MOVWF	PORTC

	CALL	COLUNA_PRESS
	BTFSS	FLAGS,0  	;TESTA O BIT SINALIZADOR: SE FLGAGS,0 = 1 É POR QUE HOUVE UMA TECLA PRESSIONADA.
	GOTO	$+2			;ROTACIONA BITS PARA A DIREIRA DO REGISTRADOR. SE A OPERAÇÃO DE COMPARAÇÃO DOS BITS DE MAPEAMENTO COM OS BITS DO PORTC FOR DIFERENTE, ROTACIONA O BIT PARA A DIREITA E LÊ A PRÓXIMA COLUNA.
	CALL	ESCREVE_DIGITO
	RRF		LINHA		;ROTACIONA BITS PARA A DIREIRA DO REGISTRADOR. SE A OPERAÇÃO DE COMPARAÇÃO DOS BITS DE MAPEAMENTO COM OS BITS DO PORTC FOR DIFERENTE, ROTACIONA O BIT PARA A DIREITA E LÊ A PRÓXIMA COLUNA.
	MOVF	LINHA,W
	MOVWF	PORTC

	CALL	COLUNA_PRESS
	BTFSS	FLAGS,0  	;TESTA O BIT SINALIZADOR: SE FLGAGS,0 = 1 É POR QUE HOUVE UMA TECLA PRESSIONADA.
	GOTO	$+2			;ROTACIONA BITS PARA A DIREIRA DO REGISTRADOR. SE A OPERAÇÃO DE COMPARAÇÃO DOS BITS DE MAPEAMENTO COM OS BITS DO PORTC FOR DIFERENTE, ROTACIONA O BIT PARA A DIREITA E LÊ A PRÓXIMA COLUNA.
	CALL	ESCREVE_DIGITO
	RRF		LINHA		;ROTACIONA BITS PARA A DIREIRA DO REGISTRADOR. SE A OPERAÇÃO DE COMPARAÇÃO DOS BITS DE MAPEAMENTO COM OS BITS DO PORTC FOR DIFERENTE, ROTACIONA O BIT PARA A DIREITA E LÊ A PRÓXIMA COLUNA.
	MOVF	LINHA,W
	MOVWF	PORTC	

	CALL	COLUNA_PRESS
	BTFSS	FLAGS,0  	;TESTA O BIT SINALIZADOR: SE FLGAGS,0 = 1 É POR QUE HOUVE UMA TECLA PRESSIONADA.
	GOTO	$+2			;ROTACIONA BITS PARA A DIREIRA DO REGISTRADOR. SE A OPERAÇÃO DE COMPARAÇÃO DOS BITS DE MAPEAMENTO COM OS BITS DO PORTC FOR DIFERENTE, ROTACIONA O BIT PARA A DIREITA E LÊ A PRÓXIMA COLUNA.
	CALL	ESCREVE_DIGITO
	RRF		LINHA		;ROTACIONA BITS PARA A DIREIRA DO REGISTRADOR. SE A OPERAÇÃO DE COMPARAÇÃO DOS BITS DE MAPEAMENTO COM OS BITS DO PORTC FOR DIFERENTE, ROTACIONA O BIT PARA A DIREITA E LÊ A PRÓXIMA COLUNA.
	MOVF	LINHA,W
	MOVWF	PORTC
	
	GOTO	LEITURA

		
COLUNA_PRESS
	BCF		FLAGS,0		;LIMPA O BIT DE TESTE.
	MOVF	PORTB,W
	MOVWF	COLUNA

	IORLW	B'11110000'	;MASCARA OS BITS PARA FAZER A OPERAÇÃO OU-EXCLUSIVA, ISTO POR QUE OS BITS DE 4 A 7 DO PORTB ESTÃO EM ZERO POIS NÃO SÃO USADOS.
	XORLW	B'11111111'

	BTFSC	STATUS,2	;SE O BIT Z FOR SETADO PRA 1 É POR QUE NENHUMA TECLA ESTÁ PRESSIONADA.
	RETURN
	CALL	DELAY

	MOVF	PORTB,W
	MOVWF	COLUNA

	IORLW	B'11110000'
	XORLW	B'11111111'

	BTFSC	STATUS,2	;PULA A LINHA SE  ESTIVER PRESSIONADO.
	BCF		FLAGS,0
	BSF		FLAGS,0

	;FICA LENDO O PORTD ENQUANTO A TECLA NÃO É SOLTA
	MOVF	PORTB,W
	IORLW	B'11110000'
	XORLW	B'11111111'
	BTFSS	STATUS,2
	GOTO	$-7
	RETURN


ESCREVE_DIGITO			;ESTA ROTINA RASTREIA O BIT E CHAMA UMA SUBROTINA PARA
						;DECODIFICAR O DÍGITO E ESCREVER NO DISPLAY.


	;BSF		STATUS,0	;INICIALIZA O BIT DO CARRY PARA ALOCAR O BIT 1 NO REGISTRADOR COLUNA QUANDO OCORRER A ROTAÇÃO DE BITS.	
	
	
	
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
	MOVWF	LINHA_	;PASSA O CONTEÚDO DO DÍGITO CORRESPONDENTE PARA O REGISTRADOR LINHA.
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
	
	MOVLW	B'00000000' ;MOVE O NÚMERO 0 PARA O REGISTRADOR LINHA_.
	MOVWF	NUM

RETURN

NUMERO_1

	MOVLW	B'00000001' ;MOVE O NÚMERO 0 PARA O REGISTRADOR LINHA_.
	MOVWF	NUM

RETURN

NUMERO_2

	MOVLW	B'00000010' ;MOVE O NÚMERO 0 PARA O REGISTRADOR LINHA_.
	MOVWF	NUM

RETURN

NUMERO_3

	MOVLW	B'00000011' ;MOVE O NÚMERO 0 PARA O REGISTRADOR LINHA_.
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
	ADDWF	PCL,f		;E APÓS SOMA COM O CONTADOR DE LINHA DE PROGRAMA QUE PULA PARA A LINHA CORRESPONDENTE AO DÍGITO QUE SERÁ MOSTRADO
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

	END		;OBRIGATÓRIO.