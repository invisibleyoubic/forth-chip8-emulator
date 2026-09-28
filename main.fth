INCLUDE emulator.fth 

: MAIN 
    RAM_MEMORY 4096 0 FILL
    load_sprites
    NEXT-ARG load_rom
    INS_00E0
    main_loop
;

MAIN