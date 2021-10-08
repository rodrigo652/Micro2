Skip to content
Search or jump to…
Pull requests
Issues
Marketplace
Explore
 
@rodrigo652 
courses-practice
/
projeto-final-rodrigo652
Private
1
00
Code
Issues
Pull requests
1
Actions
Projects
Security
Insights
projeto-final-rodrigo652/main.s
@rodrigo652
rodrigo652 Update main.s
Latest commit 9d075e1 on 6 Aug
 History
 2 contributors
@github-classroom@rodrigo652
795 lines (577 sloc)  12.5 KB
   
/*r3 = Identifica os comandos
r4  = LED e display
r5  = LED e display
r6  = Display
r7  = Display
r9  = Auxiliar
r11 = Auxiliar
r10 = Dispositivos de entrada e saída
r12 = Print
r15 = VGA pixel buffer
r13 = LEDs verdes
r16 = Display de 7 segmentos inferior*/

.equ endereco_pilha,    0x10000 #Endereço da pilha
.equ endereco_entrada_saida,  0x10000000 #Endereço entrada e saida

.equ INT_SEGS, 4 #Contagem de interrupção do cronometro

.equ LED_RED,	0x00
.equ LED_GREEN,	0x10
.equ UART,	0x1000
.equ TIMER,	0x2000
.equ VGA,	0x8000000
.equ SWITCH,0x40
.equ DS7_C,	0x20
.equ DS7_A,	0x30
.equ PB,	0x50

.equ Val_X, 0x13f #Valor de x da vga
.equ Val_Y, 0xef #Valor de y da vga

.equ COMANDO_LED_00, 0x3030 
.equ COMANDO_LED_01, 0x3031
.equ COMANDO_LED_02, 0x3032
.equ COMANDO_LED_03, 0x3033
.equ COMANDO_VGA_10, 0x3130
.equ COMANDO_COUNTER_20, 0x3230
.equ COMANDO_COUNTER_21, 0x3231
.equ COMANDO_COUNTER_22, 0x3232

#RTI
.org 0x20
RTI:
	addi 	sp, sp, -4
	stw		ra, (sp)
	
	rdctl	et, ipending
	beq		et, r0, FIM_RTI
	
	addi	ea, ea, -4
	
	andi 	et, et, 0b10
	beq		et, r0, NOT_PB
	
	call	PB_CONTADOR
	br		FIM_RTI
	
	NOT_PB:
	rdctl	et, ipending
	
	andi 	et, et, 0b01
	beq		et, r0, FIM_RTI
	
	call 	CONFIG_CONTADOR

	FIM_RTI:
	ldw		ra, (sp)
	addi 	sp, sp, 4
	
	eret

#LEDS      	                    	
COMANDO_LED: 
	movi 	r4, 0x30
	call	PRINT_COMANDO				
	
	#Seta o contador e zera os registradores
	movi	r7,  2		
	mov		r4, r0
	mov		r5, r0
	
ENTRADA_LEDS:
	
	ldwio   r9, UART(r10) #Polling esperando os digitos
	srli    r9, r9, 15
	beq     r9, r0,  ENTRADA_LEDS
		
	ldwio   r9, UART(r10)
	slli	r5, r5, 8
	add		r5, r5, r9
		
	addi	r7, r7, -1 #Verifica se entrará mais digitos
	bne		r7, r0, ENTRADA_LEDS
		
		
	srli	r4, r5, 8 #r4 será a primeira entrada e r5 a segunda
	slli	r9, r4, 8
	sub		r5, r5, r9
		
	call	PRINT_ENTRADA_LED	#mostra a posição do LED 
	call	TRATA_LED
	br		_start	

TRATA_LED:
  #comando de acender e apagar os leds
	addi	r4, r4, -0x30
	addi	r5, r5, -0x30
	
	muli	r4, r4, 10
	add		r5, r4, r5
	addi	r5, r5, -1
	
	movi	r11, 1
	sll		r11, r11, r5
	
	or		r13, r13, r11
	

	beq		r3,  r0,  ACENDE #bool = 1 acende, bool = 0 apaga.
	
	APAGA:
	xor		r13, r13, r11
	
	ACENDE:
	stwio	r13, LED_GREEN(r10)
	
	ret


