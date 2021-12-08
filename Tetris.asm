    org 100h
  
    jmp initialization

    msg_author db "A project by Fehmid, Tayyab , Ahmad$"
    msg_next db "Next$"
    msg_left db "A - Left$"
    msg_right db "S - Right$"
    msg_rotate db "SPC - Rotate$"
    msg_quit db "Q - Quit$"
    msg_lines db "Lines$"
    msg_game_over db "Game Over$"
    msg_asmtris db "Tetris$"

    delay_centiseconds db 5 
    screen_width dw 320
    
    block_size dw 5 
    blocks_per_piece dw 4 
    
    colour_cemented_piece dw 40, 48, 54, 14, 42, 36, 34 
                                                        
    colour_falling_piece dw 39, 47, 55, 44, 6, 37, 33 
    
    pieces_origin:
    piece_t dw 1605, 1610, 1615, 3210
             dw 10, 1610, 1615, 3210  
             dw 10, 1605, 1610, 1615   
             dw 10, 1605, 1610, 3210   
    piece_j dw 1605, 1610, 1615, 3215 
             dw 10, 15, 1610, 3210    
             dw 5, 1605, 1610, 1615   
             dw 10, 1610, 3205, 3210  
    piece_l dw 1605, 1610, 1615, 3205 
             dw 10, 1610, 3210, 3215  
             dw 15, 1605, 1610, 1615  
             dw 5, 10, 1610, 3210     
    piece_z dw 1605, 1610, 3210, 3215 
             dw 15, 1610, 1615, 3210   
             dw 1605, 1610, 3210, 3215 
             dw 15, 1610, 1615, 3210   
    piece_s dw 1610, 1615, 3205, 3210 
             dw 10, 1610, 1615, 3215   
             dw 1610, 1615, 3205, 3210 
             dw 10, 1610, 1615, 3215   
    piece_square dw 1605, 1610, 3205, 3210 
             dw 1605, 1610, 3205, 3210 
             dw 1605, 1610, 3205, 3210  
             dw 1605, 1610, 3205, 3210 
    piece_line dw 1600, 1605, 1610, 1615 
             dw 10, 1610, 3210, 4810   
             dw 1600, 1605, 1610, 1615 
             dw 10, 1610, 3210, 4810   


    msg_score_buffer db "000$" 
    score dw 0 

    current_frame dw 0 
    
    delay_stopping_point_centiseconds db 0 
                                           
    delay_initial db 0  
                     
    random_number db 0  
                       
    must_quit db 0 
    
    cement_counter db 0 
    
    player_input_pressed db 0 
    
    current_piece_colour_index dw 0 
    
    next_piece_colour_index dw 0 
    next_piece_orientation_index dw 0
    
    piece_definition dw 0 
                          
    piece_orientation_index dw 0
                                 
    piece_blocks dw 0, 0, 0, 0  
    
    piece_position dw 0     
                        
    piece_position_delta dw 0 
    
initialization:
    
    mov ax, 13h 
    int 10h
    
    mov ax, 0305h
    xor bx, bx
    int 16h

    call procedure_random_next_piece

    call procedure_draw_screen

; Main program

    new_piece:

    call procedure_display_score
    
    mov word [piece_position], 14550
    
    mov ax, [next_piece_colour_index]
    mov word [current_piece_colour_index], ax

    shl ax, 5 ; ax := ax * 32 ( 16 words for each piece )
    add ax, pieces_origin 
    mov [piece_definition], ax  
                                   
    mov ax, [next_piece_orientation_index]
    mov word [piece_orientation_index], ax  
                                           
    call procedure_copy_piece
    
    call procedure_can_piece_be_placed
    test al, al 
    jnz game_over 
    
    call procedure_random_next_piece
    

