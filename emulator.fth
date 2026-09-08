VARIABLE file-id

VARIABLE opcode-buffer

VARIABLE PC

: call-jump
    \ 0x0FFF
    DUP 4095 AND
    
    HEX
    CR ." DEBUG: Jump addres: " DUP .
    DECIMAL

    PC !
    DROP
;

: execute-opcode
    opcode-buffer @

    \ 0xF000
    DUP 61440 AND 12 RSHIFT
    CR ." DEBUG: Command : " DUP .

    CASE
        0  OF CR ." 0 Prefix - not implemented" ENDOF
        1  OF call-jump ENDOF
        2  OF CR ." 2 Prefix - not implemented" ENDOF
        3  OF CR ." 3 Prefix - not implemented" ENDOF
        4  OF CR ." 4 Prefix - not implemented" ENDOF
        5  OF CR ." 5 Prefix - not implemented" ENDOF
        6  OF CR ." 6 Prefix - not implemented" ENDOF
        7  OF CR ." 7 Prefix - not implemented" ENDOF
        8  OF CR ." 8 Prefix - not implemented" ENDOF
        9  OF CR ." 9 Prefix - not implemented" ENDOF
        10 OF CR ." A Prefix - not implemented" ENDOF
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

: app-loop
    BEGIN
        HEX
        CR
        CR ." DEBUG: PC: " PC @ .
        
        PC @ read-opcode
        to-big-endian-opcode

        CR ." DEBUG: Opcode byte: " opcode-buffer @ .
        CR
        DECIMAL


        KEY DROP
        CR ." DEBUG: Press to execute" CR

        execute-opcode
    AGAIN
;

0 PC !

S" samples/octojam8title.ch8" R/O BIN OPEN-FILE THROW
file-id !
file-id @ ." DEBUG: file id: " . CR CR

app-loop
