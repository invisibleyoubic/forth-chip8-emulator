VARIABLE random_seed 1 
         random_seed !

VARIABLE PREV_OC 0
         PREV_OC !

$0    CONSTANT SPRITE_START
$200  CONSTANT ROM_START
32    CONSTANT DISPLAY_HEIGHT
64    CONSTANT DISPLAY_WIDTH
16384 CONSTANT OUT_BUFFER_SIZE
16    CONSTANT KEY_COUNT

\ KEYBOARD
\ Original layout   My layout
\   1 2 3 C         Q W E R
\   4 5 6 D         A S D F
\   7 8 9 E         Y U I O
\   A 0 B F         H J K L
\ I guess I will change it (~)(~)

CREATE KEY_STATE KEY_COUNT ALLOT


\ REGISTERS 

VARIABLE PC

VARIABLE I0

VARIABLE V0
VARIABLE V1
VARIABLE V2
VARIABLE V3
VARIABLE V4
VARIABLE V5
VARIABLE V6
VARIABLE V7
VARIABLE V8
VARIABLE V9
VARIABLE VA
VARIABLE VB
VARIABLE VC
VARIABLE VD
VARIABLE VE
VARIABLE VF

\ TIMERS 

VARIABLE DelayTimer
VARIABLE SoundTimer

\ FULL RAM MEMORY OF CHIP
\ 0x000 - 0x1FF interpreter memory
\ 0x200 - 0xFFF loaded ROM data
CREATE RAM_MEMORY 4096 ALLOT

\ FULL BUFFER OF DISPLAY
\ 64 x 32 = 2048 points
CREATE DISPLAY_BUFFER 2048 ALLOT
VARIABLE DRW_X
VARIABLE DRW_Y

\ OUTPUT BUFFER TO GET RID OF BLINKING
CREATE OUT_BUFFER OUT_BUFFER_SIZE ALLOT
VARIABLE OUT_BUFFER_PTR OUT_BUFFER
         OUT_BUFFER_PTR !

: RAM@
    RAM_MEMORY + C@
;

: RAM!
    RAM_MEMORY + C!
;

: COMMAND@
    $F000 AND 12 RSHIFT
;

: PARAMS@ ( abcd -- bcd )
    $0FFF AND
;

: PC@ ( -- value )
    PC @
;

: PC! ( value -- )
    PC !
;

: NEXT_INS@ ( -- PC + 2 )
    PC@ 2 +
;

: NEXT_INS! ( -- set PC = PC + 2 )
    NEXT_INS@ PC!
;

: PREV_INS@ ( -- PC - 2 )
    PC@ 2 -
;

: PREV_INS! ( -- set PC = PC - 2 )
    PREV_INS@ PC! 
;

: IREG ( -- addr )
    I0
;

: IREG@ ( -- value )
    I0 @
;

: IREG! ( value -- )
    I0 !
;

: VREG ( n -- addr )
    CASE
        $0 OF V0 ENDOF
        $1 OF V1 ENDOF
        $2 OF V2 ENDOF
        $3 OF V3 ENDOF
        $4 OF V4 ENDOF
        $5 OF V5 ENDOF
        $6 OF V6 ENDOF
        $7 OF V7 ENDOF
        $8 OF V8 ENDOF
        $9 OF V9 ENDOF
        $A OF VA ENDOF
        $B OF VB ENDOF
        $C OF VC ENDOF
        $D OF VD ENDOF
        $E OF VE ENDOF
        $F OF VF ENDOF
    ENDCASE
;

: VREG@ ( n -- value )
    VREG C@
;

: VREG! ( value n -- )
    VREG C!
;

: DelayTimer@ ( -- value )
    DelayTimer @
;

: DelayTimer! ( value -- )
    DelayTimer !
;

: SoundTimer@ ( -- value )
    SoundTimer @
;

: SoundTimer! ( value -- )
    SoundTimer !
;

\ DISPLAY
\ TODO: overlapping
: PIXEL ( y x -- addr )
    DISPLAY_WIDTH MOD SWAP
    DISPLAY_HEIGHT MOD
    DISPLAY_WIDTH * + DISPLAY_BUFFER +
;

: PIXEL@ ( y x -- value )
    PIXEL C@
;

