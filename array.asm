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

# Function to print the board with defualt values
printBoard:
    # Save the return address ($ra) onto the stack
    subi $sp, $sp, 4   # Decrement stack pointer
    sw $ra, 0($sp)     # Store $ra onto the stack

    jal initializeArray
    jal printArray
    
    # Restore the return address ($ra) from the stack
    lw $ra, 0($sp)     # Load $ra from the stack
    addi $sp, $sp, 4   # Increment stack pointer
    jr $ra             # Return to caller


# Function to initialize the array with default values
initializeArray:
    # Load array address into a register
    la $t0, array
    
    # Load number of rows and columns
    lw $t1, rows        # Number of rows
    lw $t2, cols        # Number of columns
    addi $t7, $t1, -1   # Compute $t1 - 1 for the index of the lower boundary
    addi $t8, $t2, -1   # Compute $t2 - 1 for the index of the right boundary
    
    li $t3, 0           # Counter for rows (moving down in the array)
        
    initializeArray_outer_loop:
        bge $t3, $t1, initializeArray_exit_outer_loop   # Exit if all rows have been initialized
        li $t4, 0                       # Counter for columns (moving right in the array)
            
        initializeArray_inner_loop:
            bge $t4, $t2, initializeArray_exit_inner_loop   # Exit if all columns have been initialized
            
            # Store a colour at the array index
            beq $t3, $zero, initializeArray_set_grey        # If first row, set color to grey
            beq $t3, $t7, initializeArray_set_grey          # If last row, set color to grey
            beq $t4, $zero, initializeArray_set_grey        # If first column, set color to grey
            beq $t4, $t8, initializeArray_set_grey          # If last column, set color to grey
            
            # Determine if colour assignment should be black or dark grey
            add $t5, $t3, $t4    # $t5 = current #rows + #columns
            andi $t5, $t5, 1     # Perform bitwise AND operation with 1 ($t5 % 2)
            beq $t5, 0, initializeArray_set_black
            beq $t5, 1, initializeArray_set_dark_grey

            j initializeArray_set_black                     # Otherwise, set color to black
        
            initializeArray_set_grey:
                lw $t6, grey        # $t6 = grey
                j initializeArray_store_value
            initializeArray_set_black:
                lw $t6, black       # $t6 = black
                j initializeArray_store_value
            initializeArray_set_dark_grey:
                lw $t6, dark_grey   # $t6 = dark grey
                j initializeArray_store_value
                
            initializeArray_store_value:
                # Store value in array
                sw $t6, 0($t0)      # Store $t6 at array[index]
                addi $t0, $t0, 4    # Increment array index by 4 bytes
                
                addi $t4, $t4, 1    # Increment column counter
                j initializeArray_inner_loop        # Continue inner loop
        initializeArray_exit_inner_loop:
        
        addi $t3, $t3, 1    # Increment row counter
        j initializeArray_outer_loop        # Continue outer loop
    
    initializeArray_exit_outer_loop:
    jr $ra             # Return to caller



# Function to print all elements of the array to the bitmap display
printArray:
    # Load array address, number of rows, and columns
    la $s0, array           # $s0 = base address for array
    lw $s1, ADDR_DSPL       # $s1 = base address for display
    
    lw $t1, rows   # Load number of rows
    lw $t2, cols   # Load number of columns

    # Initialize row and column counters
    li $t3, 0      # Row counter
    li $t4, 0      # Column counter
    
    print_outer_loop:
        bge $t3, $t1, exit_print_outer_loop  # Exit if all rows have been printed
    
        print_inner_loop:
            bge $t4, $t2, exit_print_inner_loop  # Exit if all columns have been printed
        
            # Calculate index: (row * num_columns + column)
            mul $t5, $t3, $t2  # $t5 = row * num_columns
            add $t5, $t5, $t4  # $t5 = index
        
            # Load value from array and print it
            sll $t6, $t5, 2    # $t6 = index * 4 (byte offset)
            add $t6, $s0, $t6  # $t6 = base address + byte offset
            lw $t7, ($t6)      # Load value from array[$t6]
            
            # Print value to bitmap display
            sw $t7, 0($s1)      # Print colour $t7 to bitmap display
            addi $s1, $s1, 4    # Increment bitmap display index by 4
            
            addi $t4, $t4, 1   # Increment column counter
            j print_inner_loop # Continue inner loop
        exit_print_inner_loop:
        
    li $t4, 0          # Reset column counter
    addi $t3, $t3, 1   # Increment row counter
    j print_outer_loop # Continue outer loop
    
    exit_print_outer_loop:
    jr $ra             # Return to caller
    


