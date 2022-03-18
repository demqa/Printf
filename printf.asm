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

;; There can be stored some data used for my printf function


        EXTERN main
        GLOBAL _start
        GLOBAL RTprintf


        SECTION .bss

Buff:   resb 0x100

        SECTION .text


_start:
        call main

        mov rax, 0x3C           ; Terminate Function 0x3C
        xor rdi, rdi
        syscall

;; I'm usign System V calling convention
;;              1    2    3    4    5   6
;; PARAMETERS: RDI, RSI, RDX, RCX, R8, R9
;; AND FURTHER VALUES ARE PASSED IN STACK IN REVERSE ORDER (7th on the top and there we go...)
;;
;; +--------------+--------------+--------------+------------+
;; | Callee saved | Caller saved | Return Value | parameters |
;; |--------------+--------------+--------------+------------|
;; |     RBX      |     R10      |     RAX      |    RDI     |
;; |     RBP      |     R11      |              |    RSI     |
;; |     R12      |              |              |    RDX     |
;; |     R13      |              |              |    RCX     |
;; |     R14      |              |              |    R8      |
;; |     R15      |              |              |    R9      |
;; +--------------+--------------+--------------+------------+
;;
;; CALLER PUSHES & POPS PARAMETERS


RTprintf:

        push rbp
        mov  rbp, rsp

        cld

        push r9
        push r8
        push rcx
        push rdx
        push rsi

        push rbx                ; saving used register

        sub  rbp, 56            ; moving rbp that way
                                ; that [rbp - 16] will
                                ; be next parameter

        xchg rsi, rdi           ; <----- it is mov rsi, rdi
        mov  rdi, Buff          ; xchg because it is 1 byte

        xor  r9,  r9
        xor  r10, r10

.loop:
        cmp  r10, BUFF_MAX_SIZE
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
        inc r10

        jmp .loop

.jumptable:

        sub al, 'a'

        cmp al, n_cases
        jae .loop

;;      There I have to hand over somehow arguement (lol it is just the last pushed item)
;;      BUT   I have to remenber that fact, there goes call, so I have to get the second pushed item...

        mov  rdx, [SWITCH_TABLE + 8 * rax]

        cmp  r9, 5              ; checking if parameters > than 5
        jne .normal             ; then i should shift rbp on minus 16

        add rbp, 16

.normal:

        inc r9                  ; number of parameters printed in this moment

        mov  rbx, [rbp + 16]    ; taking the next parameter
        add  rbp, 8             ; move the pointer on the next

        call rdx                ; calling func from jumptable

        jmp .loop

.skip:

        cmp al, 0x00
        je .print

        inc r10
        stosb

        jmp .loop

.print:

        call clearbuff          ; exit print

.ret:

        pop rbx                 ; restoring rbx

        add rsp, 40             ; remove helping values

        mov rax, r9             ; number of arguements printed successfully

        pop rbp
        ret

clearbuff:

        push rsi
        push rdi
        push rdx
        push rax
        push rcx

        mov  rax, 0x01
        mov  rdi, 1

        mov  rsi, Buff
        mov  rdx, r10

        syscall

        pop  rcx
        pop  rax
        pop  rdx
        pop  rdi
        pop  rsi

        mov  rdi, Buff
        mov  r10, 0

        ret

my_default:

        ;; There I have to say user that there was an error...

        ret

;------------------------------------------------
; Entry:
;
; Destr:
;------------------------------------------------
char:

        mov [rdi], bl
        inc  rdi
        inc  r10

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
        inc r10

        cmp r10, BUFF_MAX_SIZE
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
        inc r10

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
        inc r10

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
        inc r10

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
        inc r10

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



SWITCH_TABLE:
    dq my_default        ; a
    dq binary            ; b
    dq char              ; c
    dq decimal           ; d
    dq my_default        ; e
    dq my_default        ; f
    dq my_default        ; g
    dq my_default        ; h
    dq my_default        ; i
    dq my_default        ; j
    dq my_default        ; k
    dq my_default        ; l
    dq my_default        ; m
    dq my_default        ; n
    dq octal             ; o
    dq my_default        ; p
    dq my_default        ; q
    dq my_default        ; r
    dq string            ; s
    dq my_default        ; t
    dq my_default        ; u
    dq my_default        ; v
    dq my_default        ; w
    dq hex               ; x
    dq my_default        ; y
    dq my_default        ; z
