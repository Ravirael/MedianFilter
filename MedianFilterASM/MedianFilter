%include "io64.inc"

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