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

##############################################################################
# Mutable Data
##############################################################################
# flag_collision:         .word -1        # flag for collision detection (1 if collision is detected, 0 otherwise)
# flag_movement:          .word -1        # flag for movement direction (0 for down, 1 for left, 2 for right, 3 for rotate)
# flag_rotation_state:    .word 0         # flag for the rotation state of the current tetromino (0 to 3)
# current_tetromino:      .word -1        # flag for current tetromino (0 for O, 1 for I, 2 for S, 3 for Z, 4 for L, 5 for J, 6 for T)
# tetromino_colour:       .word -1        # current tetromino colour (O=yellow, I=blue, S=red, Z=green, L=orange, J=pink, T=purple)
# time_down_collision:    .word 0         # amount of time there is a downwards collision (in ms)
# gravity_tick_timer:     .word 0         # the amount of time that has passed since the last gravity tick
# gravity_speed:          .word 100       # the amount of time it takes for gravity to tick (100 by default)
# gravity_increase_timer: .word 0         # the amount of time that has passed since the last gravity speed increase
# gravity_increase_speed: .word 1000      # the amount of time it takes for gravity to increase (gravity_speed decrease)
# music_counter:          .word 0         # the amount of time that has passed since the last note in the tetris theme has played
# music_arrays_index:     .word 0         # current index in the music data arrays (for tetris theme)


##############################################################################
# Imports
##############################################################################
######## All shared data between files are stored in shared_data.asm #########
.entry main
.include "shared_data.asm"
.include "keyboard.asm"
.include "array.asm"
.include "tetromino.asm"

##############################################################################
# Code
##############################################################################

