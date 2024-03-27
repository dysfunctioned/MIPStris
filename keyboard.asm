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
# current_tetromino:      .word -1        # flag for current tetromino (0 for O, 1 for I, 2 for S, 3 for Z, 4 for L, 5 for J, 6 for T)
# tetromino_colour:       .word -1        # current tetromino colour (O=yellow, I=blue, S=red, Z=green, L=orange, J=pink, T=purple)
# time_down_collision:    .word 0         # amount of time there is a downwards collision (in ms)

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



# Function to make Z piece tetromino rotate 90 degrees clockwise
rotate_Z:
    la $s0, tetromino       # $s0 = tetromino array starting address
    lw $s1, cols            # $s1 = number of rows
    la $s2, ADDR_DSPL       # Starting address of bitmap display
    
    lw $t1, ($s0)       # $t1 = address of current tetromino cell
        
    #addi $s0, $s0, 4                        # Increment array address by 4 bytes
    
    # Calculate address ($t2) of tetromino cell in game array 
    add $t2, $zero, $t1                 # Set $t2 equal to address of tetromino cell in display
    sub $t2, $t2, $s0                   # Subtract by the starting address of the display to find offset
    add $t2, $t2, $s2                   # Add the starting address of the game array
        
    # Find address of the cell right of the tetromino in game array
    addi $t4, $t2, 4   # Add offset to current cell address
            
    # Find colour stored at address in game array
    lw $t3, ($t4)
    
    addi $t0, $zero, 0      # $t0 = loop counter
    
    bne $t3, 0x0, rotate_Z_from_horizontal_loop     # Detect if the colour does not equal black 
    # j rotate_Z_from_vertical_loop                 # rotate from vertical orientation of right cell of first tetromino cell is black(empty)
    
    rotate_Z_from_horizontal_loop:
        beq $t0, 4, moveTetromino_end_loops      # End loop if array location reaches the end
        
        # Print black to the previous tetromino cell
        lw $t1, ($s0)           # Obtain the address of the current tetromino cell
        add $s2, $t1, $zero     # Obtain address of position of cell in bitmap display
        sw $zero, ($s2)         # Print black to bitmap display
        
        beq $t0, $zero, shift_first   # If $t0 = 0, shift the first tetromino element
        beq $t0, 1, shift_second      # If $t0 = 1, shift the second tetromino element
        beq $t0, 2, shift_third    # If $t0 = 2, shift the third tetromino element
        beq $t0, 3, shift_last     # If $t0 = 3, shift the fourth tetromino element
        j end_shift
        
        shift_first:
            addi $t1 $t1, 8        # Add offset to the address
            sw $t1, ($s0)           # Load address back into the array
            j end_shift
        shift_second:
            mult $t2, $s1, 4        # Number of columns * 4 = the offset of the address to shift dowm
            add $t1, $t1, $t2       # Add offset to the address
            addi $t1, $t1, 4        # Add addtional 4 to the address(move one cell right)
            sw $t1, ($s0)           # Load address back into the array
            j end_shift
        shift_third:
            add $t1, $t1, $zero    # No offset needed in this case
            sw $t1, ($s0)           # Load address back into the array
            j end_shift
        shift_last:
            mult $t2, $s1, 4        # Number of columns * 4 = the offset of the address to shift dowm
            add $t1, $t1, $t2       # Add offset to the address
            addi $t1, $t1, -4       #Subtract 4 from the address(move one cell left)
            sw $t1, ($s0)           # Load address back into the array
            j end_shift
            
        end_shift:
        addi $s0, $s0, 4            # Move to next address in memory
        addi $t0, $t0, 1            # Increment loop counter by 1
        j rotate_Z_from_horizontal_loop
    
    moveTetromino_end_loops:
    addi $t0, $zero, -1
    lw $t0, flag_movement   # Reset the movement direction
    jr $ra
    
    # rotate_Z_from_vertical_loop:
        # beq $t0, 4, moveTetromino_end_loo    # End loop if array location reaches the end
        
        # # Print black to the previous tetromino cell
        # lw $t1, ($s0)           # Obtain the address of the current tetromino cell
        # add $s2, $t1, $zero     # Obtain address of position of cell in bitmap display
        # sw $zero, ($s2)         # Print black to bitmap display
        
        # beq $t0, $zero, shift_first   # If $t0 = 0, shift the first tetromino element
        # beq $t0, 1, shift_second      # If $t0 = 1, shift the second tetromino element
        # beq $t0, 2, shift_third    # If $t0 = 2, shift the third tetromino element
        # beq $t0, 3, shift_last     # If $t0 = 3, shift the fourth tetromino element
        # j end_shift1
        
        # shift_first:
            # addi $t1, $t1, -8       # Add offset to the address
            # sw $t1, ($s0)           # Load address back into the array
            # j end_shift1
        # shift_second:
            # mult $t2, $s1, -4        # Number of columns * -4 = the offset of the address to shift up
            # add $t1, $t1, $t2       # Add offset to the address
            # addi $t1, $t1, -4        # Add addtional -4 to the address(move one cell left)
            # sw $t1, ($s0)           # Load address back into the array
            # j end_shift1
        # shift_third:
           # add $t1, $t1, $zero    # No offset needed in this case
            # sw $t1, ($s0)           # Load address back into the array
            # j end_shift1
        # shift_last:
            # mult $t2, $s1, -4        # Number of columns * -4 = the offset of the address to shift dowm
            # add $t1, $t1, $t2       # Add offset to the address
            # addi $t1, $t1, 4       #Add 4 to the address(move one cell right)
            # sw $t1, ($s0)           # Load address back into the array
            # j end_shift1
            
        # end_shift1:
        # addi $s0, $s0, 4            # Move to next address in memory
        # addi $t0, $t0, 1            # Increment loop counter by 1
        # j rotate_Z_from_vertical_loop
    
    # moveTetromino_end_loo:
    addi $t0, $zero, -1
    lw $t0, flag_movement   # Reset the movement direction
    jr $ra



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
    