: PIXEL! ( value y x -- )
    PIXEL           \ get pixel address
    SWAP DUP        \ address , value , value

    0 <> IF         \ if value != 0 => value = 0xFF
        DROP $FF
    THEN

    SWAP DUP C@         \ value , address , pixel
    ROT OVER XOR        \ address , pixel , value XOR pixel
    SWAP                \ address , value XOR pixel , pixel
    $FF = IF            \ if previous pixel was 0xFF
        DUP
        0 = IF          \ and current pixel became 0
            1 $F VREG!  \ set collission
        THEN
    THEN
    SWAP C!             \ set XORed value to pixel
;

: OUT_BUFFER_RESET ( -- )
    OUT_BUFFER OUT_BUFFER_PTR !
;

: OUT_BUFFER! ( addr len -- )
    DUP ROT SWAP
    OUT_BUFFER_PTR @ SWAP MOVE
    OUT_BUFFER_PTR +!
;

: OUT_BUFFER_C! ( char -- )
    OUT_BUFFER_PTR @ C!
    1 OUT_BUFFER_PTR +!
;

: OUT_BUFFER_U! ( u -- )
    0 <# #S #>
    OUT_BUFFER!
;

: OUT_BUFFER_S! ( -- ) 
    DEPTH 0 ?DO
        DEPTH 1- I - PICK OUT_BUFFER_U!
        S"  " OUT_BUFFER!
    LOOP
;

: OUT_BUFFER_LEN ( -- len )
    OUT_BUFFER_PTR @ OUT_BUFFER -
;

\ HELPERS

: RANDOM8@
    random_seed @
    DUP 1 AND IF
      1 RSHIFT $B4 XOR
    ELSE
      1 RSHIFT
    THEN
    dup random_seed !
    $FF AND
;

: Y ( xy -- y_reg_num )
    $00F0 AND 4 RSHIFT
;

: Y@ ( xy -- y )
    Y VREG@
;

: Y! ( value xy -- )
    Y VREG!
;

: X ( xy -- x_reg_num )
    $0F00 AND 8 RSHIFT
;

: X@ ( xy -- x )
    X VREG@
;

: X! ( value xy -- )
    X VREG!
;

: DRW_X@ ( -- value )
    DRW_X @
;

: DRW_X! ( value -- )
    DRW_X !
;

: DRW_Y@ ( -- value )
    DRW_Y @
;

: DRW_Y! ( value -- )
    DRW_Y !
;

: KEY_RESET ( -- )
    KEY_STATE KEY_COUNT ERASE
;

: KEY! ( 0/1 key -- )
    KEY_STATE + C!
;

: KEY@ ( key -- state )
    KEY_STATE + C@
;

: KEY_DOWN? ( key -- flag )
    KEY@ 0 <>
;

: ASCII>KEY ( char -- key true/false )
    CASE
        [CHAR] q OF $1 TRUE ENDOF
        [CHAR] w OF $2 TRUE ENDOF
        [CHAR] e OF $3 TRUE ENDOF
        [CHAR] r OF $C TRUE ENDOF

        [CHAR] a OF $4 TRUE ENDOF
        [CHAR] s OF $5 TRUE ENDOF
        [CHAR] d OF $6 TRUE ENDOF
        [CHAR] f OF $D TRUE ENDOF

        [CHAR] y OF $7 TRUE ENDOF
        [CHAR] u OF $8 TRUE ENDOF
        [CHAR] i OF $9 TRUE ENDOF
        [CHAR] o OF $E TRUE ENDOF

        [CHAR] h OF $A TRUE ENDOF
        [CHAR] j OF $0 TRUE ENDOF
        [CHAR] k OF $B TRUE ENDOF
        [CHAR] l OF $F TRUE ENDOF

        FALSE SWAP
    ENDCASE
;

: POLL_KEYS ( -- )
    KEY_RESET
    BEGIN
        KEY?
    WHILE
        KEY ASCII>KEY
        IF 1 SWAP KEY! THEN
    REPEAT
;

\ INSTRUCTIONS

\ SYS - jump to address
: INS_0nnn ( addr -- )
    PC!
;

\ CLS - clear screen
: INS_00E0 ( -- )
    DISPLAY_BUFFER 2048 0 FILL
;

\ RET - return from subroutine
: INS_00EE ( -- )
    PC!
;