# Run the Tetris game.
main:    
    # Print the initial state of the game to the bitmap display
    jal printBoard                      # Initialize the game
    
    # Place a single tetromino
    jal placeTetromino                  # Print a random tetromino to display
    
    game_loop:
        ######################## HANDLE USER INPUT ###########################
        
        jal handleKeyboardInput         # Recieve input from the keyboard
        
        # If the movement direction is down, left, or right, then detect collisions in the specified direction
        lw $t0, flag_movement               # Load value stored in flag_movement to $t0
        beq $t0, 0, call_detectCollisions
        beq $t0, 1, call_detectCollisions
        beq $t0, 2, call_detectCollisions
        beq $t0, 3, call_rotate_tetromino
        j end_call_rotate_tetromino         # Current movement direction is not down, left, or right
        
        call_detectCollisions:
            jal detectCollisions            # Detect if there are any collisions in the specified direction
            lw $t0, flag_collision
            beq $t0, 0, call_moveTetrmino   # Move tetromino after keyboard input if there are no collisions
            j end_call_moveTetromino        # Do not move tetromino if there is a collision
            call_moveTetrmino:
                jal printArray              # Remove the unplaced tetromino from the bitmap display
                jal moveTetromino           # Move the tetromino within the bitmap display
            end_call_moveTetromino:
            j end_call_rotate_tetromino
        end_call_detectCollisions:
        
        call_rotate_tetromino:
            jal printArray
            jal rotateTetromino            # Rotate the tetrommino
        end_call_rotate_tetromino:
        
    	jal printTetromino                 # Print the tetromino to the bitmap display
        
        
        
        ######################## PLACE TETROMINO (IF NECESSARY) ###########################
        
        # Detect if there are any downward collisions (for tetromino placement)
        sw $zero, flag_collision            # Reset the value of the collision flag
        sw $zero, flag_movement             # Set movement direction to down
        jal detectCollisions                # Detect if there are downwards collisions
        addi $t0, $zero, -1
        sw $t0, flag_movement               # Reset movement direction 
        
        # Increment downward collision timer by 1 if a collision is detected
        lw $t0, flag_collision
        beq $t0, 1, increment_collision_timer
        beq $t0, 0, reset_collision_timer
        j end_collision_timer
        increment_collision_timer:
            lw $t0, time_down_collision     # Load current collision time to $t0
            addi $t0, $t0, 1                # Increment collision timer by 1 ms
            sw $t0, time_down_collision     # Store new collision time
            j end_collision_timer
        reset_collision_timer:
            sw $zero, time_down_collision   # Reset collision timer to 0
        end_collision_timer:
        
        # Place the tetromino if timer reaches 40ms
        lw $t0, time_down_collision                 # Load collision time into $t0
    	bge $t0, 50, move_tetromino_to_2d_array     # If timer >= 50, place tetromino
    	j end_move_tetromino_to_2d_array
    	move_tetromino_to_2d_array:
    	   jal tetrominoToArray            # Move tetromino to 2d array
    	   jal clearTetromino              # Clear the current tetromino array
    	   jal placeTetromino              # Generate a new random tetromino
    	   jal clearLines                  # Clear completed lines if necessary
    	   jal redrawBackground            # Redraw the background after line clearing
    	   jal printArray                  # Print the array to the bitmap display
    	end_move_tetromino_to_2d_array:
    	
    	
    	
    	######################## HANDLE GRAVITY FEATURE ###########################
    	
    	# Increment gravity timer by 1
    	lw $t0, gravity_tick_timer         # Load value of gravity_tick_timer into $t0
    	addi $t0, $t0, 1                   # Increment gravity timer
    	sw $t0, gravity_tick_timer         # Load value back into gravity timer
    	
    	# Increment gravity_increase_timer by 1
    	lw $t0, gravity_increase_timer     # Load value of gravity_increase_timer into $t0
    	addi $t0, $t0, 1                   # Increment gravity_increase_timer
    	sw $t0, gravity_increase_timer     # Load value back into gravity_increase_timer
    	
    	# If gravity timer is equal to gravity_speed, then move tetromino downwards
    	lw $t0, gravity_tick_timer         # Load value of gravity_tick_timer into $t0
    	lw $t1, gravity_speed              # Load value of gravity_speed into $t1
    	bge $t0, $t1, gravity_tick
    	j end_tick
    	gravity_tick:
            sw $zero, flag_collision            # Reset the value of the collision flag
            sw $zero, flag_movement             # Set movement direction to down
            jal detectCollisions                # Detect if there are downwards collisions
            
            lw $t0, flag_collision
            beq $t0, 0, gravity_move_down
            j gravity_collision
            gravity_move_down:
                jal printArray                  # Remove the unplaced tetromino from the bitmap display
                jal moveTetromino               # Move the tetromino within the bitmap display
                jal printTetromino              # Print the tetromino to the bitmap display
                sw $zero, gravity_tick_timer    # Reset the value of gravity_tick_timer
            gravity_collision:
            addi $t0, $zero, -1
            sw $t0, flag_movement           # Reset the value of flag_movement
        end_tick:
        
    	# If gravity_increase_timer is equal to gravity_increase_speed, then increase gravity
    	lw $t0, gravity_increase_timer      # Load value of gravity_increase_timer into $t1
    	lw $t1, gravity_increase_speed      # Load value of gravity_increase_speed into $t1
    	bge $t0, $t1, increase_gravity       
    	j end_increase_gravity
    	increase_gravity:
    	   lw $t2, gravity_speed                   # Load the value of gravity_speed into $t2
    	   bge $t2, 20, decrement_gravity_speed    # Ensure the minimum value of gravity_speed is 20
    	   j end_decrement_gravity_speed
    	   decrement_gravity_speed:
	       	   addi $t2, $t2, -10                  # Decrease gravity_speed by 10
	       	   sw $t2, gravity_speed               # Load new value back into gravity_speed
    	   end_decrement_gravity_speed:
    	   sw $zero, gravity_increase_timer        # Reset the value of gravity_increase_timer
        end_increase_gravity:
        
        
        
        ######################## PLAY THE TETRIS THEME ###########################
        
        # Reset the array index if it reached the end
        lw $t0, music_arrays_index
        bge $t0, 39, reset_music_indices
        j end_reset_music_indices
        reset_music_indices:
            addi $t0, $zero, 0
            sw $t0, music_arrays_index
        end_reset_music_indices:
        
        # Find the current delay
        mul $t0, $t0, 4         # Multiply the index by 4 to find the address offset
        la $t1, delays          # Load the starting address of the delays array
        add $t1, $t1, $t0       # Find the current address in the delays array
        lw $t2, ($t1)           # Load the current delay into $t2
    
        # If the music counter is equal to the current delay, play the note
        lw $t3, music_counter               # Load the music counter into $t3
        bge $t3, $t2, play_current_note     # Play note if music counter >= delay
        ble $t0, 0, play_current_note       # Play note if array index == 0
        
        # Increment the music counter
        addi $t3, $t3, 15           # Increment the music counter by 10
        sw $t3, music_counter       # Store new music counter   
        j end_play_current_note
        
        play_current_note:
            la $t4, pitches
            add $t4, $t4, $t0
            lw $a0, ($t4)       # $a0 = pitch (0-127)
            
            la $t5, durations
            add $t5, $t5, $t0
            lw $a1, ($t5)       # $a1 = duration in milliseconds
            
            # Play the note
            li $v0, 31      # Load the service number for MIDI out into $v0
            li $a2, 0       # $a2 = instrument (0-127)
            li $a3, 100     # $a3 = volume (0-127)
            syscall         # Issue the SYSCALL instruction
            
            sw $zero, music_counter     # Reset the value of the music counter
            
            lw $t0, music_arrays_index  # Load the current music array index into $t0
            addi $t0, $t0, 1            # Increment the array index by 1
            sw $t0, music_arrays_index  # Store the new value
        end_play_current_note:
        
        
    	######################## SLEEP AND LOOP ###########################
        
    	# Sleep for 10ms
    	li $v0, 32
        li $a0, 10
        syscall
    
        # Return to beginning of loop
        j game_loop
    end_game_loop:

    # Exit program
    li $v0, 10           # syscall code for exit
    syscall              # exit program
