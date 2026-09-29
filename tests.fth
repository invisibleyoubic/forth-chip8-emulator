REQUIRE test/ttester.fs
INCLUDE emulator.fth

VARIABLE TESTS
VARIABLE FAILURES
VARIABLE TEST_FAILED

0 TESTS !
0 FAILURES !
0 TEST_FAILED !

: TEST_SETUP
    RAM_MEMORY 4096 0 FILL
    load_sprites
    INS_00E0

    $200 PC!
    0 IREG!
    0 DelayTimer!
    0 SoundTimer!

    $10 0 DO
        0 I VREG!
    LOOP
;

: TEST_ERROR ( addr len -- )
    2DROP

    TEST_FAILED @ 0= IF
        1 FAILURES +!
        TRUE TEST_FAILED !
    THEN

    EMPTY-STACK
;

' TEST_ERROR ERROR-XT !

: TEST: ( name -- )
    1 TESTS +!
    FALSE TEST_FAILED !

    TEST_SETUP

    ." TEST "
    PARSE-NAME TYPE
    ."  ... "
;

: TEST_END ( -- )
    TEST_FAILED @ IF
        ." [FAIL]"
    ELSE
        ." [ OK ]"
    THEN
    CR
;

: TEST_SUMMARY ( -- )
    CR
    ." ====================" CR
    ." Tests:  " TESTS @ . CR
    ." Passed: " TESTS @ FAILURES @ - . CR
    ." Failed: " FAILURES @ . CR
    ." ====================" CR
;

: PUSH_VREGS ( -- v0 v1 ... vf )
    $10 0 DO
        I VREG@
    LOOP
;

: PUSH_PIXELS ( -- pixel0 pixel1 ... pixel2047 )
    32 0 DO
        64 0 DO
            J I PIXEL@
        LOOP
    LOOP
;

: PUSH_STACK ( value count -- values )
    0 DO
        DUP
    LOOP
    DROP
;

\ =========== tests ==============

\ setup tests
TEST: test_v_regs_setup
T{
    PUSH_VREGS ->   0 0 0 0 
                    0 0 0 0 
                    0 0 0 0 
                    0 0 0 0
}T
TEST_END

TEST: test_i_reg_setup
T{
    IREG@ -> 0
}T
TEST_END

TEST: test_pc_setup
T{
    PC@ -> $200
}T
TEST_END

TEST: test_timers_setup
T{
    DelayTimer@ SoundTimer@ -> 0 0
}T
TEST_END

\ workflow tests
TEST: test_pc_flow
T{
    NEXT_INS! PC@ 
    PREV_INS! PC@ -> $202 $200
}T
TEST_END

TEST: test_x
T{
    $1234 X -> $02
}T
TEST_END

TEST: test_x!
T{
    $C $1234 X! $2 VREG@ -> $C
}T
TEST_END

TEST: test_x@
T{
    $D $2 VREG! $1234 X@ -> $D
}T
TEST_END

TEST: test_y
T{
    $1234 Y -> $003
}T
TEST_END

TEST: test_y!
T{
    $C $1234 Y! $3 VREG@ -> $C
}T
TEST_END

TEST: test_y@
T{
    $D $3 VREG! $1234 Y@ -> $D
}T
TEST_END

\ instructions tests

TEST: test_0nnn
T{
    $0555 exec_opcode
    PC@ -> $555 2 -
}T
TEST_END

\ test_00E0

TEST: test_00EE
T{
    $0555 $00EE exec_opcode 
    PC@ -> $555
}T
TEST_END

TEST: test_1nnn
T{
    $1555 exec_opcode 
    PC@ -> $555 2 -
}T
TEST_END

TEST: test_2nnn
T{
    $0222 PC!
    $2555 exec_opcode 
    PC@ -> $0222 $555 2 -
}T
TEST_END

TEST: test_3xkk_1
T{
    $6 $0 VREG! $3006 exec_opcode 
    PC@ -> $0202
}T
TEST_END

TEST: test_3xkk_2
T{
    $7 $0 VREG! $3006 exec_opcode 
    PC@ -> $0200
}T
TEST_END

TEST: test_3xkk_3
T{
    $7 $F VREG! $3F06 exec_opcode 
    PC@ -> $0200
}T
TEST_END

