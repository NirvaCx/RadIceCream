	musicRunner:	# Play the music

		lw	t0, currentNote	# start address == 0
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
			lw	t1, songNotes		# Load notes array into t1
			lw	t2, notesDuration	# Load durations array into t2
			li	t3, 4
			mul	t0, t0, t3
			
			#	Set up pointers
			add	t1, t1, t0	# t1 holds the current pitch's address
			lw	t1, 0(t1)	# t1 is now the current note
			add	t2, t2, t0 	# t2 holds the current duration's address
			lw	t2, 0(t2) 	# t2 is now the current duration
			lw	t5, 0(t2) 	# copying the duration to generate end time
		
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