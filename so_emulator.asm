section .bss

cpu_state: resb 8

section .text

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
    ; push rdi
    ; mov rdi, rax
    ; call turn_register 
    ; pop rdi
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
shr qword[rel cpu_state], 8
mov r11b, [rel cpu_state] ; wartość D
shr qword[rel cpu_state], 8
mov r12b, [rel cpu_state] ; wartość X
shr qword[rel cpu_state], 8
mov r13b, [rel cpu_state], ; wartość Y
shr qword[rel cpu_state], 8
mov r14b, [rel cpu_state] ; wartość PC
shr qword[rel cpu_state], 16 ; bo jeszcze unused
mov r15b, [rel cpu_state] ; wartość Z
shl r15w, 8
shr qword[rel cpu_state], 8
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
    ; mov r15b, 17 ; tylko do debugu!!
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

    ;tylko do debugu ta sekcja!!
    ;mov r15b, 15
    ;cmp al, 3
    ;je .debug1
    ;jmp .debug2
    ;.debug1:
    ;mov r15b, 16
    ;.debug2:
    

    cmp dil, 0
    jne .continue1
    mov r10b, al
    jmp execute_mov_exit

    .continue1:
    cmp dil, 1 
    jne .continue2
    mov r11b, al
    jmp execute_mov_exit

    .continue2:
    cmp dil, 2
    jne .continue3
    mov r12b, al
    jmp execute_mov_exit

    .continue3: 
    cmp dil, 3
    jne .continue4   
    mov r13b, al
    jmp execute_mov_exit

    .continue4:    
    cmp dil, 4
    jne .continue5
    mov r8, rdx
    add r8, r12 ; data + x
    mov [r8], al ; [x] czyli [data+x]
    jmp execute_mov_exit

    .continue5:  
    cmp dil, 5
    jne .continue6  
    mov r8, rdx
    add r8, r13 ; data + y
    mov [r8], al ; [y] czyli [data+y]
    jmp execute_mov_exit

    .continue6:   
    cmp dil, 6 
    jne .continue7
    mov r8, rdx
    add r8, r12 ; data + x
    add r8, r11 ; + d
    mov [r8], al ; [x+d] czyli [data+x+d]
    jmp execute_mov_exit

    .continue7:  
    cmp dil, 7
    jne execute_mov_exit  
    mov r8, rdx
    add r8, r13 ; data + y
    add r8, r11 ; + d
    mov [r8], al ; [y+d] czyli [data+y+d]
    jmp execute_mov_exit

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

    cmp dil, 0
    jne .continue1
    or r10b, al
    pushf
    jmp execute_or_exit

    .continue1:
    cmp dil, 1 
    jne .continue2
    or r11b, al
    pushf
    jmp execute_or_exit

    .continue2:
    cmp dil, 2
    jne .continue3
    or r12b, al
    pushf
    jmp execute_or_exit

    .continue3: 
    cmp dil, 3
    jne .continue4   
    or r13b, al
    pushf
    jmp execute_or_exit

    .continue4:    
    cmp dil, 4
    jne .continue5
    mov r8, rdx
    add r8, r12 ; data + x
    or [r8], al ; [x] czyli [data+x]
    pushf
    jmp execute_or_exit

    .continue5:  
    cmp dil, 5
    jne .continue6  
    mov r8, rdx
    add r8, r13 ; data + y
    or [r8], al ; [y] czyli [data+y]
    pushf
    jmp execute_or_exit

    .continue6:   
    cmp dil, 6 
    jne .continue7
    mov r8, rdx
    add r8, r12 ; data + x
    add r8, r11 ; + d
    or [r8], al ; [x+d] czyli [data+x+d]
    pushf
    jmp execute_or_exit

    .continue7:  
    cmp dil, 7
    jne execute_or_exit  
    mov r8, rdx
    add r8, r13 ; data + y
    add r8, r11 ; + d
    or [r8], al ; [y+d] czyli [data+y+d]
    pushf
    jmp execute_or_exit

    execute_or_exit:
        ; mov al, r15b ; to do ustawiania C będzie
        mov r15b, 0
        popf 
        jnz .no_zero ; Z się nie ustawiło w or
        mov r15b, 1
        .no_zero:
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

    ;tylko do debugu ta sekcja!!
    ;mov r14b, 15
    ;cmp al, 1
    ;je .debug1
    ;jmp .debug2
    ;.debug1:
    ;mov r14b, 16
    ;.debug2:

    cmp dil, 0
    jne .continue1
    add r10b, al
    pushf
    jmp execute_add_exit

    .continue1:
    cmp dil, 1 
    jne .continue2
    add r11b, al
    pushf
    jmp execute_add_exit

    .continue2:
    cmp dil, 2
    jne .continue3
    add r12b, al
    pushf
    jmp execute_add_exit

    .continue3: 
    cmp dil, 3
    jne .continue4   
    add r13b, al
    pushf
    jmp execute_add_exit

    .continue4:    
    cmp dil, 4
    jne .continue5
    mov r8, rdx
    add r8, r12 ; data + x
    add [r8], al ; [x] czyli [data+x]
    pushf
    jmp execute_add_exit

    .continue5:  
    cmp dil, 5
    jne .continue6  
    mov r8, rdx
    add r8, r13 ; data + y
    add [r8], al ; [y] czyli [data+y]
    pushf
    jmp execute_add_exit

    .continue6:   
    cmp dil, 6 
    jne .continue7
    mov r8, rdx
    add r8, r12 ; data + x
    add r8, r11 ; + d
    add [r8], al ; [x+d] czyli [data+x+d]
    pushf
    jmp execute_add_exit

    .continue7:  
    cmp dil, 7
    jne execute_add_exit  
    mov r8, rdx
    add r8, r13 ; data + y
    add r8, r11 ; + d
    add [r8], al ; [y+d] czyli [data+y+d]
    pushf
    jmp execute_add_exit

    execute_add_exit:
        mov r15b, 0
        popf 
        jnz .no_zero ; Z się nie ustawiło w add
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

    cmp dil, 0
    jne .continue1
    sub r10b, al
    pushf
    jmp execute_sub_exit

    .continue1:
    cmp dil, 1 
    jne .continue2
    sub r11b, al
    pushf
    jmp execute_sub_exit

    .continue2:
    cmp dil, 2
    jne .continue3
    sub r12b, al
    pushf
    jmp execute_sub_exit

    .continue3: 
    cmp dil, 3
    jne .continue4   
    sub r13b, al
    pushf
    jmp execute_sub_exit

    .continue4:    
    cmp dil, 4
    jne .continue5
    mov r8, rdx
    add r8, r12 ; data + x
    sub [r8], al ; [x] czyli [data+x]
    pushf
    jmp execute_sub_exit

    .continue5:  
    cmp dil, 5
    jne .continue6  
    mov r8, rdx
    add r8, r13 ; data + y
    sub [r8], al ; [y] czyli [data+y]
    pushf
    jmp execute_sub_exit

    .continue6:   
    cmp dil, 6 
    jne .continue7
    mov r8, rdx
    add r8, r12 ; data + x
    add r8, r11 ; + d
    sub [r8], al ; [x+d] czyli [data+x+d]
    pushf
    jmp execute_sub_exit

    .continue7:  
    cmp dil, 7
    jne execute_sub_exit  
    mov r8, rdx
    add r8, r13 ; data + y
    add r8, r11 ; + d
    sub [r8], al ; [y+d] czyli [data+y+d]
    pushf
    jmp execute_sub_exit

    execute_sub_exit:
        mov r15b, 0
        popf 
        jnz .no_zero ; Z się nie ustawiło w add
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
    pop rdx
    pop rsi
    pop rdi
    ; teraz musimy do rejestru o kodzie dil dać wartość w al

    cmp dil, 0
    jne .continue1
    add r10b, al
    pushf
    pushf
    jmp execute_adc_exit

    .continue1:
    cmp dil, 1 
    jne .continue2
    add r11b, al
    pushf
    pushf
    jmp execute_adc_exit

    .continue2:
    cmp dil, 2
    jne .continue3
    add r12b, al
    pushf
    pushf
    jmp execute_adc_exit

    .continue3: 
    cmp dil, 3
    jne .continue4   
    add r13b, al
    pushf
    pushf
    jmp execute_adc_exit

    .continue4:    
    cmp dil, 4
    jne .continue5
    mov r8, rdx
    add r8, r12 ; data + x
    add [r8], al ; [x] czyli [data+x]
    pushf
    pushf
    jmp execute_adc_exit

    .continue5:  
    cmp dil, 5
    jne .continue6  
    mov r8, rdx
    add r8, r13 ; data + y
    add [r8], al ; [y] czyli [data+y]
    pushf
    pushf
    jmp execute_adc_exit

    .continue6:   
    cmp dil, 6 
    jne .continue7
    mov r8, rdx
    add r8, r12 ; data + x
    add r8, r11 ; + d
    add [r8], al ; [x+d] czyli [data+x+d]
    pushf
    pushf
    jmp execute_adc_exit

    .continue7:  
    cmp dil, 7
    jne execute_adc_exit  
    mov r8, rdx
    add r8, r13 ; data + y
    add r8, r11 ; + d
    add [r8], al ; [y+d] czyli [data+y+d]
    pushf
    pushf
    jmp execute_adc_exit

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
    pop rdx
    pop rsi
    pop rdi
    ; teraz musimy do rejestru o kodzie dil dać wartość w al

    cmp dil, 0
    jne .continue1
    sub r10b, al
    pushf
    pushf
    jmp execute_sbb_exit

    .continue1:
    cmp dil, 1 
    jne .continue2
    sub r11b, al
    pushf
    pushf
    jmp execute_sbb_exit

    .continue2:
    cmp dil, 2
    jne .continue3
    sub r12b, al
    pushf
    pushf
    jmp execute_sbb_exit

    .continue3: 
    cmp dil, 3
    jne .continue4   
    sub r13b, al
    pushf
    pushf
    jmp execute_sbb_exit

    .continue4:    
    cmp dil, 4
    jne .continue5
    mov r8, rdx
    add r8, r12 ; data + x
    sub [r8], al ; [x] czyli [data+x]
    pushf
    pushf
    jmp execute_sbb_exit

    .continue5:  
    cmp dil, 5
    jne .continue6  
    mov r8, rdx
    add r8, r13 ; data + y
    sub [r8], al ; [y] czyli [data+y]
    pushf
    pushf
    jmp execute_sbb_exit

    .continue6:   
    cmp dil, 6 
    jne .continue7
    mov r8, rdx
    add r8, r12 ; data + x
    add r8, r11 ; + d
    sub [r8], al ; [x+d] czyli [data+x+d]
    pushf
    pushf
    jmp execute_sbb_exit

    .continue7:  
    cmp dil, 7
    jne execute_sbb_exit  
    mov r8, rdx
    add r8, r13 ; data + y
    add r8, r11 ; + d
    sub [r8], al ; [y+d] czyli [data+y+d]
    pushf
    pushf
    jmp execute_sbb_exit

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

    ; mov r15b, 17 ; tylko do debugu ta linijka!!
    ; add r15b, dil ; ta też

    cmp dil, 0
    jne .continue1    
    mov r10b, sil
    jmp execute_movi_exit

    .continue1:  
    cmp dil, 1
    jne .continue2  
    mov r11b, sil
    ; mov r15b, 22 ; tylko do debugu ta linijka!!
    jmp execute_movi_exit

    .continue2:  
    cmp dil, 2
    jne .continue3  
    mov r12b, sil
    jmp execute_movi_exit

    .continue3:  
    cmp dil, 3
    jne .continue4  
    mov r13b, sil
    jmp execute_movi_exit

    .continue4:
    cmp dil, 4
    jne .continue5    
    mov r8, rdx
    add r8, r12 ; data + x
    mov [r8], sil ; [x] czyli [data+x]
    jmp execute_movi_exit

    .continue5:
    cmp dil, 5
    jne .continue6    
    mov r8, rdx
    add r8, r13 ; data + y
    mov [r8], sil ; [y] czyli [data+y]
    jmp execute_movi_exit

    .continue6: 
    cmp dil, 6
    jne .continue7   
    mov r8, rdx
    add r8, r12 ; data + x
    add r8, r11 ; + d
    mov [r8], sil ; [x+d] czyli [data+x+d]
    jmp execute_movi_exit

    .continue7:  
    cmp dil, 7
    jne execute_movi_exit  
    mov r8, rdx
    add r8, r13 ; data + y
    add r8, r11 ; + d
    mov [r8], sil ; [y+d] czyli [data+y+d]

    execute_movi_exit:
        ret

