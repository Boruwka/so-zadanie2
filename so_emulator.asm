section .bss

cpu_state: resb 8

section .text

turn_register:
    ; dostaje rdi i w rax ma zwrócić odwrócony (w kolejności bitowej)
    push rbx
    mov rbx, 0
    mov rax, 0
    .loop:
        mov rcx, rdi
        shl rcx, 63
        shr rcx, 63
        ; teraz w rcx jest rdi mod 2
        add rax, rcx
        shl rax, 1
        shr rdi, 1
        inc rbx
        cmp rbx, 64
        jne .loop
    pop rbx
    ret

global push_state_to_rax:
push_state_to_rax:
    ; przy okazji zapisuje też stan w zmiennej cpu_state
    mov rax, 0
    add al, r15b ; wartość Z
    shl rax, 8 
    ; w r15b jest Z a w r15w\r15b jest C
    ; ustalmy to raz na zawsze
    mov r15b, 0
    shr r15w, 8 ; teraz w r15b jest C
    add al, r15b ; wartość C
    shl rax, 16 ; bo jeszcze unused
    add al, r14b ; wartość PC
    shl rax, 8
    add al, r13b ; wartość Y
    shl rax, 8
    add al, r12b ; wartość X
    shl rax, 8
    add al, r11b ; wartość D
    shl rax, 8 ;
    add al, r10b ;
    ; teraz obrócimy rax w drugą stronę, nwm po co, ale to działa
    push rdi
    mov rdi, rax
    ; call turn_register 
    pop rdi
    ; obrócone
    mov [rel cpu_state], rax ; przenosimy żeby mieć na następne wywołania
    ret

global push_state_to_registers:
push_state_to_registers:
; na początku wywołania so_emul()
; bierze zamrożone cpu_state i kopiuje je do rejestrów
; zeruje wcześniejsze części rejestrów, żeby nie było problemu
mov r10, 0
mov r11, 0
mov r12, 0
mov r13, 0
mov r14, 0
mov r15, 0
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
    add r8, r12 ; data + x
    mov [r8], al ; [x] czyli [data+x]
    cmp dil, 4
    je execute_mov_exit

    mov r8, rsi
    add r8, r13 ; data + y
    mov [r8], al ; [y] czyli [data+y]
    cmp dil, 5
    je execute_mov_exit

    mov r8, rdx
    add r8, r12 ; data + x
    add r8, r11 ; + d
    mov [r8], al ; [x+d] czyli [data+x+d]
    cmp dil, 6
    je execute_mov_exit

    mov r8, rdx
    add r8, r13 ; data + y
    add r8, r11 ; + d
    mov [r8], al ; [y+d] czyli [data+y+d]
    cmp dil, 7
    je execute_mov_exit

    execute_mov_exit:
        ret

global execute_or:
execute_or:
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

    or r10b, al
    pushf
    cmp dil, 0
    je execute_or_exit
    popf

    or r11b, al
    pushf
    cmp dil, 1
    je execute_or_exit
    popf

    or r12b, al
    pushf
    cmp dil, 2
    je execute_or_exit

    or r13b, al
    pushf
    cmp dil, 3
    je execute_or_exit
    popf

    mov r8, rdx
    add r8, r12 ; data + x
    or [r8], al ; [x] czyli [data+x]
    pushf
    cmp dil, 4
    je execute_or_exit
    popf

    mov r8, rsi
    add r8, r13 ; data + y
    or [r8], al ; [y] czyli [data+y]
    pushf
    cmp dil, 5
    je execute_or_exit
    popf

    mov r8, rdx
    add r8, r12 ; data + x
    add r8, r11 ; + d
    or [r8], al ; [x+d] czyli [data+x+d]
    pushf
    cmp dil, 6
    je execute_or_exit
    popf

    mov r8, rdx
    add r8, r13 ; data + y
    add r8, r11 ; + d
    or [r8], al ; [y+d] czyli [data+y+d]
    pushf
    cmp dil, 7
    je execute_or_exit
    popf

    execute_or_exit:
        ; mov al, r15b ; to do ustawiania C będzie
        mov r15b, 0
        popf 
        jnz .no_zero ; Z się nie ustawiło w or
        mov r15b, 1
        .no_zero:
        ; teraz w r15b mamy wynik, a chcemy go w r15w\r15b
        ; shl r15w, 8 ; to do ustawiania C będzie
        ; mov r15b, al ; przywracamy wartość C, ; to do ustawiania C będzie
        ret