DESLOCA_LED: #Desloca para esquerda ou para a direita do estado atual do LED
	movi	r4, 0x30
	call	PRINT_COMANDO		
	
	
	beq		r3, r0, DIREITA
	
	ESQUERDA:
	slli	r13, r13, 1
	stwio	r13, LED_GREEN(r10)
	
	movi	r11, 0x0a
	stwio	r11, UART(r10)
	br		_start
	
	DIREITA:
	srli	r13, r13, 1
	stwio	r13, LED_GREEN(r10)
	
	movi	r11, 0x0a
	stwio	r11, UART(r10)
	br		_start
	

#DISPLAY      	                    
COMANDO_DISPLAY:
	movi 	r4, 0x32
	call	PRINT_COMANDO				
	
	#Seta o contador e zera os registradores 
	movi	r14, 4		#contador = 4
	mov		r4, r0
	mov		r5, r0
	mov		r6, r0
	mov		r7, r0
	
ENTRADA_DISPLAY:
		#Polling para os dígitos:
		ldwio   r9, UART(r10)
	  srli    r9, r9, 15
	  beq     r9, r0,  ENTRADA_DISPLAY
		
	
	  ldwio   r9, UART(r10)
		slli	r7, r7, 8
		add		r7, r7, r9
		
		
		addi	r14, r14, -1 #Verifica se tem outros digitos:
		bne		r14, r0, ENTRADA_DISPLAY
		
		srli	r4, r7, 24 #R4 primeiro
		slli	r9, r4, 24
		sub		r7, r7, r9
		
		srli	r5, r7, 16 #R5 segundo
		slli	r9, r5, 16
		sub		r7, r7, r9
		
		srli	r6, r7, 8 #R6 terceiro
		slli	r9, r6, 8
		sub		r7, r7, r9 #R7 quarto
		
		
		movia	r11, (6+48)		#Se o dígito do segundos maior que 6 entrada invalida r11 recebe o ascii de 6
		bge		r6, r11, SET_INVALIDO
		
		call	PRINT_DISPLAY	
		
	
		addi	r4, r4, -48
		addi	r5, r5, -48
		addi	r6, r6, -48
		addi	r7, r7, -48
		
		#bool = 0 - alarme/bool = 1 - contador
		beq		r3, r0,  ALARME
		
		CONTADOR:
		addi	r7, r7, -1
		
		 
		stb		r4,  0(r16) #Salva o estado do contador na memória
		stb		r5,  1(r16)
		stb		r6,  2(r16)
		stb		r7,  3(r16)
		
		call	CONFIG_CONTADOR
		br		_start
		
		ALARME:
		
		movia	r9, ESTADO_ALARME #Salva o estado do alarme na memória
		stb		r4, 0(r9)
		stb		r5, 1(r9)
		stb		r6, 2(r9)
		stb		r7, 3(r9)
		
		call	DISPLAY_ALARME
		br		_start
	