display_next_piece:

    mov di, 17805
    mov bx, 20
    mov dl, 0
    call procedure_draw_square 

    push word [current_piece_colour_index]
    push word [piece_definition]
    push word [piece_orientation_index]
    push word [piece_position]
    
    mov ax, [next_piece_colour_index]
    mov word [current_piece_colour_index], ax 
    
    shl ax, 5 ; ax := ax * 32 ( 16 words for each piece )
    add ax, pieces_origin 
    mov [piece_definition], ax 
  
    mov ax, [next_piece_orientation_index]
    mov word [piece_orientation_index], ax  
                                           
    call procedure_copy_piece
    
    mov word [piece_position], 17805  
    mov word bx, [current_piece_colour_index]
    shl bx, 1
    mov byte dl, [colour_falling_piece + bx]
    call procedure_draw_piece
    
    pop word [piece_position]
    pop word [piece_orientation_index]
    pop word [piece_definition]
    pop word [current_piece_colour_index]
    call procedure_copy_piece
    
main_loop:

    mov word ax, [current_frame]
    inc ax
    mov word [current_frame], ax

    call procedure_delay
    
    mov word [piece_position_delta], 0
    mov byte [player_input_pressed], 0
    
    call procedure_display_logo
    
read_input:

    call procedure_read_character
    cmp byte [must_quit], 0
    jne done

handle_horizontal_movement:
    
    mov ax, [piece_position_delta]
    test ax, ax
    jz handle_vertical_movement 

    call procedure_apply_delta_and_draw_piece
    
handle_vertical_movement:
    
    mov cx, [blocks_per_piece] 
handle_vertical_movement_loop:

    mov di, [piece_position] 
    mov bx, cx 
    shl bx, 1 
    sub bx, 2 
    add di, word [piece_blocks + bx]  
    
    call procedure_can_move_down
    test al, al ; a non-zero indicates an obstacle below
    jnz handle_vertical_movement_loop_failure
    
    loop handle_vertical_movement_loop
    
    jmp handle_vertical_movement_move_down_success
    
handle_vertical_movement_loop_failure:

    mov byte al, [player_input_pressed]
    test al, al
    
     jz handle_vertical_movement_cement_immediately

    mov byte al, [cement_counter]
    dec al
    mov byte [cement_counter], al
    test al, al 
    jnz main_loop 
    


handle_vertical_movement_cement_immediately:

    mov byte [cement_counter], 0
    
    mov word bx, [current_piece_colour_index]
    shl bx, 1 
    mov byte dl, [colour_cemented_piece + bx]
    call procedure_draw_piece

    xor dx, dx 
    mov cx, 20  
               
    
handle_vertical_movement_cement_immediately_attempt_clear_lines_loop:
    push dx
    call procedure_attempt_line_removal    
    pop dx
    
    add dl, al
    loop handle_vertical_movement_cement_immediately_attempt_clear_lines_loop
    
update_score:
    mov ax, dx
    mov dl, [block_size]
    div dl ; al now contains number of block lines
    xor ah, ah
    
    mov word dx, [score]
    add ax, dx
    
    cmp ax, 1000 
    jl score_is_not_over_1000
    sub ax, 1000
score_is_not_over_1000:
    mov word [score], ax
    
    
    jmp new_piece

handle_vertical_movement_move_down_success:

    mov byte [cement_counter], 10

    mov ax, [screen_width]
    mov word [piece_position_delta], ax

    call procedure_apply_delta_and_draw_piece

    jmp main_loop

game_over:

    call procedure_display_game_over
    
game_over_loop:

    call procedure_display_logo
    
    call procedure_delay
    
    mov word ax, [current_frame]
    inc ax
    mov word [current_frame], ax
    
    mov ah, 1
    int 16h ; any key pressed ?
    jz game_over_loop ; no key pressed
    
    xor ah, ah
    int 16h
    cmp al, 'q'
    jne game_over_loop ; wait for Q to be pressed to exit the program

done:

    mov ax, 3
    int 10h ; restore text mode

    ret
