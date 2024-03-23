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
# array: .space 1056              # Allocate space for a 22x12 array (264 elements, each 4 bytes)
# rows:  .word 22                 # Number of rows
# cols:  .word 12                 # Number of columns
# ADDR_DSPL:  .word 0x10008000    # Address of the bitap display
# ADDR_KBRD:  .word 0xffff0000    # The address of the keyboard
# tetromino: .space 16            # Allocate space for a array of length 4 (4 elements, each 4 bytes)


######## All shared data between files are stored in shared_data.asm #########
.entry main
.include "shared_data.asm"
.include "keyboard.asm"
.include "array.asm"
.include "tetromino.asm"

.text

# Run the Tetris game.
main:
##############################################################################
# Mutable Data
##############################################################################
    addi $s3, $zero, -1         # $s3 = flag for collision detection (1 if collision is detected, 0 otherwise)
    addi $s4, $zero, -1         # $s4 = flag for movement direction (0 for down, 1 for left, 2 for right)
    addi $s5, $zero, -1         # $s5 = flag for current tetromino (0 for O, 1 for I, 2 for S, 3 for Z, 4 for L, 5 for J, 6 for T)
    addi $s6, $zero, -1         # $s6 = current tetromino colour (O=yellow, I=blue, S=red, Z=green, L=orange, J=pink, T=purple)

##############################################################################
# Code
##############################################################################
    # Print the initial state of the game to the bitmap display
    jal printBoard                      # Initialize the game
    
    # Place a single tetromino
    jal placeTetromino                  # Print a random tetromino to display
    
    game_loop:
        jal handleKeyboardInput         # Recieve input from the keyboard
        
        jal detectCollisions            # Detect if there are any collisions in the specified direction
        
        beq $s3, 0, call_moveTetrmino   # Move tetromino after keyboard input if there are no collisions
        j end_call_moveTetromino        # Do not move tetromino if there is a collision
        
        call_moveTetrmino:
            jal moveTetromino           # Move the tetromino within the bitmap display
        end_call_moveTetromino:
        
        addi $s3, $zero, 0              # Reset the value of the collision flag
        
    	jal printTetromino             # Print the tetromino to the bitmap display
    	
    	# Sleep
    	li $v0, 32
        li $a0, 1
        syscall
    
        # Return to beginning of loop
        j game_loop
    end_game_loop:

    # Exit program
    li $v0, 10           # syscall code for exit
    syscall              # exit program
