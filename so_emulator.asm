section .bss

cpu_state: resb 8

section .text

global push_state_to_rax:
push_state_to_rax:
    ; przy okazji zapisuje też stan w zmiennej cpu_state
    mov rax, 0
    add al, r10b ; dodajemy wartość A na koniec
    shl rax, 8 ; przesuwamy wartość A
    add al, r11b ; wartość D
    shl rax, 8
    add al, r12b ; wartość X
    shl rax, 8
    add al, r13b ; wartość Y
    shl rax, 8
    add al, r14b ; wartość PC
    shl rax, 16 ; bo jeszcze unused tu jest
    ; jeszcze z i c - trzymamy je oba w r15w 
    ; w r15b jest z a w r15w\r15b jest c
    add al, r15b ; wartość Z
    shl rax, 8 
    mov r15b, 0
    shr r15w, 8 ; teraz w r15b jest C
    add al, r15b ; wartość C
    mov [rel cpu_state], rax ; przenosimy żeby mieć na następne wywołania
    ret

global push_state_to_registers:
push_state_to_registers:
; na początku wywołania so_emul()
; bierze zamrożone cpu_state i kopiuje je do rejestrów
mov r10b, [rel cpu_state] ; wartość A
shr dword[rel cpu_state], 8
mov r11b, [rel cpu_state] ; wartość D
shr dword[rel cpu_state], 8
mov r12b, [rel cpu_state] ; wartość X
shr dword[rel cpu_state], 8
mov r13b, [rel cpu_state], ; wartość Y
shr dword[rel cpu_state], 8
mov r14b, [rel cpu_state], ; wartość PC
shr dword[rel cpu_state], 16 ; bo jeszcze unused
mov r15b, [rel cpu_state] ; wartość Z
shl r15w, 8
shr dword[rel cpu_state], 8
mov r15b, [rel cpu_state] ; wartość C
ret 

