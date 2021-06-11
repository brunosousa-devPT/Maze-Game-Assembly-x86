;------------------------------------------------------------------------
; TRABALHO PRATICO - TECNOLOGIAS e ARQUITECTURAS de COMPUTADORES
;   JOGO DO LABIRINTO
;	ANO LECTIVO 2020/2021
;--------------------------------------------------------------
;       JORGE GABRIEL QUERIDO DOS SANTOS Nº:2020133143
;		BRUNO AMADO SOUSA 				 Nº:2020132971
;		Turma Prática P9
;
;		arrow keys to move 
;		press ESC to exit
;
;--------------------------------------------------------------

.8086
.model small
.stack 2048

dseg	segment para public 'data'


		STR12	 		DB 		"            "	; String para 12 digitos
		STR3            DB      "    "           ;String para 4 digitos
		DDMMAAAA 		db		"                     "
		
		Horas			dw		0				; Vai guardar a HORA actual
		Minutos			dw		0				; Vai guardar os minutos actuais
		Segundos		dw		0				; Vai guardar os segundos actuais
		Old_seg			dw		0				; Guarda os �ltimos segundos que foram lidos
		Tempo_init		dw		0				; Guarda O Tempo de inicio do jogo
		Tempo_j			dw		0				; Guarda O Tempo que decorre o  jogo
		Tempo_limite	dw		99				; tempo m�ximo de Jogo
		String_TJ		db		"  /99$"

		Derrota 		db 		"Acabou o Tempo, Perdeu! $"
        String_nome  	db	    "LUA     $"	
		Construir_nome	db	    "               $"	
		Dim_nome		dw		3	; Comprimento do Nome
		indice_nome		dw		0	; indice que aponta para Construir_nome
		
		Fim_Ganhou		db	    " Ganhou $"	
		Fim_Perdeu		db	    " Perdeu $"	

        Erro_Open       db      'Erro ao tentar abrir o ficheiro$'
        Erro_Ler_Msg    db      'Erro ao tentar ler do ficheiro$'
        Erro_Close      db      'Erro ao tentar fechar o ficheiro$'
        Fich         	db      'labiB.TXT',0
		TopFich        db       'top.TXT',0
		
		
        HandleFich      dw      0
        car_fich        db      ?
		
		string			db	"Teste pr�tico de T.I",0
		Car				db	32	; Guarda um caracter do Ecran 
		Cor				db	7	; Guarda os atributos de cor do caracter
		POSy			db	3	; a linha pode ir de [1 .. 25]
		POSx			db	3	; POSx pode ir [1..80]	
		POSya			db	3	; Posi��o anterior de y
		POSxa			db	3	; Posi��o anterior de x
		
		GuardarValor    db  0	; guardar valor de posx e posy nas colisoes
		GuardarIndice   db  0   ; Indice palavras
		GuardarSegundos db  0   ;Isto serve para nao alterar a informaçao nao Old_seg
		Indicie_Palavra db 	5
		
		MENULEGEND1     db  "JOGO DO LABIRINTO $"
		
		MENUITEM1       db  " 1-JOGAR $"
		MENUITEM2       db  " 2-TOP10 $"
		MENUITEM3       db  " 3-SAIR  $"
		
		HELPLEGENDA     db  " Prima ENTER para seguir para o proximo nivel! $" 
		HELPLEGENDAFIM     db  " Prima ENTER para seguir para o menu! $"
		
		booleanvalue    dw  1
		booleanPalavraValue db 1
		Pontuacao           dw 0
		PALAVRAPONTOS        db "Pontos $"
		NIVEL_ATUAL     db   0
		FIM_LEGENDA     db   "Passou todos os niveis! $"
		LEVELDEC        dw   01
		PONTTEMP        dw   0
		FIMJOGOVAR      db   1
		OFFTHEGAME      db   0
		
		i               db   0  ; variavel para loops   
		VALIDALETRASIGUAL db 0  ; validar a igualdade de caracteres  
		TEMPORARIOMACROTROCAR  db 0 ; usado para guardar valores temproarios para passar para a macro 
		
		str_num			db 		5 dup(?),'$'
		ultimo_num_aleat dw 0
		
		string_TEM      db  "Tem $"   
		
		
		
dseg	ends

cseg	segment para public 'code'
assume		cs:cseg, ds:dseg



