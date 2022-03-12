;; This is NASM Syntax
;; x86-64
;; (C) Demqa Alexeev

%define n_cases        25
%define TEN            10
%define MINUS         '-'
%define ZERO          '0'
%define ONE           '1'
%define SEVEN         '7'
%define NINE          '9'
%define LETTER_A      'A'
%define LETTER_F      'F'
%define BUFF_MAX_SIZE  0xB0

        GLOBAL _start

;; There can be stored some data used for my printf function

        SECTION .data

Msg1:   db "love", 0x00

Msg:
        db "I love %x na %b%%%c", 0x0A
        db "I %s %x na %d%%%c%b", 0x0A
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

        push 255
        push 33
        push 100
        push 3802
        push Msg1
        push '!'
        push 8
        push 3802
        push Msg

        call printf


        mov rax, 0x3C               ; rax = 0x3c Terminate Function
        xor rdi, rdi                ; rdi = 0

        syscall

printf:

        pop  rax
        pop  rsi                ; getting string address
        push rax

        push rbp
        mov  rbp, rsp

        cld
        mov  rdi, Buff
        xor  rax, rax
        xor   cx, cx

.loop:
        cmp  cx, 0xB0
        jb   .resume

        call clearbuff

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
        jae .loop

;;      There I have to hand over somehow arguement (lol it is just the last pushed item)
;;      BUT   I have to remenber that fact, there goes call, so I have to get the second pushed item...

        mov  rdx, [SWITCH_TABLE + 8 * rax]

        pop  rax                ; saving    rbp
        pop  r9                 ; saving    ret address
        pop  rbx                ; putting argument in rbx                       ;
        push r9                 ; restoring ret address
        push rax                ; restoring rbp

        call rdx                ; calling func from jumptable

        jmp .loop

.skip:

        cmp al, 0x00
        je .print

        inc cx
        stosb

        jmp .loop

.print:

        call clearbuff

.ret:

        pop  rbp
        ret

clearbuff:

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
;
; Destr:
;------------------------------------------------
char:

        mov [rdi], bl
        inc  rdi
        inc  cx

        ret
;------------------------------------------------

;------------------------------------------------
; Entry:
; RBX - address of string
; Destr:
;------------------------------------------------
string:

        mov r8, rsi

        cld
        mov rsi, rbx

.loop:

        lodsb

        cmp al, 0
        je  .ret

        stosb
        inc cx

        cmp cx, BUFF_MAX_SIZE
        jbe .loop

        call clearbuff
        jmp .loop


.ret:
        mov rsi, r8
        ret
;------------------------------------------------

;------------------------------------------------
; Entry:
; RDI - destination index
; Destr: RAX, RBX, RCX, RDX, R8
;------------------------------------------------
decimal:

        mov  r8, TEN

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
        div r8          ; ax = N / 10

        mov rbx, rax    ; saving next integer

        mov rax, rdx    ; ax = N % 10

        add al, ZERO

        stosb
        inc  cx

        cmp rbx, 0h
        jne .proceed

        pop rbx

        mov r8, rdi

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

        mov rdi, r8

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
        inc cx

        shr rbx, 4h
        jnz .proceed


        mov rbx, rdx
        mov  r8, rdi

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

        mov rdi, r8

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
        inc cx

        shr rbx, 1h
        jnz .proceed


        mov rbx, rdx
        mov  r8, rdi
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

        mov rdi, r8

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
        inc cx

        shr rbx, 1h
        jnz .proceed

        mov rbx, rdx
        mov  r8, rdi
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

        mov rdi, r8

        ret
;------------------------------------------------

        SECTION .data

SWITCH_TABLE:
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
