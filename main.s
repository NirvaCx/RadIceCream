.data

.include "level_information/title_screen.data"
.include "sprites/numbers.data"

.include "level_information/level1.data"
.include "level_information/level1_bg.data"
.include "level_information/level1_info.data"
.include "level_information/level2.data"
.include "level_information/level2_bg.data"
.include "level_information/level2_info.data"

.include "sprites/empty.data"
.include "sprites/breakable.data"
.include "sprites/collectibles.data"
.include "sprites/breakable_c.data"
.include "sprites/enemy_dudu.data"
.include "sprites/char.data"
.include "sprites/building0.data"
.include "sprites/breaking0.data"

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
collectibleTypes:
.word	0, 0, 0
currentCollectible:
.word	0
levelNumber:
.word	0

mapwidth:
.word	20
mapheight:
.word	15
# map width and height are fixed for every level
tempwidth:
.word	0x0
tempheight:
.word	0x0
# matrix variables

playerState:
.word	1
# states up, down, left and right are 0, 1, 2 and 3 respectively
playerBreaking:
.word	0
# boolean value - is the player pressing space?
playerPosX:
.word	0
playerPosY:
.word	0
points:
.word	0
playerEnergy:
.word	0
maxPlayerEnergy:
.word	8
# player variables

currentframeaddress:
.word	0xff100000
displayedframeaddress:
.word	0xff200604
# frameswitch variables

currentInput:
.word	0x0
keyboardAddress:
.word	0xff200000
# input variables

# other variables

lookAheadPointer:
.word	20
# used by doSpecial
levelTimer:
.word	0
#self explanatory

.text

mainMenuRender:
	# render title screen
	mv	a0, zero
	mv	a1, zero
	la	a2, title_screen
	jal	displayPrint
	
	jal	frameSwitch

levelInput:
	# this function gets input from the keyboard numbers and loads the corresponding level.
	lw	t0, keyboardAddress
	lw	t1, 0(t0)
	andi	t1, t1, 1
	# check first bit at keyboard address to see if input has been pressed
	beq	t1, zero, levelInput
	lb	t1, 4(t0)
	li	t2, 0x031
	beq	t1, t2, load1
	li	t2, 0x032
	beq	t1, t2, load2
	j	levelInput
	
load1:
	li	t0, 1
	sw	t0, levelNumber, t1
	la	a0, level1
	la	a1, level1_bg
	la	a2, level1_info
	j	levelLoader

load2:
	li	t0, 2
	sw	t0, levelNumber, t1
	la	a0, level2
	la	a1, level2_bg
	la	a2, level2_info
	j	levelLoader

levelLoader:
	# a0 = level matrix
	# a1 = level background image
	# a2 = level information file
	# a3 = level collectible update matrix (TBA)
	
	# reset playerState
	li	t0, 1
	sw	t0, playerState, t1
	# reset points
	li	t0, 0
	sw	t0, points, t1
	# reset ticker
	li	s11, 0
	# reset player energy
	li	t0, 10
	sw	t0, playerEnergy, t1
	# reset timer
	li	t0, 1500
	sw	t0, levelTimer, t1
	
	# reset enemy states
	la	s0, enemyStates
	li	t0, 8
	li	t1, 0
	li	t2, 1
enemyReset:
	bge	t1, t0, endEnemyReset
	sb	t2, 0(s0)
	addi	t1, t1, 1
	addi	s0, s0, 1
	j	enemyReset
endEnemyReset:
	
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
levelYloop:
	bge	t3, t1, levelYloopEnd
	li	t2, 0
levelXloop:
	bge	t2, t0, levelXloopEnd
	lw	t4, 0(a0)
	sw	t4, 0(s0)
	# copy from level data pointer to currentLevel data pointer
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
bgYloop:
	bge	t3, t1, bgYloopEnd
	li	t2, 0
bgXloop:
	bge	t2, t0, bgXloopEnd
	lw	t4, 0(a1)
	sw	t4, 0(s0)
	# copy 4 pixels from background pointer to levelBackground pointer
	addi	a1, a1, 4
	addi	s0, s0, 4
	addi	t2, t2, 4
	j	bgXloop
bgXloopEnd:
	addi	t3, t3, 1
	j	bgYloop
bgYloopEnd:

getInfo:
	# collect enemy amount
	lw	s0, 0(a2)
	sw	s0, enemyAmount, t0
	addi	a2, a2, 4
	# move to enemy positions
	li	t0, 24
	# enemy position is 6 words long (allows for 8 enemies total)
	li	t1, 0
	la	s0, enemyPositions
	# counter
	# collect enemy positions
loadEnemyPos:
	bge	t1, t0, loadEnemyPosEnd
	lw	s1, 0(a2)
	sw	s1, 0(s0)
	addi	a2, a2, 4
	addi	s0, s0, 4
	addi	t1, t1, 4
	j	loadEnemyPos
