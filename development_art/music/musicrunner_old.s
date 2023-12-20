.data
# Test music: Vordt of the Boreal Valley - Dark Souls III by Motoi Sakuraba

songLength:
.word	240

# songNotes and notesDuration work in pairs, so they use the same pointer (currentNote)
songNotes: # array that contains the pitch value of each note
.word	63, 51, 51, 51, 51, 64, 65, 63, 51, 51, 53, 65, 53, 63, 51, 51, 51, 51, 64, 65, 63, 51, 62, 63, 64, 52, 52, 63, 51, 51, 51, 51, 64, 65, 63, 51, 51, 53, 65, 53, 63, 51, 51, 51, 51, 64, 65, 63, 51, 62, 63, 64, 52, 52, 63, 76, 72, 70, 75, 76, 72, 70, 68, 67, 63, 76, 72, 70, 75, 76, 72, 77, 75, 63, 51, 51, 51, 51, 64, 65, 63, 51, 51, 53, 65, 53, 63, 51, 51, 51, 51, 64, 65, 63, 51, 62, 63, 64, 52, 52, 63, 51, 51, 51, 51, 64, 65, 63, 51, 51, 53, 65, 53, 63, 51, 51, 51, 51, 64, 65, 63, 51, 62, 63, 64, 52, 52, 63, 76, 72, 70, 75, 76, 72, 70, 68, 67, 63, 76, 72, 70, 75, 76, 72, 77, 75, 63, 51, 51, 51, 51, 64, 65, 63, 51, 51, 53, 65, 53, 63, 51, 51, 51, 51, 64, 65, 63, 51, 62, 63, 64, 52, 52, 63, 51, 51, 51, 51, 64, 65, 63, 51, 51, 53, 65, 53, 63, 51, 51, 51, 51, 64, 65, 63, 51, 62, 63, 64, 52, 52, 75, 63, 72, 70, 75, 63, 72, 70, 65, 87, 75, 84, 82, 87, 75, 84, 82, 77, 75, 63, 72, 70, 75, 63, 72, 70, 63, 51, 60, 58, 53, 75, 63, 72, 70, 87, 75, 84, 82, 77
notesDuration: # array that contains the duration of each note
.word	265, 531, 531, 132, 398, 132, 132, 265, 531, 531, 265, 265, 265, 265, 531, 531, 132, 398, 132, 132, 265, 531, 132, 132, 265, 398, 398, 265, 531, 531, 132, 398, 132, 132, 265, 531, 531, 265, 265, 265, 265, 531, 531, 132, 398, 132, 132, 265, 531, 132, 132, 265, 398, 398, 531, 531, 531, 531, 531, 531, 531, 531, 531, 3717, 531, 531, 531, 531, 531, 531, 531, 531, 4248, 265, 531, 531, 132, 398, 132, 132, 265, 531, 531, 265, 265, 265, 265, 531, 531, 132, 398, 132, 132, 265, 531, 132, 132, 265, 398, 398, 265, 531, 531, 132, 398, 132, 132, 265, 531, 531, 265, 265, 265, 265, 531, 531, 132, 398, 132, 132, 265, 531, 132, 132, 265, 398, 398, 531, 531, 531, 531, 531, 531, 531, 531, 531, 3717, 531, 531, 531, 531, 531, 531, 531, 531, 4248, 265, 531, 531, 132, 398, 132, 132, 265, 531, 531, 265, 265, 265, 265, 531, 531, 132, 398, 132, 132, 265, 531, 132, 132, 265, 398, 398, 265, 531, 531, 132, 398, 132, 132, 265, 531, 531, 265, 265, 265, 265, 531, 531, 132, 398, 132, 132, 265, 531, 132, 132, 265, 398, 398, 265, 531, 531, 2920, 265, 531, 531, 531, 2389, 265, 531, 531, 2920, 265, 531, 531, 531, 2389, 265, 531, 531, 796, 265, 531, 531, 796, 265, 531, 531, 531, 2389, 265, 531, 531, 2920, 265, 531, 531, 531, 2389

currentNote: # pointer to the current note (and its duration)
.word 	0
currentEndTime:
.word	0


.text
gameLoop:
	musicRunner:	# Play the music  

		lw	t0, currentNote	# start value == 0
		beqz t0, playNote	# Song just started, skip endNoteChecker

		#	Checks if note is over playing:
		endNoteChecker:
			li	a7, 30
			ecall	# a0 holds current time
			lw	t5, currentEndTime	# (refurbishing t5 here) t5 holds currentEndTime
			blt a0, t5, notOverYet				# checks if current time is less than the previously set end time.
			# noteIsOver:					# If not, the note is over playing.
				# lw	s0, currentNote	# s0 acts like a current note counter
				# addi	s0, s0, 1	# increment counter
				# bge	s0, t4, loopSong# if song ended, loop it
				# j	outLoopSong
				# loopSong:
				# li	s0, 0	# reset counter
				# outLoopSong:
				# sw	s0, currentNote, s1	# set new pointer value to memory	
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
			li	a2, 30 	# guitar instrument
			li	a3, 50 	# volume
			ecall

			# Get current time
			li	a7, 30
			ecall

			# Setting up end time for the current note being played
			add	t6, a0, t2 # t6 is startTime + duration
			sw 	t6, currentEndTime, s2
			
			# 
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
	
	j	gameLoop