global execute_xori:
execute_xori:
    ; dostajemy jako argumenty w dil kod rejestru
    ; a w sil imm8
    ; w rdx mamy data

    cmp dil, 0
    jne .continue1    
    xor r10b, sil
    pushf
    jmp execute_xori_exit

    .continue1:  
    cmp dil, 1
    jne .continue2  
    xor r11b, sil
    pushf
    jmp execute_xori_exit

    .continue2:  
    cmp dil, 2
    jne .continue3  
    xor r12b, sil
    pushf
    jmp execute_xori_exit

    .continue3:  
    cmp dil, 3
    jne .continue4  
    xor r13b, sil
    pushf
    jmp execute_xori_exit

    .continue4:
    cmp dil, 4
    jne .continue5    
    mov r8, rdx
    add r8, r12 ; data + x
    xor [r8], sil ; [x] czyli [data+x]
    pushf
    jmp execute_xori_exit

    .continue5:
    cmp dil, 5
    jne .continue6    
    mov r8, rdx
    add r8, r13 ; data + y
    xor [r8], sil ; [y] czyli [data+y]
    pushf
    jmp execute_xori_exit

    .continue6: 
    cmp dil, 6
    jne .continue7   
    mov r8, rdx
    add r8, r12 ; data + x
    add r8, r11 ; + d
    xor [r8], sil ; [x+d] czyli [data+x+d]
    pushf
    jmp execute_xori_exit

    .continue7:  
    cmp dil, 7
    jne execute_xori_exit  
    mov r8, rdx
    add r8, r13 ; data + y
    add r8, r11 ; + d
    xor [r8], sil ; [y+d] czyli [data+y+d]
    pushf

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

    cmp dil, 0
    jne .continue1    
    add r10b, sil
    pushf
    jmp execute_addi_exit

    .continue1:  
    cmp dil, 1
    jne .continue2  
    add r11b, sil
    pushf
    jmp execute_addi_exit

    .continue2:  
    cmp dil, 2
    jne .continue3  
    add r12b, sil
    pushf
    jmp execute_addi_exit

    .continue3:  
    cmp dil, 3
    jne .continue4  
    add r13b, sil
    pushf
    jmp execute_addi_exit

    .continue4:
    cmp dil, 4
    jne .continue5    
    mov r8, rdx
    add r8, r12 ; data + x
    add [r8], sil ; [x] czyli [data+x]
    pushf
    jmp execute_addi_exit

    .continue5:
    cmp dil, 5
    jne .continue6    
    mov r8, rdx
    add r8, r13 ; data + y
    add [r8], sil ; [y] czyli [data+y]
    pushf
    jmp execute_addi_exit

    .continue6: 
    cmp dil, 6
    jne .continue7   
    mov r8, rdx
    add r8, r12 ; data + x
    add r8, r11 ; + d
    add [r8], sil ; [x+d] czyli [data+x+d]
    pushf
    jmp execute_addi_exit

    .continue7:  
    cmp dil, 7
    jne execute_addi_exit  
    mov r8, rdx
    add r8, r13 ; data + y
    add r8, r11 ; + d
    add [r8], sil ; [y+d] czyli [data+y+d]
    pushf

    execute_addi_exit:
        mov r15b, 0
        popf 
        jnz .no_zero ; Z się nie ustawiło w add
        mov r15b, 1
        .no_zero:
        ;mov r15b, 5; tylko do debugu!!
        ret

