;*****************************************************************************
; MULT_10x8.INC
; ROTINAS DE MULTIPLICAÇÃO 10x8
;*****************************************************************************

MULTI_10x8

	clrf	PRODUTO_H
	clrf	PRODUTO_L
	movf	MULT_2,W
	movwf	MULT_TEMP
	
TESTA_MULT_1

	btfsc	MULT1_H,1
	goto	TESTA_MULT_2
	btfsc	MULT1_H,0
	goto	TESTA_MULT_2
	movf	MULT1_L,W
	xorlw	0x00
	btfsc	STATUS,Z
	return

TESTA_MULT_2

	movf	MULT_2,W
	xorlw	0x00
	btfsc	STATUS,Z
	return

MULTIPLICA

	movf	MULT1_L,W
	addwf	PRODUTO_L,F
	btfsc	STATUS,C
	incf	PRODUTO_H,F
	movf	MULT1_H,W
	addwf	PRODUTO_H,F
	decfsz	MULT_TEMP,F
	goto	MULTIPLICA
	return