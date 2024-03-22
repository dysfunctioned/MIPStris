.include "shared_data.asm"
 
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
# $a0 = flag for collision detection (1 if collision is detected, 0 otherwise)
# $a1 = flag for movement direction (0 for down, 1 for left, 2 for right)
# $a2 = flag for current tetromino (0 for O, 1 for I, 2 for S, 3 for Z, 4 for L, 5 for J, 6 for T)
# $a3 = current tetromino colour (O=yellow, I=blue, S=red, Z=green, L=orange, J=pink, T=purple)

##############################################################################
# Code
##############################################################################

# Place a random tetromino on the board
placeTetromino: 
    # Save the return address ($ra) onto the stack
    subi $sp, $sp, 4   # Decrement stack pointer
    sw $ra, 0($sp)     # Store $ra onto the stack
    
    jal clearTetromino
    jal loadZTetromino
    jal getTetrominoColour
    jal printTetromino
    
    # Restore the return address ($ra) from the stack
    lw $ra, 0($sp)     # Load $ra from the stack
    addi $sp, $sp, 4   # Increment stack pointer
    
    jr $ra             # Return to caller

# Gets the colour of the current tetromino
getTetrominoColour:
    # Load flag for current tetromino into $t0 for comparison
    move $t0, $a2

    # Check the value of $t0 (current tetromino flag) and set the color flag ($a3) accordingly
    beq $t0, 0, set_yellow     # If O tetromino, set color to yellow
    beq $t0, 1, set_blue       # If I tetromino, set color to blue
    beq $t0, 2, set_red        # If S tetromino, set color to red
    beq $t0, 3, set_green      # If Z tetromino, set color to green
    beq $t0, 4, set_orange     # If L tetromino, set color to orange
    beq $t0, 5, set_pink       # If J tetromino, set color to pink
    beq $t0, 6, set_purple     # If T tetromino, set color to purple

    # Default colour
    li $a3, 0xff0000        # Set color to red
    jr $ra                  # Return to caller

    # Function labels to set color flags based on tetromino types
    set_yellow:
        li $a3, 0xFFFF00            # Set color to yellow
        jr $ra                      # Return to caller
    set_blue:
        li $a3, 0x0000FF          # Set color to blue
        jr $ra                     # Return to caller
    set_red:
        li $a3, 0xFF0000          # Set color to red
        jr $ra                     # Return to caller
    set_green:
        li $a3, 0x00FF00          # Set color to green
        jr $ra                     # Return to caller
    set_orange:
        li $a3, 0xFFA500          # Set color to orange
        jr $ra                     # Return to caller
    set_pink:
        li $a3, 0xFF1493          # Set color to pink
        jr $ra                     # Return to caller
    set_purple:
        li $a3, 0x800080          # Set color to purple
        jr $ra                     # Return to caller



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
        add $s1, $zero, $t3     # Set display location to array value $t3
        sw $a3, ($s1)           # Print colour to bitmap display
        
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



# Function to load S piece to the tetromino array
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
    
    addi $a2, $zero, 3  # Set current tetromino to Z
    
    jr $ra             # Return to caller