global execute_cmpi:
execute_cmpi:
    ; dostajemy jako argumenty w dil kod rejestru
    ; a w sil imm8
    ; w rdx mamy data

    cmp dil, 0
    jne .continue1    
    cmp r10b, sil
    pushf
    pushf
    jmp execute_cmpi_exit

    .continue1:  
    cmp dil, 1
    jne .continue2  
    cmp r11b, sil
    pushf
    pushf
    jmp execute_cmpi_exit

    .continue2:  
    cmp dil, 2
    jne .continue3  
    cmp r12b, sil
    pushf
    pushf
    jmp execute_cmpi_exit

    .continue3:  
    cmp dil, 3
    jne .continue4  
    cmp r13b, sil
    pushf
    pushf
    jmp execute_cmpi_exit

    .continue4:
    cmp dil, 4
    jne .continue5    
    mov r8, rdx
    add r8, r12 ; data + x
    cmp [r8], sil ; [x] czyli [data+x]
    pushf
    pushf
    jmp execute_cmpi_exit

    .continue5:
    cmp dil, 5
    jne .continue6    
    mov r8, rdx
    add r8, r13 ; data + y
    cmp [r8], sil ; [y] czyli [data+y]
    pushf
    pushf
    jmp execute_cmpi_exit

    .continue6: 
    cmp dil, 6
    jne .continue7   
    mov r8, rdx
    add r8, r12 ; data + x
    add r8, r11 ; + d
    cmp [r8], sil ; [x+d] czyli [data+x+d]
    pushf
    pushf
    jmp execute_cmpi_exit

    .continue7:  
    cmp dil, 7
    jne execute_addi_exit  
    mov r8, rdx
    add r8, r13 ; data + y
    add r8, r11 ; + d
    cmp [r8], sil ; [y+d] czyli [data+y+d]
    pushf
    pushf

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
    ; w rsi mamy data
    ; mov r15b, r14b ; tylko do debugu ta linijka!!
    push rdx
    push rsi
    push rdi ; na wszelki wypadek, bo kto tam wie co ta funkcja zrobi
    call get_value_from_register_code
    pop rdi
    pop rsi
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

    cmp dil, 0
    jne .continue1
    mov r10b, al
    jmp execute_rcr_exit

    .continue1:
    cmp dil, 1
    jne .continue2    
    mov r11b, al
    jmp execute_rcr_exit

    .continue2: 
    cmp dil, 2
    jne .continue3   
    mov r12b, al
    jmp execute_rcr_exit

    .continue3: 
    cmp dil, 3
    jne .continue4   
    mov r13b, al
    jmp execute_rcr_exit

    .continue4:    
    cmp dil, 4
    jne .continue5
    mov r8, rsi
    add r8, r12 ; data + x
    mov [r8], al ; [x] czyli [data+x]
    jmp execute_rcr_exit

    .continue5:
    cmp dil, 5
    jne .continue6    
    mov r8, rsi
    add r8, r13 ; data + y
    mov [r8], al ; [y] czyli [data+y]
    jmp execute_rcr_exit

    .continue6:
    cmp dil, 6
    jne .continue7    
    mov r8, rsi
    add r8, r12 ; data + x
    add r8, r11 ; + d
    mov [r8], al ; [x+d] czyli [data+x+d]
    jmp execute_rcr_exit

    .continue7:
    cmp dil, 7
    jne execute_rcr_exit   
    mov r8, rsi
    add r8, r13 ; data + y
    add r8, r11 ; + d
    mov [r8], al ; [y+d] czyli [data+y+d]

    execute_rcr_exit:
        ret