global execute_add:
execute_add:
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

    add r10b, al
    pushf
    cmp dil, 0
    je execute_add_exit
    popf

    add r11b, al
    pushf
    cmp dil, 1
    je execute_add_exit
    popf

    add r12b, al
    pushf
    cmp dil, 2
    je execute_add_exit
    popf

    add r13b, al
    pushf
    cmp dil, 3
    je execute_add_exit
    popf

    mov r8, rdx
    add r8, r12 ; data + x
    add [r8], al ; [x] czyli [data+x]
    pushf
    cmp dil, 4
    je execute_add_exit
    popf

    mov r8, rsi
    add r8, r13 ; data + y
    add [r8], al ; [y] czyli [data+y]
    pushf
    cmp dil, 5
    je execute_add_exit
    popf

    mov r8, rdx
    add r8, r12 ; data + x
    add r8, r11 ; + d
    add [r8], al ; [x+d] czyli [data+x+d]
    cmp dil, 6
    je execute_add_exit
    popf

    mov r8, rdx
    add r8, r13 ; data + y
    add r8, r11 ; + d
    add [r8], al ; [y+d] czyli [data+y+d]
    pushf
    cmp dil, 7
    je execute_add_exit
    popf

    execute_add_exit:
        mov r15b, 0
        popf 
        jnz .no_zero ; Z się nie ustawiło w or
        mov r15b, 1
        .no_zero:
        ret

global execute_sub:
execute_sub:
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

    sub r10b, al
    pushf
    cmp dil, 0
    je execute_sub_exit
    popf

    sub r11b, al
    pushf
    cmp dil, 1
    je execute_sub_exit
    popf

    sub r12b, al
    pushf
    cmp dil, 2
    je execute_sub_exit

    sub r13b, al
    pushf
    cmp dil, 3
    je execute_sub_exit
    popf

    mov r8, rdx
    add r8, r12 ; data + x
    sub [r8], al ; [x] czyli [data+x]
    pushf
    cmp dil, 4
    je execute_sub_exit

    mov r8, rsi
    add r8, r13 ; data + y
    sub [r8], al ; [y] czyli [data+y]
    pushf
    cmp dil, 5
    je execute_sub_exit
    popf

    mov r8, rdx
    add r8, r12 ; data + x
    add r8, r11 ; + d
    sub [r8], al ; [x+d] czyli [data+x+d]
    pushf
    cmp dil, 6
    je execute_sub_exit
    popf

    mov r8, rdx
    add r8, r13 ; data + y
    add r8, r11 ; + d
    sub [r8], al ; [y+d] czyli [data+y+d]
    pushf
    cmp dil, 7
    je execute_sub_exit
    popf

    execute_sub_exit:
        mov r15b, 0
        popf 
        jnz .no_zero ; Z się nie ustawiło w or
        mov r15b, 1
        .no_zero:
        ret

global execute_adc:
execute_adc:
    ; dostajemy jako argumenty kody rejestrów
    ; w dil i sil
    ; w rdx mamy data
    push rdi
    push rsi
    push rdx
    mov dil, sil ; przekazujemy argument dla funkcji get_value_from_register_code
    mov rsi, rdx
    call get_value_from_register_code
    add al, r15b ; dodajemy wartość C
    pop rdx
    pop rsi
    pop rdi
    ; teraz musimy do rejestru o kodzie dil dać wartość w al

    add r10b, al
    pushf
    pushf
    cmp dil, 0
    je execute_adc_exit
    popf
    popf

    add r11b, al
    pushf
    pushf
    cmp dil, 1
    je execute_adc_exit
    popf
    popf

    add r12b, al
    pushf
    pushf
    cmp dil, 2
    je execute_adc_exit
    popf
    popf

    add r13b, al
    pushf
    pushf
    cmp dil, 3
    je execute_adc_exit
    popf
    popf

    mov r8, rdx
    add r8, r12 ; data + x
    add [r8], al ; [x] czyli [data+x]
    pushf
    pushf
    cmp dil, 4
    je execute_adc_exit
    popf
    popf

    mov r8, rsi
    add r8, r13 ; data + y
    add [r8], al ; [y] czyli [data+y]
    pushf
    pushf
    cmp dil, 5
    je execute_adc_exit
    popf
    popf

    mov r8, rdx
    add r8, r12 ; data + x
    add r8, r11 ; + d
    add [r8], al ; [x+d] czyli [data+x+d]
    pushf
    pushf
    cmp dil, 6
    je execute_adc_exit

    mov r8, rdx
    add r8, r13 ; data + y
    add r8, r11 ; + d
    add [r8], al ; [y+d] czyli [data+y+d]
    pushf
    pushf
    cmp dil, 7
    je execute_adc_exit
    popf
    popf

    execute_adc_exit:
        mov ax, 0
        popf 
        jnc .no_c
        add ax, 0x100
        .no_c:
        popf
        jnz .no_z
        add ax, 1
        .no_z:
        mov r15w, ax ; aktualizacja flag
        ret

