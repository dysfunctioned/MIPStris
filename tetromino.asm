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
# Code
##############################################################################

# Place a random tetromino on the board
placeTetromino: 
    # Save the return address ($ra) onto the stack
    subi $sp, $sp, 4   # Decrement stack pointer
    sw $ra, 0($sp)     # Store $ra onto the stack
    
    # syscall to get random number
    li $a0, 0
    li $a1, 7                   # Upper bound of range of returned values
    li $v0, 42                  # syscall number for generating a random integer
    syscall

    # Load random number from memory
    sw $a0, current_tetromino

    # Clear the current tetromino in the array
    jal clearTetromino
    
    beq $a0, 0, load_O_tetromino
    beq $a0, 1, load_I_tetromino
    beq $a0, 2, load_S_tetromino
    beq $a0, 3, load_Z_tetromino
    beq $a0, 4, load_L_tetromino
    beq $a0, 5, load_J_tetromino
    beq $a0, 6, load_T_tetromino
    load_O_tetromino:
        jal loadOTetromino
        j end_loading
    load_I_tetromino:
        jal loadITetromino
        j end_loading
    load_S_tetromino:
        jal loadSTetromino
        j end_loading
    load_Z_tetromino:
        jal loadZTetromino
        j end_loading
    load_L_tetromino:
        jal loadLTetromino
        j end_loading
    load_J_tetromino:
        jal loadJTetromino
        j end_loading
    load_T_tetromino:
        jal loadTTetromino
        j end_loading
    end_loading:
    
    jal getTetrominoColour
    jal printTetromino
    
    # Restore the return address ($ra) from the stack
    lw $ra, 0($sp)     # Load $ra from the stack
    addi $sp, $sp, 4   # Increment stack pointer
    
    jr $ra             # Return to caller

# Gets the colour of the current tetromino
getTetrominoColour:
    lw $t0, current_tetromino   # Load flag for current tetromino into $t0 for comparison

    # Check the value of $t0 (current tetromino flag) and set the color flag accordingly
    beq $t0, 0, set_yellow     # If O tetromino, set color to yellow
    beq $t0, 1, set_blue       # If I tetromino, set color to blue
    beq $t0, 2, set_red        # If S tetromino, set color to red
    beq $t0, 3, set_green      # If Z tetromino, set color to green
    beq $t0, 4, set_orange     # If L tetromino, set color to orange
    beq $t0, 5, set_pink       # If J tetromino, set color to pink
    beq $t0, 6, set_purple     # If T tetromino, set color to purple
    jr $ra                     # Return to caller

    # Function labels to set color flags based on tetromino types
    set_yellow:
        addi $t1, $zero, 0xFFFF00
        sw $t1, tetromino_colour    # Set color to yellow
        jr $ra                      # Return to caller
    set_blue:
        addi $t1, $zero, 0x0000FF
        sw $t1, tetromino_colour    # Set color to blue
        jr $ra                      # Return to caller
    set_red:
        addi $t1, $zero, 0xFF0000
        sw $t1, tetromino_colour    # Set color to red
        jr $ra                      # Return to caller
    set_green:
        addi $t1, $zero, 0x00FF00
        sw $t1, tetromino_colour    # Set color to green
        jr $ra                      # Return to caller
    set_orange:
        addi $t1, $zero, 0xFFA500
        sw $t1, tetromino_colour    # Set color to orange
        jr $ra                      # Return to caller
    set_pink:
        addi $t1, $zero, 0xFF1493
        sw $t1, tetromino_colour    # Set color to pink
        jr $ra                      # Return to caller
    set_purple:
        addi $t1, $zero, 0x800080
        sw $t1, tetromino_colour    # Set color to purple
        jr $ra                      # Return to caller



