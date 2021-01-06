;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                   	DIV_16x16B.INC			                   *
;*                           UTFPR  	                           *
;*         DESENVOLVIDO POR PAULO DE TARSO NEVES JUNIOR		       *
;*   VERSÃO: 1.0                           DATA: 22/04/2012 	   *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                     DESCRIÇÃO DO ARQUIVO                        *
;*-----------------------------------------------------------------*
;*	ARQUIVO INCLUDE PARA DIVISÃO DE DOIS NÚMEROS DE 16 BITS EM	   * 
;*  QUATRO REGISTRADORES (DIVIDENDO_H, DIVIDENDO_L, DIVISOR_H E	   *
;*	DIVISOR_L) PASSADOS PELO PROGRAMA PRINCIPAL.				   *
;*	O RESULTADO SERÁ ARMAZENADO EM DIVIDENDO_H E DIVIDENDO_L.	   *
;*	O RESTO SERÁ ARMAZENADO EM RESTO_H E RESTO_L.				   *
;*					 											   *
;*-----------------------------------------------------------------*
;* ROTINAS A SEREM CHAMADAS PELO PROGRAMA PRINCIPAL:		       *
;*					 											   *
;* 	DIVIDE_16x16 - Divide o conteúdo de DIVIDENDO_H:DIVIDENDO_L e  *
;*					DIVISOR_H:DIVISOR_L							   *
;*					 											   *
;*-----------------------------------------------------------------*
;* REGISTRADORES A SEREM DECLARADOS NO PROGRAMA PRINCIPAL:		   *
;* 	NUM_1		- Multiplicando.								   *
;* 	NUM_2		- Multiplicador.								   *
;* 	PRODUTO_L	- Byte baixo do resultado.						   *
;* 	PRODUTO_H	- Byte alto do resultado.						   *
;*					 											   *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

DIVIDE_16x16
	clrf	QUOCIENTE_H
	clrf	QUOCIENTE_L
	movf	DIVIDENDO_L,W
	movwf	RESTOTMP_L
	movf	DIVIDENDO_H,W
	movwf	RESTOTMP_H

TESTA_DIVIDENDO
	movf	DIVISOR_L,W
	subwf	RESTOTMP_L,W
	movlw	0x01
	btfss	STATUS,C
	subwf	RESTOTMP_H,W
	btfss	STATUS,C
	goto	DIV
	movf	DIVIDENDO_L,W
	movwf	RESTO_L
	movf	DIVIDENDO_H,W
	movwf	RESTO_H	

DIV	
	call	SUBTRAI_16x16
	movlw	0x01
	btfss	STATUS,C
	return
	addwf	QUOCIENTE_L,F
	btfsc	STATUS,C
	incf	QUOCIENTE_H,F
	movf	RESTOTMP_L,W
	movwf	RESTO_L
	movf	RESTOTMP_H,W
	movwf	RESTO_H
	goto	DIV
	
SUBTRAI_16x16
	movf	DIVISOR_L,W
	subwf	RESTOTMP_L,F
	movlw	0x01
	btfss	STATUS,C
	subwf	RESTOTMP_H,F
	btfss	STATUS,C
	goto	EMPRESTA
	movf	DIVISOR_H,W
	subwf	RESTOTMP_H,F
	return

EMPRESTA
	movf	DIVISOR_H,W
	subwf	RESTOTMP_H,F
	bcf		STATUS,C
	return