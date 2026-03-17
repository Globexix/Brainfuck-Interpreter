.intel_syntax noprefix
.global _start

.section .rodata
filename: .asciz "a.out"

elf_header:
    # magic number
    .byte 0x7f, 0x45, 0x4c, 0x46
    # 64 bit
    .byte 0x02
    # little endian
    .byte 0x01
    # elf version
    .byte 0x01
    # system V ABI
    .byte 0x00
    # padding
    .byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
    # executable file
    .word 0x0002
    # x86-64
    .word 0x003e
    # elf version
    .int 0x00000001
    # entry point
    .quad 0x0000000000400078
    # program header offset (right after elf header)
    .quad 0x0000000000000040
    # section header offset (none)
    .quad 0x0000000000000000
    # flags
    .int 0x00000000
    # elf header size
    .word 0x0040
    # program header entry size
    .word 0x0038
    # program header count
    .word 0x0001
    # section header entry size
    .word 0x0040
    # section header count
    .word 0x0000
    # section name string table index
    .word 0x0000

.section .data
program_header:
    # PT_LOAD
    .int 0x00000001
    # flags: read + write + execute
    .int 0x00000007
    # offset in file
    .quad 0x0000000000000000
    # virtual address
    .quad 0x0000000000400000
    # physical address
    .quad 0x0000000000400000
    # size in file (patched at runtime)
    .quad 0x0000000000000000
    # size in memory (patched at runtime)
    .quad 0x0000000000000000
    # alignment
    .quad 0x0000000000200000


.section .bss
    buffer: .skip 30000
    code_buf: .skip 65536
    bin_buf: .skip 8

.section .text
_start: 
    # check argc >= 2
    mov rax, [rsp]
    cmp rax, 2
    jl .exit_error

    # check if argv[2] exists
    cmp rax, 3
    jl .use_default

    mov r13, [rsp + 24]
    jmp .open_file

.use_default:
    lea r13, [filename]

.open_file:
    # sys open
    mov rdi, [rsp + 16]
    mov rax, 2
    xor rsi, rsi
    xor rdx, rdx
    syscall

    cmp rax, 0
    jl .exit_error
    # save fd
    mov r8, rax

    # sys read
    mov rdi, r8 # fd
    mov rax, 0
    lea rsi, [code_buf]
    mov rdx, 65536
    syscall

    # sys close
    mov rdi, r8 # fd
    mov rax, 3
    syscall

    # allocate RWX memory
    mov rax, 9
    mov rdi, 0
    mov rsi, 65536
    mov rdx, 7
    mov r10, 0x22
    mov r8, -1
    mov r9, 0
    syscall

    cmp rax, 0
    jl .exit_error

    mov [bin_buf], rax
    # code ptr
    lea rsi, [code_buf]
    # emit ptr
    mov r12, rax

    # emit preamble
    # 48 8d 3d 00 00 00 00
    mov dword ptr [r12], 0x003d8d48
    mov dword ptr [r12 + 3], 0x00000000
    add r12, 7



.interpreter_loop:
    mov al, [rsi]
    # exit if reached null terminator
    cmp al, 0
    je .compile_and_exit

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

    cmp al, ','
    je .read_value

    cmp al, '['
    je .jump_forward

    cmp al, ']'
    je .jump_back

    inc rsi
    jmp .interpreter_loop

.compile_and_exit:
    # exit
    # 48 c7 c0 3c 00 00 00
    movabs rax, 0x000000003cc0c748
    mov qword ptr [r12], rax
    # 48 31 ff
    mov dword ptr [r12 + 7], 0xff3148
    # 0f 05
    mov word ptr [r12 + 10], 0x050f
    add r12, 12

    # calc size
    mov rax, [bin_buf]
    sub r12, rax

    # patch preamble
    mov r8, r12
    sub r8, 7
    mov dword ptr [rax + 3], r8d

    add r12, 120
    # patch ph
    mov qword ptr [program_header + 32], r12
    add r12, 30000
    mov qword ptr [program_header + 40], r12
    sub r12, 30000

    # sys open
    mov rax, 2
    mov rdi, r13
    mov rsi, 0x241
    mov rdx, 0x1ED
    syscall
    mov r14, rax # fd

    # write ELF header
    mov rax, 1
    mov rdi, r14
    lea rsi, [elf_header]
    mov rdx, 64
    syscall

    # write program header
    mov rax, 1
    mov rdi, r14
    lea rsi, [program_header]
    mov rdx, 56
    syscall

    # write code
    mov rax, 1
    mov rdi, r14
    mov rsi, [bin_buf]
    sub r12, 120
    mov rdx, r12
    syscall

    # sys close
    mov rax, 3
    mov rdi, r14
    syscall

    mov rax, 60
    xor rdi, rdi
    syscall

.exit_error:
    mov rax, 60
    mov rdi, 1
    syscall

.increment:
    xor rcx, rcx

