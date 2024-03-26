################ CSC258H1F Winter 2024 Assembly Final Project ##################
# This file contains our implementation of Tetris.
#
# Student 1: Mark Henein, 1008878537
# Student 2: Joshiah Joseph, 1009089861
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
    addi $s4, $zero, -1         # $s4 = flag for movement direction (0 for down, 1 for left, 2 for right, 3 for rotate)
    addi $s5, $zero, -1         # $s5 = flag for current tetromino (0 for O, 1 for I, 2 for S, 3 for Z, 4 for L, 5 for J, 6 for T)
    addi $s6, $zero, -1         # $s6 = current tetromino colour (O=yellow, I=blue, S=red, Z=green, L=orange, J=pink, T=purple)
    addi $s7, $zero, 0          # $s7 = amount of time there is a downwards collision

##############################################################################
# Code
##############################################################################
    # Print the initial state of the game to the bitmap display
    jal printBoard                      # Initialize the game
    
    # Place a single tetromino
    jal placeTetromino                  # Print a random tetromino to display
    
    game_loop:
        jal handleKeyboardInput         # Recieve input from the keyboard
        
        # If the movement direction is down, left, or right, then detect collisions in the specified direction
        beq $s4, 0, call_detectCollisions
        beq $s4, 1, call_detectCollisions
        beq $s4, 2, call_detectCollisions
        beq $s4, 3, call_rotate_Z
        j end_call_rotate_Z                 # Current movement direction is not down, left, or right
        
        call_detectCollisions:
            jal detectCollisions            # Detect if there are any collisions in the specified direction
            beq $s3, 0, call_moveTetrmino   # Move tetromino after keyboard input if there are no collisions
            j end_call_moveTetromino        # Do not move tetromino if there is a collision
            call_moveTetrmino:
                jal moveTetromino           # Move the tetromino within the bitmap display
            end_call_moveTetromino:
            j end_call_rotate_Z
        end_call_detectCollisions:
        
        call_rotate_Z:
            jal rotate_Z                    # Rotate the tetrommino
        end_call_rotate_Z:
        
    	jal printTetromino                 # Print the tetromino to the bitmap display
        
        
        # Detect if there are any downward collisions (for tetromino placement)
        addi $s3, $zero, 0                  # Reset the value of the collision flag
        addi $s4, $zero, 0                  # Set movement direction to down
        jal detectCollisions                # Detect if there are downwards collisions
        addi $s4, $zero, -1                 # Reset movement direction 
        
        # Increment downward collision timer by 1 if a collision is detected
        beq $s3, 1, increment_collision_timer
        beq $s3, 0, reset_collision_timer
        j end_collision_timer
        increment_collision_timer:
            addi $s7, $s7, 1                # Increment collision timer by 1 ms
            j end_collision_timer
        reset_collision_timer:
            addi $s7, $zero, 0              # Reser collision timer to 0
        end_collision_timer:
        
        # Move tetromino to 2d array 
    	beq $s7, 50, move_tetromino_to_2d_array
    	j end_move_tetromino_to_2d_array
    	move_tetromino_to_2d_array:
    	   jal tetrominoToArray
    	   jal clearTetromino
    	   jal placeTetromino
    	   jal printArray
    	end_move_tetromino_to_2d_array:
    	
    	# Sleep for 1ms
    	li $v0, 32
        li $a0, 1
        syscall
    
        # Return to beginning of loop
        j game_loop
    end_game_loop:

    # Exit program
    li $v0, 10           # syscall code for exit
    syscall              # exit program