;########################################################################
goto_xy	macro		POSx,POSy
		mov		ah,02h
		mov		bh,0		; numero da p�gina
		mov		dl,POSx
		mov		dh,POSy
		int		10h
endm

;########################################################################
; MOSTRA - Faz o display de uma string terminada em $

MOSTRA MACRO STR 
		MOV 	AH,09H
		LEA 	DX,STR 
		INT		21H
ENDM


TROCA_STR  MACRO INT 
		mov   	cl,INT 
		mov   	SI,cx
		mov  	bl, String_nome[SI]
		mov 	Construir_nome[SI],bl
	
ENDM 

PRINT_STR_TO_INT MACRO INT 
	
		mov 	ax,INT
		mov 	bl,10
		div 	bl
		add 	al,30h
		add 	ah,30h
		mov     String_TJ[0],al
		mov     String_TJ[1],ah
		
		GOTO_XY 57,0
		MOSTRA String_TJ
		

ENDM

PRINT_STR_TO_INT_V2 MACRO INT,POSx,POSy
		
		mov 	ax,INT
		mov 	bl,10
		div 	bl
		add 	al,30h
		add 	ah,30h
		mov     STR3[0],al
		mov     STR3[1],ah
		mov     STR3[2],'$'
		GOTO_XY POSx,POSy
		MOSTRA STR3
			

ENDM




; FIM DAS MACROS



;ROTINA PARA APAGAR ECRAN

apaga_ecran	proc
			mov		ax,0B800h
			mov		es,ax
			xor		bx,bx
			mov		cx,25*80
		
apaga:		mov		byte ptr es:[bx],' '
			mov		byte ptr es:[bx+1],7
			inc		bx
			inc 	bx
			loop	apaga
			ret
apaga_ecran	endp


;########################################################################
; IMP_FICH

IMP_FICH	PROC

		;abre ficheiro
        mov     ah,3dh
        mov     al,0
        lea     dx,Fich
        int     21h
        jc      erro_abrir
        mov     HandleFich,ax
        jmp     ler_ciclo

erro_abrir:
        mov     ah,09h
        lea     dx,Erro_Open
        int     21h
        jmp     sai_f

ler_ciclo:
        mov     ah,3fh ;Read from file using handle
        mov     bx,HandleFich
        mov     cx,1
        lea     dx,car_fich
        int     21h
		jc		erro_ler
		cmp		ax,0		;EOF?
		je		fecha_ficheiro
        mov     ah,02h
		mov		dl,car_fich
		int		21h
		jmp		ler_ciclo

erro_ler:
        mov     ah,09h
        lea     dx,Erro_Ler_Msg
        int     21h

fecha_ficheiro:
        mov     ah,3eh
        mov     bx,HandleFich
        int     21h
        jnc     sai_f

        mov     ah,09h
        lea     dx,Erro_Close
        Int     21h
sai_f:	
		RET
		
IMP_FICH	endp		
;########################################################################


IMP_TOP10	PROC

		;abre ficheiro
        mov     ah,3dh
        mov     al,0
        lea     dx,TopFich
        int     21h
        jc      erro_abrir
        mov     HandleFich,ax
        jmp     ler_ciclo

erro_abrir:
        mov     ah,09h
        lea     dx,Erro_Open
        int     21h
        jmp     sai_f

ler_ciclo:
        mov     ah,3fh ;Read from file using handle
        mov     bx,HandleFich
        mov     cx,1
        lea     dx,car_fich
        int     21h
		jc		erro_ler
		cmp		ax,0		;EOF?
		je		fecha_ficheiro
        mov     ah,02h
		mov		dl,car_fich
		int		21h
		jmp		ler_ciclo

erro_ler:
        mov     ah,09h
        lea     dx,Erro_Ler_Msg
        int     21h

fecha_ficheiro:
        mov     ah,3eh
        mov     bx,HandleFich
        int     21h
        jnc     sai_f

        mov     ah,09h
        lea     dx,Erro_Close
        Int     21h
sai_f:	
		RET
		
IMP_TOP10	endp