\ JP - jump to address
: INS_1nnn ( addr -- )
    PC!
;

\ CALL - call subroutine 
: INS_2nnn ( addr -- next_instr )
    PC@ SWAP PC!
;

\ SE - skip next instruction if Vx == kk
: INS_3xkk ( x kk -- )
    DUP $00FF AND SWAP
    X@
    = IF            \ if Vx == kk
        NEXT_INS!
    THEN
;

\ SNE - skip next instruction if Vx != kk
: INS_4xkk ( x kk -- )
    DUP $00FF AND SWAP
    X@
    <> IF           \ if Vx != kk
        NEXT_INS! 
    THEN
;

\ SE - skip next instruction if Vx == Vy
: INS_5xy0 ( x y -- )
    DUP
    X@ SWAP Y@
    = IF            \ if Vx == Vy
        NEXT_INS!
    THEN
;

\ LD - Vx = kk
: INS_6xkk ( x kk -- )
    DUP $00FF AND SWAP
    X!
;

\ ADD - Vx = Vx + kk
: INS_7xkk ( x kk -- )
    DUP $00FF AND 
    SWAP
    X VREG DUP C@
    ROT + SWAP C!
;

\ LD - Vx = Vy
: INS_8xy0 ( x y -- )
    DUP Y@
    SWAP
    X!
;

\ OR - Vx or Vy
: INS_8xy1 ( x y -- )
    DUP Y@
    SWAP
    X VREG DUP C@
    ROT OR SWAP C!
;

\ AND - Vx and Vy
: INS_8xy2 ( x y -- )
    DUP Y@
    SWAP
    X VREG DUP C@
    ROT AND SWAP C!
;

\ XOR - Vx xor VY
: INS_8xy3 ( x y -- )
    DUP Y@
    SWAP
    X VREG DUP C@
    ROT XOR SWAP C!
;

\ ADD - Vx = Vx + Vy, VF = carry
: INS_8xy4 ( x y -- )
    DUP Y@
    SWAP
    X VREG DUP C@
    ROT +

    DUP $FF > IF
        1 $F VREG!
    ELSE
        0 $F VREG!
    THEN
    $FF AND SWAP C!      \ only lowest 8 bits
;

\ SUB - Vx = Vx - Vy, VF = NOT borrow
: INS_8xy5 ( x y -- )
    DUP Y@
    SWAP
    X VREG DUP C@
    ROT
    2DUP > IF           \ if Vx > Vy => Vf = 1
        1 $F VREG!
    ELSE
        0 $F VREG!
    THEN
    - SWAP C!
;

\ SHR - Vx = Vx SHR 1
: INS_8xy6 ( x y -- )
    X VREG DUP C@
    DUP %0001 AND IF
        1 $F VREG!
    ELSE
        0 $F VREG!
    THEN
    1 RSHIFT SWAP C!
;

\ SUBN - Vx = Vy - Vx, VF = NOT borrow
: INS_8xy7 ( x y -- )
    DUP Y@
    SWAP
    X VREG DUP C@
    ROT
    2DUP < IF           \ if Vx > Vy => Vf = 1
        0 $F VREG!
    ELSE
        1 $F VREG!
    THEN
    SWAP - SWAP !
;

\ SHL - Vx = Vx SHL 1
: INS_8xyE ( x y -- )
    X VREG DUP C@
    DUP %1000 AND IF
        1 $F VREG!
    ELSE
        0 $F VREG!
    THEN
    1 LSHIFT SWAP !
;

\ SNE - Skip next instruction if Vx != Vy
: INS_9xy0 ( x y -- )
    DUP
    X@ SWAP Y@
    <> IF            \ if Vx != Vy
        NEXT_INS! 
    THEN
;

\ LD I - Set I = nnn
: INS_Annn ( value -- )
    IREG!
;

\ JP - Jump to location nnn + V0
: INS_Bnnn ( value -- )
    0 VREG@
    + PC!
;

\ RND - Set Vx = random byte AND kk
: INS_Cxkk ( x kk -- )
    DUP $00FF AND
    RANDOM8@ AND
    SWAP
    X!
;