CONFIG_CONTADOR:
	addi	sp, sp, -16 #Exibe o contador no display
	stw		r11,  (sp)
	stw		r9,  4(sp)
	stw		r5,  8(sp)
	stw		r4, 12(sp)
	
	stwio	r0, TIMER(r10)
	
	
	movia	r9,  CONTROLE_DISPARO #Contador = 0 o alarem esta desativado
	ldb		r11, (r9)
	beq		r11, r0, DISPARO_INATIVO
	
	ldwio	r11, LED_RED(r10)
	nor		r11, r11, r11
	stwio	r11, LED_RED(r10)
	

	ldb		r11, (r9) #Faz a contagem regressiva
	addi	r11, r11, -1
	stb		r11, (r9)
	
	DISPARO_INATIVO:
	movia	r9, ESTADO_ALARME
	
	ldb		r4,  0(r16)
	ldb		r11, 0(r9)
	bne		r4, r11, PULA_DISPARO
	
	ldb		r4,  1(r16)
	ldb		r11, 1(r9)
	bne		r4, r11, PULA_DISPARO
	
	ldb		r4,  2(r16)
	ldb		r11, 2(r9)
	bne		r4, r11, PULA_DISPARO
	
	ldb		r4,  3(r16)
	ldb		r11, 3(r9)
	bne		r4, r11, PULA_DISPARO
	
	movi	r11, -1
	beq		r4,  r11, PULA_DISPARO

	movia	r9,  CONTROLE_DISPARO         
	movi	r11, INT_SEGS
	stb		r11, (r9)
	
	PULA_DISPARO:
	movia	r9,  CONTROLE_CONTADOR #Verifica o número de interrupções do timer 
	ldb		r11, (r9)
	beq		r11, r0, COMECO_CONFIG
	
	addi	r11, r11, -1
	stb		r11, (r9)
	
	ldw		r4, 12(sp)
	ldw		r5,  8(sp)
	ldw		r9,  4(sp)
	ldw		r11,  (sp)
	addi	sp, sp, 16
	
	ret
	
	COMECO_CONFIG:
	movi	r11, INT_SEGS
	stb		r11, (r9)
	
	ldw		r4, 12(sp)
	ldw		r5,  8(sp)
	ldw		r9,  4(sp)
	ldw		r11,  (sp)
	addi	sp, sp, 16
	

	addi	sp, sp, -28 #Configura o contador
	stw		r9,    (sp)
	stw		r11,  4(sp)
	stw		r20,  8(sp)
	stw		r21, 12(sp)
	stw		r22, 16(sp)
	stw		r23, 20(sp)
	stw		ra,  24(sp)
	
	ldb		r20,  0(r16)
	ldb		r21,  1(r16)
	ldb		r22,  2(r16)
	ldb		r23,  3(r16)
	
	addi	r23, r23, 1
	
	CHECA_10_SEG:
	movi	r9,  9
	ble		r23, r9, CHECA_1_MIN
	
	mov		r23, r0
	addi	r22, r22, 1
	
	CHECA_1_MIN:
	movi	r9,  6
	blt		r22, r9, CHECA_10_MIN
	
	mov		r23, r0
	mov		r22, r0
	addi	r21, r21, 1
	
	CHECA_10_MIN:
	movi	r9,  9
	ble		r21, r9, CHECA_100_MIN
	
	mov		r21, r0
	addi	r20, r20, 1
	
	CHECA_100_MIN:
	/*Se (dezena_de_minuto > 9):
		 (zera_contador)*/
	movi	r9,  9
	ble		r20, r9, FIM_CONFIG
	
	mov		r20, r0
	mov		r21, r0
	
	FIM_CONFIG:
	stb		r20,  0(r16)
	stb		r21,  1(r16)
	stb		r22,  2(r16)
	stb		r23,  3(r16)
	
	call	SET_DISPLAY_CONT
	
	ldw		r9,    (sp)
	ldw		r11,  4(sp)
	ldw		r20,  8(sp)
	ldw		r21, 12(sp)
	ldw		r22, 16(sp)
	ldw		r23, 20(sp)
	ldw		ra,  24(sp)
	addi	sp, sp, 28
	
	ret
	