;########################################################################
;----------horas
Ler_TEMPO PROC	
 
		PUSH AX
		PUSH BX
		PUSH CX
		PUSH DX
	
		PUSHF
		
		MOV AH, 2CH             ; Buscar a hORAS
		INT 21H                 
		
		XOR AX,AX
		MOV AL, DH              ; segundos para al
		mov Segundos, AX		; guarda segundos na variavel correspondente
		
		XOR AX,AX
		MOV AL, CL              ; Minutos para al
		mov Minutos, AX         ; guarda MINUTOS na variavel correspondente
		
		XOR AX,AX
		MOV AL, CH              ; Horas para al
		mov Horas,AX			; guarda HORAS na variavel correspondente
 
		POPF
		POP DX
		POP CX
		POP BX
		POP AX
 		RET 
Ler_TEMPO   ENDP 

;###################################3

	
	
;########################################################################
; LE UMA TECLA	

LE_TECLA	PROC
sem_tecla:
		;tanto a booleanvalue como a OFFTHEGAME permitem a esta funcao saber se esta em jogo ou nao evitando wrong displays
		;apesar de elas estarem a fazer a mesma coisa como o OFFTHEGAME e usado em situacoes diferentes decidimos nao trocar as variaveis e deixar as duas
		cmp booleanvalue,0
		jne LER
		cmp OFFTHEGAME,1
		jne LER
		;como esta proc LE_TECLA esta no ciclo do AVATAR, a funcao Trata_Horas vai estar constantemente a ser chamada mesmo que o utilizador nao clique
		;em nenhuma tecla permitindo assim um refresh continuo do tempo no jogo
		call Trata_Horas
		MOV	AH,0BH
		INT 21h
		cmp AL,0
		je	sem_tecla
LER:
		MOV	AH,0BH
		INT 21h
		cmp AL,0
		je	sem_tecla
		
	
		
		MOV	AH,08H
		INT	21H
		MOV	AH,0
		CMP	AL,0
		JNE	SAI_TECLA
		MOV	AH, 08H
		INT	21H
		MOV	AH,1
SAI_TECLA:	
		RET
LE_TECLA	endp


;HOJE
HOJE PROC	

		PUSH AX
		PUSH BX
		PUSH CX
		PUSH DX
		PUSH SI
		PUSHF
		
		
		
		
		MOV AH, 2AH             ; Buscar a data
		INT 21H                 
		PUSH CX                 ; Ano-> PILHA
		XOR CX,CX              	; limpa CX
		MOV CL, DH              ; Mes para CL
		PUSH CX                 ; Mes-> PILHA
		MOV CL, DL				; Dia para CL
		PUSH CX                 ; Dia -> PILHA
		XOR DH,DH                    
		XOR	SI,SI
; DIA ------------------ 
; DX=DX/AX --- RESTO DX   
		XOR DX,DX               ; Limpa DX
		POP AX                  ; Tira dia da pilha
		MOV CX, 0               ; CX = 0 
		MOV BX, 10              ; Divisor
		MOV	CX,2
DD_DIV:                         
		DIV BX                  ; Divide por 10
		PUSH DX                 ; Resto para pilha
		MOV DX, 0               ; Limpa resto
		loop dd_div
		MOV	CX,2
DD_RESTO:
		POP DX                  ; Resto da divisao
		ADD DL, 30h             ; ADD 30h (2) to DL
		MOV DDMMAAAA[SI],DL
		INC	SI
		LOOP DD_RESTO            
		MOV DL, '/'             ; Separador
		MOV DDMMAAAA[SI],DL
		INC SI
; MES -------------------
; DX=DX/AX --- RESTO DX
		MOV DX, 0               ; Limpar DX
		POP AX                  ; Tira mes da pilha
		XOR CX,CX               
		MOV BX, 10				; Divisor
		MOV CX,2
MM_DIV:                         
		DIV BX                  ; Divisao or 10
		PUSH DX                 ; Resto para pilha
		MOV DX, 0               ; Limpa resto
		LOOP MM_DIV
		MOV CX,2 
MM_RESTO:
		POP DX                  ; Resto
		ADD DL, 30h             ; SOMA 30h
		MOV DDMMAAAA[SI],DL
		INC SI		
		LOOP MM_RESTO
		
		MOV DL, '/'             ; Character to display goes in DL
		MOV DDMMAAAA[SI],DL
		INC SI
 
;  ANO ----------------------
		MOV DX, 0               
		POP AX                  ; mes para AX
		MOV CX, 0               ; 
		MOV BX, 10              ; 
 AA_DIV:                         
		DIV BX                   
		PUSH DX                 ; Guarda resto
		ADD CX, 1               ; Soma 1 contador
		MOV DX, 0               ; Limpa resto
		CMP AX, 0               ; Compara quotient com zero
		JNE AA_DIV              ; Se nao zero
