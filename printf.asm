;; This is NASM Syntax
;; x86-64
;; (C) Demqa Alexeev

        GLOBAL _start

        SECTION .data
    ;; There can be some data used for my printf function
Msg:    db "My string", 0x0A, 0x00


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
        cmp  cx, 0xB0
        jb   .resume

        call .clearbuff

.resume:

        lodsb

        cmp  al, '%'
        jne  .skip

;;      Proceeding Specific formats
;;      There will be JUMP TABLE

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

        pop rax
        pop rdx
        pop rdi
        pop rsi


        mov cx, 0
        ret