loadEnemyPosEnd:
	# collect enemy types
	la	s0, enemyTypes
	lw	s1, 0(a2)
	sw	s1, 0(s0)
	addi	s0, s0, 4
	addi	a2, a2, 4
	lw	s1, 0(a2)
	sw	s1, 0(s0)
	addi	a2, a2, 4
	# collect player position
	la	s0, playerPosX
	lw	s1, 0(a2)
	sw	s1, 0(s0)
	
	addi	a2, a2, 4
	
	la	s0, playerPosY
	lw	s1, 0(a2)
	sw	s1, 0(s0)
	
	addi	a2, a2, 4
	# init collectible amount
	la	s0, collectibleCount
	lw	s1, 0(a2)
	sw	s1, 0(s0)
	
	# init collectible updates
	addi	a2, a2, 4
	la	s0, collectibleUpdates
	lw	s1, 0(a2)
	sw	s1, 0(s0)
	
	addi	a2, a2, 4
	la	s0, collectibleTypes
	li	t1, 0
initCollectibleTypes:
	bgt	t1, s1, outICT
	lw	s2, 0(a2)
	sw	s2, 0(s0)
	addi	a2, a2, 4
	addi	s0, s0, 4
	addi	t1, t1, 1
	j	initCollectibleTypes
outICT:
	# init currentCollectible
	la	s0, collectibleTypes
	lw	s1, 0(s0)
	sw	s1, currentCollectible, s0
	
gameLoop:
	# movement code can probably be reused for enemy movement by substituting "playerState" for "elementState"
	# this can generalize many things which would otherwise become huge amounts of code
	# s11 will be used as a ticker as it will be updated frequently
	
	li	t0, 200
	bge	s11, t0, resetTicker
	# reset ticker if it reaches 200 (every ~10 seconds)
	j	outResetTicker
resetTicker:
	li	s11, 0
outResetTicker:

	# decrement timer every second (very approximate)
	li	t0, 20
	remu	t0, s11, t0
	beq	t0, zero, timerDecrement
	j	outTimerDecrement
timerDecrement:
	lw	t0, levelTimer
	addi	t0, t0, -1
	sw	t0, levelTimer, t1
	bne	t0, zero, outTimerDecrement
	j	gameOver
outTimerDecrement:

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
	
getInput:
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
	
	# set matrix pointer t0 to player position
	# t2 is used as a temporary for this process, getting mostly values from memory
	lw	t2, playerPosY
	li	t0, 20
	mul	t0, t0, t2
	lw	t2, playerPosX
	add	t0, t0, t2
	la	t2, currentLevel
	addi	t2, t2, 8
	add	t0, t0, t2
	
	# movement selector based on received input
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
	# if the input was not in the selector, no action is performed
	li	t2, 0x51
	beq	t1, t2, mainMenuRender
	# cheat key for going back to level select
	j	outInput
	
	# the four labels below all do the same thing for different movements
	# t3 will store the number that will be used to create the pointer
	# that points to the cell towards which the character just tried to move
	# they also update the player's state accordingly
moveUp:
	li	t3, -20
	sw	t3, lookAheadPointer, t4
	lw	s0, playerState
	li	s0, 0
	sw	s0, playerState, s1
	j	movePlayer
moveDn:
	li	t3, 20
	sw	t3, lookAheadPointer, t4
	lw	s0, playerState
	li	s0, 1
	sw	s0, playerState, s1
	j	movePlayer
moveLt:
	li	t3, -1
	sw	t3, lookAheadPointer, t4
	lw	s0, playerState
	li	s0, 2
	sw	s0, playerState, s1
	j	movePlayer
moveRt:
	li	t3, 1
	sw	t3, lookAheadPointer, t4
	lw	s0, playerState
	li	s0, 3
	sw	s0, playerState, s1
	j	movePlayer
	
doSpecial:
	# only allow special if energy is full
	lw	t4, maxPlayerEnergy
	lw	s0, playerEnergy
	blt	s0, t4, outInput
	# reset playerEnergy
	li	s0, 0
	sw	s0, playerEnergy, s1
	
	lw	s0, playerBreaking
	li	s0, 1
	sw	s0, playerBreaking, s1
	
	lw	t3, lookAheadPointer
	# t3 is the constant increment that will be used to "walk" to the next block
	
	add	t4, t0, t3
	li	t6, 0
	# t6 is a flag for whether or not one of the functions has already run
	# e.g. playerDestroy should NOT run if playerBuild did run
	# t4 is target cell pointer; t1 is whatever is contained in that cell
playerBuild:
	lb	t1, 0(t4)
	li	t5, 0
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
	li	t1, 11
	sb	t1, 0(t4)
	add	t4, t4, t3
	li	t6, 1
	j	playerBuild

playerDestroy:
	lb	t1, 0(t4)
	li	t5, 2
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
	bne	t1, t2, continueMovement0
	j	gameOver
