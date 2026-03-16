.intel_syntax noprefix
.global _start

.section .bss
    buffer: .skip 30000
    code_buf: .skip 65536
    jit_base: .skip 8

.section .text
_start: 
    # check argc >= 2
    mov rax, [rsp]
    cmp rax, 2
    jl .exit_error

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

    mov [jit_base], rax
    # code pointer
    lea rsi, [code_buf]
    # value pointer
    lea rdi, [buffer]
    # jit pointer
    mov r12, rax

.interpreter_loop:
    mov al, [rsi]
    # exit if reached null terminator
    cmp al, 0
    je .run_and_exit

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

.run_and_exit:
    # ret
    mov byte ptr [r12], 0xc3

    mov rax, [jit_base]
    call rax

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
    inc rsi
    mov dword ptr [r12], 0x00c7ff48
    add r12, 3
    jmp .interpreter_loop

.dec_pointer:
    inc rsi
    mov dword ptr [r12], 0x00cfff48
    add r12, 3
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

