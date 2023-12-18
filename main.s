#########################################################
#						        #
# Universidade de Brasilia			        #
# Instituto de Ciencias Exatas			        #
# Departamento de Ciencia da Computacao		       	#
# Introducao aos Sistemas Computacionais - 2023.2	#
# Professor Marcus Vinicius Lamar			#
# Alunos Nirva Neves, Rodrigo Rafik e Mariana Simion    #
# Projeto Final					   	#
# Nome do jogo: RadIceCream				#
#							#
#########################################################
#
# Notes:
# 1 - Registers are used rather liberally, with only argument registers really being used for their intended purposes.
# Since memory is used so extensively, we delegated the function of saved registers mostly to memory. In other words,
# temporary and saved registers are pretty much used interchangeably.
#
# 2 - Register s11 is exclusively used as a tick counter. 

# good luck lol

.data

###############
### globals ###
###############

# map width and height are fixed for every level
mapwidth:
.word	20
mapheight:
.word	15

# how many levels are unlocked
unlockedLevels:
.word	1

#####################
### external data ###
#####################

.include "level_information/menu_screens/title_screen.data"
.include "level_information/menu_screens/level_select.data"
.include "level_information/menu_screens/padlockoverlay.data"
.include "level_information/menu_screens/pause_overlay.data"
.include "level_information/menu_screens/death_overlay.data"
.include "level_information/menu_screens/gameover.data"
.include "level_information/menu_screens/victoryscreen.data"
.include "sprites/numbers.data"

.include "level_information/level_1/level1.data"
.include "level_information/level_1/level1_bg.data"
.include "level_information/level_1/level1_info.data"
.include "level_information/level_1/level1_colupdates.data"

.include "level_information/level_2/level2.data"
.include "level_information/level_2/level2_bg.data"
.include "level_information/level_2/level2_info.data"
.include "level_information/level_2/level2_colupdates.data"

.include "level_information/level_3/level3.data"
.include "level_information/level_3/level3_bg.data"
.include "level_information/level_3/level3_info.data"
.include "level_information/level_3/level3_colupdates.data"

.include "sprites/empty.data"
.include "sprites/breakable.data"
.include "sprites/collectibles.data"
.include "sprites/breakable_c.data"
.include "sprites/enemy_dudu.data"
.include "sprites/enemy_tonho.data"
.include "sprites/char.data"
.include "sprites/building0.data"
.include "sprites/breaking0.data"
.include "sprites/explosion.data"

#########################
### ingame variables  ###
#########################

# levelLoader data
currentLevel:
.space	308	# 20 * 15 bytes + 2 words
levelBackground:
.space	76808	# 320 * 240 bytes + 2 words
enemyAmount:
.word	0
enemyPositions:
.space	24
enemyTypes:
.space	8
enemyStates:
.byte
	0, 0,
	0, 0,
	0, 0,
	0, 0,
	0, 0,
	0, 0,
	0, 0,
	0, 0
playerPosition:
.space	8
collectibleCount:
.word	0
collectibleUpdates:
.word	0
updateCounter:
.word	0

# Enough space for three updates, could be expanded but I can't be bothered since the max is 3 anyway
# Like why would anyone in their right mind put four collectibles in a level
collectibleTypes:
.word	0, 0, 0
collectibleMatrices:
.space	900
collectibleDecrement:
.word	0
currentCollectible:
.word	0
levelNumber:
.word	0

# Music info
currentSongID:
.word	0 #
songLength:
.word 	0

# songNotes and notesDuration work in pairs, so they use the same pointer (currentNote)
songNotes: # array that contains the pitch value of each note
.byte 	0
notesDuration: # array that contains the duration of each note
.byte 	0

currentNote: # pointer to the current note (and its duration)
.word 	0

explosionMatrix:
.space	300
explosionFlag:
.word	0
explosionState:
.word	0


########################
### player variables ###
########################

# states up, down, left and right are 0, 1, 2 and 3 respectively
playerState:
.word	0

# boolean value - is the player pressing space?
playerBreaking:
.word	0

# position
playerPosX:
.word	0
playerPosY:
.word	0

# movement limiters
playerEnergy:
.word	0
maxPlayerEnergy:
.word	8

# How much each collectible is worth
collectibleValue:
.word	0
points:
.word	0

######################
### MMIO variables ###
######################

# frameswitch variables
currentframeaddress:
.word	0xff100000
displayedframeaddress:
.word	0xff200604

# input variables
currentInput:
.word	0x0
keyboardAddress:
.word	0xff200000

#######################
### Other variables ###
#######################

# used by doSpecial
lookAheadPointer:
.word	20

# time variables
levelTimer:
.word	0
levelPaused:
.word	0

# game flags
victoryFlag:
.word 0

# mapRender variables
tempwidth:
.word	0x0
tempheight:
.word	0x0

######################################
######### End of data segment ########
######################################

.text

mainMenuRender:
	# render title screen
	mv	a0, zero
	mv	a1, zero
	la	a2, title_screen
	jal	displayPrint
	jal	frameSwitch

mainMenuSelect:
	
	# get input from the keyboard for menu options
	lw	t0, keyboardAddress
	lw	t1, 0(t0)
	andi	t1, t1, 1
	# check first bit at keyboard address to see if input has been pressed
	beq	t1, zero, mainMenuSelect
	lb	t1, 4(t0)
	
	li	t2, 0x031
	beq	t1, t2, levelSelect
	li	t2, 0x032
	# this slight madness below has to be done because exitProgram is out of the branch's range (+- 512 words)
	bne	t1, t2, continueMMSelect
	j	exitProgram
continueMMSelect:
	
	j	mainMenuSelect
	
levelSelect:
	# render level select screen
	mv	a0, zero
	mv	a1, zero
	la	a2, level_select
	jal	displayPrint
	
	# padlocks rendering
	lw	s0, unlockedLevels
	la	s1, padlockoverlay
	
padlock2:
	li	t0, 2
	bge	s0, t0, padlock3
	li	a0, 144
	li	a1, 112
	mv	a2, s1
	mv	a3, zero
	jal	displayPrint
padlock3:
	li	t0, 3
	bge	s0, t0, finishPadlocks
	li	a0, 208
	li	a1, 112
	mv	a2, s1
	mv	a3, zero
	jal	displayPrint
	
finishPadlocks:
	
	jal	frameSwitch
	
levelInput:
	# get input from the keyboard numbers and loads the corresponding level.
	lw	t0, keyboardAddress
	lw	t1, 0(t0)
	andi	t1, t1, 1
	# check first bit at keyboard address to see if input has been pressed
	beq	t1, zero, levelInput
	lb	t1, 4(t0)
	
	# pressing 0 is a cheat to unlock all levels
	li	t2, 0x30
	beq	t1, t2, unlockLevels
	# pressing [-] is a cheat to lock levels
	li	t2, 0x2D
	beq	t1, t2, lockLevels
	
	# load level according to keyboard numbers
	li	t2, 0x031
	beq	t1, t2, load1
	li	t2, 0x032
	beq	t1, t2, load2
	li	t2, 0x033
	beq	t1, t2, load3
	
	# p returns to main menu
	li	t2, 0x70
	beq	t1, t2, mainMenuRender
	j	levelInput