AA_RESTO:
		POP DX                  
		ADD DL, 30h             ; ADD 30h (2) to DL
		MOV DDMMAAAA[SI],DL
		INC SI
		LOOP AA_RESTO
		POPF
		POP SI
		POP DX
		POP CX
		POP BX
		POP AX
 		RET 
HOJE   ENDP 


;*****Timer*****
;Horas 



Trata_Horas PROC

		PUSHF
		PUSH AX
		PUSH BX
		PUSH CX
		PUSH DX		

		CALL 	Ler_TEMPO				; Horas MINUTOS e segundos do Sistema
		
		MOV		AX, Segundos
		cmp		AX, Old_seg			; VErifica se os segundos mudaram desde a ultima leitura
		je		fim_horas			; Se a hora não mudou desde a última leitura sai.	
		
		
		mov		Old_seg, AX			; Se segundos são diferentes actualiza informação do tempo 
		
		mov     bx,Tempo_limite
		
		inc     Tempo_j  ;TIMER
		cmp     Tempo_j,bx
		je   	FIM
		
		mov 	ax,Horas
		MOV		bl, 10     
		div 	bl
		add 	al, 30h				; Caracter Correspondente às dezenas
		add		ah,	30h				; Caracter Correspondente às unidades
		MOV 	STR12[0],al			; 
		MOV 	STR12[1],ah
		MOV 	STR12[2],'h'		
		MOV 	STR12[3],'$'
		GOTO_XY 2,0
		MOSTRA STR12
		PRINT_STR_TO_INT Tempo_j
		
		
        
		mov 	ax,Minutos
		MOV 	bl, 10     
		div 	bl
		add 	al, 30h				; Caracter Correspondente às dezenas
		add		ah,	30h				; Caracter Correspondente às unidades
		MOV 	STR12[0],al			; 
		MOV 	STR12[1],ah
		MOV 	STR12[2],'m'		
		MOV 	STR12[3],'$'
		GOTO_XY	6,0
		MOSTRA	STR12 		
		
		mov 	ax,Segundos
		MOV 	bl, 10     
		div 	bl
		add 	al, 30h				; Caracter Correspondente às dezenas
		add		ah,	30h				; Caracter Correspondente às unidades
		MOV 	STR12[0],al			; 
		MOV 	STR12[1],ah
		MOV 	STR12[2],'s'		
		MOV 	STR12[3],'$'
		GOTO_XY	10,0
		MOSTRA	STR12
		
		;Prints construir nome no ecra
		;Building NAME and String 
		GOTO_XY 9,20
		MOSTRA  String_nome
		GOTO_XY 9,21
        MOSTRA  Construir_nome
		
		
		CALL 	HOJE				; Data de HOJE
		MOV 	al ,DDMMAAAA[0]	
		MOV 	STR12[0], al	
		MOV 	al ,DDMMAAAA[1]	
		MOV 	STR12[1], al	
		MOV 	al ,DDMMAAAA[2]	
		MOV 	STR12[2], al	
		MOV 	al ,DDMMAAAA[3]	
		MOV 	STR12[3], al	
		MOV 	al ,DDMMAAAA[4]	
		MOV 	STR12[4], al	
		MOV 	al ,DDMMAAAA[5]	
		MOV 	STR12[5], al	
		MOV 	al ,DDMMAAAA[6]	
		MOV 	STR12[6], al	
		MOV 	al ,DDMMAAAA[7]	
		MOV 	STR12[7], al	
		MOV 	al ,DDMMAAAA[8]	
		MOV 	STR12[8], al
		MOV 	al ,DDMMAAAA[9]	
		MOV 	STR12[9], al		
		MOV 	STR12[10],'$'
		GOTO_XY	68,0
		MOSTRA	STR12
		jmp fim_horas
		
		
FIM:
	call apaga_ecran
    GOTO_XY 30,10
    mov OFFTHEGAME,0
	
    MOSTRA Derrota
    GOTO_XY 30,15
    MOSTRA PALAVRAPONTOS
	mov dh,38 ;AAAA
	mov dl,15  ;AAA
	mov ax,Pontuacao ;AAA
	push dx
	push ax
	call impnum  ;AAAA
	
    ;PRINT_STR_TO_INT_V2  Pontuacao,38,15
	GOTO_XY 28,17
	MOSTRA HELPLEGENDAFIM