global execute_sbb:
execute_sbb:
    ; dostajemy jako argumenty kody rejestrów
    ; w dil i sil
    ; w rdx mamy data
    push rdi
    push rsi
    push rdx
    mov dil, sil ; przekazujemy argument dla funkcji get_value_from_register_code
    mov rsi, rdx
    call get_value_from_register_code
    add al, r15b ; dodajemy wartość C
    pop rdx
    pop rsi
    pop rdi
    ; teraz musimy do rejestru o kodzie dil dać wartość w al

    sub r10b, al
    pushf
    pushf
    cmp dil, 0
    je execute_sbb_exit
    popf
    popf

    sub r11b, al
    pushf
    pushf
    cmp dil, 1
    je execute_sbb_exit
    popf
    popf

    sub r12b, al
    pushf
    pushf
    cmp dil, 2
    je execute_sbb_exit
    popf
    popf

    sub r13b, al
    pushf
    pushf
    cmp dil, 3
    je execute_sbb_exit
    popf
    popf

    mov r8, rdx
    add r8, r12 ; data + x
    sub [r8], al ; [x] czyli [data+x]
    pushf
    pushf
    cmp dil, 4
    je execute_sbb_exit
    popf
    popf

    mov r8, rsi
    add r8, r13 ; data + y
    sub [r8], al ; [y] czyli [data+y]
    pushf
    pushf
    cmp dil, 5
    je execute_sbb_exit
    popf
    popf

    mov r8, rdx
    add r8, r12 ; data + x
    add r8, r11 ; + d
    sub [r8], al ; [x+d] czyli [data+x+d]
    pushf
    pushf
    cmp dil, 6
    je execute_sbb_exit
    popf
    popf

    mov r8, rdx
    add r8, r13 ; data + y
    add r8, r11 ; + d
    sub [r8], al ; [y+d] czyli [data+y+d]
    pushf
    pushf
    cmp dil, 7
    je execute_sbb_exit
    popf
    popf

    execute_sbb_exit:
        mov ax, 0
        popf 
        jnc .no_c
        add ax, 0x100
        .no_c:
        popf
        jnz .no_z
        add ax, 1
        .no_z:
        mov r15w, ax ; aktualizacja flag
        ret

global execute_movi:
execute_movi:
    ; dostajemy jako argumenty w dil kod rejestru
    ; a w sil imm8
    ; w rdx mamy data
    ; teraz musimy do rejestru o kodzie dil dać wartość w sil

    mov r10b, sil
    cmp dil, 0
    je execute_movi_exit

    mov r11b, sil
    cmp dil, 1
    je execute_movi_exit

    mov r12b, sil
    cmp dil, 2
    je execute_movi_exit

    mov r13b, sil
    cmp dil, 3
    je execute_movi_exit

    mov r8, rdx
    add r8, r12 ; data + x
    mov [r8], sil ; [x] czyli [data+x]
    cmp dil, 4
    je execute_movi_exit

    mov r8, rsi
    add r8, r13 ; data + y
    mov [r8], sil ; [y] czyli [data+y]
    cmp dil, 5
    je execute_movi_exit

    mov r8, rdx
    add r8, r12 ; data + x
    add r8, r11 ; + d
    mov [r8], sil ; [x+d] czyli [data+x+d]
    cmp dil, 6
    je execute_movi_exit

    mov r8, rdx
    add r8, r13 ; data + y
    add r8, r11 ; + d
    mov [r8], sil ; [y+d] czyli [data+y+d]
    cmp dil, 7
    je execute_movi_exit

    execute_movi_exit:
        ret