unlockLevels:
	# unlock levels and go back to level prompt
	li	t0, 9
	sw	t0, unlockedLevels, t1
	j	levelSelect

lockLevels:
	# lock levels and go back to level prompt
	li	t0, 1
	sw	t0, unlockedLevels, t1
	j	levelSelect

load1:
	li	t0, 1
	sw	t0, levelNumber, t1
	la	a0, level1
	la	a1, level1_bg
	la	a2, level1_info
	la	a3, level1_colupdates
	j	levelLoader

load2:
	# only loadable if unlocked
	lw	t0, unlockedLevels
	li	t1, 2
	blt	t0, t1, levelInput
	li	t0, 2
	
	sw	t0, levelNumber, t1
	la	a0, level2
	la	a1, level2_bg
	la	a2, level2_info
	la	a3, level2_colupdates
	j	levelLoader

load3:
	# equally
	lw	t0, unlockedLevels
	li	t1, 3
	blt	t0, t1, levelInput
	li	t0, 3
	
	sw	t0, levelNumber, t1
	la	a0, level3
	la	a1, level3_bg
	la	a2, level3_info
	la	a3, level3_colupdates
	j	levelLoader
	
dynamicLoader:
	# loads a level based on the current levelNumber
	# useful for restarting and loading the next level after victory
	lw	t0, levelNumber
	li	t1, 1
	beq	t0, t1, load1
	li	t1, 2
	beq	t0, t1, load2
	li	t1, 3
	beq	t0, t1, load3
	j	mainMenuRender

levelLoader:
	# a0 = level matrix
	# a1 = level background image
	# a2 = level information file
	# a3 = level collectible update matrix
	
	
	# reset collectible values
	li	t0, 100
	sw	t0, collectibleValue, t1
	# reset victory flag
	li	t0, 0
	sw	t0, victoryFlag, t1
	# reset collectible update counter
	li	t0, 0
	sw	t0, updateCounter, t1
	# reset pause flag
	li	t0, 0
	sw	t0, levelPaused, t1
	# reset playerState
	li	t0, 1
	sw	t0, playerState, t1
	# reset lookAheadPointer
	li	t0, 20
	sw	t0, lookAheadPointer, t1
	# reset points
	li	t0, 0
	sw	t0, points, t1
	# reset ticker
	li	s11, 0
	# reset player energy
	li	t0, 10
	sw	t0, playerEnergy, t1
	# reset explosionState
	li	t0, 0
	sw	t0, explosionState, t1
	# reset explosionFlag
	li	t0, 0
	sw	t0, explosionFlag, t1

	# reset explosionMatrix
	la	s0, explosionMatrix
	li	t2, 75
	li	t0, 0
explosionMatrixReset:
	bge	t0, t2, outExplosionMatrixReset
	li	t1, 0
	sw	t1, 0(s0)
	
	addi	t0, t0, 1
	addi	s0, s0, 4
	j	explosionMatrixReset
outExplosionMatrixReset:

	# reset enemy states
	la	s0, enemyStates
	li	t0, 4
	li	t1, 0
	# the reason for this number is that it alternates between bytes 0 and 1
	# we want all enemies to start facing down and not performing specials
	li	t2, 0x00010001
enemyStateReset:
	bge	t1, t0, endEnemyStateReset
	sw	t2, 0(s0)
	addi	t1, t1, 1
	addi	s0, s0, 4
	j	enemyStateReset
endEnemyStateReset:
	
	# copy from level data to currentLevel
	la	s0, currentLevel
	lw	t0, 0(a0)
	sw	t0, 0(s0)
	# t0 = width
	lw	t1, 4(a0)
	sw	t1, 4(s0)
	# t1 = height
	li	t2, 0
	li	t3, 0
	# t2 = current x
	# t3 = current y
	addi	s0, s0, 8
	addi	a0, a0, 8
	# s0 is currentLevel saver pointer and a0 is level data loader pointer
levelYloop:
	# iterate through matrix lines
	bge	t3, t1, levelYloopEnd
	li	t2, 0
levelXloop:
	# iterate through matrix columns
	bge	t2, t0, levelXloopEnd
	# copy from level data pointer to currentLevel data pointer
	lw	t4, 0(a0)
	sw	t4, 0(s0)
	
	# increments
	addi	a0, a0, 4
	addi	s0, s0, 4
	addi	t2, t2, 4
	j	levelXloop
levelXloopEnd:
	addi	t3, t3, 1
	j	levelYloop
levelYloopEnd:

getBackground:

	# copy background data to levelBackground
	la	s0, levelBackground
	lw	t0, 0(a1)
	sw	t0, 0(s0)
	# t0 = width
	lw	t1, 4(a1)
	sw	t1, 4(s0)
	# t1 = height
	li	t2, 0
	li	t3, 0
	# t2 = current x
	# t3 = current y
	addi	s0, s0, 8
	addi	a1, a1, 8
	# very similar to the procedure above (It's almost the same code.)
bgYloop:
	bge	t3, t1, bgYloopEnd
	li	t2, 0
bgXloop:
	bge	t2, t0, bgXloopEnd
	# copy 4 pixels from background pointer to levelBackground pointer
	lw	t4, 0(a1)
	sw	t4, 0(s0)
	
	# increments
	addi	a1, a1, 4
	addi	s0, s0, 4
	addi	t2, t2, 4
	j	bgXloop
bgXloopEnd:
	addi	t3, t3, 1
	j	bgYloop
bgYloopEnd:
	
	# now using argument a2 for accessing level information
getInfo:
	# collect enemy amount
	lw	s0, 0(a2)
	sw	s0, enemyAmount, t0
	
	# move a2 to enemy positions
	addi	a2, a2, 4
	li	t0, 24
	# enemy position is 6 words long (allows for 8 enemies total)
	li	t1, 0
	la	s0, enemyPositions
	# counter
	# collect enemy positions
	# deja vu
loadEnemyPos:
	bge	t1, t0, loadEnemyPosEnd
	lw	s1, 0(a2)
	sw	s1, 0(s0)
	
	addi	a2, a2, 4
	addi	s0, s0, 4
	addi	t1, t1, 4
	j	loadEnemyPos
loadEnemyPosEnd:
	
	# collect enemy types (could've been iterative but why iterate through only two words?)
	la	s0, enemyTypes
	lw	s1, 0(a2)
	sw	s1, 0(s0)
	addi	s0, s0, 4
	addi	a2, a2, 4
	lw	s1, 0(a2)
	sw	s1, 0(s0)
	
	# move a2 to player positions
	addi	a2, a2, 4
	# collect player positions
	la	s0, playerPosX
	lw	s1, 0(a2)
	sw	s1, 0(s0)
	
	addi	a2, a2, 4
	la	s0, playerPosY
	lw	s1, 0(a2)
	sw	s1, 0(s0)
	
	# move a2 to collectible amount
	addi	a2, a2, 4
	# init collectible amount
	la	s0, collectibleCount
	lw	s1, 0(a2)
	sw	s1, 0(s0)
	
	# move a2 to collectible updates
	addi	a2, a2, 4
	# init collectible Update amount
	la	s0, collectibleUpdates
	lw	s1, 0(a2)
	sw	s1, 0(s0)
	
	# move a2 to collectible types
	addi	a2, a2, 4
	
	# init collectible types (iterative because 2 words is too little and 3 is enough apparently)
	la	s0, collectibleTypes
	li	s1, 3
	li	t1, 0