# Function to clear completed lines in the array
clearLines:
    la $s0, array               # $s0 = initial address of array
    addi $t0, $zero, 1          # $t0 = outer loop counter (row counter)
    addi $t1, $zero, 1          # $t1 = inner loop counter (column counter)
    lw $t4, dark_grey           # $t4 = dark grey
    
    clearLines_outer_loop:
        beq $t0, 21, end_clearLines_outer_loop
        clearLines_inner_loop:
            mult $t2, $t0, 48   # $t2 = vertical offset from initial address
            mult $t3, $t1, 4    # $t3 = horizontal offset from initial address
            add $t5, $t2, $t3   # $t5 = total offset
            add $t5, $t5, $s0   # Calculate initial address of array + offset
            lw $t5, ($t5)       # Obtain the colour stored at that address
            
            # Check if the colour is not black or dark grey
            bne $t5, $zero, detect_dark_grey
            j no_colour_detected
            detect_dark_grey:
                bne $t5, $t4, colour_detected   # Colour is not black or dark grey
            no_colour_detected:
                j end_clearLines_inner_loop     # End completed line detection for this line
            colour_detected:        
                beq $t1, 11, end_detection
                addi $t1, $t1, 1                # Increment inner loop counter by 1
                j clearLines_inner_loop
            
            end_detection:
            addi $t1, $zero, 1      # Reset value of inner loop counter
            
            # Completed line is detected, shift rows above line downwards
            add $t6, $zero, $t0                 # $t6 = loop counter (current line in shift)
            shift_lines_down:
                addi $t7, $zero, 1              # $t7 = inner loop counter (current block in line)
                beq $t6, 0, end_shift_lines_down
                beq $t6, 1, load_empty_line
                j load_above_line
                
                # Load an empty line to the array
                load_empty_line:
                    beq $t7, 11, end_load_line      # Counter has reached the end of the line
                    
                    # Determine current array address
                    add $t8, $zero, $t6             # $t8 = current row count
                    mult $t8, $t8, 12               # $t8 = current row offset
                    mult $t8, $t8, 4                # $t8 = current row offset (in bytes)
                    add $t9, $zero, $t7             # $t9 = current column count
                    mult $t9, $t9, 4                # $t9 = current row offset (in bytes)
                    add $s1, $t8, $t9               # $s1 = total offset
                    add $s1, $s1, $s0               # $s1 = address of array + offset
                    
                    sw $zero, 0($s1)      # Store $t9 at the current location
                
                    addi $t7, $t7, 1                # Increment loop counter by 1
                    j load_empty_line
                    
                # Shift the above line downwards
                load_above_line:
                    beq $t7, 11, end_load_line      # Counter has reached the end of the line
                    
                    # Determine current array address
                    add $t8, $zero, $t6             # $t8 = current row count
                    mult $t8, $t8, 12               # $t8 = current row offset
                    mult $t8, $t8, 4                # $t8 = current row offset (in bytes)
                    add $t9, $zero, $t7             # $t9 = current column count
                    mult $t9, $t9, 4                # $t9 = current row offset (in bytes)
                    add $s1, $t8, $t9               # $s1 = total offset
                    add $s1, $s1, $s0               # $s1 = address of array + offset
                    
                    # Determine array value located of cell above current
                    addi $s2, $s1, -48
                    lw $t9, ($s2)
                    
                    # Store colour value in the array
                    sw $t9, ($s1)
                    
                    addi $t7, $t7, 1                # Increment loop counter by 1
                    j load_above_line
                end_load_line:
                
                addi $t6, $t6, -1               # Decrement completed block counter by 1
                j shift_lines_down
            end_shift_lines_down:
            
            # Load the service number for MIDI out into $v0
            li $v0, 31
            # Load the arguments for MIDI out
            li $a0, 80      # $a0 = pitch (0-127)
            li $a1, 5       # $a1 = duration in milliseconds
            li $a2, 80      # $a2 = instrument (0-127)
            li $a3, 127     # $a3 = volume (0-127)
            syscall         # Issue the SYSCALL instruction
                
                
        end_clearLines_inner_loop:
        addi $t0, $t0, 1        # Increment outer loop counter by 1
        j clearLines_outer_loop
    end_clearLines_outer_loop:
    jr $ra                      # Return to caller



# Function to redraw the background in the array (called after line clear)
redrawBackground:
    la $s0 array                # $s0 = initial address of array
    addi $t0, $zero, 0          # $t0 = outer loop counter (row counter)
    
    redrawBackground_outer_loop:
        beq $t0, 22, end_redrawBackground_outer_loop
        addi $t1, $zero, 0      # $t1 = inner loop counter (column counter)
        
        redrawBackground_inner_loop:
            beq $t1, 12, end_redrawBackground_inner_loop
            addi $t1, $t1, 1    # Increment inner loop counter by 1
                    
            # Determine if colour assignment should be black or dark grey
            add $t2, $t0, $t1    # $t8 = current #rows + #columns
            andi $t2, $t2, 1     # Perform bitwise AND operation with 1 ($t8 % 2)
            beq $t2, 0, load_empty_line_set_black
            beq $t2, 1, load_empty_line_set_dark_grey
            
            # Store colour value in the array
            load_empty_line_set_black:
                lw $t3, black       # $t9 = black
                j load_empty_line_store_value
            load_empty_line_set_dark_grey:
                lw $t3, dark_grey   # $t9 = dark grey
                j load_empty_line_store_value
            load_empty_line_store_value:
                # Load colour at current cell of array
                add $t4, $zero, $t0             # $t4 = current row count
                mult $t4, $t4, 48               # $t4 = current row offset (in bytes)
                add $t5, $zero, $t1             # $t5 = current column count
                mult $t5, $t5, 4                # $t5 = current row offset (in bytes)
                add $t6, $t4, $t5               # $t6 = total offset
                add $t6, $t6, $s0               # $t6 = address of array + offset
                lw $t7, ($t6)                   # $t7 = colour at array address
                
                # Replace colour at current cell of array if it is a background block
                lw $t8, dark_grey               # $t8 = dark grey
                beq $t7, $zero, replace_background_cell
                beq $t7, $t8, replace_background_cell
                j not_background_cell
                replace_background_cell:
                    sw $t3, 0($t6)                  # Store colour at the current location
                not_background_cell:
                
            j redrawBackground_inner_loop
        
        end_redrawBackground_inner_loop:
        addi $t0, $t0, 1        # Increment outer loop counter by 1
        j redrawBackground_outer_loop
        
    end_redrawBackground_outer_loop:
    jr $ra                      # Return to caller