\ DRW - Display n byte sprite from I at Vx, Vy, Set VF = collision
: INS_Dxyn ( x y n -- )
    0 $F VREG!      \ set 0 to VF register

    DUP X@ DRW_X!
    DUP Y@ DRW_Y!

    $F AND 0 DO
        IREG@ I + RAM@

        8 0 DO
            DUP
            1 7 I - LSHIFT AND  \ RAM[I] and (1 << 7 - J)
            DRW_Y@ DRW_X@ I +
            PIXEL!
        LOOP

        DROP
        DRW_Y@ 1+ DRW_Y!
    LOOP
;

\ SKP - Skip next instution if key with the value of Vx is pressed
: INS_Ex9E ( x -- )
    X@
    KEY_DOWN? 0 <> IF NEXT_INS! THEN
;

\ SKNP - Skip next instution if key with the value of Vx is not pressed
: INS_ExA1 ( x -- )
    X@
    KEY_DOWN? 0 = IF NEXT_INS! THEN
;

\ LD Vx DT - Set Vx = delay timer value
: INS_Fx07 ( x -- )
    DelayTimer@ SWAP X!
;

\ LD Vx - Wait for a key press, store the value of the key in Vx
: INS_Fx0A ( x -- )
    X KEY
    ASCII>KEY DROP
    SWAP VREG!
;

\ LD DT Vx - Set delay timer = Vx
: INS_Fx15 ( x -- )
    X@ DelayTimer!
;

\ LD ST Vx - Set sound timer = Vx
: INS_Fx18 ( x -- )
    X@ SoundTimer!
;

\ ADD I - Set I = I + Vx
: INS_Fx1E ( x -- )
    X@ IREG@ + IREG!
;

\ LD F Vx - Set I = location of sprite for digit Vx
: INS_Fx29 ( x -- )
    X@
    5 * SPRITE_START + IREG!
;

\ LD B Vx - Store BCD representation of Vx in memory locations I, I+1, and I+2
: INS_Fx33 ( x -- )
    X@
    10 /MOD  \ ones , tens-hundreds
    10 /MOD  \ ones , tens , hundreds

    IREG     C!
    IREG 1 + C!
    IREG 2 + C!
;

\ LD [I] Vx - Store registers V0 through Vx in memory starting at location I
: INS_Fx55
    X
    DUP 1+ 0 DO
        I VREG@
        IREG@ I + RAM!
    LOOP
;

\ LD Vx [I] - Read registers V0 through Vx from memory starting at location I
: INS_Fx65
    X
    DUP 1+ 0 DO
        IREG@ I + RAM@
        I VREG!
    LOOP
    DROP
;

: CALL_0 ( params -- )
    DUP $FF00 AND 8 RSHIFT
    $00 <> IF       \ if command is not 00xx -> call SYS instruction
        INS_0nnn
        PREV_INS!
        EXIT
    THEN

    $00FF AND
    CASE
        $0E0 OF INS_00E0 ENDOF
        $0EE OF INS_00EE ENDOF
    ENDCASE
;

: CALL_8
    DUP $000F AND
    CASE
        $0 OF INS_8xy0 ENDOF
        $1 OF INS_8xy1 ENDOF
        $2 OF INS_8xy2 ENDOF
        $3 OF INS_8xy3 ENDOF
        $4 OF INS_8xy4 ENDOF
        $5 OF INS_8xy5 ENDOF
        $6 OF INS_8xy6 ENDOF
        $7 OF INS_8xy7 ENDOF
        $E OF INS_8xyE ENDOF
    ENDCASE
;

: CALL_E
    DUP $00FF AND
    CASE
        $9E OF INS_Ex9E ENDOF
        $A1 OF INS_ExA1 ENDOF
    ENDCASE
;

: CALL_F
    DUP $00FF AND
    CASE
        $07 OF INS_Fx07 ENDOF
        $0A OF INS_Fx0A ENDOF
        $15 OF INS_Fx15 ENDOF
        $18 OF INS_Fx18 ENDOF
        $1E OF INS_Fx1E ENDOF
        $29 OF INS_Fx29 ENDOF
        $33 OF INS_Fx33 ENDOF
        $55 OF INS_Fx55 ENDOF
        $65 OF INS_Fx65 ENDOF
    ENDCASE
;