initCollectibleTypes:
	beq	t1, s1, outICT
	lw	s2, 0(a2)
	sw	s2, 0(s0)
	addi	a2, a2, 4
	addi	s0, s0, 4
	addi	t1, t1, 1
	j	initCollectibleTypes
outICT:

	# load timer
	lw	s2, 0(a2)
	sw	s2, levelTimer, t0
	
	# move to cdpm
	addi	a2, a2, 4
	# load collectible decrement per minute
	lw	s2, 0(a2)
	sw	s2, collectibleDecrement, t0
	
	# now using a3 to collect the update matrices
	
	# init collectible matrices
	la	s0, collectibleMatrices
	lw	s1, collectibleUpdates
	li	t0, 0
	# these matrices are self-contained so there is no need to count x and y
initCollectibleMatrices:
	bge	t0, s1, outICM
	li	t1, 0
	# all matrices are 300 bytes long (20 * 15)
	li	t2, 300
ICMLoop:
	bge	t1, t2, outICMLoop
	lb	t3, 0(a3)
	sb	t3, 0(s0)
	addi	t1, t1, 1
	addi	a3, a3, 1
	addi	s0, s0, 1
	j	ICMLoop
outICMLoop:
	addi	t0, t0, 1
	j	initCollectibleMatrices
outICM:

	# init currentCollectible
	la	s0, collectibleTypes
	lw	s1, 0(s0)
	sw	s1, currentCollectible, s0
	
runtimeLoop:
	
gameLoop:
	
	# level pauser
	lw	t0, levelPaused
	beq	t0, zero, outPauseLevel
pauseLevel:
	# display pause screen
	li	a0, 0
	li	a1, 0
	la	a2, pause_overlay
	li	a3, 0
	jal	displayPrint
	jal	frameSwitch
	
pauseInput:
	# get input from the keyboard numbers and perform the relevant action
	lw	t0, keyboardAddress
	lw	t1, 0(t0)
	andi	t1, t1, 1
	# check first bit at keyboard address to see if input has been pressed
	# again, if no input it just keeps checking
	beq	t1, zero, pauseInput
	lb	t1, 4(t0)
	# 1 for unpause
	li	t2, 0x031
	beq	t1, t2, outPauseLevel
	# 2 for restart (dynamicLoader loads current level)
	li	t2, 0x032
	beq	t1, t2, dynamicLoader
	# 3 for main menu
	li	t2, 0x33
	beq	t1, t2, mainMenuRender
	# other inputs are invalid
	j	pauseInput
	
outPauseLevel:
	# remove pause flag
	sw	zero, levelPaused, t0

	# decrement timer every second (approximate)
	li	t0, 20
	# since s11 is only divisible by 20 once per second, the code runs as intended.
	remu	t0, s11, t0
	beq	t0, zero, timerDecrement
	j	outTimerDecrement
	
timerDecrement:
	lw	t0, levelTimer
	addi	t0, t0, -1
	sw	t0, levelTimer, t1
	# game ends if player runs out of time
	bne	t0, zero, outTimerDecrement
	j	gameOver
outTimerDecrement:
	
	# Collectibles will lose value every minute; value lost is specified on level information file
	# 1200 ticks = one minute
	li	t1, 1200
	remu	t1, s11, t1
	beq	s11, zero, noLower
	beq	t1, zero, lowerCollectibleValue
	j	noLower
lowerCollectibleValue:
	lw	s0, collectibleValue
	lw	t1, collectibleDecrement
	sub	s0, s0, t1
	sw	s0, collectibleValue, s1
noLower:

	# player stamina system core
	# used in move and special functions
	# energy capped at 10, regenerates 1 point every tick. player may only
	# move or perform a special when it is equal to 10
	lw	s0, playerEnergy
	lw	t1, maxPlayerEnergy
	blt	s0, t1, addEnergy
	j	outAddEnergy
addEnergy:
	addi	s0, s0, 1
	sw	s0, playerEnergy, s1
outAddEnergy:
	
	# maintain breaking state while energy hasn't yet recovered
	lw	t0, playerEnergy
	bge	t0, t1, resetPlayerBreaking
	j	outResetPlayerBreaking
resetPlayerBreaking:
	lw	s0, playerBreaking
	li	s0, 0
	sw	s0, playerBreaking, s1
outResetPlayerBreaking:

	# enemy ai for movement should be run every 0.8s (16 ticks)
	# enemy ai should never be run at the very start of the match
	li	t3, 16
	blt	s11, t3, outEnemyAI
	li	t0, 0
	# t0 will hold the current enemy ID
	li	t3, 16
	rem	t3, s11, t3
	beq	t3, zero, flagEnMov
	
	li	t3, 160
	li	t2, 8
	sub	t2, s11, t2
	rem	t3, t2, t3
	beq	t3, zero, flagEnExp
	
	j	outEnemyAI
flagEnMov:
	li	t3, 0
	sw	t3, explosionFlag, t2
	j	enemyAI

flagEnExp:
	li	t3, 1
	sw	t3, explosionFlag, t2
	li	t3, 0
	sw	t3, explosionState, t2
	j	enemyAI
	
enemyAI:
	# once there are no more enemies to verify, continue
	lw	t3, enemyAmount
	bge	t0, t3, outEnemyAI
	
	# gathering enemy information
	# position (s0 and s1)
	la	t1, enemyPositions
	li	t3, 3
	mul	t3, t0, t3
	add	t1, t3, t1
	lb	s0, 0(t1)
	lb	s1, 1(t1)
	
	# type (s3)
	la	t1, enemyTypes
	add	t1, t0, t1
	lb	s3, 0(t1)
	
	# states (s4 and s5)
	la	t1, enemyStates
	li	t3, 2
	mul	t3, t0, t3
	add	t1, t3, t1
	lb	s4, 0(t1)
	lb	s5, 1(t1)	
	
	lw	t3, explosionFlag
	beq	t3, zero, enemyMovement
	j	enemyExplosion
	
enemyMovement:
	# establish enemy location pointer on the matrix (t5)
	la	t1, currentLevel
	addi	t1, t1, 8
	li	t3, 20
	mul	t3, s1, t3
	add	t1, t3, t1
	add	t5, s0, t1
	
	# s6 will hold the amount of times the enemy tried to decide its direction
	# if greater than or equal to 4, the enemy is stuck and cannot move.
	li	s6, 0
movementDecision:
	# the specific order below might seem strange but it iterates through states clockwise.
	beq	s4, zero, moveUpE
	li	t3, 3
	beq	s4, t3, moveRtE
	li	t3, 1
	beq	s4, t3, moveDnE
	li	t3, 2
	beq	s4, t3, moveLtE
	# if somehow the enemy state is weird it goes to the next enemy
	j	nextEnemy
	
moveUpE:
	# The reason for these specific values are better explained in the player movement function below enemyAI
	# s7, s8 and s9 will represent the other blocks around the enemy (to the left, to the right and back)
	li	t3, -20
	li	s7, -1
	li	s8, 1
	li	s9, 20
	li	s4, 0
	j	moveEnemy

moveDnE:
	li	t3, 20
	li	s7, 1
	li	s8, -1
	li	s9, -20
	li	s4, 1
	j	moveEnemy

