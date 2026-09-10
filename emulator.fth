VARIABLE file_id

VARIABLE opcode_buffer
VARIABLE random_seed 1 random_seed !

VARIABLE PC

VARIABLE I0Reg

VARIABLE V0Reg
VARIABLE V1Reg
VARIABLE V2Reg
VARIABLE V3Reg
VARIABLE V4Reg
VARIABLE V5Reg
VARIABLE V6Reg
VARIABLE V7Reg
VARIABLE V8Reg
VARIABLE V9Reg
VARIABLE VAReg
VARIABLE VBReg
VARIABLE VCReg
VARIABLE VDReg
VARIABLE VEReg
VARIABLE VFREg

VARIABLE DT
VARIABLE ST

\ 2048 symbols
\ 64 x 32
CREATE frame_buffer 2048 ALLOT

\ TODO: remove later
VARIABLE drw_x
VARIABLE drw_y


: 12_rightmost ( abcd -- bcd )
    $0FFF AND
;

: V_register_address ( num -- addr )
    CASE
        0  OF V0Reg ENDOF
        1  OF V1Reg ENDOF
        2  OF V2Reg ENDOF
        3  OF V3Reg ENDOF
        4  OF V4Reg ENDOF
        5  OF V5Reg ENDOF
        6  OF V6Reg ENDOF
        7  OF V7Reg ENDOF
        8  OF V8Reg ENDOF
        9  OF V9Reg ENDOF
        10 OF VAReg ENDOF
        11 OF VBReg ENDOF
        12 OF VCReg ENDOF
        13 OF VDReg ENDOF
        14 OF VEReg ENDOF
        15 OF VFReg ENDOF
    ENDCASE
;

: call_JMP
    $200 -
    HEX
    CR ." DEBUG: Jump address: " DUP .
    DECIMAL

    PC !
;

: call_CALL
    PC @ 2 + SWAP
    $200 -

    HEX
    CR ." DEBUG: Address to call: " DUP .
    DECIMAL

    PC !
;

: call_RET
    PC !
;

: call_CLS
    frame_buffer 2048 0 FILL
;

: call_LDI
    I0Reg !
;

: call_LDV
    DUP $00FF AND SWAP

    $0F00 AND 8 RSHIFT
    V_register_address !
;

: call_ADD
    DUP $00FF AND SWAP

    $0F00 AND 8 RSHIFT
    V_register_address
    DUP @ ROT + SWAP !
;

: call_SE
    DUP $00FF AND SWAP

    $0F00 AND 8 RSHIFT
    V_register_address @
    = IF 
        PC @ 2 + 
        PC ! 
    THEN
;

: call_FCMD
    DUP $0F00 AND 8 RSHIFT
    SWAP
    $00FF AND

    CASE
        $07   OF DT @ SWAP V_register_address ! ENDOF
        $0A  OF ." Wait for a key. Not implemented" ENDOF
        $15  OF V_register_address @ DT ! ENDOF
        $18  OF V_register_address @ ST ! ENDOF
        $1E  OF V_register_address @ I0Reg @ + I0Reg ! ENDOF
        $29  OF ." Set I to location of sprite of Vx. Not implemented" ENDOF
        $33  OF ." Store hundreds in I, tens in I+1 and ones in I+2. Not implemented" ENDOF
        $55  OF ." Copy values from V0 to VX to address of I. Not implemented" ENDOF
        $65 OF ." Read values from address of I to V0 to VX. Not implemented" ENDOF
    ENDCASE
;

: random8
    random_seed @
    DUP 1 AND IF
      1 RSHIFT $B4 XOR
    ELSE
      1 RSHIFT
    THEN
    dup random_seed !
    $FF AND
;

: call_RND
    DUP $00FF AND
    random8 AND 
    SWAP
    $0F00 AND 8 RSHIFT
    V_register_address !
;

\ TODO: constants
\ TODO: overlapping
\ TODO: parameters order
: pixel_address ( x y -- addr )
    32 * + frame_buffer +
