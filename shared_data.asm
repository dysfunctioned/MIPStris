.data

##############################################################################
# Immutable Data
##############################################################################
    array:      .space 1056             # Allocate space for a 22x12 array (264 elements, each 4 bytes)
    rows:       .word 22                # Number of rows
    cols:       .word 12                # Number of columns
    ADDR_DSPL:  .word 0x10008000        # Address of the bitap display
    ADDR_KBRD:  .word 0xffff0000        # The address of the keyboard
    tetromino:  .space 16               # Allocate space for a array of length 4 (4 elements, each 4 bytes)
    
    # The default colour values of the array
    black:      .word 0x0
    grey:       .word 0x808080
    dark_grey:  .word 0x242424
    
    # Rotation offsets for tetromino rotation
    O_spin_1:   .word 0, 0, 0, 0
    O_spin_2:   .word 0, 0, 0, 0
    O_spin_3:   .word 0, 0, 0, 0
    O_spin_4:   .word 0, 0, 0, 0
    
    I_spin_1:   .word 40, -4, -48, -92
    I_spin_2:   .word -40, 4, 48, 92
    I_spin_3:   .word 40, -4, -48, -92
    I_spin_4:   .word -40, 4, 48, 92
    
    S_spin_1:   .word -4, 48, 4, 56
    S_spin_2:   .word 4, -48, -4, -56
    S_spin_3:   .word -4, 48, 4, 56
    S_spin_4:   .word 4, -48, -4, -56
    
    Z_spin_1:   .word 8, 52, 0, 44
    Z_spin_2:   .word -8, -52, 0, -44
    Z_spin_3:   .word 8, 52, 0, 44
    Z_spin_4:   .word -8, -52, 0, -44
    
    L_spin_1:   .word 52, 0, -52, -8
    L_spin_2:   .word 44, 0, -44, -96
    L_spin_3:   .word -52, 0, 52, 8
    L_spin_4:   .word -44, 0, 44, 96
    
    J_spin_1:   .word 52, 0, -52, -96
    J_spin_2:   .word 44, 0, -44, 8
    J_spin_3:   .word -52, 0, 52, 96
    J_spin_4:   .word -44, 0,44, -8
    
    T_spin_1:   .word -44, 0, 44, -52
    T_spin_2:   .word 52, 0, -52, -44
    T_spin_3:   .word 44, 0, -44, 52
    T_spin_4:   .word -52, 0, 52, 44
    
    # Tetris theme data
    pitches:    .word 64, 59, 60, 62, 60, 59, 57, 57, 60, 64, 62, 60, 59, 59, 60, 62, 64, 60, 57, 57, 62, 65, 69, 67, 65, 64, 60, 64, 62, 60, 59, 59, 60, 62, 64, 60, 57, 57, 0
    durations:  .word 100, 50, 500, 100, 50, 50, 100, 50, 50, 200, 100, 100, 200, 100, 100, 200, 200, 200, 200, 200, 200, 100, 200, 100, 100, 300, 100, 200, 100, 100, 200, 100, 100, 200, 200, 200, 200, 200, 0
    delays:     .word 0, 325, 200, 200, 325, 200, 200, 325, 200, 200, 325, 200, 200, 325, 200, 200, 325, 325, 325, 325, 1150, 325, 200, 325, 200, 200, 550, 200, 325, 200, 200, 325, 200, 200, 325, 325, 325, 325, 1000
    
##############################################################################
# Mutable Data
##############################################################################
    flag_collision:         .word -1        # flag for collision detection (1 if collision is detected, 0 otherwise)
    flag_movement:          .word -1        # flag for movement direction (0 for down, 1 for left, 2 for right, 3 for rotate)
    flag_rotation_state:    .word 0         # flag for the rotation state of the current tetromino (0 to 3)
    current_tetromino:      .word -1        # flag for current tetromino (0 for O, 1 for I, 2 for S, 3 for Z, 4 for L, 5 for J, 6 for T)
    tetromino_colour:       .word -1        # current tetromino colour (O=yellow, I=blue, S=red, Z=green, L=orange, J=pink, T=purple)
    time_down_collision:    .word 0         # amount of time there is a downwards collision (in ms)
    gravity_tick_timer:     .word 0         # the amount of time that has passed since the last gravity tick
    gravity_speed:          .word 100       # the amount of time it takes for gravity to tick (100 by default)
    gravity_increase_timer: .word 0         # the amount of time that has passed since the last gravity speed increase
    gravity_increase_speed: .word 1000      # the amount of time it takes for gravity to increase (gravity_speed decrease)
    music_counter:          .word 0         # the amount of time that has passed since the last note in the tetris theme has played
    music_arrays_index:     .word 0         # current index in the music data arrays (for tetris theme)

.text