global execute_clc:
execute_clc:
    mov cx, r15w
    mov ch, 0
    mov r15w, cx
    ret

global execute_stc:
execute_stc:
    mov cx, r15w
    mov ch, 1
    mov r15w, cx
    ret



global execute_jmp:
execute_jmp:
    ; po prostu zwiększa pc o argument z dil
    add r14b, bl
    ret

global execute_jz:
execute_jz:
    cmp r15b, 1
    jne execute_jz_exit
    call execute_jmp
    execute_jz_exit:
        ret

global execute_jnz:
execute_jnz:
    cmp r15b, 0
    jne execute_jnz_exit
    call execute_jmp
    execute_jnz_exit:
        ret

global execute_jc:
execute_jc:
    push rcx
    mov cx, r15w
    shr cx, 8
    cmp cl, 1
    jne execute_jc_exit
    call execute_jmp
    execute_jc_exit:
        pop rcx
        ret

global execute_jnc:
execute_jnc:
    push rcx
    mov cx, r15w
    shr cx, 8
    cmp cl, 0
    jne execute_jnc_exit
    call execute_jmp
    execute_jnc_exit:
        pop rcx
        ret


global execute_command:
execute_command:
    ; argumenty:
    ; rdi - code (wskaźnik)
    ; rsi - data (wskaźnik)
    ; rdx - steps 
    ; rcx - core
    ; bx - instrukcja, którą mamy wykonać
    push rbx

    ; najpierw sprawdzimy skoki
    ; a potem dla pozostałych wyłuskamy argumenty i wywołamy odpowiednią funkcję
    ; mov dil, bl ; żeby było dla skoków jako argument

    cmp bh, 0xc0 ; jmp
    jne .continue1
    ; jeśli tu jesteśmy to mamy jmp
    call execute_jmp ; dostaje w bl swój argument
    jmp execute_command_exit

    .continue1:
    ; teraz będziemy sprawdzać pozostałe skoki

    cmp bh, 0xc2
    jne .continue2
    ; jeśli tu jesteśmy to mamy jnc
    ; mov r15b, 21 ; tylko do debugu ta linijka!!
    call execute_jnc ; dostaje w bl swój argument
    jmp execute_command_exit

    .continue2:
    cmp bh, 0xc3
    jne .continue3
    ; jeśli tu jesteśmy to mamy jc
    call execute_jc ; dostaje w bl swój argument
    jmp execute_command_exit

    .continue3:
    cmp bh, 0xc4
    jne .continue4
    ; jeśli tu jesteśmy to mamy jnz
    call execute_jnz ; dostaje w bl swój argument
    jmp execute_command_exit

    .continue4:
    cmp bh, 0xc5
    jne .continue5
    ; jeśli tu jesteśmy to mamy jz
    call execute_jz ; dostaje w bl swój argument
    jmp execute_command_exit

    .continue5:
    ; jeśli tu jesteśmy to to nie jest skok
    ; musimy teraz wyłuskać która to z pozostałych instrukcji i dać jej argumenty
    ; i ją wywołać

    cmp bx, 0x8000 
    jne .continue6
    call execute_clc
    jmp execute_command_exit

    .continue6:
    cmp bx, 0x8100 
    jne .continue7
    call execute_stc
    jmp execute_command_exit

    .continue7:
    ; clc, stc, brk i skoki obsłużone, teraz reszta


    cmp bx, 0x7001
    jl .continue8
    ; to jest rcr
    ; teraz musimy wyłuskać argumenty
    sub bx, 0x7001
    push rdi
    push rsi
    push rdx
    push rcx
    ; rsi - data
    mov cl, bh
    mov dil, cl ; przenoszenie arg
    ; mov dil, bh ; arg
    call execute_rcr
    pop rcx
    pop rdx
    pop rsi
    pop rdi
    jmp execute_command_exit

    .continue8:
    cmp bx, 0x6800
    jl .continue9
    ; to jest cmpi
    ; teraz musimy wyłuskać argumenty
    sub bx, 0x6800
    push rdi
    push rsi
    push rdx
    push rcx
    mov rdx, rsi ; data
    mov sil, bl ; imm8
    mov cl, bh
    mov dil, cl ; arg1
    ; mov dil, bh ; arg1
    call execute_cmpi
    pop rcx
    pop rdx
    pop rsi
    pop rdi
    jmp execute_command_exit

    .continue9:
    cmp bx, 0x6000
    jl .continue10
    ; to jest addi
    ; teraz musimy wyłuskać argumenty
    sub bx, 0x6000
    push rdi
    push rsi
    push rdx
    push rcx
    mov rdx, rsi ; data
    mov sil, bl ; imm8
    mov cl, bh
    mov dil, cl ; arg1
    ; mov dil, bh ; arg1
    call execute_addi
    pop rcx
    pop rdx
    pop rsi
    pop rdi
    jmp execute_command_exit

    .continue10:
    cmp bx, 0x5800
    jl .continue11
    ; to jest xori
    ; teraz musimy wyłuskać argumenty
    sub bx, 0x5800
    push rdi
    push rsi
    push rdx
    push rcx
    mov rdx, rsi ; data
    mov sil, bl ; imm8
    mov cl, bh 
    mov dil, cl ; arg1
    ; mov dil, bh ; arg1
    call execute_xori
    pop rcx
    pop rdx
    pop rsi
    pop rdi
    ; mov r15b, 17 ; tylko do debugu!!
    jmp execute_command_exit

    .continue11:
    cmp bx, 0x4000
    jl .continue12
    ; to jest movi
    ; teraz musimy wyłuskać argumenty
    sub bx, 0x4000
    push rdi
    push rsi
    push rdx
    push rcx
    mov rdx, rsi ; data
    mov sil, bl ; imm8
    mov cl, bh 
    ; mov r15b, 52 ; tylko do debugu!!
    ; add r15b, cl ; tylko do debugu!!
    mov dil, cl ; arg1
    ; mov dil, bh ; arg1
    call execute_movi
    pop rcx
    pop rdx
    pop rsi
    pop rdi
    jmp execute_command_exit

    .continue12:
    mov r8b, bl 
    shl r8b, 4
    shr r8b, 4 ; teraz w r8b mamy końcówkę mówiącą jaka to instrukcja
    ; mov r15b, r8b ; tylko do debugu!!
    push rdx
    push rsi
    push rdi
    mov rdx, rsi ; data
    sub bl, r8b ; mamy bez końcówki
    ; spośród mov, or, add, sub, adc, sbb
    ; tu musimy wyłuskać argumenty dla nich
    ; i wstawić je w odpowiednie miejsca, bo dla wszystkich są takie same
    shr bx, 3 ; 
    shr bl, 5 ; teraz w bl jest arg1 a w bh arg2
    mov dil, bl
    push rcx
    mov cl, bh
    mov sil, cl
    pop rcx

    

    cmp r8b, 0 
    jne .continue13
    ; to mov
    ; mov r15b, 0 ; tylko do debugu
    call execute_mov
    pop rdi
    pop rsi
    pop rdx
    jmp execute_command_exit

    .continue13:    
    cmp r8b, 2 
    jne .continue14
    ; to or
    call execute_or
    pop rdi
    pop rsi
    pop rdx
    jmp execute_command_exit

    .continue14:    
    cmp r8b, 4 
    jne .continue15
    ; to add
    ; mov r14b, 0x22 ; tylko do debugu ta linijka
    call execute_add
    pop rdi
    pop rsi
    pop rdx
    jmp execute_command_exit

    .continue15:    
    cmp r8b, 5 
    jne .continue16
    ; to sub
    call execute_sub
    pop rdi
    pop rsi
    pop rdx
    jmp execute_command_exit

    .continue16:    
    cmp r8b, 6 
    jne .continue17
    ; to adc
    call execute_adc
    pop rdi
    pop rsi
    pop rdx
    jmp execute_command_exit

    .continue17:    
    cmp r8b, 7 
    jne .continue18
    ; to sbb
    call execute_sbb
    pop rdi
    pop rsi
    pop rdx
    jmp execute_command_exit

    .continue18:
       

    execute_command_exit:
        pop rbx
        ret