: exec_opcode
    DUP PREV_OC ! 
    DUP PARAMS@
    SWAP COMMAND@

    CASE
        $0 OF CALL_0                ENDOF
        $1 OF INS_1nnn PREV_INS!    ENDOF
        $2 OF INS_2nnn PREV_INS!    ENDOF
        $3 OF INS_3xkk              ENDOF
        $4 OF INS_4xkk              ENDOF
        $5 OF INS_5xy0              ENDOF
        $6 OF INS_6xkk              ENDOF
        $7 OF INS_7xkk              ENDOF
        $8 OF CALL_8                ENDOF
        $9 OF INS_9xy0              ENDOF
        $A OF INS_Annn              ENDOF
        $B OF INS_Bnnn PREV_INS!    ENDOF
        $C OF INS_Cxkk              ENDOF
        $D OF INS_Dxyn              ENDOF
        $E OF CALL_E                ENDOF
        $F OF CALL_F                ENDOF
    ENDCASE
;

: get_opcode ( addr -- )
    DUP RAM@ 8 LSHIFT
    SWAP 1 + RAM@
    OR
;

: key_highlight_on ( -- )
    27 OUT_BUFFER_C!
    S" [30;47m" OUT_BUFFER!
;

: key_highlight_off ( -- )
    27 OUT_BUFFER_C!
    S" [0m" OUT_BUFFER!
;

: print_key ( key char -- )
    OVER KEY_DOWN? IF
        key_highlight_on

        BL OUT_BUFFER_C!
        NIP OUT_BUFFER_C!
        BL OUT_BUFFER_C!

        key_highlight_off
    ELSE
        BL OUT_BUFFER_C!
        NIP OUT_BUFFER_C!
        BL OUT_BUFFER_C!
    THEN
;

: print_keyboard_row_1
    S" |" OUT_BUFFER!

    $1 [CHAR] 1 print_key
    S" |" OUT_BUFFER!

    $2 [CHAR] 2 print_key
    S" |" OUT_BUFFER!

    $3 [CHAR] 3 print_key
    S" |" OUT_BUFFER!

    $C [CHAR] C print_key
    S" |" OUT_BUFFER!
;

: print_keyboard_row_2
    S" |" OUT_BUFFER!

    $4 [CHAR] 4 print_key
    S" |" OUT_BUFFER!

    $5 [CHAR] 5 print_key
    S" |" OUT_BUFFER!

    $6 [CHAR] 6 print_key
    S" |" OUT_BUFFER!

    $D [CHAR] D print_key
    S" |" OUT_BUFFER!
;

: print_keyboard_row_3
    S" |" OUT_BUFFER!

    $7 [CHAR] 7 print_key
    S" |" OUT_BUFFER!

    $8 [CHAR] 8 print_key
    S" |" OUT_BUFFER!

    $9 [CHAR] 9 print_key
    S" |" OUT_BUFFER!

    $E [CHAR] E print_key
    S" |" OUT_BUFFER!
;

: print_keyboard_row_4
    S" |" OUT_BUFFER!

    $A [CHAR] A print_key
    S" |" OUT_BUFFER!

    $0 [CHAR] 0 print_key
    S" |" OUT_BUFFER!

    $B [CHAR] B print_key
    S" |" OUT_BUFFER!

    $F [CHAR] F print_key
    S" |" OUT_BUFFER!
;

: print_keyboard
    CASE
        0  OF ENDOF
        1  OF ENDOF
        2  OF ENDOF
        3  OF ENDOF
        4  OF ENDOF
        5  OF ENDOF
        6  OF ENDOF
        7  OF ENDOF
        8  OF ENDOF
        9  OF ENDOF

        10 OF S"  ** KEYBOARD **" OUT_BUFFER!   ENDOF
        11 OF print_keyboard_row_1              ENDOF
        12 OF print_keyboard_row_2              ENDOF
        13 OF print_keyboard_row_3              ENDOF
        14 OF print_keyboard_row_4              ENDOF

        15 OF ENDOF
        16 OF ENDOF
        17 OF ENDOF
        18 OF ENDOF
        19 OF ENDOF
        20 OF ENDOF
        21 OF ENDOF
        22 OF ENDOF
        23 OF ENDOF
        24 OF ENDOF
        25 OF ENDOF
        26 OF ENDOF
        27 OF ENDOF
        28 OF ENDOF
        29 OF ENDOF
        30 OF ENDOF
        31 OF ENDOF
    ENDCASE
;

