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
    
    # Set the messages printed to the console when keys are pressed
    down_msg:   .asciiz "Down key pressed\n"
    left_msg:   .asciiz "Left key pressed\n"
    right_msg:  .asciiz "Right key pressed\n"
    
    .align 2
    
    # Set the default colour values of the array
    black:      .word 0x0
    grey:       .word 0x808080
    dark_grey:  .word 0x242424
.text