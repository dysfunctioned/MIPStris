################ CSC258H1F Winter 2024 Assembly Final Project ##################
# This file contains our implementation of Tetris.
#
# Student 1: Mark Henein, 1008878537
# Student 2: Joshiah Joseph, Student Number
######################## Bitmap Display Configuration ########################
# - Unit width in pixels:       1
# - Unit height in pixels:      1
# - Display width in pixels:    12 (10 blocks + 2 boundaries)
# - Display height in pixels:   22 (20 blocks + 2 boundaries)
# - Base Address for Display:   0x10008000 ($gp)
##############################################################################

##############################################################################
# Immutable Data
##############################################################################
.data
    array: .space 1056              # Allocate space for a 22x12 array (264 elements, each 4 bytes)
    rows:  .word 22                 # Number of rows
    cols:  .word 12                 # Number of columns
    ADDR_DSPL:  .word 0x10008000    # Address of the bitap display
    ADDR_KBRD:  .word 0xffff0000    # The address of the keyboard
        
.include "array.asm"
##############################################################################
# Mutable Data
##############################################################################

##############################################################################
# Code
##############################################################################
.text
.globl main

# Run the Tetris game.
main:
    # Initialize the game
    jal printBoard

game_loop:
	# 1a. Check if key has been pressed
    # 1b. Check which key has been pressed
    # 2a. Check for collisions
	# 2b. Update locations (paddle, ball)
	# 3. Draw the screen
	# 4. Sleep

    #5. Go back to 1
    # b game_loop
end_game_loop:

# Exit program
li $v0, 10           # syscall code for exit
syscall              # exit program
