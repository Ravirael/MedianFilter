;%include "io64.inc"
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
    MASK times 16 db 1
    x0 times 16 db 0
    x1 times 16 db 0
    x2 times 16 db 0
    x3 times 16 db 0
    temp dd 0.0, 0.0, 0.0, 0.0
    src db 1, 2, 3, 4, \
           5, 6, 7, 8, \
           9, 10, 11, 12, \
           13, 14, 15, 16
    dst times 16 db 0

section .text
    global main
main:
    mov rbp, rsp; for correct debugging
    push rbp
    mov rbp, rsp; for correct debugging
        
    mov R_Width, 4
    mov R_Height, 4
    mov R_Channels, 1
    mov rsi, src
    mov rdi, dst
    
    call filter    
    
    ;PRINT_STRING msg
    ;NEWLINE
    xor rax, rax
    pop rbp
    ret
    
filter:
    push rbp
    mov rbp, rsp; for correct debugging

    xor R_C, R_C
    channelsLoop:
        
        xor R_Y, R_Y
        columnLoop:
        
            xor R_X, R_X
            rowLoop:

                call add_to_window
                movups [x0], xmm0  
                
                mov rcx, 0
                call mediana
                cmp rcx, 5
                jge median_ready
                call mediana
                cmp rcx, 5
                jge median_ready
                call mediana
                cmp rcx, 5
                jge median_ready
                call mediana
                cmp rcx, 5
                jge median_ready
                call mediana
                
            median_ready:
                mov bl, al
                
                mov rax, R_Width
                mul R_Y
                add rax, R_X
                mul R_Channels
                add rax, R_C
                add rdi, rax
                
                mov [rdi], bl
                sub rdi, rax
                
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
    
    pop rbp
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
    ;movups xmm0, [floats]
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
    
    ;zliczanie ilość wystąpień maksa - ilosc w cl
    pcmpeqb xmm0, xmm2
    movups [x0], xmm0
    
    movaps xmm1, xmm0
    movups [x1], xmm1
    movups xmm3, [MASK]
    movups [x3], xmm3
    pand xmm1, xmm3
    movups [x1], xmm1
    pxor xmm3, xmm3
    psadbw xmm1, xmm3
    movups [x1], xmm1 
    movups [x3], xmm3 

    pextrb rdx, xmm1, 0
    add rcx, rdx
    pextrb rdx, xmm1, 8
    add rcx, rdx    
    ;wyzeruj max elementy w xmm0
    pandn xmm0, xmm2
    
        
    movups [x0], xmm0
ret
    
    add_to_window:
 ;zerujemy rejestr okna
            pxor xmm0, xmm0
                        
                %assign i 0
                %rep 9
                ;---------------------------------------------------
                mov R_I, R_X
                sub R_I, WINDOW_SIZE / 2
                add R_I, i % WINDOW_SIZE
                
                call clampI_procedure
                
                mov R_J, R_Y
                sub R_J, WINDOW_SIZE / 2 
                add R_J, i / WINDOW_SIZE
                
                call clampJ_procedure

                ;obliczanie adresu aktualnego bajtu
                mov rax, R_Width
                mul R_J
                add rax, R_I
                mul R_Channels
                add rax, R_C
                add rsi, rax
                
                xor ebx, ebx
                mov bl, [rsi]
                sub rsi, rax
  
                pinsrb xmm0, bl, i
                
                %assign i i+1        
                
                %endrep
ret