continueMovement0:
	# collision with ID 5 (enemy) results in a gameover
	li	t2, 3
	bne	t1, t2, noPoint
	lw	s0, points
	addi	s0, s0, 100
	sw	s0, points, s1
	lw	s0, collectibleCount
	addi	s0, s0, -1
	sw	s0, collectibleCount, s1
	j	continueMovement1
	# collision with a collectible will replace the collectible with empty space,
	# add 100 points, remove 1 from the collectible counter and finish the movement algorithm
noPoint:
	bne	t1, zero, outInput
	# since the only cells towards which you can move other than collectibles are empty cells,
	# we can cancel the movement algorithm if the cell is not empty
continueMovement1:
	mv	t1, zero
	sb	t1, 0(t0)
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
	
	# collectible updating function (for when the player collects every objective on screen)
	lw	s0, collectibleCount
	ble	s0, zero, collectibleUpdate
	j	backgroundRender
collectibleUpdate:
	j	gameOver

backgroundRender:
	mv	a0, zero
	mv	a1, zero
	la	a2, levelBackground
	jal	displayPrint

menuRender:
	# Menu positions for reference:
	# Level Number: Y 70 X 29
	# Timer Digits: Y 113, X 16, 24, 34, 42 respectively
	# Score Digits: Y 153, X 17, 25, 33, 41 respectively 
	# Current Item: Y 206, X 24
	# I deeply apologize for how unelegant the following code is.
	
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
	li	t1, 128
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
	li	t2, 3
	sb	t2, 0(s0)
	la	a2, collectibles
	lw	t2, currentCollectible
	li	t1, 128
	mul	a3, t1, t2
	jal	displayPrint
	j	continueRW

renderBreakableC:
	li	t2, 4
	sb	t2, 0(s0)
	la	a2, breakable_c
	jal	displayPrint
	j	continueRW
	
renderEnemy:
	# needs to use t0 and t1 to find out ID of the enemy in this position and render according to state and type
	la	a2, enemy_dudu
	jal	displayPrint
	j	continueRW

renderPlayer:
	# render selector (now using a spritesheet)
	li	a3, 256
	lw	t3, playerState
	mul	a3, t3, a3
	lw	t3, playerBreaking
	beq	t3, zero, noBreak
	li	t3, 1024
	add	a3, t3, a3
noBreak:
	la	a2, char
	jal	displayPrint
	j	continueRW

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
	lw	t0, tempwidth
	lw	t1, tempheight
	# recover tempwidth and height from memory
	addi	t0, t0, 1
	# increment tempwidth by one
	addi	s0, s0, 1
	# data pointer goes to adjacent matrix object
	j	renderWidthLoop
renderWidthEnd:
	addi	t1, t1, 1
	# increment tempheight by one
	j	renderHeightLoop
mapRenderEnd:
	
	jal	frameSwitch
	
	# define tickrate
	addi	s11, s11, 1
	
	li	a7, 32
	li	a0, 50
	ecall

continueLoop: j gameLoop

gameOver:

exitProgram:
	li	a7, 10
	ecall

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
	xor	t1, t1, t0
	sw	t1, currentframeaddress, t0
	
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
	
	lw	t5, 0(a2)
	# t5 = width (x) of image
	addi	a2, a2, 4
	lw	t6, 0(a2)
	# t6 = height (y) of image
	addi	a2, a2, 4
	# a2 = start of image pixel information
	add	a2, a3, a2
	# select image using a3
	
	# illegal printing prevention below
	
	blt	a0, zero, displayPrintEnd
	# if starting x position is less than zero, print nothing
	blt	a1, zero, displayPrintEnd
	# if starting y position is less than zero, print nothing
	li	t1, 320
	add	t0, t5, a0
	bgt	t0, t1, displayPrintEnd
	# if part of the image falls beyond the display width, print nothing
	li	t1, 240
	add	t0, t6, a1
	bgt	t0, t1, displayPrintEnd
	# if part of the image falls beyond the display height, print nothing
	
	# below are calculations for the display pointer.
	# just knowing it works is enough
	li	t3, 320
	mul	a1, t3, a1
	lw	t3, currentframeaddress
	add	t3, a1, t3
	add	t3, a0, t3
	# t3 = bitmap display location pointer
	
	li	t2, 0
	# t2 = currentY
yLoop:
	bge	t2, t6, displayPrintEnd
	# while currentY < height
	li	t1, 0
	# init currentX to 0
xLoop:
	bge	t1, t5, xEnd
	# while currenX < width
	lw	t4, 0(a2)
	sw	t4, 0(t3)
	# copy information from image to bitmap display according to the relevant pointers
	
	addi	a2, a2, 4
	addi	t3, t3, 4
	addi	t1, t1, 4
	# increment image pointer, display pointer and currentX by one
	j	xLoop
xEnd:
	addi	t3, t3, 320
	sub	t3, t3, t5
	# next BMD line, reset position according to width
	addi	t2, t2, 1
	# increment currentY
	j	yLoop	
displayPrintEnd:
	mv	a3, zero
	# reset a3 for safety purposes (it is only used by display print and is never reset anywhere)
	ret
