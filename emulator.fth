VARIABLE random_seed 1 
         random_seed !

$0   CONSTANT SPRITE_START
$200 CONSTANT ROM_START
32   CONSTANT DISPLAY_HEIGHT
64   CONSTANT DISPLAY_WIDTH

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

: RAM@
    RAM_MEMORY + C@
;

: COMMAND@
    $F000 AND 12 RSHIFT
;

: PARAMS@ ( abcd -- bcd )
    $0FFF AND
;

: PC ( -- addr )
    PC
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

: DelayTimer ( -- addr )
    DelayTimer
;

: DelayTimer@ ( -- value )
    DelayTimer @
;

: DelayTimer! ( value -- )
    DelayTimer !
;

: SoundTimer ( -- addr )
    SoundTimer
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
    32 * + DISPLAY_BUFFER +
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
    $0F00 AND 8 RSHIFT

    VREG@
    = IF            \ if Vx == kk
        NEXT_INS!
    THEN
;

\ SNE - skip next instruction if Vx != kk
: INS_4xkk ( x kk -- )
    DUP $00FF AND SWAP
    $0F00 AND 8 RSHIFT

    VREG@
    <> IF           \ if Vx != kk
        NEXT_INS! 
    THEN
;

\ SE - skip next instruction if Vx == Vy
: INS_5xy0 ( x y -- )
    DUP $0F00 AND 16 RSHIFT 
    VREG@

    SWAP

    $00F0 AND 8 RSHIFT
    VREG@

    = IF            \ if Vx == Vy
        NEXT_INS!
    THEN
;

\ LD - Vx = kk
: INS_6xkk ( x kk -- )
    DUP $00FF AND SWAP

    $0F00 AND 8 RSHIFT
    VREG!
;

\ ADD - Vx = Vx + kk
: INS_7xkk ( x kk -- )
    DUP $00FF AND SWAP

    $0F00 AND 8 RSHIFT
    VREG DUP @ 
    ROT + SWAP !
;

\ LD - Vx = Vy
: INS_8xy0 ( x y -- )
    DUP $00F0 AND 8 RSHIFT
    VREG@

    SWAP

    $0F00 AND 16 RSHIFT 
    VREG@

    + VREG!
;

\ OR - Vx or Vy
: INS_8xy1 ( x y -- )
    DUP $00F0 AND 8 RSHIFT
    VREG@

    SWAP

    $0F00 AND 16 RSHIFT 
    VREG@

    OR VREG!
;

\ AND - Vx and Vy
: INS_8xy2 ( x y -- )
    DUP $00F0 AND 8 RSHIFT
    VREG@

    SWAP

    $0F00 AND 16 RSHIFT 
    VREG@

    AND VREG!
;

\ XOR
: INS_8xy3 ( x y -- )
    DUP $00F0 AND 8 RSHIFT
    VREG@

    SWAP

    $0F00 AND 16 RSHIFT 
    VREG@

    XOR VREG!
;

\ ADD - Vx = Vx + Vy, VF = carry
: INS_8xy4 ( x y -- )
    DUP $00F0 AND 8 RSHIFT
    VREG@

    SWAP

    $0F00 AND 16 RSHIFT 
    VREG@

    + DUP $FF > IF 
        1 $F VREG!
    THEN
    $FF AND VREG!
;

\ SUB - Vx = Vx - Vy, VF = NOT borrow
: INS_8xy5 ( x y -- )
;

\ SHR - Vx = Vx SHR 1
: INS_8xy6 ( x y -- )
;

\ SUBN - Vx = Vy - Vx, VF = NOT borrow
: INS_8xy7 ( x y -- )
;

\ SHL - Vx = Vx SHL 1
: INS_8xyE ( x y -- )
;

\ SNE - Skip next instruction if Vx != Vy.
: INS_9xy0 ( x y -- )
    DUP $0F00 AND 16 RSHIFT 
    VREG@

    SWAP

    $00F0 AND 8 RSHIFT
    VREG@

    <> IF            \ if Vx != Vy
        PC @ 2 + 
        PC ! 
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
    $0F00 AND 8 RSHIFT
    VREG !
;

\ DRW - Display n byte sprite from I at Vx, Vy, Set VF = collision
: INS_Dxyn ( x y n -- )
    0 $F VREG!  \ set 0 to VF register

    DUP $0F00 AND 8 RSHIFT
    VREG@ DRW_X!

    DUP $00F0 AND 4 RSHIFT
    VREG@ DRW_Y!

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
    \ TODO: keyboard check
    DUP $0F00 AND 8 RSHIFT
    VREG@
    KEY = IF 
        NEXT_INS!
    THEN
;