moveLtE:
	li	t3, -1
	li	s7, 20
	li	s8, -20
	li	s9, 1
	li	s4, 2
	j	moveEnemy

moveRtE:
	li	t3, 1
	li	s7, -20
	li	s8, 20
	li	s9, -1
	li	s4, 3
	j	moveEnemy
	
moveEnemy:
	# establish target location pointer
	add	t6, t5, t3
	# s2 is target cell container
	lb	s2, 0(t6)
	# game ends if enemy collides with player
	li	t3, 9
	bne	s2, t3, noGameOverEnemy
	j	gameOver
noGameOverEnemy:
	# enemy may move onto empty cells only
	bne	s2, zero, repeatDecision
	j	continueMoveEnemy

repeatDecision:
	# if too many repeat decisions are made, next enemy may be moved
	li	t3, 4
	bge	s6, t3, nextEnemy
	addi	s6, s6, 1
	
	# load relative spaces to find out which are free according to
	# randomly selected priority
	add	s7, t5, s7
	lb	s7, 0(s7)
	add	s8, t5, s8
	lb	s8, 0(s8)
	add	s9, t5, s9
	lb	s9, 0(s9)
	
	# randomly prioritize left, right or back
	li	a0, 46391665
	li	a1, 3
	li	a7, 42
	ecall
	# s10 will be used to find the player
	li	s10, 9
	
	beq	a0, zero, leftPriority
	li	t3, 1
	beq	a0, t3, rightPriority
	li	t3, 2
	beq	a0, t3, backPriority
	li	t3, 3
	beq	a0, t3, backPriority
leftPriority:
	beq	s7, zero, newLeftDirection
	beq	s7, s10, gameOver
	beq	s8, zero, newRightDirection
	beq	s8, s10, gameOver
	beq	s9, zero, newBackDirection
	beq	s9, s10, gameOver
	j	nextEnemy
rightPriority:
	beq	s8, zero, newRightDirection
	beq	s8, s10, gameOver
	beq	s7, zero, newLeftDirection
	beq	s7, s10, gameOver
	beq	s9, zero, newBackDirection
	beq	s9, s10, gameOver
	j	nextEnemy
backPriority:
	beq	s9, zero, newBackDirection
	beq	s9, s10, gameOver
	beq	s7, zero, newLeftDirection
	beq	s7, s10, gameOver
	beq	s8, zero, newRightDirection
	beq	s8, s10, gameOver
	j	nextEnemy

newLeftDirection:
	li	t3, 0
	beq	s4, t3, moveLtE
	li	t3, 1
	beq	s4, t3, moveRtE
	li	t3, 2
	beq	s4, t3, moveDnE
	li	t3, 3
	beq	s4, t3, moveUpE
newRightDirection:
	li	t3, 1
	beq	s4, t3, moveLtE
	li	t3, 0
	beq	s4, t3, moveRtE
	li	t3, 3
	beq	s4, t3, moveDnE
	li	t3, 2
	beq	s4, t3, moveUpE
newBackDirection:
	li	t3, 3
	beq	s4, t3, moveLtE
	li	t3, 2
	beq	s4, t3, moveRtE
	li	t3, 0
	beq	s4, t3, moveDnE
	li	t3, 1
	beq	s4, t3, moveUpE
	
	j	repeatDecision

continueMoveEnemy:
	# erase current position and update target position
	sb	zero, 0(t5)
	li	t3, 5
	sb	t3, 0(t6)
	
	# saving new information
	
	# save direction state
	la	t1, enemyStates
	li	t3, 2
	mul	t3, t0, t3
	add	t1, t3, t1
	sb	s4, 0(t1)
	
	beq	s4, zero, moveUpE2
	li	t3, 1
	beq	s4, t3, moveDnE2
	li	t3, 2
	beq	s4, t3, moveLtE2
	li	t3, 3
	beq	s4, t3, moveRtE2

moveUpE2:
	addi	s1, s1, -1
	j	saveEnemyPosition

moveDnE2:
	addi	s1, s1, 1
	j	saveEnemyPosition

moveLtE2:
	addi	s0, s0, -1
	j	saveEnemyPosition

moveRtE2:
	addi	s0, s0, 1
	j	saveEnemyPosition
	
saveEnemyPosition:
	# pretty self explanatory
	la	t1, enemyPositions
	li	t3, 3
	mul	t3, t0, t3
	add	t1, t3, t1
	sb	s0, 0(t1)
	sb	s1, 1(t1)
	j	nextEnemy

enemyPanic:
	# This erases the enemy in case of a bad glitch that messes with its direction and desyncs
	# enemy position from the actual cell the enemy is in
	# such a desync would be very bad; it'd be as if the enemy's soul just left its body
	# and they are now both wandering aimlessly
	sb	zero, 0(t6)
	j	nextEnemy

enemyExplosion:
	# set matrixExplosion's line and column for this enemy to 1
	# reminder to self: do not modify s0, s1, s3 or t0
	beq	s3, zero, nextEnemy

explodeX:
	la	s4, explosionMatrix
	li	t3, 20
	mul	t3, s1, t3
	add	s4, s4, t3
	
	li	t1, 0
	li	t2, 20
explodeXloop:
	bge	t1, t2, explodeY
	li	t3, 1
	sb	t3, 0(s4)
	
	addi	s4, s4, 1
	addi	t1, t1, 1
	j	explodeXloop

explodeY:
	la	s4, explosionMatrix
	add	s4, s4, s0
	
	li	t1, 0
	li	t2, 15
explodeYloop:
	bge	t1, t2, setExpState
	li	t3, 1
	sb	t3, 0(s4)
	
	addi	s4, s4, 20
	addi	t1, t1, 1
	j	explodeYloop

setExpState:
	la	s4, enemyStates
	li	t3, 2
	mul	t3, t0, t3
	add	s4, s4, t3
	li	t3, 1
	sb	t3, 1(s4)

nextEnemy:
	addi	t0, t0, 1
	j	enemyAI
	
outEnemyAI:

playerInput:
	lw	t0, keyboardAddress
	lw	t1, 0(t0)
	andi	t1, t1, 1
	# check first bit at keyboard address to see if input has been pressed
	bne	t1, zero, continueInput
	# move on if none
	j	outInput
continueInput:
	lb	t1, 4(t0)
	# w = 0x77
	# s = 0x73
	# a = 0x61
	# d = 0x64
	# space = 0x20
	# p = 0x70
	# - = 0x2D
	
	# set matrix pointer t0 to player position
	# t2 is used as a temporary for this process, getting mostly values from memory
	# this must be done before keycheck to prevent a lot of code repetition
	lw	t2, playerPosY
	li	t0, 20
	mul	t0, t0, t2
	lw	t2, playerPosX
	add	t0, t0, t2
	la	t2, currentLevel
	addi	t2, t2, 8
	add	t0, t0, t2
	
	# action selector based on received input
	li	t2, 0x077
	beq	t1, t2, moveUp
	li	t2, 0x073
	beq	t1, t2, moveDn
	li	t2, 0x061
	beq	t1, t2, moveLt
	li	t2, 0x064
	beq	t1, t2, moveRt
	li	t2, 0x20
	beq	t1, t2, doSpecial
	li	t2, 0x70
	beq	t1, t2, flagPause
	li	t2, 0x30
	beq	t1, t2, cheatVictory
	li	t2, 0x2D
	beq	t1, t2, cheatLose
	
	# if the input was not in the selector, no action is performed
	j	outInput
	
