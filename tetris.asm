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


######## All shared data between files are stored in shared_data.asm #########
.entry main
.include "shared_data.asm"
.include "array.asm"
.include "tetromino.asm"
.include "keyboard.asm"

##############################################################################
# Code
##############################################################################
.text

# Run the Tetris game.
main:
    # Print the initial state of the game to the bitmap display
    jal printBoard      # Initialize the game
    
    # Place a single tetromino
    jal placeTetromino  # Print a random tetromino to display
    
    # Exit program
    li $v0, 10           # syscall code for exit
    syscall              # exit program


# game_loop:
	# # 1a. Check if key has been pressed
    # # 1b. Check which key has been pressed
    # # 2a. Check for collisions
	# # 2b. Update locations (paddle, ball)
	# # 3. Draw the screen
	# # 4. Sleep

    # #5. Go back to 1
    # # b game_loop
# end_game_loop:
