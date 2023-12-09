# songrunner function
.data
# 
#
#
#

# I decided to not bother with multiple midi channels
# Function is modular, main.s will only send the song 

SONG_ID_0: # Menu Theme
	# Doom E1M1 - At Doom's Gate
	SONG_LEN: .word 260 # how many notes it'll play
	NOTES:  #
	
SONG_ID_1: # Level 1 Music
	SONG_LEN: .word # how many notes it'll play
	NOTES:
	
SONG_ID_2: # Level 2 Music
	SONG_LEN: .word # how many notes it'll play
	NOTES:
	
SONG_ID_3: # Level 3 Music
	SONG_LEN: .word # how many notes it'll play
	NOTES:
#
#
#

.text
.text
	la s0,NUM		# define o endereço do número de notas
	lw s1,0(s0)		# le o numero de notas
	la s0,NOTAS		# define o endereço das notas
	li t0,0			# zera o contador de notas
	li a2,30		# define o instrumento
	li a3,127		# define o volume

LOOP:	beq t0,s1, FIM		# contador chegou no final? então  vá para FIM
	lw a0,0(s0)		# le o valor da nota
	lw a1,4(s0)		# le a duracao da nota
	li a7,31		# define a chamada de syscall
	ecall			# toca a nota
	# pegar o tempo
	li a7 30
	ecall
	mv a0,s2		# passa a duração da nota para a pausa
	li a7,32		# define a chamada de syscal 
	
	ecall			# realiza uma pausa de a0 ms
	addi s0,s0,8		# incrementa para o endereço da próxima nota
	addi t0,t0,1		# incrementa o contador de notas
	j LOOP			# volta ao loop