flagPause:
	li	t0, 1
	sw	t0, levelPaused, t1
	j	outInput

cheatVictory:
	li	t0, 1
	sw	t0, victoryFlag, t1
	j	outInput

cheatLose:
	j	gameOver
	
	# the four labels below all do the same thing for different movements
	# t3 will store the number that will be used to create the pointer
	# that points to the cell towards which the character just tried to move
	# they also update the player's state accordingly
	
moveUp:
	# these are all similar
	# t3 loads the matrix increment/decrement for the target cell
	li	t3, -20
	# this increment is important for the special move, so it's saved in memory
	sw	t3, lookAheadPointer, t4
	lw	s0, playerState
	li	s1, 0
	sw	s1, playerState, s2
	# player will move in a direction they're already facing
	# otherwise, they will only update the direction this tick
	beq	s0, s1, movePlayer
	j	outInput
moveDn:
	li	t3, 20
	sw	t3, lookAheadPointer, t4
	lw	s0, playerState
	li	s1, 1
	sw	s1, playerState, s2
	beq	s0, s1, movePlayer
	j	outInput
moveLt:
	li	t3, -1
	sw	t3, lookAheadPointer, t4
	lw	s0, playerState
	li	s1, 2
	sw	s1, playerState, s2
	beq	s0, s1, movePlayer
	j	outInput
moveRt:
	li	t3, 1
	sw	t3, lookAheadPointer, t4
	lw	s0, playerState
	li	s1, 3
	sw	s1, playerState, s2
	beq	s0, s1, movePlayer
	j	outInput
	
doSpecial:
	# only allow special if energy is full
	lw	t4, maxPlayerEnergy
	lw	s0, playerEnergy
	blt	s0, t4, outInput
	# reset playerEnergy
	li	s0, 0
	sw	s0, playerEnergy, s1
	
	# set player secondary state for rendering the animation
	lw	s0, playerBreaking
	li	s0, 1
	sw	s0, playerBreaking, s1
	
	# t3 is the constant increment that will be used to "walk" to the next block
	lw	t3, lookAheadPointer
	
	# t6 is a flag for whether or not one of the functions has already run
	# e.g. playerDestroy should NOT run if playerBuild did run
	# t4 is target cell pointer; t1 is whatever is contained in that cell
	add	t4, t0, t3
	li	t6, 0
	
playerBuild:
	lb	t1, 0(t4)
	li	t5, 0
	# build will run if t1 is an open cell (0 or 3)
	beq	t1, t5, buildBreakable
	li	t5, 3
	beq	t1, t5, buildBreakable_c
	beq	t6, zero, playerDestroy
	j	outInput
buildBreakable:
	li	t1, 10
	sb	t1, 0(t4)
	add	t4, t4, t3
	li	t6, 1
	j	playerBuild
buildBreakable_c:
	# has a collectible inside
	li	t1, 11
	sb	t1, 0(t4)
	add	t4, t4, t3
	li	t6, 1
	j	playerBuild

playerDestroy:
	lb	t1, 0(t4)
	li	t5, 2
	# destroy will run if t1 is a breakable (2 or 4)
	beq	t1, t5, destroyBreakable
	li	t5, 4
	beq	t1, t5, destroyBreakable_c
	j	outInput
destroyBreakable:
	li	t1, 12
	sb	t1, 0(t4)
	add	t4, t4, t3
	j	playerDestroy
destroyBreakable_c:
	# drops a collectible later
	li	t1, 13
	sb	t1, 0(t4)
	add	t4, t4, t3
	j	playerDestroy

movePlayer:
	# only allow movement if energy is full
	lw	t4, maxPlayerEnergy
	lw	s0, playerEnergy
	blt	s0, t4, outInput
	# reset playerEnergy
	li	s0, 0
	sw	s0, playerEnergy, s1
	# t4 is target cell pointer
	add	t4, t0, t3
	# t1 is whatever is contained in target cell
	lb	t1, 0(t4)
	li	t2, 5
	# collision with ID 5 (enemy) results in a gameover
	bne	t1, t2, continueMovement0
	j	gameOver
continueMovement0:
	# check for collision with collectible
	li	t2, 3
	bne	t1, t2, noPoint
	# collision with a collectible will replace the collectible with empty space,
	# add 100 points, remove 1 from the collectible counter and finish the movement algorithm
	
	# Play sfx
	li	a0, 62	# Pitch 		
	li	a1, 300	# Duration in ms
	li	a2, 31	# Instrument
	li	a3, 30	# Volume
	li	a7, 31	# MidiOut syscall
	ecall
	
	lw	s0, points
	lw	s2, collectibleValue
	add	s2, s0, s2
	sw	s2, points, s1
	lw	s0, collectibleCount
	addi	s0, s0, -1
	sw	s0, collectibleCount, s1
	
	j	continueMovement1
noPoint:
	# since the only cells towards which you can move other than collectibles are empty cells,
	# we can cancel the movement algorithm if the cell is not empty since if we are in noPoint
	# we already know it's not a collectible
	bne	t1, zero, outInput
	
continueMovement1:
	# replace previous cell with empty
	mv	t1, zero
	sb	t1, 0(t0)
	# replace target with player
	li	t1, 9
	sb	t1, 0(t4)
	
	# all the code below down to outInput simply updates the player's
	# x and y positions stored in memory, according to the defined player state
	lw	t3, playerState
	li	t1, 0
	beq	t3, t1, moveUp2
	li	t1, 1
	beq	t3, t1, moveDn2
	li	t1, 2
	beq	t3, t1, moveLt2
	li	t1, 3
	beq	t3, t1, moveRt2
moveUp2:
	li	t3, -1
	lw	s0, playerPosY
	add	s0, s0, t3
	sw	s0, playerPosY, t3
	j	outInput
moveDn2:
	li	t3, 1
	lw	s0, playerPosY
	add	s0, s0, t3
	sw	s0, playerPosY, t3
	j	outInput
moveLt2:
	li	t3, -1
	lw	s0, playerPosX
	add	s0, s0, t3
	sw	s0, playerPosX, t3
	j	outInput
moveRt2:
	li	t3, 1
	lw	s0, playerPosX
	add	s0, s0, t3
	sw	s0, playerPosX, t3
	j	outInput
outInput:
	
	# enter collectible updating function (only for when the player collects every objective on screen)
	lw	t0, collectibleCount
	bne	t0, zero, finishColupdates
updateCollectibles:
	# function should also only run while there are still updates
	lw	t0, collectibleUpdates
	bgt	t0, zero, proceedColupdates
	# if there are no more collectibles on the screen and no updates to be made, player wins
	beq	t0, zero, flagVictory
	j	finishColupdates
flagVictory:
	li	t0, 1
	sw	t0, victoryFlag, t1
	j	finishColupdates