LER_ENTER:
	call LE_TECLA
	cmp  ah,0 
	je   IRPARAOMENU
    jmp LER_ENTER	

IRPARAOMENU:
	cmp al,13
	jne LER_ENTER
	mov Tempo_j,0
	call apaga_ecran
	call MENU
	jmp fim_horas
						
fim_horas:		
		goto_xy	POSx,POSy			; Volta a colocar o cursor onde estava antes de actualizar as horas
		
		POPF
		POP DX		
		POP CX
		POP BX
		POP AX
		RET		
			
Trata_Horas ENDP

;########################################################################
;------------------------------------------------------
;impnum - imprime um numero de 16 bits na posicao x,y
;Parametros passados pela pilha
;entrada:
;param1 -  8 bits - posicao x
;param2 -  8 bits - posicao y
;param3 - 16 bits - numero a imprimir
;saida:
;não tem parametros de saída
;notas adicionais:
; deve estar definida uma variavel => str_num db 5 dup(?),'$'
; assume-se que DS esta a apontar para o segmento onde esta armazenada str_num
; sao eliminados da pilha os parametros de entrada
impnum proc near
	push	bp
	mov		bp,sp
	push	ax
	push	bx
	push	cx
	push	dx
	push	di
	mov		ax,[bp+4] ;param3
	lea		di,[str_num+5]
	mov		cx,5
prox_dig:
	xor		dx,dx
	mov		bx,10
	div		bx
	add		dl,'0' ; dh e' sempre 0
	dec		di
	mov		[di],dl
	loop	prox_dig

	mov		ah,02h
	mov		bh,00h
	mov		dl,[bp+7] ;param1
	mov		dh,[bp+6] ;param2
	int		10h
	mov		dx,di
	mov		ah,09h
	int		21h
	pop		di
	pop		dx
	pop		cx
	pop		bx
	pop		ax
	pop		bp
	ret		4 ;limpa parametros (4 bytes) colocados na pilha
impnum endp

;########################################################################
;NEW LEVEL PROC
;Esta proc permite o controlo dos niveis do jogo
; nao recebe nenhum parametros assim como nao da output de nada simplesmente permite mudar as regras
; do jogo ao longo do tempo, ou seja a media que o utilizador vai jogando e passando os niveis esta proc
; e responsavel pelo update dos niveis assim como o fim do jogo pela vitoria
;existem variaveis de controlo como OFFTHEGAME que permitem saber se o jogador se encontra em menus ou no jogo para evitar displays errados
;########################################################################

NEW_LEVEL PROC
    call apaga_ecran
	mov OFFTHEGAME,0
	xor ax,ax
	xor bx,bx
	
	
	mov ax, Tempo_limite
	mov bx, Tempo_j
	sub ax,bx
	
	

	add Pontuacao,ax
	
	
	inc NIVEL_ATUAL
	inc LEVELDEC
	
	cmp NIVEL_ATUAL,6   
	je MODIFICAR_OPTIONS_PALAVRA6
	
	

	
;imprime splashscreen da vitoria da ronda
IMPRIME:
	
	GOTO_XY 36,10
	MOSTRA string_TEM
	GOTO_XY 20,15
	MOSTRA HELPLEGENDA
	mov dh,40 ;AAAA
	mov dl,10  ;AAA
	mov ax,Pontuacao ;AAA
	push dx
	push ax
	call impnum  ;AAAA
	;PRINT_STR_TO_INT_V2 Pontuacao,40,10
	GOTO_XY 47,10
	MOSTRA PALAVRAPONTOS
	
	
LER_ENTER: 
    call LE_TECLA
	cmp  ah,0 
	je   AVANCAR_LEVEL
    jmp LER_ENTER	

AVANCAR_LEVEL:
	cmp al,13
	je MODIFICAR_OPTIONS_PALAVRA1
	cmp al, 27
	je FIM
	jmp LER_ENTER
	
	
