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

: 12-rightmost
    \ 0x0FFF
    DUP 4095 AND
;

: call-jump
    HEX
    CR ." DEBUG: Jump addres: " DUP .
    DECIMAL

    PC !
    DROP
;

: call-LDI
    I0Reg !
;

: call-LDV
    \ 0x0F00
    DUP 3840 AND 8 RSHIFT

    HEX
    CR ." DEBUG: V register number: " DUP .
    DECIMAL

    CASE
        0  OF 255 AND V0Reg ! ENDOF
        1  OF 255 AND V1Reg ! ENDOF
        2  OF 255 AND V2Reg ! ENDOF
        3  OF 255 AND V3Reg ! ENDOF
        4  OF 255 AND V4Reg ! ENDOF
        5  OF 255 AND V5Reg ! ENDOF
        6  OF 255 AND V6Reg ! ENDOF
        7  OF 255 AND V7Reg ! ENDOF
        8  OF 255 AND V8Reg ! ENDOF
        9  OF 255 AND V9Reg ! ENDOF
        10 OF 255 AND VAReg ! ENDOF
        11 OF 255 AND VBReg ! ENDOF
        12 OF 255 AND VCReg ! ENDOF
        13 OF 255 AND VDReg ! ENDOF
        14 OF 255 AND VEReg ! ENDOF
        15 OF 255 AND VFReg ! ENDOF
    ENDCASE
;

: execute-opcode
    opcode-buffer @

    \ 0xF000
    DUP 61440 AND 12 RSHIFT
    CR ." DEBUG: Command : " DUP .

    CASE
        0  OF CR ." 0 Prefix - not implemented" ENDOF
        1  OF 12-rightmost call-jump ENDOF
        2  OF CR ." 2 Prefix - not implemented" ENDOF
        3  OF CR ." 3 Prefix - not implemented" ENDOF
        4  OF CR ." 4 Prefix - not implemented" ENDOF
        5  OF CR ." 5 Prefix - not implemented" ENDOF
        6  OF 12-rightmost call-LDV PC @ 2 + PC ! ENDOF
        7  OF CR ." 7 Prefix - not implemented" ENDOF
        8  OF CR ." 8 Prefix - not implemented" ENDOF
        9  OF CR ." 9 Prefix - not implemented" ENDOF
        10 OF 12-rightmost call-LDI PC @ 2 + PC ! ENDOF
        11 OF CR ." B Prefix - not implemented" ENDOF
        12 OF CR ." C Prefix - not implemented" ENDOF
        13 OF CR ." D Prefix - not implemented" ENDOF
        14 OF CR ." E Prefix - not implemented" ENDOF
        15 OF CR ." F Prefix - not implemented" ENDOF
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

app-loop
