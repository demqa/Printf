;; This is NASM Syntax
;; x86-64
;; (C) Demqa Alexeev

        GLOBAL _start

        SECTION .text

_start:

        mov rax, 0x01               ; rax = 0x01 Write Function
        mov rdi, 1                  ; rdi = 1,  stdout file descriptor

        mov rsi, Msg                ; rsi = string out address
        mov rdx, MsgLen             ; rdx = string out length

        syscall


        mov rax, 0x3C               ; rax = 0x3c Terminate Function
        xor rdi, rdi                ; rdi = 0

        syscall


        SECTION .data

Msg:    db "Hello, World!", 0x0A
MsgLen  equ $ - Msg
