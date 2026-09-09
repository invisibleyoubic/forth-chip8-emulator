VARIABLE file-id

VARIABLE opcode-buffer

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
CREATE frame-buffer 2048 ALLOT

\ TODO: remove later
VARIABLE drw-x
VARIABLE drw-y


: 12-rightmost
    \ 0x0FFF
    DUP 4095 AND
;

: V-register-address ( num -- addr )
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

: call-jump
    HEX
    CR ." DEBUG: Jump address: " DUP .
    DECIMAL

    PC !
    DROP
;

: call-LDI
    I0Reg !
;

: call-LDV
    \ 0x00FF
    DUP 255 AND SWAP

    \ 0x0F00
    3840 AND 8 RSHIFT
    V-register-address !
;

: call-FResolve
    \ 0x0F00
    DUP 3840 AND 8 RSHIFT SWAP

    \ 0x00FF
    255 AND

    CASE
        7   OF DT @ SWAP V-register-address ! ENDOF
        10  OF ." Wait for a key. Not implemented" ENDOF
        21  OF V-register-address @ DT ! ENDOF
        24  OF V-register-address @ ST ! ENDOF
        30  OF V-register-address @ I0Reg @ + I0Reg ! ENDOF
        41  OF ." Set I to location of sprite of Vx. Not implemented" ENDOF
        51  OF ." Store hundreds in I, tens in I+1 and ones in I+2. Not implemented" ENDOF
        85  OF ." Copy values from V0 to VX to address of I. Not implemented" ENDOF
        101 OF ." Read values from address of I to V0 to VX. Not implemented" ENDOF
    ENDCASE
;

\ TODO: constants
\ TODO: overlapping 
\ offset = y * 64 + x + bit
: pixel-address ( x y -- addr )
    32 * + frame-buffer +
;

: pixel! ( value x y -- )
    pixel-address
    SWAP DUP 0 <> IF DROP 255 THEN SWAP
    DUP C@ ROT XOR SWAP
    C!
;

: print-screen
    32 0 DO
        CR
        64 0 DO
            J I pixel-address C@
            DUP 0 = IF ." .." THEN
            255 = IF ." ##" THEN
        LOOP
    LOOP
;

\ TODO: rewrite
: call-DRV
    \ x
    \ 0x0F00
    DUP 3840 AND 8 RSHIFT
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
    drw-x !

    \ y
    \ 0x00F0
    DUP 240 AND 4 RSHIFT
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
    drw-y !

    \ n
    \ 0x000F
    15 AND

    HEX
    \ memory of ROM starts from 0x200
    I0Reg @ 512 -
    S>D file-id @ REPOSITION-FILE THROW

    0 DO
        opcode-buffer 1 file-id @ READ-FILE THROW DROP

        opcode-buffer C@ 128 AND drw-y @ drw-x @ 0 +
        pixel!

        opcode-buffer C@ 64 AND drw-y @ drw-x @ 1 +
        pixel!

        opcode-buffer C@ 32 AND drw-y @ drw-x @ 2 +
        pixel!

        opcode-buffer C@ 16 AND drw-y @ drw-x @ 3 +
        pixel!

        opcode-buffer C@ 8 AND drw-y @ drw-x @ 4 +
        pixel!

        opcode-buffer C@ 4 AND drw-y @ drw-x @ 5 +
        pixel!

        opcode-buffer C@ 2 AND drw-y @ drw-x @ 6 +
        pixel!

        opcode-buffer C@ 1 AND drw-y @ drw-x @ 7 +
        pixel!

        drw-y @ 1+ drw-y !
    LOOP

    DECIMAL
;

: execute-opcode
    opcode-buffer @

    \ 0xF000
    DUP 61440 AND 12 RSHIFT
    CR ." DEBUG: Command : " DUP .

    CASE
        0  OF CR ." 0 Prefix - not implemented" ENDOF
        1  OF 12-rightmost call-jump DROP ENDOF
        2  OF CR ." 2 Prefix - not implemented" ENDOF
        3  OF CR ." 3 Prefix - not implemented" ENDOF
        4  OF CR ." 4 Prefix - not implemented" ENDOF
        5  OF CR ." 5 Prefix - not implemented" ENDOF
        6  OF 12-rightmost call-LDV PC @ 2 + PC ! DROP ENDOF
        7  OF CR ." 7 Prefix - not implemented" ENDOF
        8  OF CR ." 8 Prefix - not implemented" ENDOF
        9  OF CR ." 9 Prefix - not implemented" ENDOF
        10 OF 12-rightmost call-LDI PC @ 2 + PC ! DROP ENDOF
        11 OF CR ." B Prefix - not implemented" ENDOF
        12 OF CR ." C Prefix - not implemented" ENDOF
        13 OF 12-rightmost call-DRV PC @ 2 + PC ! DROP ENDOF
        14 OF CR ." E Prefix - not implemented" ENDOF
        15 OF 12-rightmost call-FResolve PC @ 2 + PC ! DROP ENDOF
    ENDCASE
;

: to-big-endian ( addr -- )
    DUP
    C@ 8 LSHIFT
    SWAP 1+ C@ OR
;

: to-big-endian-opcode
    opcode-buffer to-big-endian
    opcode-buffer !
;

: read-opcode ( addr -- )
    S>D file-id @ REPOSITION-FILE THROW

    opcode-buffer 2 file-id @ READ-FILE
    0 <> THROW
    2 <> THROW
;

: print-registers
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

: app-loop
    BEGIN
        HEX
        CR
        CR ." DEBUG: PC:" 5 SPACES PC @ .
        print-registers

        PC @ read-opcode
        to-big-endian-opcode

        CR CR ." DEBUG: OC:" 5 SPACES opcode-buffer @ .
        CR

        CR ." STACK: " .S
        print-screen
        DECIMAL

        CR ." ============================================"
        CR ." DEBUG: Press to execute" CR
        KEY DROP

        execute-opcode
    AGAIN
;

0 PC !

S" samples/octojam8title.ch8" R/O BIN OPEN-FILE THROW
file-id !
file-id @ ." DEBUG: file id: " . CR CR

frame-buffer 2048 0 FILL
app-loop
