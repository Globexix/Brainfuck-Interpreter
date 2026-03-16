.intel_syntax noprefix
.global _start

.section .rodata
    # Hello World!
    code: .ascii "++++++++[>++++[>++>+++>+++>+<<<<-]>+>+>->>+[<]<-]>>.>---.+++++++..+++.>>.<-.<.+++.------.--------.>>+.>++."
    .byte 0

.section .bss
    buffer: .skip 30000

.section .text
_start: 
    # code pointer
    # load adress of 'code' into rsi
    lea rsi, [code]

    # value pointer
    lea rdi, [buffer]

.interpreter_loop:
    mov al, [rsi]
    # exit if reached null terminator
    cmp al, 0
    je .exit

    cmp al, '+'
    je .increment

    cmp al, '-'
    je .decrement

    cmp al, '>'
    je .inc_pointer

    cmp al, '<'
    je .dec_pointer

    cmp al, '.'
    je .print_value

    inc rsi
    jmp .interpreter_loop

.exit:
    # print buffer to debug with strace ./brainfuck 
    mov rax, 1          
    mov rdi, 1         
    lea rsi, [buffer]
    mov rdx, 30000      
    syscall

    mov rax, 60
    xor rdi, rdi
    syscall

.increment:
    inc rsi
    inc byte ptr [rdi]
    jmp .interpreter_loop

.decrement:
    inc rsi
    dec byte ptr [rdi]
    jmp .interpreter_loop

.inc_pointer:
    inc rsi
    inc rdi
    jmp .interpreter_loop

.dec_pointer:
    inc rsi
    dec rdi 
    jmp .interpreter_loop

.print_value:
    call .print
    inc rsi
    jmp .interpreter_loop

.print: 
    push rsi
    push rdi

    mov rax, 1
    lea rsi, [rdi]
    mov rdi, 1
    mov rdx, 1
    syscall

    pop rsi
    pop rdi
    ret