.inc_loop:
    cmp byte ptr [rsi], '+'
    jne .inc_done
    inc rcx
    inc rsi
    jmp .inc_loop

.inc_done:
    cmp rcx, 1
    jg .inc_multi

    mov word ptr [r12], 0x07fe
    add r12, 2
    jmp .interpreter_loop

.inc_multi:
    # 80 07 (cl)
    mov word ptr [r12], 0x0780
    mov byte ptr[r12 + 2], cl

    add r12, 3  
    jmp .interpreter_loop

.decrement:
    xor rcx, rcx
.dec_loop:
    cmp byte ptr [rsi], '-'
    jne .dec_done
    inc rcx
    inc rsi
    jmp .dec_loop

.dec_done:
    cmp rcx, 1
    jg .dec_multi

    mov word ptr[r12], 0x0ffe
    add r12, 2
    jmp .interpreter_loop

.dec_multi:
    # 80 2f (cl)
    mov word ptr [r12], 0x2f80
    mov byte ptr [r12 + 2], cl
    add r12, 3
    jmp .interpreter_loop

.inc_pointer:
    xor rcx, rcx

.inc_pointer_loop:
    cmp byte ptr [rsi], '>'
    jne .inc_pointer_done
    inc rcx
    inc rsi
    jmp .inc_pointer_loop

.inc_pointer_done:
    cmp rcx, 1
    jg .inc_pointer_multi

    mov dword ptr [r12], 0x00c7ff48
    add r12, 3
    jmp .interpreter_loop

.inc_pointer_multi:
    # 48 83 c7 (cl)
    mov dword ptr [r12], 0xc78348
    mov byte ptr [r12 + 3], cl
    add r12, 4
    jmp .interpreter_loop


.dec_pointer:
    xor rcx, rcx

.dec_pointer_loop:
    cmp byte ptr [rsi], '<'
    jne .dec_pointer_done
    inc rcx
    inc rsi
    jmp .dec_pointer_loop

.dec_pointer_done:
    cmp rcx, 1
    jg .dec_pointer_multi

    mov dword ptr [r12], 0x00cfff48
    add r12, 3
    jmp .interpreter_loop

.dec_pointer_multi:
    # 48 83 ef (cl)
    mov dword ptr [r12], 0xef8348
    mov byte ptr [r12 + 3], cl
    add r12, 4
    jmp .interpreter_loop

.print_value: 
    # 56 57 51 48 c7 c0 01 00
    movabs rax, 0x0001c0c748515756
    mov qword ptr [r12], rax
    # 00 00 48 8d 37 48 c7 c7
    movabs rax, 0xc7c748378d480000
    mov qword ptr[r12 + 8], rax
    # 01 00 00 00 48 c7 c2 01
    movabs rax, 0x01c2c74800000001
    mov qword ptr[r12 + 16], rax
    # 00 00 00 0f 05 59 5f 5e
    movabs rax, 0x5e5f59050f000000
    mov qword ptr [r12 + 24], rax
    
    add r12, 32
    
    inc rsi
    jmp .interpreter_loop

.read_value:
    # 56 57 51 48 89 fe 48 c7
    movabs rax, 0xc748fe8948515756
    mov qword ptr [r12], rax
    # c0 00 00 00 00 48 c7 c7
    movabs rax, 0xc7c74800000000c0
    mov qword ptr [r12 + 8], rax
    # 00 00 00 00 48 c7 c2 01
    movabs rax, 0x01c2c74800000000
    mov qword ptr [r12 + 16], rax
    # 00 00 00 0f 05 59 5f 5e
    movabs rax, 0x5e5f59050f000000
    mov qword ptr [r12 + 24], rax
    
    add r12, 32
    
    inc rsi
    jmp .interpreter_loop

.jump_forward:
    # 80 3f 00 0f 84 00 00 00 00

    # 80 3f 00 0f
    mov dword ptr [r12], 0x0f003f80
    # 84 00 00 00
    mov dword ptr[r12 + 4], 0x00000084
    # 00
    mov byte ptr [r12 + 8], 0x00

    add r12, 9

    # push end of '[' to stack
    push r12

    inc rsi
    jmp .interpreter_loop

.jump_back:
    # pop end of '[' into r8
    pop r8
    
    # 80 3f 00 0f 85
    mov dword ptr [r12], 0x0f003f80
    mov byte ptr[r12 + 4], 0x85

    # end of current ']' instruction
    lea r9, [r12 + 9]

    # offset = dest - source end
    # target is r9 (end of ']'), source is r8 (end of '[')
    mov rax, r9
    sub rax, r8

    # patch '[' offset (4 bytes before its end)
    mov dword ptr[r8 - 4], eax

    # jump back offset
    neg eax

    # write offset into current ']' (starts at r12 + 5)
    mov dword ptr[r12 + 5], eax

    add r12, 9

    inc rsi
    jmp .interpreter_loop
