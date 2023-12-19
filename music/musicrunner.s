.data

songLength:
.word	260

# songNotes and notesDuration work in pairs, so they use the same pointer (currentNote)
songNotes: # array that contains the pitch value of each note
.word	40, 40, 52, 40, 40, 50, 40, 40, 48, 40, 40, 46, 40, 40, 47, 48, 40, 40, 52, 40, 40, 50, 40, 40, 48, 40, 40, 46, 40, 40, 52, 40, 40, 50, 40, 40, 48, 40, 40, 46, 40, 40, 47, 48, 40, 40, 52, 40, 40, 50, 40, 40, 67, 64, 60, 64, 67, 64, 67, 72, 67, 64, 67, 64, 67, 72, 76, 79, 45, 45, 57, 45, 45, 55, 45, 45, 53, 45, 45, 51, 45, 45, 52, 53, 45, 45, 57, 45, 45, 55, 45, 45, 53, 45, 45, 51, 45, 45, 57, 45, 45, 55, 45, 45, 53, 45, 45, 51, 45, 45, 52, 53, 45, 45, 57, 45, 45, 55, 45, 45, 65, 61, 60, 65, 60, 57, 60, 65, 69, 65, 60, 65, 60, 65, 60, 57, 40, 40, 52, 40, 40, 50, 40, 40, 48, 40, 40, 46, 40, 40, 47, 48, 40, 40, 52, 40, 40, 50, 40, 40, 48, 40, 40, 46, 40, 40, 52, 40, 40, 50, 40, 40, 48, 40, 40, 46, 40, 40, 47, 48, 40, 40, 52, 40, 40, 50, 40, 40, 48, 40, 40, 46, 50, 50, 62, 50, 50, 59, 50, 50, 57, 50, 50, 56, 50, 50, 56, 57, 47, 47, 59, 47, 47, 57, 47, 47, 56, 45, 45, 54, 40, 40, 52, 40, 40, 50, 40, 40, 48, 40, 40, 46, 40, 40, 47, 48, 40, 40, 52, 40, 40, 50, 40, 40, 64, 67, 60, 55, 64, 60, 67, 64, 67, 64, 60, 55, 64, 67, 72, 76
notesDuration: # array that contains the duration of each note
.word	135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 677, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 67, 67, 67, 67, 67, 67, 67, 67, 67, 67, 67, 67, 67, 67, 67, 67, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 677, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 67, 67, 67, 67, 67, 67, 67, 67, 67, 67, 67, 67, 67, 67, 67, 67, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 677, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 677, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 677, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 135, 67, 67, 67, 67, 67, 67, 67, 67, 67, 67, 67, 67, 67, 67, 67, 67

currentNote: # pointer to the current note (and its duration)
.word 	0
currentEndTime:
.word	0


.text
	musicRunner:	# Play the music  

		lw	t0, currentNote	# start value == 0
		beqz t0, playNote	# Song just started, skip endNoteChecker

		#	Checks if note is over playing:
		endNoteChecker:
			li	a7, 30
			ecall	# a0 holds current time
			lw	t5, currentEndTime	# (refurbishing t5 here) t5 holds currentEndTime
			blt a0, t5, notOverYet	# checks if current time is less than the previously set end time.
			noteIsOver:					# If not, the note is over playing.
				lw	s0, currentNote	# s0 acts like a current note counter
				addi	s0, s0, 1	# increment counter
				bgt	s0, t4, loopSong# if song ended, loop it
				j	outLoopSong
				loopSong:
				li	s0, 0	# reset counter
				outLoopSong:
				sw	s0, currentNote, s1	# set new pointer value to memory	
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
			addi	t5, t2, 0	# copying the duration to generate end time

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
			add	t6, a0, t5 # t6 is startTime + duration
			sw 	t6, currentEndTime, s2

		notOverYet:		
		j	musicRunner
donePlaying:
li t0, 0
sw t0, currentNote, t1