procedure_display_score:

    mov word ax, [score]
    mov dl, 100
    div dl ; hundreds in al, remainder in ah 
    mov cl, '0'
    add cl, al
    mov byte [msg_score_buffer], cl ; set hundreds digit
    
    mov al, ah ; divide remainder again
    xor ah, ah
    mov dl, 10
    div dl ; tens in al, remainder in ah
    mov cl, '0'
    add cl, al
    mov byte [msg_score_buffer + 1], cl ; set tens digit
    
    mov cl, '0'
    add cl, ah
    mov byte [msg_score_buffer + 2], cl ; set units digit
    
    mov bx, msg_score_buffer
    mov dh, 15
    mov dl, 26
    call procedure_print_at
    
    ret

    
procedure_print_at:

    push bx
    mov ah, 2
    xor bh, bh
    int 10h
    
    mov ah, 9
    pop dx
    int 21h
    
    ret
    
    
procedure_random_next_piece:
    
    call procedure_delay ; advance random number (or seed for the initial call)
    
    mov bl, 7
    call procedure_generate_random_number 
    mov word [next_piece_colour_index], ax 
    
    mov bl, 4
    call procedure_generate_random_number 
    
    mov word [next_piece_orientation_index], ax 
    
    ret


procedure_attempt_line_removal:

    push cx
    
    mov di, 47815
    mov cx, 104 
    
    attempt_line_removal_loop:

    
    call procedure_is_horizontal_line_full
    test al, al
    jz attempt_line_removal_full_line_found
    
    
    sub di, [screen_width] 
    loop attempt_line_removal_loop
    
    
    jmp attempt_line_removal_no_line_found
    
attempt_line_removal_full_line_found:
    
attempt_line_removal_shift_lines_down_loop:
    
    
    push cx 
    push di
        
    
    mov si, di
    sub si, [screen_width] ; line above (source)
   
    mov cx, 50
    
    push ds
    push es
    mov ax, 0A000h 
    mov ds, ax 
    mov es, ax 
    rep movsb
    pop es
    pop ds
    
    
    pop di
    pop cx
    
    
    sub di, [screen_width] ; move one line up
    
    loop attempt_line_removal_shift_lines_down_loop
    
    
    xor dl, dl
    mov cx, 50
    call procedure_draw_line ; empty the top most line
    
    
    mov al, 1
    jmp attempt_line_removal_done

attempt_line_removal_no_line_found:    
    
    xor al, al
    
attempt_line_removal_done:
    pop cx
    ret

procedure_is_horizontal_line_full:
    push cx
    push di
   
    mov cx, 50 
is_horizontal_line_full_loop:

  
    call procedure_read_pixel
    test dl, dl 
    jz is_horizontal_line_full_failure
    
    inc di 
    loop is_horizontal_line_full_loop
 
    xor ax, ax
    jmp is_horizontal_line_full_loop_done
    
is_horizontal_line_full_failure:

    mov al, 1
    
is_horizontal_line_full_loop_done:
    pop di
    pop cx
    
    ret

procedure_generate_random_number:

    mov al, byte [random_number]
    add al, 31
    mov byte [random_number], al

    div bl
    mov al, ah 
    xor ah, ah
    
    ret

procedure_copy_piece:
    
    push ds
    push es
    
    mov ax, cs 
    mov ds, ax
    mov es, ax 
    
   
    mov di, piece_blocks ; 
    
    mov ax, [piece_orientation_index] 
                                      
    
    mov si, [piece_definition] 
                               
    shl ax, 3 
    add si, ax 
    
    mov cx, 4
    
    rep movsw 
    
    pop es
    pop ds
    
    ret
    procedure_apply_delta_and_draw_piece:

    mov dl, 0
    call procedure_draw_piece

    mov ax, [piece_position]
    add ax, [piece_position_delta]
    mov [piece_position], ax
    
    mov word bx, [current_piece_colour_index]
    shl bx, 1
    mov byte dl, [colour_falling_piece + bx]
    call procedure_draw_piece

    ret
    