;Estes "modificar"s	 permitem a definicao das regras doss proximos niveis 
MODIFICAR_OPTIONS_PALAVRA1:
	add Pontuacao,2
	cmp FIMJOGOVAR,0
	je RESETARPALAVRA
	
	cmp NIVEL_ATUAL,1
	jne MODIFICAR_OPTIONS_PALAVRA2
	mov String_nome[0],'M'
	mov String_nome[1],'E'
	mov String_nome[2],'S'
	mov String_nome[3],'A'
	mov POSx,3
	mov POSy,18
	
	
	mov Dim_nome,4
	

MODIFICAR_OPTIONS_PALAVRA2:
	add Pontuacao,4
	cmp NIVEL_ATUAL,2
	jne MODIFICAR_OPTIONS_PALAVRA3

	mov String_nome[0],'E'
	mov String_nome[1],'S'
	mov String_nome[2],'E'
	mov String_nome[3],'C'
	mov Dim_nome,4
	mov Tempo_limite,80
	mov String_TJ[3],'8'
	mov String_TJ[4],'0'
	mov POSx,47
	mov POSy,9
	
MODIFICAR_OPTIONS_PALAVRA3:
	add Pontuacao,8
	cmp NIVEL_ATUAL,3
	jne MODIFICAR_OPTIONS_PALAVRA4
	
	mov String_nome[0],'C'
	mov String_nome[1],'H'
	mov String_nome[2],'I'
	mov String_nome[3],'C'
	mov String_nome[4],'O'
	mov Dim_nome,5
	mov Tempo_limite,70
	mov String_TJ[3],'7'
	mov String_TJ[4],'0'
	mov POSx,8
	mov POSy,18
	
	
MODIFICAR_OPTIONS_PALAVRA4:
	add Pontuacao,16
	cmp NIVEL_ATUAL,4
	jne MODIFICAR_OPTIONS_PALAVRA5
	
	mov String_nome[0],'B'
	mov String_nome[1],'A'
	mov String_nome[2],'L'
	mov String_nome[3],'E'
	mov String_nome[4],'I'
	mov String_nome[5],'A'
	mov Dim_nome,6
	mov Tempo_limite,70
	mov String_TJ[3],'7'
	mov String_TJ[4],'0'
	mov POSx,49
	mov POSy,18
	
MODIFICAR_OPTIONS_PALAVRA5:
	add Pontuacao,32
	
	cmp NIVEL_ATUAL,5
	jne MODIFICAR_OPTIONS_PALAVRA6
	
	mov String_nome[0],'P'
	mov String_nome[1],'A'
	mov String_nome[2],'N'
	mov String_nome[3],'D'
	mov String_nome[4],'E'
	mov String_nome[5],'M'
	mov String_nome[6],'I'
	mov String_nome[7],'A'
	mov Dim_nome,8
	mov Tempo_limite,60
	mov String_TJ[3],'6'
	mov String_TJ[4],'0'
	mov POSx,64
	mov POSy,14
	

MODIFICAR_OPTIONS_PALAVRA6:
	cmp NIVEL_ATUAL,6
	je BLACKSCREEN
	

RESETARPALAVRA:

	mov Construir_nome[0],' '
	mov Construir_nome[1],' '
	mov Construir_nome[2],' '
	mov Construir_nome[3],' '
	mov Construir_nome[4],' '
	mov Construir_nome[5],' '
	mov Construir_nome[6],' '
	mov Construir_nome[7],' '
	mov Construir_nome[8],' '
	
	cmp FIMJOGOVAR,0
	jne GO
	
	;no fim do jogo isto faz reset as definicoes do jogo (tempo,palavra inicial, dimensao da palavra, posicao inicial )

RESETARDEFAULTRULES:
	mov NIVEL_ATUAL,0
	mov Dim_nome,3
	mov GuardarIndice,0
	mov Pontuacao,0
	mov String_nome[0],'A'
	mov String_nome[1],'B'
	mov String_nome[2],'A'
	mov String_nome[3],' '
	mov String_nome[4],' '
	mov String_nome[5],' '
	mov String_nome[6],' '
	mov String_nome[7],' '
	mov Tempo_limite,99
	mov String_TJ[3],'9'
	mov String_TJ[4],'9'
	mov POSx,3
	mov POSy,3
	GOTO_XY 3,3
	
	jmp FIM
	
	


GO:
   mov OFFTHEGAME,1
   call apaga_ecran
   goto_xy 0,0 
   call IMP_FICH
  ; mov  POSy,3
   ;mov  POSx,3
   goto_xy POSx,POSy
   mov Tempo_j,0
   mov GuardarIndice,0
   
   call Avatar
   jmp FIM
 
 ;Splashcreen da vitoria