SET_DISPLAY_CONT: 
	addi	sp, sp, -20
	stw		r11, 16(sp)
	stw		r4,  12(sp)
	stw		r5,   8(sp)
	stw		r6,   4(sp)
	stw		r7,    (sp)

	mov		r11, r0
	

	ldb		r4, 0(r16) #Aplica a conversao para cada digito
	addi	r9,   r4,  CONVERSAO
	ldb		r9,  (r9)
	slli	r9,   r9,  24
	add		r11,  r11, r9
	
	ldb		r5, 1(r16)
	addi	r9,   r5,  CONVERSAO
	ldb		r9,  (r9)
	slli	r9,   r9,  16
	add		r11,  r11, r9
	
	ldb		r6, 2(r16)
	addi	r9,   r6,  CONVERSAO
	ldb		r9,  (r9)
	slli	r9,   r9,  8
	add		r11,  r11, r9
	
	ldb		r7, 3(r16)
	addi	r9,   r7,  CONVERSAO
	ldb		r9,  (r9)
	add		r11,  r11, r9
	
	stwio	r11, DS7_C(r10)
	
	stb		r4,  0(r16)
	stb		r5,  1(r16)
	stb		r6,  2(r16)
	stb		r7,  3(r16)
	
	ldw		r11, 16(sp)
	ldw		r4,  12(sp)
	ldw		r5,   8(sp)
	ldw		r6,   4(sp)
	ldw		r7,    (sp)
	addi	sp, sp, 20
	
	ret


DISPLAY_ALARME: #Exibe o estado do alarme no display:
	mov		r11, r0	   	
	
	addi	r9,  r4,  CONVERSAO
	ldb		r9, (r9)
	slli	r9,  r9,  24
	add		r11, r11, r9
	
	addi	r9,  r5,  CONVERSAO
	ldb		r9, (r9)
	slli	r9,  r9,  16
	add		r11, r11, r9
	
	addi	r9,  r6,  CONVERSAO
	ldb		r9, (r9)
	slli	r9,  r9,  8
	add		r11, r11, r9
	
	addi	r9,  r7,  CONVERSAO
	ldb		r9, (r9)
	add		r11, r11, r9
	
	stwio	r11, DS7_A(r10)
	movia 	r9,  ESTADO_ALARME
	
	ret
	
ZERA_ALARME:
	movi	r4, 0x32
	call	PRINT_COMANDO
	
	stwio	r0,  DS7_A(r10)
	
	movia	r9,  ESTADO_ALARME #Zera o estado do alarme
	movi	r11, -1
	
	stb		r11, 0(r9)
	stb		r0,  1(r9)
	stb		r0,  2(r9)
	stb		r0,  3(r9)
	
	movi	r11, 0x0a
	stwio	r11, UART(r10)
	br		_start
		

SET_INVALIDO: #Printa invalido na uart
	movi	r11, 0x20
	stwio	r11, UART(r10)
	
	movia	r12, FORA_DO_INTERVALO
	call	PRINT_STRING
	br 		_start
	
#VGA PIXEL BUFFER    	                    
DESENHA_PIXEL:
	addi	sp, sp, -4
	stw		r11, (sp)
	
	slli	r4, r4, 1
	slli	r5, r5, 10
	add		r11,  r4, r5
	
	add		r15, r15, r11 	#Pinta com a cor de r6
	sthio	r6, (r15)
	sub		r15, r15, r11
	
	srli	r4, r4, 1
	srli	r5, r5, 10
	
	stw		r11, (sp)
	addi	sp, sp, 4
	
	ret
	
LIMPA_VIDEO:
	movi	r4, 0x31
	call	PRINT_COMANDO		
	
	mov		r4, r0
	mov		r5, r0
	
	ldhio	r6, SWITCH(r10)		
	
	movia	r7, Val_X
	movia	r9, Val_Y
	
	#Pinta no intervalo de x e de y:
	FOR_I:
		FOR_J:
			call 	DESENHA_PIXEL
			addi	r5, r5, 1
			ble		r5, r9, FOR_J
			mov		r5, r0
		
		addi	r4, r4, 1
		ble		r4, r7, FOR_I
	
	movi	r11, 0x0a
	stwio	r11, UART(r10)
	br		_start
	