procedure_draw_piece:    

    mov cx, [blocks_per_piece]
draw_piece_loop:

    mov di, [piece_position]
    
    mov bx, cx
    shl bx, 1 
    sub bx, 2 
    add di, word [piece_blocks + bx]  
                                    
                                     
 
    mov bx, [block_size]
    call procedure_draw_square
    
 
    loop draw_piece_loop
    
    ret

procedure_can_piece_be_placed:
        
    mov cx, [blocks_per_piece] 
can_piece_be_placed_loop:

 
    mov di, [piece_position]
    
    mov bx, cx 
    shl bx, 1 
    sub bx, 2 
    add di, word [piece_blocks + bx]
    
    push cx 
    

    mov bx, 1 
    

    mov cx, [block_size]
can_piece_be_placed_line_by_line_loop:

    call procedure_is_line_available
    test al, al 
    jne can_piece_be_placed_failure
    
    add di, [screen_width]
    loop can_piece_be_placed_line_by_line_loop
    
    pop cx
    
    loop can_piece_be_placed_loop
    
    xor ax, ax
    jmp can_piece_be_placed_success

can_piece_be_placed_failure:
    
    mov al, 1
    
    pop cx

can_piece_be_placed_success:

    ret

procedure_advance_orientation:

    mov word ax, [piece_orientation_index]
    inc ax
    and ax, 3 
    mov word [piece_orientation_index], ax
    

    call procedure_copy_piece
    
    ret
    
    
procedure_read_character: 

 
    mov ah, 1
    int 16h 
    jnz read_character_key_was_pressed 
    
    ret

read_character_key_was_pressed:


    mov ah, 0
    int 16h
   
    push ax    
    mov ah, 6 
    mov dl, 0FFh 
    int 21h 
    pop ax

handle_input:
    cmp al, 's'
    je move_right
    
    cmp al, 'a'
    je move_left
    
    cmp al, ' '
    je rotate
    
    cmp al, 'q'
    je quit    
    
    ret

quit:
    
    mov byte [must_quit], 1    
    
    ret

rotate:
   
    push word [piece_orientation_index]
    
    
    call procedure_advance_orientation
    
    
    call procedure_can_piece_be_placed
    test al, al 
    jz rotate_perform 
    
    pop word [piece_orientation_index] 
    call procedure_copy_piece
    
    ret
    
rotate_perform:
    
    pop word [piece_orientation_index] 
    call procedure_copy_piece
    
    xor dl, dl ; black colour
    call procedure_draw_piece
    
    call procedure_advance_orientation
    
    mov al, byte [random_number]
    add al, 11
    mov byte [random_number], al
    
    ret
    
move_right:
   
    mov byte [player_input_pressed], 1
    
    
    mov cx, [blocks_per_piece]
move_right_loop:
    
    mov di, [piece_position]
    
  
    mov bx, cx
    shl bx, 1 
    sub bx, 2 
    add di, word [piece_blocks + bx] 
    
    add di, [block_size]

    mov bx, [screen_width]
    call procedure_is_line_available
    
    
    test al, al 
    jnz move_right_done 
    
    loop move_right_loop
    
    mov ax, [piece_position_delta]
    add ax, [block_size]
    mov [piece_position_delta], ax

move_right_done:
    mov al, byte [random_number]
    add al, 3
    mov byte [random_number], al
    
    ret
    
move_left:
  
    mov byte [player_input_pressed], 1
    
    mov cx, [blocks_per_piece]
move_left_loop:    
    
    mov di, [piece_position]
    
    mov bx, cx
    shl bx, 1 
    sub bx, 2 
    add di, word [piece_blocks + bx] 
    
    dec di
    
   
    mov bx, [screen_width]
    call procedure_is_line_available
    
    
    test al, al 
    jnz move_left_done     
    
   
    loop move_left_loop
    
    
    mov ax, [piece_position_delta]
    sub ax, [block_size]
    mov [piece_position_delta], ax
    
