;; This is NASM Syntax
;; x86-64
;; (C) Demqa Alexeev

%define n_cases  26
%define TEN      10
%define MINUS    '-'
%define ZERO     '0'
%define ONE      '1'
%define SEVEN    '7'
%define NINE     '9'
%define LETTER_A 'A'
%define LETTER_F 'F'

        GLOBAL _start

        SECTION .data

;; There can be stored some data used for my printf function

Msg:
        db "My string12", 0x0A
        db 0x00

        SECTION .bss

Buff:   resb 0x100

        SECTION .text

_start:

;; "%d...%o tilt %s %%", arg1, arg2, arg3                                  |  empty  |
;; ^------------------------------------------------------------------     -----------
;; Last arguement is a string address, which is formatted like this --|    |str addr |  <-- stack_top
;; and string ending with 0x00 symbol. Then goes arg1, arg2, arg3...       -----------
;;                                                                         |  arg1   |
;;                                                                         -----------
;;                                                                         |  arg2   |
;;                                                                         -----------
;;                                                                         |next args|
;;                                                                         -----------
;;                                                                         |  .....  |

     ;; push rsi
     ;; push rdi
     ;; push rax
        push Msg
        call printf


        mov rax, 0x3C               ; rax = 0x3c Terminate Function
        xor rdi, rdi                ; rdi = 0

        syscall

printf:

        push rbp
        mov  rbp, rsp

        cld
        mov  rsi, [rbp + 16]
        mov  rdi, Buff
        xor  cx, cx

.loop:
        cmp  cx, 0x100
        jb   .resume

        call .clearbuff

.resume:

        lodsb

        cmp  al, '%'
        jne  .skip

;;      Proceeding Specific formats
;;      There will be JUMP TABLE

        lodsb

        cmp  al, '%'
        jne  .jumptable

        stosb
        inc cx

        jmp .loop

.jumptable:

        sub al, 'a'
        cmp al, n_cases

        jng .loop

        call my_default

        jmp .loop

.skip:

        cmp al, 0x00
        je .print

        inc cx
        stosb

        jmp .loop

.print:

        call .clearbuff

.ret:

        pop  rbp
        ret


.clearbuff:

        push rsi
        push rdi
        push rdx
        push rax

        mov  rax, 0x01
        mov  rdi, 1

        mov  rsi, Buff
        xor  rdx, rdx
        mov   dx,  cx

        syscall

        pop  rax
        pop  rdx
        pop  rdi
        pop  rsi

        mov  rdi, Buff
        mov   cx, 0

        ret

my_default:

        ret

;------------------------------------------------
; Entry:
; RDI - destination index
; RBX - input integer
; Destr: RAX, RDX, RCX
;------------------------------------------------
decimal:

        mov  rcx, TEN

        cmp  rbx, 0h
        push rdi
        jns  .proceed

        mov  al, MINUS
        stosb

        pop  rdx
        push rdi

        neg  rbx

.proceed:

        xor rdx, rdx

        mov rax, rbx    ; ax = N
        div rcx       ; ax = N / 10

        mov rbx, rax    ; saving next integer

        mov rax, rdx    ; ax = N % 10

        add al, ZERO

        stosb

        cmp rbx, 0h
        jne .proceed


        pop rbx
        sub rdi, 1

.reverse:
        mov al, [rdi]
        mov dl, [rbx]
        mov [rdi], dl
        mov [rbx], al

        inc rbx
        dec rdi

        cmp rbx, rdi
        jb .reverse

        ret
;------------------------------------------------

;------------------------------------------------
; Entry:
; RDI - destination index
; RBX - input integer
; Destr: RAX, RDX
;------------------------------------------------
hex:

        mov rdx, rdi
        cld

.proceed:

        mov rax, rbx    ; ax = N

        and rax, 0Fh

        cmp al, 9h
        jbe .number

        add al, LETTER_A - ZERO - 0Ah

.number:

        add al, ZERO

        stosb

        shr rbx, 4h
        jnz .proceed


        mov rbx, rdx
        sub rdi, 1

.reverse:
        mov al, [rdi]
        mov dl, [rbx]
        mov [rdi], dl
        mov [rbx], al

        inc rbx
        dec rdi

        cmp rbx, rdi
        jb .reverse

        ret
;------------------------------------------------

;------------------------------------------------
; Entry:
; RDI - destination index
; RBX - input integer
; Destr: RAX, RDX
;------------------------------------------------
octal:

        mov rdx, rdi
        cld

.proceed:

        mov rax, rbx    ; ax = N

        and rax, 07h

        add al, ZERO

        stosb

        shr rbx, 1h
        jnz .proceed


        mov rbx, rdx
        sub rdi, 1

.reverse:
        mov al, [rdi]
        mov dl, [rbx]
        mov [rdi], dl
        mov [rbx], al

        inc rbx
        dec rdi

        cmp rbx, rdi
        jb .reverse

        ret
;------------------------------------------------

;------------------------------------------------
; Entry:
; RDI - destination index
; RBX - input integer
; Destr: RAX, RDX
;------------------------------------------------
binary:

        mov rdx, rdi
        cld

.proceed:

        mov rax, rbx    ; ax = N

        and rax, 01h

        add al, ZERO

        stosb

        shr rbx, 1h
        jnz .proceed

        mov rbx, rdx
        sub rdi, 1

.reverse:
        mov al, [rdi]
        mov dl, [rbx]
        mov [rdi], dl
        mov [rbx], al

        inc rbx
        dec rdi

        cmp rbx, rdi
        jb .reverse

        ret
;------------------------------------------------

        SECTION .data

.SWITCH_TABLE:
    dq my_default
    dq binary
    dq char
    dq decimal
    dq 10 dup (my_default)
    dq octal
    dq 3  dup (my_default)
    dq string
    dq 4  dup (my_default)
    dq hex
    dq 2  dup (my_default)