global execute_xori:
execute_xori:
    ; dostajemy jako argumenty w dil kod rejestru
    ; a w sil imm8
    ; w rdx mamy data

    xor r10b, sil
    pushf
    cmp dil, 0
    je execute_xori_exit
    popf

    xor r11b, sil
    pushf
    cmp dil, 1
    je execute_xori_exit
    popf

    xor r12b, sil
    pushf
    cmp dil, 2
    je execute_xori_exit
    popf

    xor r13b, sil
    pushf
    cmp dil, 3
    je execute_xori_exit
    popf

    mov r8, rdx
    add r8, r12 ; data + x
    xor [r8], sil ; [x] czyli [data+x]
    pushf
    cmp dil, 4
    je execute_xori_exit
    popf

    mov r8, rsi
    add r8, r13 ; data + y
    xor [r8], sil ; [y] czyli [data+y]
    pushf
    cmp dil, 5
    je execute_xori_exit
    popf

    mov r8, rdx
    add r8, r12 ; data + x
    add r8, r11 ; + d
    xor [r8], sil ; [x+d] czyli [data+x+d]
    pushf
    cmp dil, 6
    je execute_xori_exit
    popf

    mov r8, rdx
    add r8, r13 ; data + y
    add r8, r11 ; + d
    xor [r8], sil ; [y+d] czyli [data+y+d]
    pushf
    cmp dil, 7
    je execute_xori_exit
    popf

    execute_xori_exit:
        mov r15b, 0
        popf 
        jnz .no_zero ; Z się nie ustawiło w xor
        mov r15b, 1
        .no_zero:
        ret


global execute_addi:
execute_addi:
    ; dostajemy jako argumenty w dil kod rejestru
    ; a w sil imm8
    ; w rdx mamy data

    add r10b, sil
    pushf
    cmp dil, 0
    je execute_xori_exit
    popf

    add r11b, sil
    pushf
    cmp dil, 1
    je execute_addi_exit
    popf

    add r12b, sil
    pushf
    cmp dil, 2
    je execute_addi_exit
    popf

    add r13b, sil
    pushf
    cmp dil, 3
    je execute_addi_exit
    popf

    mov r8, rdx
    add r8, r12 ; data + x
    add [r8], sil ; [x] czyli [data+x]
    pushf
    cmp dil, 4
    je execute_addi_exit
    popf

    mov r8, rsi
    add r8, r13 ; data + y
    add [r8], sil ; [y] czyli [data+y]
    pushf
    cmp dil, 5
    je execute_addi_exit
    popf

    mov r8, rdx
    add r8, r12 ; data + x
    add r8, r11 ; + d
    add [r8], sil ; [x+d] czyli [data+x+d]
    pushf
    cmp dil, 6
    je execute_addi_exit
    popf

    mov r8, rdx
    add r8, r13 ; data + y
    add r8, r11 ; + d
    add [r8], sil ; [y+d] czyli [data+y+d]
    pushf
    cmp dil, 7
    je execute_addi_exit
    popf

    execute_addi_exit:
        mov r15b, 0
        popf 
        jnz .no_zero ; Z się nie ustawiło w xor
        mov r15b, 1
        .no_zero:
        ret

