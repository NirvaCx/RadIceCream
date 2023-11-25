.data

.include "maps/map1.data"

.include "sprites/level1_bg.data"
.include "sprites/empty.data"
.include "sprites/breakable.data"
.include "sprites/collectible_1.data"
.include "sprites/char.data"

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
.word	12
playerPosY:
.word	3
points:
.word	0
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

.text

gameLoop:
	
	# movement code can probably be reused for enemy movement by substituting "playerState" for "elementState"
	# this can generalize many things which would otherwise become huge amounts of code
	
	lw	s0, playerBreaking
	li	s0, 0
	sw	s0, playerBreaking, s1
	
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
	la	t2, map1
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
	j	outInput
	
	# the four labels below all do the same thing for different movements
	# t3 will store the number that will be used to create the pointer
	# that points to the cell towards which the character just tried to move
	# they also update the player's state accordingly
moveUp:
	li	t3, -20
	lw	s0, playerState
	li	s0, 0
	sw	s0, playerState, s1
	j	movePlayer
moveDn:
	li	t3, 20
	lw	s0, playerState
	li	s0, 1
	sw	s0, playerState, s1
	j	movePlayer
moveLt:
	li	t3, -1
	lw	s0, playerState
	li	s0, 2
	sw	s0, playerState, s1
	j	movePlayer
moveRt:
	li	t3, 1
	lw	s0, playerState
	li	s0, 3
	sw	s0, playerState, s1
	j	movePlayer
doSpecial:
	li	t3, 1
	lw	s0, playerBreaking
	li	s0, 1
	sw	s0, playerBreaking, s1
	j	outInput

movePlayer:
	# t4 is target cell pointer
	add	t4, t0, t3
	# t1 is whatever is contained in target cell
	lb	t1, 0(t4)
	li	t2, 5
	beq	t1, t2, gameOver
	# collision with ID 5 (enemy) results in a gameover
	li	t2, 3
	bne	t1, t2, noPoint
	lw	s0, points
	addi	s0, s0, 1
	sw	s0, points, s1
	j	continueMovement
	# collision with a collectible will replace the collectible with empty space,
	# add a point and finish the movement algorithm
noPoint:
	bne	t1, zero, outInput
	# since the only cells towards which you can move other than collectibles are empty cells,
	# we can cancel the movement algorithm if the cell is not empty
continueMovement:
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
	
	
backgroundRender:
	# render background map
	li	a0, 64
	mv	a1, zero
	la	a2, level1_bg
	jal	displayPrint
	
mapRender:
	# initialize map1 information
	la	s0, map1
	addi	s0, s0, 8
	# s0 now points to map1 matrix data
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
	beq	t2, t3, renderEmpty
	# unbreakable blocks also render empty cells
	
	li	t3, 2
	beq	t2, t3, renderBreakable
	
	li	t3, 3
	beq	t2, t3, renderCollectible

	li	t3, 9
	beq	t2, t3, renderPlayer

renderEmpty:
	la	a2, empty
	jal	displayPrint
	j	continueRW
	
renderBreakable:
	la	a2, breakable
	jal	displayPrint
	j	continueRW

renderCollectible:
	la	a2, collectible_1
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
	
	# define tickrate
	li	a7, 32
	li	a0, 100
	ecall

continueLoop: j gameLoop

gameOver:

exitProgram:
	li	a7, 10
	ecall
	
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