BLACKSCREEN:
	call apaga_ecran
	mov dh,40 
	mov dl,10  
	mov ax,Pontuacao 
	push dx
	push ax
	call impnum  ;imprimir pontuacao no ecra
	;imprimir legenda ecra
	GOTO_XY 50,10
	MOSTRA PALAVRAPONTOS
	GOTO_XY 40,12
	MOSTRA FIM_LEGENDA
	mov FIMJOGOVAR,0
	mov NIVEL_ATUAL,0
	jmp LER_ENTER
	
FIM: 
   call apaga_ecran
   call MENU
   RET   
NEW_LEVEL ENDP



; Avatar

AVATAR	PROC
			
			mov		ax,0B800h
			mov		es,ax
			
			
			goto_xy	POSx,POSy		; Vai para nova possi��o
			mov 	ah,08h			; Guarda o Caracter que est� na posi��o do Cursor
			mov		bh,0			; numero da p�gina
			int		10h			
			mov		Car, al			; Guarda o Caracter que est� na posi��o do Cursor
			mov		Cor, ah			; Guarda a cor que est� na posi��o do Cursor	
			
			
			
			

CICLO:		

			goto_xy	POSxa,POSya		; Vai para a posi��o anterior do cursor
			mov		ah, 02h
			mov		dl, Car			; Repoe Caracter guardado 
			int		21H		
		
			goto_xy	POSx,POSy		; Vai para nova possi��o
			mov 	ah, 08h
			mov		bh,0			; numero da p�gina
			int		10h		
			mov		Car, al			; Guarda o Caracter que est� na posi��o do Cursor
			mov		Cor, ah			; Guarda a cor que est� na posi��o do Cursor
			
			;compare characters
		
			
			cmp al,32 ;verificar se nao estamos a analisar um space
			je IMPRIME
	
			mov SI,-1 ;comecar em -1 para quando comecar COMPARAR, SI ser igual a 0
		
			mov cx, Dim_nome 
	
;comparar o character com as palavras
	
COMPARAR:   
	inc SI
	cmp SI, cx
	JA IGUAL

	;se este character já tiver sido descoberto entao parar de comparar pois ja foi contando, evitando assim a pessoa obter os pontos da letra
	;e passar mais facilmente o nivel
	cmp al, Construir_nome[SI]
	je IGUAL
	;se o character e igual a um na variavel onde esta a palavra do nivel entao foi descoberta uma letra
	cmp al,String_nome[SI]
	jne COMPARAR
	
	mov bl ,String_nome[SI]
	mov Construir_nome[SI],bl
	
	inc GuardarIndice
	inc Pontuacao
	;esta variavel permite ao IGUAL saber se houve uma letra encontrada ou nao, se nao no igual ele salta para o IMPRIME evitando que o utilizador apanhe uma letra diferente
	mov VALIDALETRASIGUAL,1
	
	jmp COMPARAR
	
	
	


IGUAL: 
	cmp VALIDALETRASIGUAL,0 
	je IMPRIME
			

	;comparar indice com tamanho para acabar nivel
	xor ax,ax
	mov  ax,Dim_nome
	mov VALIDALETRASIGUAL,0 ; repor valor para poder usa lo de novo em cima  AAAA
	cmp GuardarIndice,al ;tem de se comparar com variavel
	jne IMPRIME
	call NEW_LEVEL
	

	
			
IMPRIME:	
			mov		ah, 02h
			mov		dl, 190	; Coloca AVATAR
			int		21H	
			goto_xy	POSx,POSy	; Vai para posi��o do cursor
		
			mov		al, POSx	; Guarda a posi��o do cursor
			mov		POSxa, al
			mov		al, POSy	; Guarda a posi��o do cursor
			mov 	POSya, al
		
LER_SETA:	call 	LE_TECLA
			cmp		ah, 1
			je		ESTEND
			CMP 	AL, 27	; ESCAPE
			JE		FIM
			jmp		LER_SETA
		