global execute_cmpi:
execute_cmpi:
    ; dostajemy jako argumenty w dil kod rejestru
    ; a w sil imm8
    ; w rdx mamy data

    cmp r10b, sil
    pushf
    pushf
    cmp dil, 0
    je execute_cmpi_exit
    popf
    popf

    cmp r11b, sil
    pushf
    pushf
    cmp dil, 1
    je execute_cmpi_exit
    popf
    popf

    cmp r12b, al
    pushf
    pushf
    cmp dil, 2
    je execute_cmpi_exit
    popf
    popf

    cmp r13b, sil
    pushf
    pushf
    cmp dil, 3
    je execute_cmpi_exit
    popf
    popf

    mov r8, rdx
    add r8, r12 ; data + x
    cmp [r8], sil ; [x] czyli [data+x]
    pushf
    pushf
    cmp dil, 4
    je execute_cmpi_exit
    ; jmp execute_cmpi_exit ; tylko do debugu ta linijka
    popf
    popf

    mov r8, rsi
    add r8, r13 ; data + y
    cmp [r8], sil ; [y] czyli [data+y]
    pushf
    pushf
    cmp dil, 5
    je execute_cmpi_exit
    popf
    popf

    mov r8, rdx
    add r8, r12 ; data + x
    add r8, r11 ; + d
    cmp [r8], sil ; [x+d] czyli [data+x+d]
    pushf
    pushf
    cmp dil, 6
    je execute_cmpi_exit
    popf
    popf

    mov r8, rdx
    add r8, r13 ; data + y
    add r8, r11 ; + d
    cmp [r8], sil ; [y+d] czyli [data+y+d]
    pushf
    pushf
    cmp dil, 7
    je execute_cmpi_exit
    popf
    popf

    execute_cmpi_exit:
        mov ax, 0
        popf 
        jnc .no_c
        add ax, 0x100
        .no_c:
        popf
        jnz .no_z
        add ax, 1
        .no_z:
        mov r15w, ax ; aktualizacja flag
        ret

global execute_rcr:
    execute_rcr:
    ; w dil mamy kod rejestru
    ; w rdx mamy data
    push rdx
    push rdi ; na wszelki wypadek, bo kto tam wie co ta funkcja zrobi
    call get_value_from_register_code
    pop rdi
    pop rdx
    ; w al mamy teraz wartość, którą mamy obrócić i przekopiować do rejestru o kodzie dil z powrotem
    push rbx
    push rcx
    mov bx, r15w 
    mov bl, 0
    ; teraz w bh mamy wartość flagi C
    shl bh, 7 ; teraz w najmniej znaczącym bicie bh mamy wartość C
    mov cl, al ; teraz w cl mamy tę liczbę którą mamy obrócić
    shl cl, 7
    shr cl, 7 ; a teraz tylko jej najmniej znaczący bit, czyli to co będzie miało być w C
    shr al, 1 ; obracamy al
    add al, bh ; dodajemy do najbardziej znaczącego bitu tę flagę
    ; teraz w al mamy obróconą liczbę, wystarczy dodać do C
    mov bl, r15b ; kopiujemy Z
    mov bh, cl
    mov r15w, bx ; dodajemy obie części flag
    pop rcx
    pop rbx
    ; teraz w C jest to co miało być
    ; a w al obrócona liczba
    ; musimy dodać tę liczbę w al do rejestru o kodzie dil

    mov r10b, al
    cmp dil, 0
    je execute_rcr_exit

    mov r11b, al
    cmp dil, 1
    je execute_rcr_exit

    mov r12b, al
    cmp dil, 2
    je execute_rcr_exit

    mov r13b, al
    cmp dil, 3
    je execute_rcr_exit

    mov r8, rdx
    add r8, r12 ; data + x
    mov [r8], al ; [x] czyli [data+x]
    cmp dil, 4
    je execute_rcr_exit

    mov r8, rsi
    add r8, r13 ; data + y
    mov [r8], al ; [y] czyli [data+y]
    cmp dil, 5
    je execute_rcr_exit

    mov r8, rdx
    add r8, r12 ; data + x
    add r8, r11 ; + d
    mov [r8], al ; [x+d] czyli [data+x+d]
    cmp dil, 6
    je execute_rcr_exit

    mov r8, rdx
    add r8, r13 ; data + y
    add r8, r11 ; + d
    mov [r8], al ; [y+d] czyli [data+y+d]
    cmp dil, 7
    je execute_rcr_exit

    execute_rcr_exit:
        ret

global testowa:
testowa: 
; przestrzega abi
; wywołuje inne funkcje
; w rdi dostaje data
; w rax zwraca co chcemy
push r12
push r13
push r14
push r15
call push_state_to_registers
mov rdx, rdi ; data
mov rsi, rdi ; data
mov dil, 0
mov r10b, 2
call execute_rcr
call push_state_to_rax
pop r15
pop r14
pop r13
pop r12
ret
