%include "io64.inc"
%define R_Channels R8
%define R_Width R9
%define R_Height R10
%define R_X R11
%define R_Y R12
%define R_C R13
%define R_I R14
%define R_J R15
%define WINDOW_SIZE 3

section .data
    msg db 'Hello, world!', 0
    floats db 1, 2, 3, 4, 5, 6, 7, 69, 9, 10, 12, 13, 14, 15, 16
    temp dd 0.0, 0.0, 0.0, 0.0

section .text
    global CMAIN
CMAIN:
    mov rbp, rsp; for correct debugging
    call mediana
    
    mov rbp, rsp
    PRINT_STRING msg
    NEWLINE
    xor rax, rax
    ret
    
filter:
    
    xor R_C, R_C
    channelsLoop:
        
        xor R_Y, R_Y
        columnLoop:
        
            xor R_X, R_X
            rowLoop:
            
                %assign i 0
                %rep 9
                
                mov R_I, R_X
                sub R_I, WINDOW_SIZE / 2 + i % WINDOW_SIZE
                
                call clampI_procedure
                
                mov R_J, R_Y
                sub R_J, WINDOW_SIZE / 2 + i / WINDOW_SIZE
                
                call clampJ_procedure

                ;obliczanie adresu aktualnego bajtu
                mov rax, R_Width
                mul R_J
                add rax, R_I
                mul R_Channels
                add rax, R_C
                add rax, RSI
                
                mov al, [rax]
                pinsrb xmm0, al, i
                
                
                %assign i i+1
                %endrep
                
            inc R_X
            cmp R_X, R_Width
            jne rowLoop
        
        inc R_Y
        cmp R_Y, R_Height
        jne columnLoop
        
    ;koniec pętli po kanałach
    inc R_C
    cmp R_C, R_Channels
    jne channelsLoop
ret

clampI_procedure:
                cmp  R_I, R_Width
	        jae  clampI
	        clampI_finished:
ret

clampJ_procedure:
                cmp  R_J, R_Height
	        jae  clampJ
	        clampJ_finished:
ret

clampI:   
    ;flagi ustawione w cmp rax, r12

    mov ebx, 0 ;mov aby zachowac flagi

    lea    R_I, [R_Width - 1]  ;nie zmienia flag
    cmovl  R_I, rbx     ; rax=0 jesli POPRZEDNI rax < R_srcWidth. 
jmp  clampI_finished

clampJ:   
    mov ebx, 0        
    lea    R_J, [R_Height - 1]
    cmovl  R_J, rbx
jmp  clampJ_finished
    
mediana: 
    movups xmm0, [floats]
    movaps xmm2, xmm0
    
    ;max w pierwszym bajcie xmm0
    movhlps xmm1, xmm0         
    pmaxub xmm0, xmm1
    pshufd  xmm1, xmm0, 0b01010101
    pmaxub xmm0, xmm1
    pshuflw xmm1, xmm0, 0b01010101
    pmaxub xmm0, xmm1
    pextrb rax, xmm0, 1
    pinsrb xmm1, al, 0
    pmaxub xmm0, xmm1
    
    ;max w calym wektorze
    pextrb rax, xmm0, 0
    pinsrb xmm0, al, 1
    pshuflw xmm0, xmm0, 0b00000000
    pshufd xmm0, xmm0, 0b00000000
    
    ;wyzeruj max element w xmm0
    pcmpeqb xmm0, xmm2
    pandn xmm0, xmm2
    
    
    
    movups [floats], xmm0
    ret