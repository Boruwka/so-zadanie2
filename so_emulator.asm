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


global get_value_from_register_code:
get_value_from_register_code:
    ; otrzymujemy register code w dil (odpowiedniku rdi)
    ; w rsi mamy data
    ; a zwracamy w al
    
    mov al, r10b 
    cmp dil, 0
    je get_value_from_register_code_exit

    mov al, r11b 
    cmp dil, 1
    je get_value_from_register_code_exit

    mov al, r12b 
    cmp dil, 2
    je get_value_from_register_code_exit

    mov al, r13b 
    cmp dil, 3
    je get_value_from_register_code_exit

    mov r8, rsi
    add r8b, r12b ; data + x
    mov al, [r8] ; [x] czyli [data+x]
    cmp dil, 4
    je get_value_from_register_code_exit

    mov r8, rsi
    add r8b, r13b ; data + y
    jno .no_overflow_1
    add r8, 0x100
    .no_overflow_1: 
    mov al, [r8] ; [y] czyli [data+y]
    cmp dil, 5
    je get_value_from_register_code_exit

    mov r8, rsi
    add r8b, r12b ; data + x
    jno .no_overflow_2
    add r8, 0x100
    .no_overflow_2: 
    add r8b, r11b ; + d
    jno .no_overflow_3
    add r8, 0x100
    .no_overflow_3: 
    mov al, [r8] ; [x+d] czyli [data+x+d]
    cmp dil, 6
    je get_value_from_register_code_exit

    mov r8, rsi
    add r8b, r13b ; data + y
    jno .no_overflow_4
    add r8, 0x100
    .no_overflow_4: 
    add r8b, r11b ; + d
    jno .no_overflow_5
    add r8, 0x100
    .no_overflow_5: 
    mov al, [r8] ; [y+d] czyli [data+y+d]
    cmp dil, 7
    je get_value_from_register_code_exit

    get_value_from_register_code_exit:
        ret 

global execute_mov:
execute_mov:
    ; dostajemy jako argumenty kody rejestrów
    ; w dil i sil
    ; w rdx mamy data
    push rdi
    push rsi
    push rdx
    mov dil, sil ; przekazujemy argument dla funkcji get_value_from_register_code
    mov rsi, rdx
    call get_value_from_register_code
    pop rdx
    pop rsi
    pop rdi
    ; teraz musimy do rejestru o kodzie dil dać wartość w al

    mov r10b, al
    cmp dil, 0
    je execute_mov_exit
    ; jmp execute_mov_exit ; tylko do debugu ta linijka

    mov r11b, al
    cmp dil, 1
    je execute_mov_exit

    mov r12b, al
    cmp dil, 2
    je execute_mov_exit

    mov r13b, al
    cmp dil, 3
    je execute_mov_exit

    mov r8, rdx
    add r8b, r12b ; data + x
    mov [r8], al ; [x] czyli [data+x]
    cmp dil, 4
    je execute_mov_exit

    mov r8, rsi
    add r8b, r13b ; data + y
    jno .no_overflow_1
    add r8, 0x100
    .no_overflow_1: 
    mov [r8], al ; [y] czyli [data+y]
    cmp dil, 5
    je execute_mov_exit

    mov r8, rdx
    add r8b, r12b ; data + x
    jno .no_overflow_2
    add r8, 0x100
    .no_overflow_2: 
    add r8b, r11b ; + d
    jno .no_overflow_3
    add r8, 0x100
    .no_overflow_3: 
    mov [r8], al ; [x+d] czyli [data+x+d]
    cmp dil, 6
    je execute_mov_exit

    mov r8, rdx
    add r8b, r13b ; data + y
    jno .no_overflow_4
    add r8, 0x100
    .no_overflow_4: 
    add r8b, r11b ; + d
    jno .no_overflow_5
    add r8, 0x100
    .no_overflow_5: 
    mov [r8], al ; [y+d] czyli [data+y+d]
    cmp dil, 7
    je execute_mov_exit

    execute_mov_exit:
        ret

global testowa:
testowa: 
; przestrzega abi
; wywołuje inne funkcje
; w rdi dostaje data
; w rax zwraca co chcemy
push r12
push r13
call push_state_to_registers
mov rdx, rdi ; data
mov dil, 0
mov sil, 4
call execute_mov
mov al, r10b
; call push_state_to_rax
;mov dil, 4 
;pop rsi
;call get_value_from_register_code
pop r13
pop r12
ret