# Function to print tetromino array to display
printTetromino:
    lw $s1, ADDR_DSPL       # $s1 = base address for display
    la $s2, tetromino       # $s2 = tetromino array
    addi $t0, $zero, 0               # Load number of searched cells
    addi $t1, $zero, 4               # Load total number of cells
    addi $t2, $zero, 0xff0000        # Load colour red
    
    printTetromino_loop:        
        # Set the value from the memory address to zero
        lw $t3, ($s2)       # $t3 = value at current tetromino index
        addi $s2, $s2, 4    # Increment array index by 4 bytes
        addi $t0, $t0, 1    # Increment searched cells by 1
        
        # Print value to bitmap display
        add $s1, $zero, $t3         # Set display location to array value $t3
        lw $t4, tetromino_colour    # Load current tetromino colour to $t4
        sw $t4, ($s1)               # Print colour to bitmap display
        
        bge $t0, $t1, printTetromino_end_loop   # End loop if all cells are searched
        
        j printTetromino_loop
    printTetromino_end_loop:
    jr $ra              # Return to caller



# Function to clear tetromino array
clearTetromino:
    la $s2, tetromino       # $s2 = tetromino array
    addi $t1, $zero, 0   # Load number of searched cells
    addi $t2, $zero, 3   # Load index of last cell
    
    clearTetromino_loop:
        # Set the value from the memory address to zero
        sw $zero, 0($s2)    # Store $zero at current tetromino address
        addi $s2, $s2, 4    # Increment array index by 4 bytes
        addi $t1, $t1, 1    # Increment searched cells by 1
        
        bge $t1, $t2, clearTetromino_end_loop   # End loop if all cells are searched
        
        j clearTetromino_loop
    clearTetromino_end_loop:
    jr $ra              # Return to caller



# Function to move tetromino data to the 2d array
tetrominoToArray:
    la $s0, array       # $s0 = initial address of 2d array
    la $s1, tetromino   # $s1 = initial address of tetromino array
    lw $s2, ADDR_DSPL   # $s2 = initial address of bitmap display
    
    addi $t0, $zero, 0  # $t0 = loop counter
    
    place_tetromino_loop:
        beq $t0, 4, place_tetromino_end_loop
        
        lw $t1, ($s1)               # Load the value stored at the current tetromino address (address in bitmap display)
        sub $t1, $t1, $s2           # Calculate the offset of the address
        add $t2, $s0, $t1           # $t2 = address of the 2d array + offset
        
        lw $t3, tetromino_colour    # Load the curret tetromino colour to $t3
        sw $t3, ($t2)               # Write current colour to array position
        
        addi $s1, $s1, 4            # Increment current tetromino address by 4
        addi $t0, $t0, 1            # Increment the loop counter by 1
        
        j place_tetromino_loop
    place_tetromino_end_loop:
    sw $zero, flag_rotation_state   # Reset the value of the current rotation state
    
    # Load the service number for MIDI out into $v0
    li $v0, 31
    # Load the arguments for MIDI out
    li $a0, 30      # $a0 = pitch (0-127)
    li $a1, 5       # $a1 = duration in milliseconds
    li $a2, 87      # $a2 = instrument (0-127)
    li $a3, 100     # $a3 = volume (0-127)
    syscall         # Issue the SYSCALL instruction
    
    jr $ra                          # Return to caller



# Function to load Z piece to the tetromino array
loadZTetromino:
    lw $s1, ADDR_DSPL       # $s1 = base address for display
    la $s2, tetromino       # $s2 = base address for tetromino
    addi $t3, $zero, 0xff0000        # Load colour red
    
    # Initialize default positions in the display
    addi $t0, $zero, 4      # $t0 = size of each array element
    addi $t1, $zero, 64     # $t1 = starting point of tetromino (16 * 4)
    
    add $s1, $s1, $t1   # Move display address to $t1
    sw $s1, 0($s2)      # Store display address at current tetromino address
    
    addi $s1, $s1, 4    # Increment display address by 4
    addi $s2, $s2, 4    # Increment tetromino array address by 4
    sw $s1, 0($s2)      # Store display address at current tetromino address
    
    addi $s1, $s1, 48   # Increment display address by 48 (12 * 4)
    addi $s2, $s2, 4    # Increment tetromino array address by 4
    sw $s1, 0($s2)      # Store display address at current tetromino address
    
    addi $s1, $s1, 4    # Increment display address by 4
    addi $s2, $s2, 4    # Increment tetromino array address by 4
    sw $s1, 0($s2)      # Store display address at current tetromino address
    
    addi $t1, $zero, 3
    sw $t1, current_tetromino   # Set current tetromino to Z
    
    jr $ra             # Return to caller