: print_register
    CASE
        0  OF                                                   ENDOF
        1  OF S" ** REGISTERS INFO **" OUT_BUFFER!              ENDOF
        2  OF                                                   ENDOF

        3  OF S" P_OC:" OUT_BUFFER! PREV_OC @   OUT_BUFFER_U!   ENDOF
        4  OF S" OC:"   OUT_BUFFER! DUP         OUT_BUFFER_U!   ENDOF
        5  OF S" PC:"   OUT_BUFFER! PC@         OUT_BUFFER_U!   ENDOF
        6  OF                                                   ENDOF

        7  OF S" I: "   OUT_BUFFER! IREG@       OUT_BUFFER_U!   ENDOF
        8  OF                                                   ENDOF

        9  OF S" V0:"   OUT_BUFFER! $0 VREG@    OUT_BUFFER_U!   ENDOF
        10 OF S" V1:"   OUT_BUFFER! $1 VREG@    OUT_BUFFER_U!   ENDOF
        11 OF S" V2:"   OUT_BUFFER! $2 VREG@    OUT_BUFFER_U!   ENDOF
        12 OF S" V3:"   OUT_BUFFER! $3 VREG@    OUT_BUFFER_U!   ENDOF
        13 OF S" V4:"   OUT_BUFFER! $4 VREG@    OUT_BUFFER_U!   ENDOF
        14 OF S" V5:"   OUT_BUFFER! $5 VREG@    OUT_BUFFER_U!   ENDOF
        15 OF S" V6:"   OUT_BUFFER! $6 VREG@    OUT_BUFFER_U!   ENDOF
        16 OF S" V7:"   OUT_BUFFER! $7 VREG@    OUT_BUFFER_U!   ENDOF
        17 OF S" V8:"   OUT_BUFFER! $8 VREG@    OUT_BUFFER_U!   ENDOF
        18 OF S" V9:"   OUT_BUFFER! $9 VREG@    OUT_BUFFER_U!   ENDOF
        19 OF S" VA:"   OUT_BUFFER! $A VREG@    OUT_BUFFER_U!   ENDOF
        20 OF S" VB:"   OUT_BUFFER! $B VREG@    OUT_BUFFER_U!   ENDOF
        21 OF S" VC:"   OUT_BUFFER! $C VREG@    OUT_BUFFER_U!   ENDOF
        22 OF S" VD:"   OUT_BUFFER! $D VREG@    OUT_BUFFER_U!   ENDOF
        23 OF S" VE:"   OUT_BUFFER! $E VREG@    OUT_BUFFER_U!   ENDOF
        24 OF S" VF:"   OUT_BUFFER! $F VREG@    OUT_BUFFER_U!   ENDOF
        25 OF                                                   ENDOF
        26 OF                                                   ENDOF

        27 OF S" DelayTimer:"   OUT_BUFFER! DelayTimer@ OUT_BUFFER_U!   ENDOF
        28 OF S" SoundTimer:"   OUT_BUFFER! SoundTimer@ OUT_BUFFER_U!   ENDOF
        29 OF                                                           ENDOF
        30 OF S" ** STACK **"   OUT_BUFFER!                             ENDOF

        31 OF S" STACK:"        OUT_BUFFER!             OUT_BUFFER_S!   ENDOF
    ENDCASE
;

: print_screen
    OUT_BUFFER_RESET

    27 OUT_BUFFER_C!        \ 27 EMIT
    S" [H" OUT_BUFFER!      \ move cursor to begin

    32 0 DO
        10 OUT_BUFFER_C!    \ \n

        27 OUT_BUFFER_C!    \ 27 EMIT
        S" [K" OUT_BUFFER!  \ EOF

        64 0 DO
            J I PIXEL@ DUP
            $00 = IF S"   " OUT_BUFFER! THEN
            $FF = IF S" ██" OUT_BUFFER! THEN
        LOOP

        S"      " OUT_BUFFER! \ 5 SPACES
        I print_register
        S"                  " OUT_BUFFER!
        I print_keyboard
    LOOP

    OUT_BUFFER OUT_BUFFER_LEN TYPE
;

