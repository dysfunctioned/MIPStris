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

##############################################################################
# Code
##############################################################################

# Function to handle keyboard input
handleKeyboardInput:
    lw $s0, ADDR_KBRD           # $s0 = base address for keyboard
    lw $t0, 0($s0)              # Load first word from keyboard
    beq $t0, 1, keyboard_input  # If first word 1, key is pressed
    lw $zero, ($s0)             # Clear indication that key is pressed
    j handleKeyboardInput_exit
    
    keyboard_input:
        lw $t1, 4($s0)                  # Load second word from keyboard
        beq $t1, 0x61, respond_to_A     # Check if the key 'A' was pressed
        beq $t1, 0x73, respond_to_S     # Check if the key 'S' was pressed
        beq $t1, 0x64, respond_to_D     # Check if the key 'D' was pressed
        beq $t1, 0x77, respond_to_W     # Check if the key 'W' was pressed 
        j handleKeyboardInput_exit
        
        respond_to_S:
            sw $zero, flag_movement     # Update direction flag to zero (down)    
            j handleKeyboardInput_exit
        respond_to_A:
            addi $t0, $zero, 1          
            sw $t0, flag_movement       # Update direction flag to 1 (left)
            j handleKeyboardInput_exit
        respond_to_D:
            addi $t0, $zero, 2
            sw $t0, flag_movement       # Update direction flag to 2 (right)
            j handleKeyboardInput_exit
        respond_to_W:
            addi $t0, $zero, 3
            sw $t0, flag_movement       # Update direction flag to 3 (up/rotate)
            j handleKeyboardInput_exit
            
    handleKeyboardInput_exit:
    jr $ra                  # Return to caller



# Function to make tetromino move in a given direction
moveTetromino:
    la $s0, tetromino       # $s0 = tetrmomino array
    lw $s1, cols            # $s1 = number of rows
    la $s2, ADDR_DSPL       # Stating addres of bitmap display
    addi $t0, $zero, 0      # $t0 = loop counter
    
    moveTetromino_loop:
        beq $t0, 4, moveTetromino_end_loop      # End loop if array location reaches the end
        
        # Remove the previous tetromino cell
        lw $t1, ($s0)           # Obtain the address of the current tetromino cell
        add $s2, $t1, $zero     # Obtain address of position of cell in bitmap display
        
        lw $t3, flag_movement       # Load the current movement flag into $t3
        beq $t3, $zero, move_down   # If $t3 = 0, move the tetromino down
        beq $t3, 1, move_left       # If $t3 = 1, move the tetromino left
        beq $t3, 2, move_right      # If $t3 = 2, move the tetromino right
        j end_move
        
        move_down:
            mult $t2, $s1, 4        # Number of columns * 4 = the offset of the address to shift dowm
            add $t1, $t1, $t2       # Add offset to the address
            sw $t1, ($s0)           # Load address back into the array
            j end_move
        move_left:
            addi $t1, $t1, -4       # Add offset to the address
            sw $t1, ($s0)           # Load address back into the array
            j end_move
        move_right:
            addi $t1, $t1, 4        # Add offset to the address
            sw $t1, ($s0)           # Load address back into the array
            j end_move
            
        end_move:
        addi $s0, $s0, 4            # Move to next address in memory
        addi $t0, $t0, 1            # Increment loop counter by 1
        j moveTetromino_loop
    
    moveTetromino_end_loop:
    addi $t0, $zero, -1
    lw $t0, flag_movement   # Reset the movement direction
    jr $ra                  # Return to caller



# Function to detect collisions
detectCollisions:
    lw $s0, ADDR_DSPL       # $s0 = display starting address
    la $s1, tetromino       # $s1 = tetromino array starting address
    la $s2, array           # $s2 = game array starting address
    
    addi $t0, $zero, 0      # Load loop counter
    lw $t4, dark_grey       # $t4 = dark grey
    
    detectCollisions_loop:
        bge $t0, 4, detectCollisions_end_loop   # End loop at the end of the array
        
        # Load the value from the calculated memory address
        lw $t1, ($s1)       # $t1 = address of current tetromino cell
        
        addi $s1, $s1, 4                        # Increment array address by 4 bytes
        addi $t0, $t0, 1                        # Increment the loop counter by 1
        
        # Calculate address ($t2) of tetromino cell in game array 
        add $t2, $zero, $t1                 # Set $t2 equal to address of tetromino cell in display
        sub $t2, $t2, $s0                   # Subtract by the starting address of the display to find offset
        add $t2, $t2, $s2                   # Add the starting address of the game array
        
        # Check the movement direction flag
        lw $t5, flag_movement           # Store the movement direction in $t5
        beq $t5, $zero, detect_down     # If flag is 0, check for down movement
        beq $t5, 1, detect_left         # If flag is 1, check for left movement
        beq $t5, 2, detect_right        # If flag is 2, check for right movement
        j detectCollisions_end_loop
        
        detect_down:
            # Find address of the cell below the tetromino in game array
            lw $t3, cols        # Load number of columns
            mult $t3, $t3, 4    # Multiply by 4 to find offset
            add $t2, $t2, $t3   # Add offset to current cell address
            
            # Find colour stored at address in game array
            lw $t3, ($t2)
            
            # If colour is not black, check if it is dark grey
            bne $t3, $zero, check_dark_grey
            j no_collision_detected
            check_dark_grey:
                bne $t3, $t4, collition_detected    # Colour is not black or dark grey
            no_collision_detected:
                sw $zero, flag_collision            # Update flag to indicate that a collision is not detected
                j detectCollisions_loop
        
        detect_left:
            # Find address of the cell left of the tetromino in game array
            addi $t2, $t2, -4   # Add offset to current cell address
            
            # Find colour stored at address in game array
            lw $t3, ($t2)

            # If colour is not black, check if it is dark grey
            bne $t3, $zero, check_dark_grey
            j no_collision_detected
            check_dark_grey:
                bne $t3, $t4, collition_detected    # Colour is not black or dark grey
            no_collision_detected:
                sw $zero, flag_collision            # Update flag to indicate that a collision is not detected
                j detectCollisions_loop
        
        detect_right:
            # Find address of the cell left of the tetromino in game array
            addi $t2, $t2, 4   # Add offset to current cell address
            
            # Find colour stored at address in game array
            lw $t3, ($t2)

            # If colour is not black, check if it is dark grey
            bne $t3, $zero, check_dark_grey
            j no_collision_detected
            check_dark_grey:
                bne $t3, $t4, collition_detected    # Colour is not black or dark grey
            no_collision_detected:
                sw $zero, flag_collision            # Update flag to indicate that a collision is not detected
                j detectCollisions_loop
        
        collition_detected:
            addi $t0, $zero, 1
            sw $t0, flag_collision          # Update flag to indicate that a collision is detected
            j detectCollisions_end_loop
            
    detectCollisions_end_loop:
    jr $ra                  # Return to caller
    
    
    