global so_emul:
so_emul:
    ; argumenty:
    ; rdi - code (wskaźnik)
    ; rsi - data (wskaźnik)
    ; rdx - steps 
    ; rcx - core
    ; rejestry SO trzymamy w:
    ; r10b - A
    ; r11b - D
    ; r12b - X
    ; r13b - Y
    ; r14b - PC
    ; r15w\r15b - C
    ; r15b - Z
    push rbx
    push r12
    push r13
    push r14
    push r15
    ; push_state_to_registers nie potrzebuje argumentów
    push rdi
    push rsi
    push rdx
    push rcx ; na wszelki wypadek 
    call push_state_to_registers
    pop rcx
    pop rdx
    pop rsi
    pop rdi

    mov rbx, 0 ; rbx - counter głównej pętli programu
    cmp rdx, 0 ; czy steps = 0? 
    je main_exit ; jeśli steps = 0 to od razu idziemy do exit
    
    main_loop:
        inc rbx
        cmp rbx, rdx ; porównuję ze steps
        ; execute command przyjmuje takie parametry jak so_emul
        push rdi ; ale nie wiem czy ich nie zmienia, więc na wszelki wypadek
        push rsi
        push rdx
        push rcx
        push rbx
        mov r8, rdi
        shl r14, 1 ; mnożymy PC razy 16 na chwilę żeby przesunąć o dwa bajty
        add r8, r14 ; dodajemy PC
        shr r14, 1 
        mov bx, [r8] ; instrukcja, którą mamy wykonać
        cmp bx, 0xffff ; czy to brk?
        je brk_exit ; jeśli to brk to przerywamy
        call execute_command ; jeśli nie brk to exectujemy
        pop rbx
        pop rcx
        pop rdx
        pop rsi
        pop rdi
        inc r14b ; pc++
        cmp rbx, rdx ; counter pętli, steps
        mov r9b, 2 ; tylko do debugu ta linijka!!
        jne main_loop

    jmp main_exit
    brk_exit:
        pop rbx
        pop rcx
        pop rdx
        pop rsi
        pop rdi

    main_exit:
        ; push_state_to_rax nie potrzebuje argumentów
        call push_state_to_rax
        pop r15
        pop r14
        pop r13
        pop r12
        pop rbx
        ret