move_left_done:
   
    mov al, byte [random_number]
    add al, 5
    mov byte [random_number], al
    
    ret

 
procedure_can_move_down:

    push cx
    push di
    
    mov cx, [block_size]
can_move_down_find_delta:
    add di, [screen_width]
    loop can_move_down_find_delta
    
    mov bx, 1
    call procedure_is_line_available
    
    test al, al ; did we get a 0, meaning success ?
    jnz can_move_down_obstacle_found ; no
    
    xor ax, ax
    jmp can_move_down_done
    
can_move_down_obstacle_found:
    mov ax, 1
    
can_move_down_done:
    
    pop di
    pop cx
    
    ret


procedure_is_line_available:

    push bx
    push cx
    push di
    
    mov cx, [block_size]
is_line_available_loop:

    call procedure_read_pixel
    test dl, dl ; is colour at current location black?
    jnz is_line_available_obstacle_found
    
is_line_available_loop_next_pixel:    
    add di, bx ; move to next pixel of this line
    loop is_line_available_loop
    
    xor ax, ax
    jmp is_line_available_loop_done

    
is_line_available_obstacle_found:
    push bx
    mov word bx, [current_piece_colour_index]
    shl bx, 1 ; two bytes per colour
    mov byte al, [colour_falling_piece + bx]
    cmp dl, al ; if obstacle is a falling block, treat it as a non-obstacle
    pop bx
    jne is_line_available_failure
    
    jmp is_line_available_loop_next_pixel
    
is_line_available_failure:
    mov al, 1
    
is_line_available_loop_done:
    pop di
    pop cx
    pop bx
    
    ret


procedure_delay:
    push bx
    push cx
    push dx 
    push ax

    xor bl, bl
    mov ah, 2Ch
    int 21h
    
    mov byte al, [random_number]
    add al, dl
    mov byte [random_number], al
    
    mov [delay_initial], dh
    
    add dl, [delay_centiseconds]
    cmp dl, 100
    jb delay_second_adjustment_done
    
    sub dl, 100
    mov bl, 1

delay_second_adjustment_done:
    mov [delay_stopping_point_centiseconds], dl

read_time_again:
    int 21h
    
    test bl, bl ; will we stop within the same second?
    je must_be_within_same_second
    
    cmp dh, [delay_initial]
    je read_time_again
    
    push dx
    sub dh, [delay_initial]
    cmp dh, 2
    pop dx
    jae done_delay
    
    jmp check_stopping_point_reached
    
must_be_within_same_second: 
    cmp dh, [delay_initial]
    jne done_delay
    
check_stopping_point_reached:
    cmp dl, [delay_stopping_point_centiseconds]
    jb read_time_again

done_delay:
    pop ax
    pop dx
    pop cx
    pop bx
    
    ret

procedure_draw_square:

    mov ax, bx
    call procedure_draw_rectangle
    
    ret
    
procedure_draw_rectangle:

    push di
    push dx
    push cx
    
    mov cx, ax
draw_rectangle_loop:    
    push cx
    push di
    mov cx, bx
    call procedure_draw_line
    
    pop di
    
    add di, [screen_width]
    
    pop cx
    
    loop draw_rectangle_loop

    pop cx
    pop dx
    pop di
    
    ret


procedure_draw_line_vertical:

    call procedure_draw_pixel
    
    add di, [screen_width]
    
    loop procedure_draw_line_vertical
    
    ret

    
procedure_draw_line:

    call procedure_draw_pixel
    
    inc di
    
    loop procedure_draw_line
    
    ret

procedure_draw_pixel:

    push ax
    push es

    mov ax, 0A000h
    mov es, ax
    mov byte [es:di], dl
    
    pop es
    pop ax
    
    ret


