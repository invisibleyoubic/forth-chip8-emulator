require test/ttester.fs

VARIABLE TESTS
VARIABLE FAILURES
VARIABLE TEST_FAILED

0 TESTS !
0 FAILURES !
0 TEST_FAILED !

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


\ =========== tests ==============

TEST: test_1

T{
    1 2 + -> 5
}T

TEST_END


TEST: test_2

T{
    1 2 + -> 3
}T

TEST_END

TEST_SUMMARY