proceedColupdates:
	# get information from memory
	la	s0, collectibleMatrices
	lw	s1, updateCounter
	lw	s2, collectibleCount
	la	s3, currentLevel
	addi	s3, s3, 8
	
	# set s0 to properly point at the update matrix
	li	t0, 300
	mul	t1, s1, t0
	add	s0, s0, t1
	
	# matrix is 300 bytes long, so we iterate 300 times
	li	t0, 300
	li	t1, 0
	
checkColupdates:
	# see comment above
	bge	t1, t0, finishColchecks
	
	lb	s4, 0(s0)
	beq	s4, zero, continueColchecks
	
	# load cell type
	lb	s4, 0(s3)
	
	# it only has to update these cell types
	beq	s4, zero, updateEmpty
	li	t2, 2
	beq	s4, t2, updateBreakable
	j	continueColchecks

updateEmpty:
	li	t2, 3
	sb	t2, 0(s3)
	# collectible amount is increased if a collectible is placed
	addi	s2, s2, 1
	j	continueColchecks

updateBreakable:
	li	t2, 4
	sb	t2, 0(s3)
	addi	s2, s2, 1
	j	continueColchecks
	
continueColchecks:
	# only increments
	addi	s0, s0, 1
	addi	s3, s3, 1
	addi	t1, t1, 1
	j	checkColupdates
	
finishColchecks:
	# save new collectible amount
	la	s0, collectibleCount
	sw	s2, 0(s0)
	
	# increment update counter
	lw	s0, updateCounter
	addi	s0, s0, 1
	sw	s0, updateCounter, s1
	
	# decrement update queue
	lw	s0, collectibleUpdates
	addi	s0, s0, -1
	sw	s0, collectibleUpdates, s1
	
	# update current collectible
	lw	s0, updateCounter
	li	t0, 4
	mul	s0, s0, t0
	la	s1, collectibleTypes
	la	s2, currentCollectible
	add	s1, s1, s0
	lw	t0, 0(s1)
	sw	t0, 0(s2)
finishColupdates:

backgroundRender:
	mv	a0, zero
	mv	a1, zero
	la	a2, levelBackground
	mv	a3, zero
	jal	displayPrint

menuRender:
	# Menu positions for reference:
	# Level Number: Y 70 X 29
	# Timer Digits: Y 113, X 16, 24, 34, 42 respectively
	# Score Digits: Y 153, X 17, 25, 33, 41 respectively 
	# Current Item: Y 206, X 24
	# I deeply apologize for how unelegant the following code is.
	# This procedure renders the numbers on the display. It will appear again later for accurate scoring.
	
	# level number renderer
	la	a2, numbers
	lw	t0, levelNumber
	li	a0, 29
	li	a1, 70
	li	t1, 128
	mul	a3, t0, t1
	jal	displayPrint
	
	# current collectible renderer
	la	a2, collectibles
	lw	t0, currentCollectible
	li	a0, 24
	li	a1, 206
	li	t1, 256
	mul	a3, t0, t1
	jal	displayPrint
	
	# timer renderer
	la	a2, numbers
	lw	s0, levelTimer
	li	a0, 16
	li	a1, 113
	li	t1, 600
	div	t0, s0, t1
	remu	s0, s0, t1
	li	t1, 128
	mul	a3, t0, t1
	jal	displayPrint
	
	la	a2, numbers
	li	a0, 24
	li	a1, 113
	li	t1, 60
	div	t0, s0, t1
	remu	s0, s0, t1
	li	t1, 128
	mul	a3, t0, t1
	jal	displayPrint
	
	la	a2, numbers
	li	a0, 34
	li	a1, 113
	li	t1, 10
	div	t0, s0, t1
	remu	s0, s0, t1
	li	t1, 128
	mul	a3, t0, t1
	jal	displayPrint
	
	la	a2, numbers
	li	a0, 42
	li	a1, 113
	mv	t0, s0
	li	t1, 128
	mul	a3, t0, t1
	jal	displayPrint
	
	# score renderer
	lw	s0, points
	la	a2, numbers
	li	a0, 17
	li	a1, 153
	li	t1, 1000
	div	t0, s0, t1
	remu	s0, s0, t1
	li	t1, 128
	mul	a3, t0, t1
	jal	displayPrint
	
	la	a2, numbers
	li	a0, 25
	li	a1, 153
	li	t1, 100
	div	t0, s0, t1
	remu	s0, s0, t1
	li	t1, 128
	mul	a3, t0, t1
	jal	displayPrint
	
	la	a2, numbers
	li	a0, 33
	li	a1, 153
	li	t1, 10
	div	t0, s0, t1
	remu	s0, s0, t1
	li	t1, 128
	mul	a3, t0, t1
	jal	displayPrint
	
	la	a2, numbers
	li	a0, 41
	li	a1, 153
	mv	t0, s0
	li	t1, 128
	mul	a3, t0, t1
	jal	displayPrint
	
mapRender:
	# initialize level information
	la	s0, currentLevel
	addi	s0, s0, 8
	# s0 now points to level matrix data
	lw	s1, mapwidth
	# s1 = mapwidth
	lw	s2, mapheight
	# s2 = mapheight
	li	t1, 0
	# reset t1; t1 = tempheight
	# t0 = tempwidth
renderHeightLoop:
	bge	t1, s2 mapRenderEnd
	# while tempheight <= mapheight
	li	t0, 0
	# reset tempwidth after jumping matrix line
renderWidthLoop:
	bge	t0, s1 renderWidthEnd
	# while tempwidth <= mapwidth
	li	t2, 16
	mul	a0, t0, t2
	# bitmap x = tempwidth * 16
	mul	a1, t1, t2
	# bitmap y = tempwidth * 16

	sw	t0, tempwidth, t2
	sw	t1, tempheight, t2
	# save tempwidth and height to memory before function call
	
	# Render selector
	lb	t2, 0(s0)
	beq	t2, zero, renderEmpty

	li	t3, 1
	beq	t2, t3, renderUnbreakable
	
	li	t3, 2
	beq	t2, t3, renderBreakable
	
	li	t3, 3
	beq	t2, t3, renderCollectible
	
	li	t3, 4
	beq	t2, t3, renderBreakableC
	
	li	t3, 5
	beq	t2, t3, renderEnemy

	li	t3, 9
	beq	t2, t3, renderPlayer
	
	li	t3, 10
	beq	t2, t3, renderBuilding
	li	t3, 11
	beq	t2, t3, renderBuilding
	
	li	t3, 12
	beq	t2, t3, renderBreaking
	li	t3, 13
	beq	t2, t3, renderBreaking
	
renderEmpty:
	# at first, the rendering functions really only did rendering, but some of them now do manipulation
	# the reason for the is that if we get strange values on a cell we can call this as a panic button
	li	t2, 0
	sb	t2, 0(s0)
	la	a2, empty
	jal	displayPrint
	j	continueRW

renderUnbreakable:
	la	a2, empty
	jal	displayPrint
	j	continueRW
	
renderBreakable:
	li	t2, 2
	sb	t2, 0(s0)
	la	a2, breakable
	jal	displayPrint
	j	continueRW

renderCollectible:
	# there are some other reasons like updating animated positions
	# the function above does almost the same thing, the one below even more so
	li	t2, 3
	sb	t2, 0(s0)
	la	a2, collectibles
	lw	t2, currentCollectible
	li	t1, 256
	mul	a3, t1, t2
	jal	displayPrint
	j	continueRW