ESTEND:		cmp 	al,48h
			jne		BAIXO
			;Detetar colisão com parede em cima
			xor     ah,ah     ; limpar
			mov     al,POSy
			;este GuardarValor serve para nao alterar o valor em al usando o valor decremente ou incrementado respondente a futura posicao do player na macro goto_xy
			mov 	GuardarValor,al
			dec     GuardarValor
			xor     al,al  ; limp
			goto_xy POSx,GuardarValor  ;cursor para onde se pretende ir
			mov		ah,08h  ; usar a sfuncao 8 de int 10
			mov 	bh,0
			int 	10H
			
			cmp     al,177 ; comparar carateres
			je		CICLO
			;se nao detetar colisao entao avançar
			dec		POSy		;cima
			
			jmp		CICLO

BAIXO:		cmp		al,50h
			jne		ESQUERDA
			;Detetar colisão com parede em baixo
			xor     ah,ah     ; limpar
			mov     al,POSy
			mov 	GuardarValor,al
			inc     GuardarValor
			xor     al,al  ; limp
			goto_xy POSx,GuardarValor  ;cursor para onde se pretende ir
			mov		ah,08h  ; usar a sfuncao 8 de int 10
			mov 	bh,0
			int 	10H
			
			cmp     al,177 ; comparar carateres
			je		CICLO
			;se nao detetar colisao entao avançar
			inc 	POSy		;Baixo
			jmp		CICLO

ESQUERDA:
			cmp		al,4Bh
			jne		DIREITA
			;Detetar colisão com parede na esquerda
			xor     ah,ah     ; limpar
			mov     al,POSx
			mov 	GuardarValor,al
			dec     GuardarValor
			xor     al,al  ; limp
			goto_xy GuardarValor,POSy  ;cursor para onde se pretende ir
			mov		ah,08h  ; usar a sfuncao 8 de int 10
			mov 	bh,0
			int 	10H
			
			cmp     al,177 ; comparar carateres
			je		CICLO
			;se nao detetar colisao entao avançar
			dec		POSx		;Esquerda
			jmp		CICLO

DIREITA:
			cmp		al,4Dh
			jne		LER_SETA 
			;Detetar colisão com parede na direita
			xor     ah,ah     ; limpar
			mov     al,POSx
			mov 	GuardarValor,al
			inc     GuardarValor
			xor     al,al  ; limp
			goto_xy GuardarValor,POSy  ;cursor para onde se pretende ir
			mov		ah,08h  ; usar a sfuncao 8 de int 10
			mov 	bh,0
			int 	10H
			
			cmp     al,177 ; comparar carateres
			je		CICLO
			;se nao detetar colisao entao avançar
			inc		POSx		;Direita
			jmp		CICLO

fim:			
			
			RET
AVATAR		endp


;MENU 

MENU PROC
call apaga_ecran
goto_xy 28,5
MOSTRA MENULEGEND1
goto_xy 30,12
MOSTRA MENUITEM1
goto_xy 30,14
MOSTRA MENUITEM2
goto_xy 30,16
MOSTRA MENUITEM3
goto_xy 90,30
LER_COMANDO:
	call LE_TECLA
	cmp ah,0
	je  PLAY
	CMP AL,27
	JE FIM_PROG
	jmp LER_COMANDO

PLAY:
	
	cmp al,49
	jne TOP10
	mov FIMJOGOVAR,1
	mov booleanvalue,0
	mov OFFTHEGAME,1
	call apaga_ecran
	goto_xy 0,0
	mov Tempo_j,0
	call IMP_FICH
	call AVATAR
	goto_xy 0,22
	
TOP10:
	cmp al,50
	jne FIM_PROG
	call apaga_ecran
	goto_xy 0,5
	call IMP_TOP10
	call LE_TECLA
	cmp al,27
	je MENU
	
	
FIM_PROG:
	goto_xy 78,0
	cmp al, 27
	
	je FIM_PROGRAMA
	cmp al,51
	jne LER_COMANDO
	jmp FIM_PROGRAMA
	
FIM_PROGRAMA:
	call apaga_ecran
	goto_xy 78,0
	mov			ah,4CH
	INT			21H
	RET
MENU ENDP 
 



;########################################################################
Main  proc
		mov			ax, dseg
		mov			ds,ax
		
		mov			ax,0B800h
		mov			es,ax
		
		call		apaga_ecran
		goto_xy		0,0
		call 		MENU
		
		
	
		call apaga_ecran
		mov			ah,4CH
		INT			21H
Main	endp
Cseg	ends
end	Main