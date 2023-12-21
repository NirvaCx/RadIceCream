.data

#################################
##		  Test music:          ##
##	Vordt of the Boreal Valley ##
##		Dark Souls III		   ##
##	   by Motoi Sakuraba	   ## 
#################################

songLength:
.word	120

# songNotes and notesDuration work in pairs, so they use the same pointer (currentNote)
songNotes: # array that contains the pitch value of each note
.word	63, 64, 61, 63, 59, 61, 58, 59, 56, 58, 54, 63, 64, 61, 63, 59, 61, 58, 59, 56, 58, 54, 63, 64, 61, 63, 59, 61, 58, 59, 56, 58, 54, 63, 64, 61, 63, 59, 61, 58, 68, 66, 63, 64, 61, 63, 60, 57, 66, 64, 66, 68, 66, 64, 66, 64, 63, 61, 65, 64, 65, 66, 65, 61, 64, 68, 63, 64, 61, 63, 59, 61, 58, 59, 56, 58, 54, 63, 64, 61, 63, 59, 61, 58, 59, 56, 58, 54, 63, 64, 61, 63, 59, 61, 58, 59, 56, 58, 54, 63, 64, 61, 63, 59, 61, 58, 68, 66, 64, 63, 61, 65, 64, 65, 66, 65, 61, 64, 68, 64
notesDuration: # array that contains the duration of each note
.word	316, 316, 316, 316, 316, 316, 316, 316, 316, 316, 632, 316, 316, 316, 316, 316, 316, 316, 316, 316, 316, 632, 316, 316, 316, 316, 316, 316, 316, 316, 316, 316, 632, 316, 316, 316, 316, 316, 316, 316, 632, 1264, 632, 632, 632, 632, 632, 632, 632, 1264, 632, 632, 1264, 632, 632, 1264, 632, 632, 1264, 632, 632, 1264, 632, 632, 1264, 1580, 316, 316, 316, 316, 316, 316, 316, 316, 316, 316, 632, 316, 316, 316, 316, 316, 316, 316, 316, 316, 316, 632, 316, 316, 316, 316, 316, 316, 316, 316, 316, 316, 632, 316, 316, 316, 316, 316, 316, 316, 632, 632, 1264, 632, 632, 1264, 632, 632, 1264, 632, 632, 1264, 632, 632

currentNote: 	# pointer to the current note (and its duration)
.word 	0
currentEndTime:
.word	0


.text
# MUSIC
	
musicRunner:
	lw	t0, currentNote	# start value == 0
	beqz t0, playNote	# Song just started, skip endNoteChecker
	#	Checks if note is over playing:
endNoteChecker:
	li	a7, 30
	ecall	# a0 holds current time
	lw	t5, currentEndTime	# (refurbishing t5 here) t5 holds currentEndTime
	blt	a0, t5, notOverYet	# checks if current time is less than the previously set end time.
playNote:
	#	Get memory info
	lw	t4, songLength		# load song length in notes
	lw	t0, currentNote		# load pointer
	la	t1, songNotes		# Load notes array address into t1
	la	t2, notesDuration	# Load durations array address into t2
	li	t3, 4
	mul	t0, t0, t3

	#	Set up pointers
	add	t1, t1, t0	# t1 holds the current pitch's address
	lw	t1, 0(t1)	# t1 is now the current note
	add	t2, t2, t0 	# t2 holds the current duration's address
	lw	t2, 0(t2) 	# t2 is now the current duration

	#	Midi Output
	li	a7, 31 	# MidiOut syscall
	mv	a0, t1 	# move pitch from t1 to a0
	mv	a1, t2 	# move duration from t2 to a1
	li	a2, 52 	# Choir instrument
	li	a3, 85 	# volume
	ecall

	# Get current time
	li	a7, 30
	ecall
	
	# Setting up end time for the current note being played
	add	t6, a0, t2 # t6 is startTime + duration
	sw 	t6, currentEndTime, s2
	
	lw	s0, currentNote		# s0 acts like a current note counter
	addi	s0, s0, 1		# increment counter
	bge	s0, t4, loopSong	# if song ended, loop it
	j	outLoopSong
loopSong:
	li	s0, 0			# reset counter
outLoopSong:
	sw	s0, currentNote, s1	# set new pointer value to memory
notOverYet:

	li a0, 50
	li a7,32
	ecall
	
	j	musicRunner