procedure_read_pixel:

    push ax
    push es

    mov ax, 0A000h
    mov es, ax
    mov byte dl, [es:di]
    
    pop es
    pop ax
    
    ret


procedure_draw_border:

    mov dl, 200 ; colour
    
    mov bx, 4
    mov ax, 200
    
    xor di, di
    call procedure_draw_rectangle
    
    mov di, 316
    call procedure_draw_rectangle
    
    mov bx, 317
    mov ax, 4
    
    xor di, di
    call procedure_draw_rectangle
    
    mov di, 62720
    call procedure_draw_rectangle
    
    ret


procedure_draw_screen:

    call procedure_draw_border
    
draw_screen_play_area:
    mov dl, 27 ; colour
    
    mov cx, 52
    mov di, 14214
    call procedure_draw_line
    
    mov cx, 52
    mov di, 48134
    call procedure_draw_line

    mov cx, 105
    mov di, 14534
    call procedure_draw_line_vertical
    
    mov cx, 105
    mov di, 14585
    call procedure_draw_line_vertical

draw_screen_next_piece_area:
    
    mov di, 16199
    mov cx, 31
    call procedure_draw_line
    
    mov di, 25799
    mov cx, 31
    call procedure_draw_line
    
    mov di, 16199
    mov cx, 31
    call procedure_draw_line_vertical
    
    mov di, 16230
    mov cx, 31
    call procedure_draw_line_vertical

draw_screen_strings:
    mov dh, 21
    mov dl, 4
    mov bx, msg_author
    call procedure_print_at
    
    mov dh, 11
    mov dl, 25
    mov bx, msg_next
    call procedure_print_at
    
    mov dh, 8
    mov dl, 4
    mov bx, msg_left
    call procedure_print_at
    
    mov dh, 10
    mov dl, 4
    mov bx, msg_right
    call procedure_print_at
    
    mov dh, 12
    mov dl, 4
    mov bx, msg_rotate
    call procedure_print_at
    
    mov dh, 14
    mov dl, 4
    mov bx, msg_quit
    call procedure_print_at
    
    mov bx, msg_lines
    mov dh, 16
    mov dl, 24
    call procedure_print_at
    
    mov bx, msg_asmtris
    mov dh, 3
    mov dl, 16
    call procedure_print_at
    
    ret


procedure_display_logo:

    mov word ax, [current_frame]
    and ax, 3 ; ax := ax mod 4
    jz display_logo_begin
    
    ret
    
display_logo_begin:
    mov di, 4905
    
    mov cx, 20
display_logo_horizontal_loop:
    mov word ax, [current_frame]    
    and ax, 8
    shr ax, 3
    
    add ax, di
    and al, 1
    
    shl al, 3
    
    add al, 192
    mov dl, al
    mov bx, 5
    call procedure_draw_square
    
    push di
    add di, 6400
    
    call procedure_draw_square
    
    pop di
    add di, bx
    loop display_logo_horizontal_loop
    
    mov di, 4905
    
    mov cx, 5
display_logo_vertical_loop:
    mov word ax, [current_frame]    
    and ax, 8
    shr ax, 3
    push ax
    
    mov ax, di
    mov bl, 160
    div bl
    xor ah, ah
    shr ax, 1
    
    and al, 1
    
    pop bx
    add al, bl
    and al, 1
    
    shl al, 3
    
    add al, 192
    mov dl, al
    mov bx, 5
    call procedure_draw_square
    
    push di
    add di, 100    
    
    call procedure_draw_square
    
    pop di
    add di, 1600
    loop display_logo_vertical_loop
    
    ret
    
    
procedure_display_game_over:

    xor dl, dl
    mov ax, 45
    mov bx, 100
    mov di, 19550
    call procedure_draw_rectangle

    mov dl, 40
    mov ax, 16
    mov bx, 88
    mov di, 29560
    call procedure_draw_rectangle

    mov dh, 12
    mov dl, 16
    mov bx, msg_game_over
    call procedure_print_at

    ret
    
