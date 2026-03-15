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
    mov rax, 60
    xor rdi, rdi
    syscall