renderBreakableC:
	li	t2, 4
	sb	t2, 0(s0)
	la	a2, breakable_c
	lw	t2, currentCollectible
	li	t1, 256
	mul	a3, t1, t2
	jal	displayPrint
	j	continueRW
	
renderEnemy:
	# the intricate process of enemy rendition is explained in the article
	# needs to use t0 and t1 to find out ID of the enemy in this position and render according to state and type
	la	s3, enemyPositions
	li	s5, 8
	li	s6, 0
findEnemy:
	# panic check - no matching enemy position was found, replace with empty cell
	bge	s6, s5, renderEmpty
	lb	s4, 0(s3)
	beq	t0, s4, xMatch
	addi	s3, s3, 3
	addi	s6, s6, 1
	j	findEnemy
xMatch:
	# if x and y matches, we found the right enemy ID
	lb	s4, 1(s3)
	beq	t1, s4, enemyFound
	addi	s3, s3, 3
	addi	s6, s6, 1
	j	findEnemy
enemyFound:
	# gather ID (now held in s4)
	lb	s4, 2(s3)
	
	# gather direction
	la	s3, enemyStates
	li	t0, 2
	mul	s5, s4, t0
	add	s3, s5, s3
	lb	s5, 0(s3)
	
	# gather special state
	li	t0, 4
	lb	s6, 1(s3)
	mul	s6, s6, t0
	
	# load a3 state argument
	li	t0, 256
	add	a3, s5, s6
	mul	a3, t0, a3
	
	# gather type
	la	s3, enemyTypes
	add	s3, s4, s3
	lb	s3, 0(s3)
	
	# enemy render selector
	beq	s3, zero, renderDudu
	li	t0, 1
	beq	s3, t0, renderTonho
	# if somehow an enemy doesn't match any known enemy type, replace with an empty cell (to be replaced with missing texture)
	j	renderEmpty
	
renderDudu:
	la	a2, enemy_dudu
	jal	displayPrint
	j	continueRW

renderTonho:
	la	a2, enemy_tonho
	jal	displayPrint
	j	continueRW

renderPlayer:
	# render selector using states and the spritesheet
	li	a3, 256
	lw	t3, playerState
	mul	a3, t3, a3
	lw	t3, playerBreaking
	beq	t3, zero, noPlayerBreak
	li	t3, 1024
	add	a3, t3, a3
noPlayerBreak:
	la	a2, char
	jal	displayPrint
	j	continueRW


	# The rendering functions below call cell updates when necessary
renderBuilding:
	lw	t0, playerEnergy
	lw	t1, maxPlayerEnergy
	addi	t1, t1, -1
	blt	t0, t1, renderBuilding1
finishBuilding:
	li	t3, 10
	beq	t2, t3, renderBreakable
	j	renderBreakableC
renderBuilding1:
	la	a2, building0
	jal	displayPrint
	j	continueRW

renderBreaking:
	lw	t0, playerEnergy
	lw	t1, maxPlayerEnergy
	addi	t1, t1, -1
	blt	t0, t1, renderBreaking1
finishBreaking:
	li	t3, 12
	beq	t2, t3, renderEmpty
	j	renderCollectible
renderBreaking1:
	la	a2, breaking0
	jal	displayPrint
	j	continueRW

continueRW:
	# recover tempwidth and height from memory
	lw	t0, tempwidth
	lw	t1, tempheight
	# increment tempwidth by one
	addi	t0, t0, 1
	# data pointer goes to adjacent matrix object
	addi	s0, s0, 1
	j	renderWidthLoop
	
renderWidthEnd:
	# increment tempheight by one
	addi	t1, t1, 1
	j	renderHeightLoop
	
mapRenderEnd:


	la	t0, explosionFlag
	bne	t0, zero, explosionMatrixRender
	j	outFinishExplosions
explosionMatrixRender:
	# s0 points to explosionMatrix and s3 to level matrix
	la	s3, currentLevel
	addi	s3, s3, 8
	la	s0, explosionMatrix
	# map width and height
	li	s1, 20
	li	s2, 15
	
	li	t1, 0
EMRy:
	bge	t1, s2, outEMR	
	li	t0, 0
EMRx:	
	bge	t0, s1, outEMRx
	li	t2, 4
	blt	t0, t2, continueEMRx
	
	# set displayPrint arguments for X and Y
	li	t2, 16
	mul	a0, t0, t2
	mul	a1, t1, t2
	
	sw	t0, tempwidth, t2
	sw	t1, tempheight, t2
	
	lb	t3, 0(s0)
	# explosion render selector
	# should only render where the explosion matrix has a 1
	beq	t3, zero, outRenderExplosion

renderExplosion:
	li	t0, 256
	lw	t1, explosionState
	la	a2, explosion
	mul	a3, t0, t1
	jal	displayPrint
	
	# break blocks and/or kill player
	lb	t3, 0(s3)
	
	li	t4, 9
	beq	t3, t4, gameOver
	li	t4, 2
	beq	t3, t4, breakBreakable
	li	t4, 4
	beq	t3, t4, breakBreakable_c
	j	outRenderExplosion
breakBreakable:
	sb	zero, 0(s3)
	j	outRenderExplosion
breakBreakable_c:
	li	t0, 3
	sb	t0, 0(s3)
	j	outRenderExplosion
outRenderExplosion:

	lw	t0, tempwidth
	lw	t1, tempheight
	
continueEMRx:
	
	# increment pointers and counters
	addi	s3, s3, 1
	addi	s0, s0, 1
	addi	t0, t0, 1
	j	EMRx
outEMRx:
	addi	t1, t1, 1
	j	EMRy

outEMR:	
	
	lw	t0, explosionState
	addi	t0, t0, 1
	sw	t0, explosionState, t1
	li	t1, 6
	bge	t0, t1, finishExplosions
	j	outFinishExplosions
	
finishExplosions:
	# reset blow up states
	# reset explosionMatrix
	# reset explosion flag and state
	
	li	t0, 0
	sw	t0, explosionFlag, t1
	sw	t0, explosionState, t1
	
	la	s0, explosionMatrix
	li	t2, 75
	li	t0, 0
EMreset:
	bge	t0, t2, outEMreset
	li	t1, 0
	sw	t1, 0(s0)
	
	addi	t0, t0, 1
	addi	s0, s0, 4
	j	EMreset
outEMreset:
	la	s0, enemyStates
	li	t2, 8
	li	t0, 0
enemyExpStateReset:
	bge	t0, t2, outFinishExplosions
	li	t1, 0
	sb	t1, 1(s0)
	addi	s0, s0, 2
	addi	t0, t0, 1
	j	enemyExpStateReset

outFinishExplosions:

	jal	frameSwitch
	
	# check for victory
	lw	t0, victoryFlag
	bne	t0, zero, victoryScreen
	
	# define tick period (equation: sleep + gameloop runtime = 50ms)
	# example: if the gameloop takes ~10ms to run, the sleep call below should use 40ms
	
	addi	s11, s11, 1
	
	li	a7, 32
	li	a0, 44
	ecall

continueLoop: j runtimeLoop

