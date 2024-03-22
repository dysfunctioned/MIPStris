##############################################################################
# Immutable Data
##############################################################################
.data
    array: .space 1056              # Allocate space for a 22x12 array (264 elements, each 4 bytes)
    rows:  .word 22                 # Number of rows
    cols:  .word 12                 # Number of columns
    ADDR_DSPL:  .word 0x10008000    # Address of the bitap display
    ADDR_KBRD:  .word 0xffff0000    # The address of the keyboard
    tetromino: .space 16            # Allocate space for a array of length 4 (4 elements, each 4 bytes)

.text
##############################################################################
# Mutable Data
##############################################################################
addi $a0, $zero, 0         # $a0 = flag for collision detection (1 if collision is detected, 0 otherwise)
addi $a1, $zero, 0         # $a1 = flag for movement direction (0 for down, 1 for left, 2 for right)
addi $a2, $zero, 0         # $a2 = flag for current tetromino (0 for O, 1 for I, 2 for S, 3 for Z, 4 for L, 5 for J, 6 for T)
addi $a3, $zero, 0         # $a3 = current tetromino colour (O=yellow, I=blue, S=red, Z=green, L=orange, J=pink, T=purple)