TEST: test_3xkk_4
T{
    $6 $F VREG! $3F06 exec_opcode 
    PC@ -> $0202
}T
TEST_END

TEST: test_4xkk_1
T{
    $6 $0 VREG! $4006 exec_opcode 
    PC@ -> $0200
}T
TEST_END

TEST: test_4xkk_2
T{
    $7 $F VREG! $4006 exec_opcode 
    PC@ -> $0202
}T
TEST_END

TEST: test_4xkk_3
T{
    $6 $F VREG! $4F06 exec_opcode 
    PC@ -> $0200
}T
TEST_END

TEST: test_4xkk_4
T{
    $7 $F VREG! $4F06 exec_opcode 
    PC@ -> $0202
}T
TEST_END

TEST: test_5xy0_1
T{
    $6 $F VREG! $7 $0 VREG! $5F00 exec_opcode
    PC@ -> $0200
}T
TEST_END

TEST: test_5xy0_2
T{
    $6 $F VREG! $6 $0 VREG! $5F00 exec_opcode
    PC@ -> $0202
}T
TEST_END

TEST: test_5xy0_3
T{
    $6 $F VREG! $7 $0 VREG! $50F0 exec_opcode
    PC@ -> $0200
}T
TEST_END

TEST: test_5xy0_4
T{
    $6 $F VREG! $6 $0 VREG! $50F0 exec_opcode
    PC@ -> $0202
}T
TEST_END

TEST: test_6xkk
T{
    $6010 exec_opcode
    $6111 exec_opcode
    $6212 exec_opcode
    $6313 exec_opcode
    $6414 exec_opcode
    $6515 exec_opcode
    $6616 exec_opcode
    $6717 exec_opcode
    $6818 exec_opcode 
    $6919 exec_opcode
    $6A20 exec_opcode
    $6B21 exec_opcode
    $6C22 exec_opcode
    $6D23 exec_opcode
    $6E24 exec_opcode
    $6F25 exec_opcode 
    PUSH_VREGS -> $10 $11 $12 $13
                  $14 $15 $16 $17
                  $18 $19 $20 $21
                  $22 $23 $24 $25
}T
TEST_END

TEST: test_7xkk
T{
    $10 $0 VREG! $7010 exec_opcode
    $10 $1 VREG! $7111 exec_opcode
    $10 $2 VREG! $7212 exec_opcode
    $10 $3 VREG! $7313 exec_opcode
    $10 $4 VREG! $7414 exec_opcode
    $10 $5 VREG! $7515 exec_opcode
    $10 $6 VREG! $7616 exec_opcode
    $10 $7 VREG! $7717 exec_opcode
    $10 $8 VREG! $7818 exec_opcode 
    $10 $9 VREG! $7919 exec_opcode
    $10 $A VREG! $7A20 exec_opcode
    $10 $B VREG! $7B21 exec_opcode
    $10 $C VREG! $7C22 exec_opcode
    $10 $D VREG! $7D23 exec_opcode
    $10 $E VREG! $7E24 exec_opcode
    $10 $F VREG! $7F25 exec_opcode 
    PUSH_VREGS -> $20 $21 $22 $23
                  $24 $25 $26 $27
                  $28 $29 $30 $31
                  $32 $33 $34 $35
}T
TEST_END

TEST: test_8xy0_1
T{
    $FF $0 VREG! $8F00 exec_opcode 
    $F VREG@ $0 VREG@ -> $FF $FF
}T
TEST_END

TEST: test_8xy0_2
T{
    $FF $F VREG! $80F0 exec_opcode 
    $0 VREG@ $F VREG@ -> $FF $FF
}T
TEST_END

TEST: test_8xy1
T{
    %0101 $0 VREG!
    %1010 $F VREG! 
    $8F01 exec_opcode 
    $F VREG@ $0 VREG@ -> %1111 %0101
}T
TEST_END

TEST: test_8xy2
T{
    %0101 $0 VREG!
    %1110 $F VREG! 
    $8F02 exec_opcode 
    $F VREG@ $0 VREG@ -> %0100 %0101
}T
TEST_END