# Function to load S piece to the tetromino array
loadSTetromino:
    lw $s1, ADDR_DSPL       # $s1 = base address for display
    la $s2, tetromino       # $s2 = base address for tetromino
    addi $t3, $zero, 0xff0000        # Load colour red
    
    # Initialize default positions in the display
    addi $t0, $zero, 4      # $t0 = size of each array element
    addi $t1, $zero, 72     # $t1 = starting point of tetromino (18 * 4)
    
    add $s1, $s1, $t1   # Move display address to $t1
    sw $s1, 0($s2)      # Store display address at current tetromino address
    
    addi $s1, $s1, -4    # Decrement display address by 4
    addi $s2, $s2, 4    # Increment tetromino array address by 4
    sw $s1, 0($s2)      # Store display address at current tetromino address
    
    addi $s1, $s1, 48   # Increment display address by 48 (12 * 4)
    addi $s2, $s2, 4    # Increment tetromino array address by 4
    sw $s1, 0($s2)      # Store display address at current tetromino address
    
    addi $s1, $s1, -4    # Decrement display address by 4
    addi $s2, $s2, 4    # Increment tetromino array address by 4
    sw $s1, 0($s2)      # Store display address at current tetromino address
    
    addi $t1, $zero, 2
    sw $t1, current_tetromino   # Set current tetromino to S
    
    jr $ra             # Return to caller
    

# Function to load I piece to the tetromino array
loadITetromino:
    lw $s1, ADDR_DSPL       # $s1 = base address for display
    la $s2, tetromino       # $s2 = base address for tetromino
    addi $t3, $zero, 0x0000ff        # Load colour blue
    
    # Initialize default positions in the display
    addi $t0, $zero, 4      # $t0 = size of each array element
    addi $t1, $zero, 68     # $t1 = starting point of tetromino (17 * 4)
    
    add $s1, $s1, $t1   # Move display address to $t1
    sw $s1, 0($s2)      # Store display address at current tetromino address
    
    addi $s1, $s1, 48    # Increment display address by 48(12 * 4)
    addi $s2, $s2, 4    # Increment tetromino array address by 4
    sw $s1, 0($s2)      # Store display address at current tetromino address
    
    addi $s1, $s1, 48   # Increment display address by 48 (12 * 4)
    addi $s2, $s2, 4    # Increment tetromino array address by 4
    sw $s1, 0($s2)      # Store display address at current tetromino address
    
    addi $s1, $s1, 48    # Increment display address by 48(12 * 4)
    addi $s2, $s2, 4    # Increment tetromino array address by 4
    sw $s1, 0($s2)      # Store display address at current tetromino address
    
    addi $t1, $zero, 1
    sw $t1, current_tetromino   # Set current tetromino to I
    
    jr $ra             # Return to caller
    
    
# Function to load L piece to the tetromino array
loadLTetromino:
    lw $s1, ADDR_DSPL       # $s1 = base address for display
    la $s2, tetromino       # $s2 = base address for tetromino
    addi $t3, $zero, 0xffa500        # Load colour orange
    
    # Initialize default positions in the display
    addi $t0, $zero, 4      # $t0 = size of each array element
    addi $t1, $zero, 68     # $t1 = starting point of tetromino (17 * 4)
    
    add $s1, $s1, $t1   # Move display address to $t1
    sw $s1, 0($s2)      # Store display address at current tetromino address
    
    addi $s1, $s1, 48    # Increment display address by 48(12 * 4)
    addi $s2, $s2, 4    # Increment tetromino array address by 4
    sw $s1, 0($s2)      # Store display address at current tetromino address
    
    addi $s1, $s1, 48   # Increment display address by 48 (12 * 4)
    addi $s2, $s2, 4    # Increment tetromino array address by 4
    sw $s1, 0($s2)      # Store display address at current tetromino address
    
    addi $s1, $s1, 4    # Increment display address by 4
    addi $s2, $s2, 4    # Increment tetromino array address by 4
    sw $s1, 0($s2)      # Store display address at current tetromino address
    
    addi $t1, $zero, 4
    sw $t1, current_tetromino   # Set current tetromino to L
    
    jr $ra             # Return to caller
    