;

: pixel! ( value x y -- )
    pixel_address
    SWAP DUP
    0 <> IF
        DROP $FF 
    THEN
    SWAP DUP C@
    ROT XOR SWAP
    C!
;

: print_screen
    32 0 DO
        CR
        64 0 DO
            J I pixel_address C@
            DUP 0 = IF ." .." THEN
            255 = IF ." ##" THEN
        LOOP
    LOOP
;

\ TODO: rewrite
: call_DRV
    \ x
    DUP $0F00 AND 8 RSHIFT
    CASE
        0  OF V0Reg @ ENDOF
        1  OF V1Reg @ ENDOF
        2  OF V2Reg @ ENDOF
        3  OF V3Reg @ ENDOF
        4  OF V4Reg @ ENDOF
        5  OF V5Reg @ ENDOF
        6  OF V6Reg @ ENDOF
        7  OF V7Reg @ ENDOF
        8  OF V8Reg @ ENDOF
        9  OF V9Reg @ ENDOF
        10 OF VAReg @ ENDOF
        11 OF VBReg @ ENDOF
        12 OF VCReg @ ENDOF
        13 OF VDReg @ ENDOF
        14 OF VEReg @ ENDOF
        15 OF VFReg @ ENDOF
    ENDCASE
    drw_x !

    \ y
    DUP $00F0 AND 4 RSHIFT
    CASE
        0  OF V0Reg @ ENDOF
        1  OF V1Reg @ ENDOF
        2  OF V2Reg @ ENDOF
        3  OF V3Reg @ ENDOF
        4  OF V4Reg @ ENDOF
        5  OF V5Reg @ ENDOF
        6  OF V6Reg @ ENDOF
        7  OF V7Reg @ ENDOF
        8  OF V8Reg @ ENDOF
        9  OF V9Reg @ ENDOF
        10 OF VAReg @ ENDOF
        11 OF VBReg @ ENDOF
        12 OF VCReg @ ENDOF
        13 OF VDReg @ ENDOF
        14 OF VEReg @ ENDOF
        15 OF VFReg @ ENDOF
    ENDCASE
    drw_y !

    \ n
    $F AND

    HEX
    \ memory of ROM starts from 0x200
    I0Reg @ $200 -
    S>D file_id @ REPOSITION-FILE THROW

    0 DO
        opcode_buffer 1 file_id @ READ-FILE THROW DROP

        opcode_buffer C@ 128 AND drw_y @ drw_x @ 0 +
        pixel!

        opcode_buffer C@ 64 AND drw_y @ drw_x @ 1 +
        pixel!

        opcode_buffer C@ 32 AND drw_y @ drw_x @ 2 +
        pixel!

        opcode_buffer C@ 16 AND drw_y @ drw_x @ 3 +
        pixel!

        opcode_buffer C@ 8 AND drw_y @ drw_x @ 4 +
        pixel!

        opcode_buffer C@ 4 AND drw_y @ drw_x @ 5 +
        pixel!

        opcode_buffer C@ 2 AND drw_y @ drw_x @ 6 +
        pixel!

        opcode_buffer C@ 1 AND drw_y @ drw_x @ 7 +
        pixel!

        drw_y @ 1+ drw_y !
    LOOP

    DECIMAL
;