TEST: test_8xy3
T{
    %0101 $0 VREG!
    %1100 $F VREG! 
    $8F03 exec_opcode 
    $F VREG@ $0 VREG@ -> %1001 %0101
}T
TEST_END

TEST: test_8xy4_1
T{
    $A $0 VREG!
    $B $E VREG! 
    $8E04 exec_opcode 
    $E VREG@ $0 VREG@ $F VREG@ -> $15 $A 0
}T
TEST_END

TEST: test_8xy4_2
T{
    $FF $0 VREG!
    $FF $E VREG! 
    $8E04 exec_opcode 
    $E VREG@ $0 VREG@ $F VREG@ -> $FE $FF 1
}T
TEST_END

TEST: test_8xy4_3
T{
    $FF $0 VREG!
    $00 $E VREG! 
    $8E04 exec_opcode 
    $E VREG@ $0 VREG@ $F VREG@ -> $FF $FF 0
}T
TEST_END

TEST: test_8xy4_3
T{
    $1 $0 VREG!
    $FF $E VREG! 
    $8E04 exec_opcode 
    $E VREG@ $0 VREG@ $F VREG@ -> $00 $1 1
}T
TEST_END

TEST: test_8xy5_1
T{
    $A $0 VREG!
    $B $E VREG! 
    $8E05 exec_opcode 
    $E VREG@ $0 VREG@ $F VREG@ -> 1 $A 1
}T
TEST_END

TEST: test_8xy5_2
T{
    $B $0 VREG!
    $9 $E VREG! 
    $8E05 exec_opcode 
    $E VREG@ $0 VREG@ $F VREG@ -> $FE $B 0
}T
TEST_END

TEST: test_8xy5_3
T{
    $B $0 VREG!
    $B $E VREG! 
    $8E05 exec_opcode 
    $E VREG@ $0 VREG@ $F VREG@ -> 0 $B 0
}T
TEST_END

TEST: test_8xy5_4
T{
    $FF $0 VREG!
    $00 $E VREG! 
    $8E05 exec_opcode 
    $E VREG@ $0 VREG@ $F VREG@ -> 1 $FF 0
}T
TEST_END

TEST: test_8xy6_1
T{
    %11111110 $E VREG!
    $8E06 exec_opcode
    $E VREG@ $F VREG@ -> %11111110 2 / 0
}T
TEST_END

TEST: test_8xy6_2
T{
    %11111111 $E VREG!
    $8E06 exec_opcode
    $E VREG@ $F VREG@ -> %11111111 2 / 1
}T
TEST_END

TEST: test_8xy6_3
T{
    $1 $E VREG!
    $8E06 exec_opcode
    $E VREG@ $F VREG@ -> $1 2 / 1
}T
TEST_END

TEST: test_8xy6_4
T{
    $0 $E VREG!
    $8E06 exec_opcode
    $E VREG@ $F VREG@ -> $0 2 / 0
}T
TEST_END

TEST: test_8xy7_1
T{
    $A $0 VREG!
    $B $E VREG!
    $80E7 exec_opcode 
    $0 VREG@ $E VREG@ $F VREG@ -> 1 $B 1
}T
TEST_END

TEST: test_8xy7_2
T{
    $B $0 VREG!
    $9 $E VREG! 
    $80E7 exec_opcode 
    $0 VREG@ $E VREG@ $F VREG@ -> $FE $9 0
}T
TEST_END

TEST: test_8xy7_3
T{
    $B $0 VREG!
    $B $E VREG! 
    $80E7 exec_opcode 
    $0 VREG@ $E VREG@ $F VREG@ -> 0 $B 0
}T
TEST_END

TEST: test_8xy7_4
T{
    $FF $0 VREG!
    $00 $E VREG! 
    $80E7 exec_opcode 
    $0 VREG@ $E VREG@ $F VREG@ -> 1 $00 0
}T
TEST_END

TEST: test_8xyE_1
T{
    %01111111 $E VREG!
    $8E0E exec_opcode
    $E VREG@ $F VREG@ -> %01111111 2 * 0
}T
TEST_END

TEST: test_8xyE_2
T{
    %10000000 $E VREG!
    $8E0E exec_opcode
    $E VREG@ $F VREG@ -> $10000000 2 * $FF AND 1
}T
TEST_END

