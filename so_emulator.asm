section .bss

cpu_state: resb 8

section .text

global push_state_to_rax:
push_state_to_rax:
    ; przy okazji zapisuje też stan w zmiennej cpu_state
    push rbx ; bo będziemy z niego korzystać
    mov rax, 0
    add rax, r10b ; dodajemy wartość A na koniec
    shl rax, 8 ; przesuwamy wartość A
    add rax, r11b ; wartość D
    shl rax, 8
    add rax, r12b ; wartość X
    shl rax, 8
    add rax, r13b ; wartość Y
    shl rax, 8
    add rax, r14b ; wartość PC
    shl rax, 16 ; bo jeszcze unused tu jest
    ; jeszcze z i c - trzymamy je oba w r15w 
    ; w r15b jest z a w r15w\r15b jest c
    add rax, r15b ; wartość z
    shl rax, 8 
    mov r15b, 0
    shr r15w, 8 ; teraz w r15b jest c
    add rax, r15b ; wartość c
    mov [cpu_state], rax ; przenosimy żeby mieć na następne wywołania
    pop rbx
    ret
