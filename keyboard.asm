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

# Function to detect collisions (IN PROGRESS)
detectCollisions:
    la $s0, array           # $s0 = base address for array
    lw $s1, ADDR_DSPL       # $s1 = base address for display
    la $s2, tetromino       # $s2 = tetromino array
    
    lw $t0, 4   # Load number of cells in the tetromino
    lw $t1, 0   # Load number of searched cells
    lw $t2, 3   # Load index of last cell
    
    detectCollisions_loop:
        # Load the value from the calculated memory address
        lw $t3, ($s2)       # $t3 = value at current tetromino index
        addi $s2, $s2, 4    # Increment array index by 4 bytes
        addi $t1, $t1, 1    # Increment searched cells by 1
        
        bge $t1, $t2, detectCollisions_end_loop
    detectCollisions_end_loop:
    jr $ra             # Return to caller