TEST: test_8xyE_3
T{
    $1 $E VREG!
    $8E0E exec_opcode
    $E VREG@ $F VREG@ -> $1 2 * 0
}T
TEST_END

TEST: test_8xyE_4
T{
    $0 $E VREG!
    $8E0E exec_opcode
    $E VREG@ $F VREG@ -> $0 2 * 0
}T
TEST_END

TEST: test_9xy0_1
T{
    $6 $F VREG! $7 $0 VREG! $9F00 exec_opcode
    PC@ -> $0202
}T
TEST_END

TEST: test_9xy0_2
T{
    $6 $F VREG! $6 $0 VREG! $9F00 exec_opcode
    PC@ -> $0200
}T
TEST_END

TEST: test_9xy0_3
T{
    $6 $F VREG! $7 $0 VREG! $90F0 exec_opcode
    PC@ -> $0202
}T
TEST_END

TEST: test_9xy0_4
T{
    $6 $F VREG! $6 $0 VREG! $90F0 exec_opcode
    PC@ -> $0200
}T
TEST_END

TEST: test_Annn
T{
    $A123 exec_opcode IREG@ -> $123
}T
TEST_END

TEST: test_Bnnn
T{
    $10 $0 VREG! $B123 exec_opcode PC@ -> $131
}T
TEST_END

\ test_Cxkk

\ test_Dxyn

\ test_Ex9E

\ test_ExA1

TEST: test_Fx07
T{
    $23 DelayTimer!
    $F507 exec_opcode
    $5 VREG@ -> $23
}T
TEST_END

\ test_Fx0A

TEST: test_Fx15
T{
    $23 $5 VREG!
    $F515 exec_opcode
    DelayTimer@ -> $23
}T
TEST_END

TEST: test_Fx18
T{
    $26 $6 VREG!
    $F618 exec_opcode
    SoundTimer@ -> $26
}T
TEST_END

TEST: test_Fx1E
T{
    $15 IREG!
    $26 $A VREG!
    $FA1E exec_opcode
    IREG@ -> $26 $15 +
}T
TEST_END

\ TODO
TEST: test_Fx29
T{
    $1 -> $0
}T
TEST_END

\ I'm not sure
\ TEST: test_Fx33_1
\ T{
\     234 $B VREG!
\     $FB33 exec_opcode
\     IREG DUP 0 + C@
\     SWAP DUP 1 + C@
\     SWAP DUP 2 + C@
\     SWAP DROP -> 2 3 4
\ }T
\ TEST_END

\ TEST: test_Fx33_2
\ T{
\     067 $B VREG!
\     $FB33 exec_opcode
\     IREG DUP 0 + C@
\     SWAP DUP 1 + C@
\     SWAP DUP 2 + C@
\     SWAP DROP -> 0 6 7
\ }T
\ TEST_END

\ TEST: test_Fx33_3
\ T{
\     240 $B VREG!
\     $FB33 exec_opcode
\     IREG DUP 0 + C@
\     SWAP DUP 1 + C@
\     SWAP DUP 2 + C@
\     SWAP DROP -> 2 4 0
\ }T
\ TEST_END

TEST: test_Fx33_1
T{
    234 $B VREG!
    $300 IREG!
    $FB33 exec_opcode
    RAM_MEMORY $300 + C@
    RAM_MEMORY $301 + C@
    RAM_MEMORY $302 + C@ -> 2 3 4
}T
TEST_END

TEST: test_Fx33_2
T{
    067 $B VREG!
    $300 IREG!
    $FB33 exec_opcode
    RAM_MEMORY $300 + C@
    RAM_MEMORY $301 + C@
    RAM_MEMORY $302 + C@ -> 0 6 7
}T
TEST_END

TEST: test_Fx33_3
T{
    240 $B VREG!
    $300 IREG!
    $FB33 exec_opcode
    RAM_MEMORY $300 + C@
    RAM_MEMORY $301 + C@
    RAM_MEMORY $302 + C@ -> 2 4 0
}T
TEST_END

\ TODO:;
\ TEST: test_Fx55
\ T{
\     $1 -> $0
\ }T
\ TEST_END

\ TODO:
\ TEST: test_Fx65
\ T{
\     $1 -> $0
\ }T
\ TEST_END

TEST_SUMMARY