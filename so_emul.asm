section .text

; wszystkie moje funkcje przestrzegają abi, żeby się je dało testować 

get_value_from_register_code:
    ; otrzymujemy tę value w dil (odpowiedniku rdi)
    ; w rsi mamy data
    ; a zwracamy w al
    
    mov dil, r10b 
    cmp al, 0
    je get_value_from_register_code_exit

    mov dil, r11b 
    cmp al, 1
    je get_value_from_register_code_exit

    mov dil, r12b 
    cmp al, 2
    je get_value_from_register_code_exit

    mov dil, r13b 
    cmp al, 3
    je get_value_from_register_code_exit

    mov r8, rsi
    add r8, r12b ; data + x
    mov dil, [r8] ; [x] czyli [data+x]
    cmp al, 4
    je get_value_from_register_code_exit

    mov r8, rsi
    add r8, r13b ; data + y
    mov dil, [r8] ; [y] czyli [data+y]
    cmp al, 5
    je get_value_from_register_code_exit

    mov r8, rsi
    add r8, r12b ; data + x
    add r8, r11b ; + d
    mov dil, [r8] ; [x] czyli [data+x]
    cmp al, 6
    je get_value_from_register_code_exit

    mov r8, rsi
    add r8, r13b ; data + y
    add r8, r11b ; + d
    mov dil, [r8] ; [y] czyli [data+y]
    cmp al, 7
    je get_value_from_register_code_exit

    get_value_from_register_code_exit:
        ret



global find_arg2_value:
find_arg2_value:
    ; w di dostajemy wartość instrukcji
    ; instrukcje dla których to pasuje: mov, or, add, sub, adc, sbb
    ; i mamy znaleźć *wartość w* arg2 i zwrócić go w al
    ; arg2 jest w kodzie instrukcji przekazywany jako arg2 * 0800
    ; czyli na pewno nas interesują tylko dwa pierwsze bity
    mov bl, 0 ; zerujemy wynik
    shr di, 3 ; likwidujemy trzy ostatnie bity di
    shl di, 5 ; likwidujemy dwa pierwsze bity di
    shr di, 5 
    mov bl, di 
    ; teraz w bl mamy kod arg2, potrzebujemy wartości z niego

    ; tu trzeba będzie poprzenosić argumenty i scallować funkcję

    find_arg2_value_exit:
        ret


mov_execute:
    ; al - wartość w arg2
    ; będziemy tak zrobić, że 8 cmpami znajdziemy wartość w arg1 i potem w arg2 i je gdzieś zapiszemy i wtedy zmovujemy odpowiednie rejestry
    ; tzn najpierw znajdziemy tą do zmovovania
    ; żeby nie robić 64 ifów


; argumenty, które dostaje:
; rdi - kod
; rsi - data
; rdx - steps
; rcx - core
; ważne pytanie - jak traktujemy parametr steps w kontekście skoków? 
; wszystkie rejestry są ośmiobitowe - czyli tak jakby jednobajtowe, lol

; r10b - rejestr A
; r11b - rejestr D
; r12b - rejestr X
; r13b - rejestr Y 
; rbx - tak, rbx, bo steps jest size_t - counter kroków, aż osiągnie steps

global so_emul
so_emul:

mov rbx 0 ; zerowanie countera
main_loop:
    call 
    inc rbx 
    cmp rbx, rdx ; sprawdzam czy już było steps kroków
    jne main_loop

main_exit:
    ret ; ta funkcja to void, więc nie trzeba nic zwracać sensownego