: execute_opcode
    opcode_buffer @

    DUP $F000 AND 12 RSHIFT
    CR ." DEBUG: Command : " DUP .

    CASE
        0  OF
            12_rightmost
            $00FF AND
            $EE = IF
                call_RET
            ELSE
                $E0 = IF
                    call_CLS
                THEN
            THEN
        ENDOF
        1  OF 
            12_rightmost call_JMP
        ENDOF
        2  OF 
            12_rightmost call_CALL
        ENDOF
        3  OF 
            12_rightmost call_SE PC @ 2 + PC !
        ENDOF
        4  OF 
            CR ." 4 Prefix - not implemented"
        ENDOF
        5  OF 
            CR ." 5 Prefix - not implemented"
        ENDOF
        6  OF 
            12_rightmost call_LDV PC @ 2 + PC !
        ENDOF
        7  OF 
            12_rightmost call_ADD PC @ 2 + PC !
        ENDOF
        8  OF 
            CR ." 8 Prefix - not implemented"
        ENDOF
        9  OF 
            CR ." 9 Prefix - not implemented"
        ENDOF
        10 OF 
            12_rightmost call_LDI PC @ 2 + PC !
        ENDOF
        11 OF 
            CR ." B Prefix - not implemented"
        ENDOF
        12 OF 
            12_rightmost call_RND PC @ 2 + PC !
        ENDOF
        13 OF 
            12_rightmost call_DRV PC @ 2 + PC !
        ENDOF
        14 OF 
            CR ." E Prefix - not implemented"
        ENDOF
        15 OF 
            12_rightmost call_FCMD PC @ 2 + PC !
        ENDOF
    ENDCASE
;

: to_big_endian ( addr -- )
    DUP
    C@ 8 LSHIFT
    SWAP 1+ C@ OR
;

: to_big_endian_opcode
    opcode_buffer to_big_endian
    opcode_buffer !
;

: read_opcode ( addr -- )
    S>D file_id @ REPOSITION-FILE THROW

    opcode_buffer 2 file_id @ READ-FILE
    0 <> THROW
    2 <> THROW
;

: print_registers
    CR ." DEBUG: I0:" 5 SPACES I0Reg @ .
    CR ." DEBUG: V0:" 5 SPACES V0Reg @ .
    CR ." DEBUG: V1:" 5 SPACES V1Reg @ .
    CR ." DEBUG: V2:" 5 SPACES V2Reg @ .
    CR ." DEBUG: V3:" 5 SPACES V3Reg @ .
    CR ." DEBUG: V4:" 5 SPACES V4Reg @ .
    CR ." DEBUG: V5:" 5 SPACES V5Reg @ .
    CR ." DEBUG: V6:" 5 SPACES V6Reg @ .
    CR ." DEBUG: V7:" 5 SPACES V7Reg @ .
    CR ." DEBUG: V8:" 5 SPACES V8Reg @ .
    CR ." DEBUG: V9:" 5 SPACES V9Reg @ .
    CR ." DEBUG: VA:" 5 SPACES VAReg @ .
    CR ." DEBUG: VB:" 5 SPACES VBReg @ .
    CR ." DEBUG: VC:" 5 SPACES VCReg @ .
    CR ." DEBUG: VD:" 5 SPACES VDReg @ .
    CR ." DEBUG: VE:" 5 SPACES VEReg @ .
    CR ." DEBUG: VF:" 5 SPACES VFREg @ .
;

: app_loop
    BEGIN
        PAGE
        HEX
        CR
        CR ." DEBUG: PC:" 5 SPACES PC @ .
        print_registers

        CR ." DEBUG: DT:" 5 SPACES DT @ .
        CR ." DEBUG: ST:" 5 SPACES ST @ .

        PC @ read_opcode
        to_big_endian_opcode

        CR CR ." DEBUG: OC:" 5 SPACES opcode_buffer @ .
        CR

        CR ." STACK: " .S
        print_screen
        DECIMAL

        \ CR ." ============================================"
        \ CR ." DEBUG: Press to execute" CR
        \ KEY DROP

        \ TODO: implement timer
        20 MS
        0 DT @ <> IF DT @ 1 - DT ! THEN
        execute_opcode
    AGAIN
;

0 PC !

S" samples/octojam8title.ch8" R/O BIN OPEN-FILE THROW
\ S" samples/octojam7title.ch8" R/O BIN OPEN-FILE THROW

file_id !
file_id @ ." DEBUG: file id: " . CR CR

frame_buffer 2048 0 FILL
app_loop