gameOver:
	
	# renders a red effect on the screen for one second when the game is over
	mv	a0, zero
	mv	a1, zero
	la	a2, death_overlay
	mv	a3, zero
	jal	displayPrint
	jal	frameSwitch
	
	li	a0, 1000
	li	a7, 32
	ecall
	
	# render the gameover screen
	mv	a0, zero
	mv	a1, zero
	la	a2, gameover
	mv	a3, zero
	jal	displayPrint
	jal	frameSwitch
	
overInput:
	# wait for input to restart.
	lw	t0, keyboardAddress
	lw	t1, 0(t0)
	andi	t1, t1, 1
	beq	t1, zero, overInput
	lb	t1, 4(t0)
	li	t2, 0x072
	beq	t1, t2, dynamicLoader
	j	overInput

victoryScreen:

	# below are carbon copies of menuRender and renderBackground functions
	# necessary because they're not callable (calling functions recursively requires using the stack and we have no clue how)
	# would've been cool if we learned. Maybe if the professor hadn't lost 6 of his classes to holidays on Thursdays this semester.
	# instead of using the stack, one could just create a list that acts as a stack
	# truth be told I'm just lazy
	
	mv	a0, zero
	mv	a1, zero
	la	a2, levelBackground
	jal	displayPrint
	
	# I once again deeply apologize for how unelegant the following code is.
	
	# level number renderer
	la	a2, numbers
	lw	t0, levelNumber
	li	a0, 29
	li	a1, 70
	li	t1, 128
	mul	a3, t0, t1
	jal	displayPrint
	
	# current collectible renderer
	la	a2, collectibles
	lw	t0, currentCollectible
	li	a0, 24
	li	a1, 206
	li	t1, 256
	mul	a3, t0, t1
	jal	displayPrint
	
	# timer renderer
	la	a2, numbers
	lw	s0, levelTimer
	li	a0, 16
	li	a1, 113
	li	t1, 600
	div	t0, s0, t1
	remu	s0, s0, t1
	li	t1, 128
	mul	a3, t0, t1
	jal	displayPrint
	
	la	a2, numbers
	li	a0, 24
	li	a1, 113
	li	t1, 60
	div	t0, s0, t1
	remu	s0, s0, t1
	li	t1, 128
	mul	a3, t0, t1
	jal	displayPrint
	
	la	a2, numbers
	li	a0, 34
	li	a1, 113
	li	t1, 10
	div	t0, s0, t1
	remu	s0, s0, t1
	li	t1, 128
	mul	a3, t0, t1
	jal	displayPrint
	
	la	a2, numbers
	li	a0, 42
	li	a1, 113
	mv	t0, s0
	li	t1, 128
	mul	a3, t0, t1
	jal	displayPrint
	
	# score renderer
	lw	s0, points
	la	a2, numbers
	li	a0, 17
	li	a1, 153
	li	t1, 1000
	div	t0, s0, t1
	remu	s0, s0, t1
	li	t1, 128
	mul	a3, t0, t1
	jal	displayPrint
	
	la	a2, numbers
	li	a0, 25
	li	a1, 153
	li	t1, 100
	div	t0, s0, t1
	remu	s0, s0, t1
	li	t1, 128
	mul	a3, t0, t1
	jal	displayPrint
	
	la	a2, numbers
	li	a0, 33
	li	a1, 153
	li	t1, 10
	div	t0, s0, t1
	remu	s0, s0, t1
	li	t1, 128
	mul	a3, t0, t1
	jal	displayPrint
	
	la	a2, numbers
	li	a0, 41
	li	a1, 153
	mv	t0, s0
	li	t1, 128
	mul	a3, t0, t1
	jal	displayPrint
	
	li	a0, 64
	mv	a1, zero
	la	a2, victoryscreen
	mv	a3, zero
	jal	displayPrint
	jal	frameSwitch
	
	# Finished rendering numbers
	
	# Code below is mostly placeholding

	li	a0, 4000
	li	a7, 32
	ecall
	
	lw	t0, levelNumber
	addi	t0, t0, 1
	lw	t1, unlockedLevels
	bgt	t1, t0, noUnlocks
	sw	t0, unlockedLevels, t1
noUnlocks:
	sw	t0, levelNumber, t1
	
	j	dynamicLoader

frameSwitch:
	# frameswitch algorithm
	# the way rendering works in this game is that the opposite frame is rendered while the current frame
	# is displayed. This removes weird "line" effects on the display as switching frames is instant
	# as opposed to pixel by pixel
	# since this runs at the very end of the loop, the frame is only switched once the frame we are
	# switching to is fully rendered.
	# the algorithm for switching itself below is rather self-explanatory
	lui	t0, 0x00100
	lw	t1, currentframeaddress
	# invert the third byte's last bit (left to right)(This switches frames in essence)
	xor	t1, t1, t0
	# save nthe new value
	sw	t1, currentframeaddress, t0
	
	# display the new frame, similarly through bit inversion, this time of the first bit in this address
	lw	t1, displayedframeaddress
	lw	t2, 0(t1)
	xori	t2, t2, 1
	sw	t2, 0(t1)
	ret

displayPrint:
	# basic renderer function
	# utilizes only temporaries
	# a0 = bitmap display x position (from the left)
	# a1 = bitmap display y position (from the top)
	# a2 = image pointer
	# a3 = image selector (for spritesheets)
	
	# t5 = width (x) of image
	lw	t5, 0(a2)
	
	# t6 = height (y) of image
	addi	a2, a2, 4
	lw	t6, 0(a2)
	
	# a2 = start of image pixel information
	addi	a2, a2, 4
	# select image using a3 (for spritesheets)
	add	a2, a3, a2
	
	# illegal printing prevention
	
	# if starting x position is less than zero, print nothing
	blt	a0, zero, displayPrintEnd
	# if starting y position is less than zero, print nothing
	blt	a1, zero, displayPrintEnd
	# if part of the image falls beyond the display width, print nothing
	li	t1, 320
	add	t0, t5, a0
	bgt	t0, t1, displayPrintEnd
	# if part of the image falls beyond the display height, print nothing
	li	t1, 240
	add	t0, t6, a1
	bgt	t0, t1, displayPrintEnd
	
	# below are calculations for the display pointer.
	# just knowing it works is enough
	# if you spend enough time reading it you'll understand it
	# t3 = bitmap display location pointer
	li	t3, 320
	mul	a1, t3, a1
	lw	t3, currentframeaddress
	add	t3, a1, t3
	add	t3, a0, t3
	
	# t2 = currentY
	li	t2, 0
yLoop:
	# while currentY < height
	bge	t2, t6, displayPrintEnd
	# init currentX to 0
	li	t1, 0
xLoop:
	# while currenX < width
	bge	t1, t5, xEnd
	# copy information from image to bitmap display according to the relevant pointers
	lw	t4, 0(a2)
	sw	t4, 0(t3)
	
	# increments
	addi	a2, a2, 4
	addi	t3, t3, 4
	addi	t1, t1, 4
	j	xLoop
xEnd:
	# next BMD line, reset position according to width
	addi	t3, t3, 320
	sub	t3, t3, t5
	
	# increment currentY
	addi	t2, t2, 1
	j	yLoop	
displayPrintEnd:
	# reset a3 for safety purposes (it is only used by display print and is never reset anywhere)
	mv	a3, zero
	ret
	
exitProgram:
	# exitProgram was placed way down here to prevent drops
	li	a7, 10
	ecall
# Nirva was here >:3