# Function to load J piece to the tetromino array
loadJTetromino:
    lw $s1, ADDR_DSPL       # $s1 = base address for display
    la $s2, tetromino       # $s2 = base address for tetromino
    addi $t3, $zero, 0xffc0cb       # Load colour pink
    
    # Initialize default positions in the display
    addi $t0, $zero, 4      # $t0 = size of each array element
    addi $t1, $zero, 72     # $t1 = starting point of tetromino (18 * 4)
    
    add $s1, $s1, $t1   # Move display address to $t1
    sw $s1, 0($s2)      # Store display address at current tetromino address
    
    addi $s1, $s1, 48    # Increment display address by 48(12 * 4)
    addi $s2, $s2, 4    # Increment tetromino array address by 4
    sw $s1, 0($s2)      # Store display address at current tetromino address
    
    addi $s1, $s1, 48   # Increment display address by 48 (12 * 4)
    addi $s2, $s2, 4    # Increment tetromino array address by 4
    sw $s1, 0($s2)      # Store display address at current tetromino address
    
    addi $s1, $s1, -4    # Decrement display address by 48(12 * 4)
    addi $s2, $s2, 4    # Increment tetromino array address by 4
    sw $s1, 0($s2)      # Store display address at current tetromino address
    
    addi $t1, $zero, 5
    sw $t1, current_tetromino   # Set current tetromino to J
    
    jr $ra             # Return to caller
    

# Function to load T piece to the tetromino array
loadTTetromino:
    lw $s1, ADDR_DSPL       # $s1 = base address for display
    la $s2, tetromino       # $s2 = base address for tetromino
    addi $t3, $zero, 0x800080       # Load colour purple
    
    # Initialize default positions in the display
    addi $t0, $zero, 4      # $t0 = size of each array element
    addi $t1, $zero, 64     # $t1 = starting point of tetromino (16 * 4)
    
    add $s1, $s1, $t1   # Move display address to $t1
    sw $s1, 0($s2)      # Store display address at current tetromino address
    
    addi $s1, $s1, 4    # Increment display address by 4
    addi $s2, $s2, 4    # Increment tetromino array address by 4
    sw $s1, 0($s2)      # Store display address at current tetromino address
    
    addi $s1, $s1, 4   # Increment display address by 4
    addi $s2, $s2, 4    # Increment tetromino array address by 4
    sw $s1, 0($s2)      # Store display address at current tetromino address
    
    addi $s1, $s1, 44   # Increment display address by 44(11 * 4)
    addi $s2, $s2, 4    # Increment tetromino array address by 4
    sw $s1, 0($s2)      # Store display address at current tetromino address
    
    addi $t1, $zero, 6
    sw $t1, current_tetromino   # Set current tetromino to T
    
    jr $ra             # Return to caller
    

# Function to load O piece to the tetromino array
loadOTetromino:
    lw $s1, ADDR_DSPL       # $s1 = base address for display
    la $s2, tetromino       # $s2 = base address for tetromino
    addi $t3, $zero, 0xff0000        # Load colour yellow
    
    # Initialize default positions in the display
    addi $t0, $zero, 4      # $t0 = size of each array element
    addi $t1, $zero, 68     # $t1 = starting point of tetromino (16 * 4)
    
    add $s1, $s1, $t1   # Move display address to $t1
    sw $s1, 0($s2)      # Store display address at current tetromino address
    
    addi $s1, $s1, 4    # Increment display address by 4
    addi $s2, $s2, 4    # Increment tetromino array address by 4
    sw $s1, 0($s2)      # Store display address at current tetromino address
    
    addi $s1, $s1, 44   # Increment display address by 44 (11 * 4)
    addi $s2, $s2, 4    # Increment tetromino array address by 4
    sw $s1, 0($s2)      # Store display address at current tetromino address
    
    addi $s1, $s1, 4    # Increment display address by 4
    addi $s2, $s2, 4    # Increment tetromino array address by 4
    sw $s1, 0($s2)      # Store display address at current tetromino address
    
    addi $t1, $zero, 0
    sw $t1, current_tetromino   # Set current tetromino to O
    
    jr $ra             # Return to caller
