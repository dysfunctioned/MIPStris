.data
##############################################################################
# Immutable Data
##############################################################################
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
    
    # The default colour values of the array
    black:      .word 0x0
    grey:       .word 0x808080
    dark_grey:  .word 0x242424


##############################################################################
# Mutable Data
##############################################################################
    flag_collision:         .word -1        # flag for collision detection (1 if collision is detected, 0 otherwise)
    flag_movement:          .word -1        # flag for movement direction (0 for down, 1 for left, 2 for right, 3 for rotate)
    current_tetromino:      .word -1        # flag for current tetromino (0 for O, 1 for I, 2 for S, 3 for Z, 4 for L, 5 for J, 6 for T)
    tetromino_colour:       .word -1        # current tetromino colour (O=yellow, I=blue, S=red, Z=green, L=orange, J=pink, T=purple)
    time_down_collision:    .word 0         # amount of time there is a downwards collision (in ms)
    gravity_tick_timer:     .word 0         # the amount of time that has passed since the last gravity tick
    gravity_speed:          .word 100       # the amount of time it takes for gravity to tick (100 by default)
    gravity_increase_timer: .word 0         # the amount of time that has passed since the last gravity speed increase
    gravity_increase_speed: .word 1000      # the amount of time it takes for gravity to increase (gravity_speed decrease)

.text