#PUSH BUTTON      	                    
#Starta ou Pausa o contador
PB_CONTADOR:
	addi	sp, sp, -12
	stw		r9,   (sp)
	stw		r11, 4(sp)
	stw		r12, 8(sp)
	
	ldwio	r9,  PB+12(r10) #Verifica onde aconteceu a interrupçao
	movi  	r11, 0b0100
	
	and		r12, r11, r9
	beq		r12, r0, BOTAO_1
	
	stwio 	r11, PB+12(r10)
	br		BOTAO_2
	
	#comeco = 0 parada = 1 VERDADEIRO
	BOTAO_1:
	movi  	r11, 0b0010
	stwio 	r11, PB+12(r10)
	
	movia	r9,  TIMER_PAUSE
	movi	r11, 1
	stb		r11, (r9)			
	
	movi  	r11, 0b1011
 	stwio 	r11, TIMER+4(r10)
	
	br		FIM_PB_CONTADOR
	
	#Mesma coisa do botão 1 mas agora FALSO
	BOTAO_2:
	movi  	r11, 0b0010
	stwio 	r11, PB+12(r10)
	
	movia	r9,  TIMER_PAUSE
	stb		r0,  (r9)			
	
	movi  	r11, 0b0111
 	stwio 	r11, TIMER+4(r10)
	
	FIM_PB_CONTADOR:
	ldw		r9,   (sp)
	ldw		r11, 4(sp)
	ldw		r12, 8(sp)
	addi	sp, sp, 12
	
	ret

PRINT_STRING:
	addi	sp, sp, -8
	stw		r9,   (sp)
	stw		r11, 4(sp)
	
	LOOP_PRINT:
	ldb		r11, 0(r12) #Printa na UART
	beq		r11, r0, FIM_PRINT
	
	ldwio	r9,  UART+4(r10)
	beq		r9,  r0, FIM_CHAR
	stwio	r11, UART(r10)

	FIM_CHAR:
	addi	r12, r12, 1
	br		LOOP_PRINT
	
	FIM_PRINT:
	ldw		r9,    (sp)
	ldw		r11,  4(sp)
	addi	sp, sp, 8
	
	ret
	
PRINT_COMANDO:
	stwio	r4, UART(r10)		#Digito 1
	stwio	r5, UART(r10)		#Digito 2
	
	ret
	
PRINT_ENTRADA_LED:
	movi	r11, 0x20
	stwio	r11, UART(r10)		
	
	stwio	r4, UART(r10)		#
	stwio	r5, UART(r10)		
	
	movi	r11, 0x0a
	stwio	r11, UART(r10)		
	
	ret
	
PRINT_DISPLAY:
	movi	r11, 0x20			
	stwio	r11, UART(r10)
	
	stwio	r4,  UART(r10)		
	stwio	r5,  UART(r10)		
	
	movi	r11, 0x3a
	stwio	r11, UART(r10)		
	
	stwio	r6,  UART(r10)		
	stwio	r7,  UART(r10)		
	
	movi	r11, 0x0a
	stwio	r11, UART(r10)		
	
	ret
	
#AUXILIARES
COMANDO_APAGAR:
	addi	r3, r3, 1
	br		COMANDO_LED			#LED = VERDADEIRO
	
COMANDO_ACENDER:
	br		COMANDO_LED			#LED = FALSO
	
COMANDO_CONT:
	addi	r3, r3, 1
	br		COMANDO_DISPLAY		#CONTADOR = VERDADEIRO
	
COMANDO_ALARME:
	br		COMANDO_DISPLAY		#CONTADOR = FALSO
	
DESLOCA_ESQUERDA:
	addi	r3, r3, 1
	br		DESLOCA_LED			
	
DESLOCA_DIREITA:
	br		DESLOCA_LED			
	