: main_loop
    \ start from firts byte of ROM
    ROM_START PC ! 
    HEX
    BEGIN
        PC @ get_opcode

        POLL_KEYS

        \ PAGE
        print_screen

        \ CR ." ============================================"
        \ CR ." DEBUG: Press to continue" CR
        \ KEY DROP

        \ TODO: implement timer
        DelayTimer@
        DUP 0 <> IF
            16 MS
            1 - DelayTimer!
        ELSE
            DROP
        THEN

        exec_opcode
        NEXT_INS!
    AGAIN
    DECIMAL
;

\ Probably it is not original sprites
: load_sprites ( -- )
    \ counter
    0 >R

    \ 0x000
    %11110000 RAM_MEMORY R@ + C! R> 1 + >R \ ****
    %10010000 RAM_MEMORY R@ + C! R> 1 + >R \ *  *
    %10010000 RAM_MEMORY R@ + C! R> 1 + >R \ *  *
    %10010000 RAM_MEMORY R@ + C! R> 1 + >R \ *  *
    %11110000 RAM_MEMORY R@ + C! R> 1 + >R \ ****

    \ 0x005
    %00100000 RAM_MEMORY R@ + C! R> 1 + >R \   * 
    %01100000 RAM_MEMORY R@ + C! R> 1 + >R \  ** 
    %00100000 RAM_MEMORY R@ + C! R> 1 + >R \   * 
    %00100000 RAM_MEMORY R@ + C! R> 1 + >R \   * 
    %01110000 RAM_MEMORY R@ + C! R> 1 + >R \  ***

    \ 0x00A
    %11110000 RAM_MEMORY R@ + C! R> 1 + >R \ ****
    %00010000 RAM_MEMORY R@ + C! R> 1 + >R \    *
    %11110000 RAM_MEMORY R@ + C! R> 1 + >R \ ****
    %10000000 RAM_MEMORY R@ + C! R> 1 + >R \ *   
    %11110000 RAM_MEMORY R@ + C! R> 1 + >R \ ****

    \ 0x00F
    %11110000 RAM_MEMORY R@ + C! R> 1 + >R \ ****
    %00010000 RAM_MEMORY R@ + C! R> 1 + >R \    *
    %11110000 RAM_MEMORY R@ + C! R> 1 + >R \ ****
    %00010000 RAM_MEMORY R@ + C! R> 1 + >R \    *
    %11110000 RAM_MEMORY R@ + C! R> 1 + >R \ ****

    \ 0x014
    %10010000 RAM_MEMORY R@ + C! R> 1 + >R \ *  *
    %10010000 RAM_MEMORY R@ + C! R> 1 + >R \ *  *
    %11110000 RAM_MEMORY R@ + C! R> 1 + >R \ ****
    %00010000 RAM_MEMORY R@ + C! R> 1 + >R \    *
    %00010000 RAM_MEMORY R@ + C! R> 1 + >R \    *

    \ 0x019
    %11110000 RAM_MEMORY R@ + C! R> 1 + >R \ ****
    %10000000 RAM_MEMORY R@ + C! R> 1 + >R \ *   
    %11110000 RAM_MEMORY R@ + C! R> 1 + >R \ ****
    %00010000 RAM_MEMORY R@ + C! R> 1 + >R \    *
    %11110000 RAM_MEMORY R@ + C! R> 1 + >R \ ****

    \ 0x01E
    %11110000 RAM_MEMORY R@ + C! R> 1 + >R \ ****
    %10000000 RAM_MEMORY R@ + C! R> 1 + >R \ *   
    %11110000 RAM_MEMORY R@ + C! R> 1 + >R \ ****
    %10010000 RAM_MEMORY R@ + C! R> 1 + >R \ *  *
    %11110000 RAM_MEMORY R@ + C! R> 1 + >R \ ****

    \ 0x023
    %11110000 RAM_MEMORY R@ + C! R> 1 + >R \ ****
    %00010000 RAM_MEMORY R@ + C! R> 1 + >R \    *
    %00100000 RAM_MEMORY R@ + C! R> 1 + >R \   * 
    %01000000 RAM_MEMORY R@ + C! R> 1 + >R \  *  
    %01000000 RAM_MEMORY R@ + C! R> 1 + >R \  *  

    \ 0x028
    %11110000 RAM_MEMORY R@ + C! R> 1 + >R \ ****
    %10010000 RAM_MEMORY R@ + C! R> 1 + >R \ *  *
    %11110000 RAM_MEMORY R@ + C! R> 1 + >R \ ****
    %10010000 RAM_MEMORY R@ + C! R> 1 + >R \ *  *
    %11110000 RAM_MEMORY R@ + C! R> 1 + >R \ ****

    \ 0x02D
    %11110000 RAM_MEMORY R@ + C! R> 1 + >R \ ****
    %10010000 RAM_MEMORY R@ + C! R> 1 + >R \ *  *
    %11110000 RAM_MEMORY R@ + C! R> 1 + >R \ ****
    %00010000 RAM_MEMORY R@ + C! R> 1 + >R \    *
    %11110000 RAM_MEMORY R@ + C! R> 1 + >R \ ****

    \ 0x032
    %11110000 RAM_MEMORY R@ + C! R> 1 + >R \ ****
    %10010000 RAM_MEMORY R@ + C! R> 1 + >R \ *  *
    %11110000 RAM_MEMORY R@ + C! R> 1 + >R \ ****
    %10010000 RAM_MEMORY R@ + C! R> 1 + >R \ *  *
    %10010000 RAM_MEMORY R@ + C! R> 1 + >R \ *  *

    \ 0x037
    %11100000 RAM_MEMORY R@ + C! R> 1 + >R \ *** 
    %10010000 RAM_MEMORY R@ + C! R> 1 + >R \ *  *
    %11100000 RAM_MEMORY R@ + C! R> 1 + >R \ *** 
    %10010000 RAM_MEMORY R@ + C! R> 1 + >R \ *  *
    %11100000 RAM_MEMORY R@ + C! R> 1 + >R \ *** 

    \ 0x03C
    %11110000 RAM_MEMORY R@ + C! R> 1 + >R \ ****
    %10000000 RAM_MEMORY R@ + C! R> 1 + >R \ *   
    %10000000 RAM_MEMORY R@ + C! R> 1 + >R \ *   
    %10000000 RAM_MEMORY R@ + C! R> 1 + >R \ *   
    %11110000 RAM_MEMORY R@ + C! R> 1 + >R \ ****

    \ 0x041
    %11100000 RAM_MEMORY R@ + C! R> 1 + >R \ *** 
    %10010000 RAM_MEMORY R@ + C! R> 1 + >R \ *  *
    %10010000 RAM_MEMORY R@ + C! R> 1 + >R \ *  *
    %10010000 RAM_MEMORY R@ + C! R> 1 + >R \ *  *
    %11100000 RAM_MEMORY R@ + C! R> 1 + >R \ *** 

    \ 0x046
    %11110000 RAM_MEMORY R@ + C! R> 1 + >R \ ****
    %10000000 RAM_MEMORY R@ + C! R> 1 + >R \ *   
    %11110000 RAM_MEMORY R@ + C! R> 1 + >R \ ****
    %10000000 RAM_MEMORY R@ + C! R> 1 + >R \ *   
    %11110000 RAM_MEMORY R@ + C! R> 1 + >R \ ****

    \ 0x04B
    %11110000 RAM_MEMORY R@ + C! R> 1 + >R \ ****
    %10000000 RAM_MEMORY R@ + C! R> 1 + >R \ *   
    %11110000 RAM_MEMORY R@ + C! R> 1 + >R \ ****
    %10000000 RAM_MEMORY R@ + C! R> 1 + >R \ *   
    %10000000 RAM_MEMORY R@ + C! R> 1 + >R \ *   

    \ free return stack
    R> DROP
;

: load_rom ( str_addr len -- )
    R/O BIN OPEN-FILE THROW \ open file
    DUP FILE-SIZE THROW 2>R \ get file size to return stack as double word

    DUP 0 S>D ROT           \ REPOSITION-FILE takes double word
    REPOSITION-FILE THROW   \ set start pointer to 0
    DUP

    \ ROM should starts from 0x200
    RAM_MEMORY ROM_START +  \ file_id, file_id, output
    2R> D>S                 \ file_id, file_id, output, file_size
    ROT                     \ file_id, output, file_size file_id
    READ-FILE THROW         \ file_id, bytes_read )

    CR ." Bytes read: " . CR

    CLOSE-FILE THROW        \ empty
;

RAM_MEMORY 4096 0 FILL
load_sprites
NEXT-ARG load_rom
INS_00E0
main_loop

\ ROMs with errors:
\ 1 - key capture