\ SKNP - Skip next instution if key with the value of Vx is not pressed
: INS_ExA1 ( x -- )
    \ TODO: keyboard check
    DUP $0F00 AND 8 RSHIFT
    VREG@
    KEY <> IF 
        NEXT_INS!
    THEN
;

\ LD Vx DT - Set Vx = delay timer value
: INS_Fx07 ( x -- )
    $0F00 AND 8 RSHIFT
    DelayTimer@ SWAP VREG!
;

\ LD Vx - Wait for a key press, store the value of the key in Vx
: INS_Fx0A ( x -- )
    \ TODO: keyboard capture
    $0F00 AND 8 RSHIFT
    KEY SWAP VREG!
;

\ LD DT Vx - Set delay timer = Vx
: INS_Fx15 ( x -- )
    $0F00 AND 8 RSHIFT
    VREG@ DelayTimer!
;

\ LD ST Vx - Set sound timer = Vx
: INS_Fx18 ( x -- )
    $0F00 AND 8 RSHIFT
    VREG@ SoundTimer!
;

\ ADD I - Set I = I + Vx
: INS_Fx1E ( x -- )
    $0F00 AND 8 RSHIFT
    VREG@ IREG@ + IREG!
;

\ LD F Vx - Set I = location of sprite for digit Vx
: INS_Fx29 ( x -- )
    $0F00 AND 8 RSHIFT VREG@
    5 * SPRITE_START + IREG!
;

\ LD B Vx - Store BCD representation of Vx in memory locations I, I+1, and I+2.
: INS_Fx33 ( x -- )
    \ TODO:;
;

\ LD [I] Vx - Store registers V0 through Vx in memory starting at location I
: INS_Fx55
    \ TODO:;
;

\ LD Vx [I] - Read registers V0 through Vx from memory starting at location I
: INS_Fx65
    \ TODO:;
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
    DUP PARAMS@
    CR ." DEBUG: Params:  " DUP .
    SWAP COMMAND@
    CR ." DEBUG: Command: " DUP .

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

: print_register
    CASE
        0  OF ." "                          ENDOF
        1  OF ." ** REGISTERS INFO **"      ENDOF
        2  OF ." "                          ENDOF
        3  OF ." "                          ENDOF

        4  OF ." OC:" DUP .                 ENDOF
        5  OF ." PC:" PC@ .                 ENDOF
        6  OF ." "                          ENDOF

        7  OF ." I: " IREG@ .               ENDOF
        8  OF ." "                          ENDOF

        9  OF ." V0:" $0 VREG@ .            ENDOF
        10 OF ." V1:" $1 VREG@ .            ENDOF
        11 OF ." V2:" $2 VREG@ .            ENDOF
        12 OF ." V3:" $3 VREG@ .            ENDOF
        13 OF ." V4:" $4 VREG@ .            ENDOF
        14 OF ." V5:" $5 VREG@ .            ENDOF
        15 OF ." V6:" $6 VREG@ .            ENDOF
        16 OF ." V7:" $7 VREG@ .            ENDOF
        17 OF ." V8:" $8 VREG@ .            ENDOF
        18 OF ." V9:" $9 VREG@ .            ENDOF
        19 OF ." VA:" $A VREG@ .            ENDOF
        20 OF ." VB:" $B VREG@ .            ENDOF
        21 OF ." VC:" $C VREG@ .            ENDOF
        22 OF ." VD:" $D VREG@ .            ENDOF
        23 OF ." VE:" $E VREG@ .            ENDOF
        24 OF ." VF:" $F VREG@ .            ENDOF
        25 OF ." "                          ENDOF
        26 OF ." "                          ENDOF

        27 OF ." DelayTimer:" DelayTimer@ . ENDOF
        28 OF ." SoundTimer:" SoundTimer@ . ENDOF
        29 OF ." "                          ENDOF
        30 OF ." ** STACK **"               ENDOF

        31 OF ." STACK:"   .S               ENDOF
    ENDCASE
;

: print_screen
    32 0 DO
        CR
        64 0 DO
            J I PIXEL@ DUP
            $00 = IF ." .." THEN
            $FF = IF ." ##" THEN
        LOOP
        5 SPACES I print_register
    LOOP
;

: main_loop
    \ start from firts byte of ROM
    ROM_START PC ! 
    HEX
    BEGIN
        PC @ get_opcode

        PAGE
        print_screen

        \ CR ." ============================================"
        \ CR ." DEBUG: Press to continue" CR
        \ KEY DROP

        \ TODO: implement timer
        DelayTimer@
        DUP 0 <> IF
            100 MS
            1 - DelayTimer!
        ELSE
            DROP
        THEN

        exec_opcode
        NEXT_INS!
    AGAIN
    DECIMAL
;

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

\ TODO: implement sturtup params
load_sprites
S" samples/octojam8title.ch8" load_rom
\ INS_00E0
main_loop