rotateTetromino:
    la $s0, tetromino               # Load the address of the tetromino array into $s0
    la $s1, O_spin_1                # Load the base address of O_spin_1 into $s1
    la $s2, array                   # Load the address of the 2d array into $s2
    lw $s3, ADDR_DSPL               # Load the address of the bitmap display into $s3
    lw $t0, current_tetromino       # Load current_tetromino into $t0
    lw $t1, flag_rotation_state     # Load flag_rotation_state into $t1
    
    # Calculate the offset of the address of the appropriate array
    mult $t0, $t0, 64       # Calculate offset of tetromino rotation group
    mult $t1, $t1, 16       # Calculate offset of array within rotation group
    add $t0, $t0, $t1       # Calculate total offset
    add $s1, $s1, $t0       # Add the offset to get the desired array address
    
    
    # Check if there are any collisions caused by this rotation
    li $t2, 0                   # Initialize loop counter
    add $t3, $zero, $s0         # Load address of tetromino into $t3
    add $t4, $zero, $s1         # Load address of offset array into $t4
    add $t5, $zero, $s2         # Load address of 2d array into $t5
    
    rotation_collision_loop:
        # Calculate new address of tetromino cell
        lw $t6, ($t3)           # Load initial address of tetromino cell
        lw $t7, ($t4)           # Load the offset for the current cell
        add $t6, $t6, $t7       # Add the offset to the tetromino cell
        
        # Calculate the address of this cell in the 2d array
        sub $t6, $t6, $s3       # Subtract the address of the cell by the address of the bitmap display to find offset
        add $t6, $t6, $t5       # Add the cell address to the address of the 2d array
        lw $t6, ($t6)           # Load the colour stored at this address
                
        # Check if the colour stored in the 2d array ($t6) is not a background colour
        lw $t7, dark_grey                                       # $t7 = dark_grey
        beq $t6, $zero, no_current_cell_rotation_collision      # Cell is coloured black
        beq $t6, $t7, no_current_cell_rotation_collision        # Cell is coloured dark grey
        j rotation_collision_found                              # Cell is not part of background
        
        no_current_cell_rotation_collision:
        addi $t3, $t3, 4                        # Move to the next element in the teromino array
        addi $t4, $t4, 4                        # Move to the next element in the offset array
        addi $t2, $t2, 1                        # Increment loop counter
        blt $t2, 4, rotation_collision_loop     # Branch back to rotation_collision_loop if loop counter < 4
    
    # Update the values of the tetromino array elements
    li $t2, 0                   # Initialize loop counter
    rotateTetromino_loop:
        lw $t3, ($s1)           # Load offset array element into $t3
        lw $t4, ($s0)           # Load tetromino array element into $t4
        
        # Update value stored in tetromino array with value stored in offset array
        add $t4, $t4, $t3       # Add offset to tetromino element
        sw $t4, ($s0)           # Store updated tetromino element
        
        addi $s0, $s0, 4                    # Move to the next element in the teromino array
        addi $s1, $s1, 4                    # Move to the next element in offset array
        addi $t2, $t2, 1                    # Increment loop counter
        blt $t2, 4, rotateTetromino_loop    # Branch back to rotateTetromino_loop if loop counter < 4

    # Increment rotation state by 1
    lw $t0, flag_rotation_state
    addi $t0, $t0, 1
    
    # Reset rotation state to 0 if it is >=4
    bge $t0, 4, reset_rotation_state
    j end_reset_rotation_state
    reset_rotation_state:
        addi $t0, $zero, 0     # Reset value to 0
    end_reset_rotation_state:
    # Load the service number for MIDI out into $v0
        li $v0, 31
        
        # Load the arguments for MIDI out
        # $a0 = pitch (0-127)
        li $a0, 60   # Example: Middle C (C4)
        
        # $a1 = duration in milliseconds
        li $a1, 750  # Example: Duration of 500 milliseconds
        
        # $a2 = instrument (0-127)
        li $a2, 0    # Example: Default instrument
        
        # $a3 = volume (0-127)
        li $a3, 100  # Example: Volume 100
        
        # Issue the SYSCALL instruction
        syscall
    sw $t0, flag_rotation_state # Store new value in flag_rotation_state
    
    rotation_collision_found:
    jr $ra                      # Return to the calling function