.global _start
_start:
	movia	sp,  endereco_pilha
	movia	r10, endereco_entrada_saida
	
	movi  	r11, 0b0110 #Iterrupcao botao 1 e 2
	stwio 	r11, PB+8(r10)
	
	
 	movia 	r9, 12500000 #1/4 segundo
	
 	andi  	r11, r9, 0xFFFF
 	stwio 	r11, TIMER+8(r10) 
	
 	srli  	r11, r9, 16
 	stwio 	r11, TIMER+12(r10)
 	
	movi  	r11, 0b0111
 	stwio 	r11, TIMER+4(r10)
	
	movia	r9,  TIMER_PAUSE
	ldb		r11, (r9)
	beq		r11, r0, DONT_RESET_CONTINUE
	
	movi  	r11, 0b1011
 	stwio 	r11, TIMER+4(r10)
	
 	DONT_RESET_CONTINUE: 
	movi  	r11, 0b11 #Interrupcao do pushbutton
	wrctl 	ienable, r11
   
  movi  	r11, 0b1
  wrctl 	status, r11
	
	movia	r16, ESTADO_CONTADOR #0 o contador
	movia	r9,  INICIO_EXEC
	ldb		r11, 0(r9)
	beq		r11, r0, NAO_ZERADO
	call	SET_DISPLAY_CONT
	movia	r9,  INICIO_EXEC
	stb		r0,  0(r9)
	
	NAO_ZERADO:
	mov		r3,  r0
	mov		r4,  r0
	mov		r5,  r0
	mov		r6,  r0
	mov		r7,  r0
	mov		r8,  r0
	mov		r9,  r0
	mov		r11, r0
	mov		r14, r0
	movia	r15, VGA
	mov		r20, r0
	mov		r21, r0
	mov		r22, r0
	mov		r23, r0
	
	movia	r12, STRING_MENU
	call	PRINT_STRING

	movi	r7, 2	#Comando na UART
	
	LE_COMANDO:
	ldwio   r9, UART(r10)
  srli    r9, r9, 15
  beq     r9, r0, LE_COMANDO
	
  ldwio   r9, UART(r10)
	slli	r5, r5, 8
	add		r5, r5, r9
	
  addi    r7, r7, -1
  bne     r7, r0, LE_COMANDO
	
	CHAMA_COMANDO:
	movi 	r7, COMANDO_LED_00
	beq		r5, r7, COMANDO_APAGAR
	
	movi 	r7, COMANDO_LED_01
	beq		r5, r7, COMANDO_ACENDER
	
	movi 	r7, COMANDO_LED_02
	beq		r5, r7, DESLOCA_ESQUERDA
	
	movi 	r7, COMANDO_LED_03
	beq		r5, r7, DESLOCA_DIREITA
	
	movi 	r7, COMANDO_VGA_10
	beq		r5, r7, LIMPA_VIDEO
	
	movi 	r7, COMANDO_COUNTER_20
	beq		r5, r7, COMANDO_CONT
	
	movi 	r7, COMANDO_COUNTER_21
	beq		r5, r7, COMANDO_ALARME
	
	movi 	r7, COMANDO_COUNTER_22
	beq		r5, r7, ZERA_ALARME
	
	movi	r12, STRING_INVALIDA
	call	PRINT_STRING
	br		_start
	
.data
STRING_MENU:
	.asciz "Entre com o comando: "
	
STRING_INVALIDA:
	.asciz "ENTRADA ERRADA!"
	
FORA_DO_INTERVALO:
	.asciz "FORA DO INTERVALO MM:SS!"
	
INICIO_EXEC:
	.byte    1
	
ESTADO_CONTADOR:
	.byte	 0, 0, 0, 0
	
ESTADO_ALARME:
	.byte	-1, 0, 0, 0

CONTROLE_CONTADOR:
	.byte 	INT_SEGS
	
CONTROLE_DISPARO:
	.byte	0
	
TIMER_PAUSE:
	.byte	0
	
CONVERSAO:
	.byte 	0x3f,0x06,0x5b,0x4f,0x66,0x6d,0x7d,0x07,0x7f,0x67,0x77,0x7c,0x39,0x5e,0x79,0x71

.end
© 2021 GitHub, Inc.
Terms
Privacy
Security
Status
Docs
Contact GitHub
Pricing
API
Training
Blog
About
Loading complete
