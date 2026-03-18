.intel_syntax noprefix
.global bf_interpreter

.section .text
bf_interpreter:

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

    cmp al, ','
    je .read_input

    cmp al, '['
    je .jump_forward

    cmp al, ']'
    je .jump_back

    inc rsi
    jmp .interpreter_loop

.exit:
    xor rax, rax
    ret

.exit_error:
    mov rax, 1
    ret

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
    push rsi
    push rdi
    push rcx

    mov rax, 1
    lea rsi, [rdi]
    mov rdi, 1
    mov rdx, 1
    syscall

    pop rcx
    pop rdi
    pop rsi
    
    inc rsi
    jmp .interpreter_loop

.read_input:
    push rsi
    push rdi
    push rcx

    mov rsi, rdi
    mov rax, 0
    mov rdi, 0
    mov rdx, 1
    syscall

    pop rcx
    pop rdi
    pop rsi

    inc rsi
    jmp .interpreter_loop


.jump_forward:
    cmp byte ptr [rdi], 0
    jne .skip_forward
    
    mov rcx, 1
.jump_forward_loop:
    inc rsi

    mov al, [rsi]
    cmp al, '['
    je .jump_forward_inc_depth

    cmp al, ']'
    je .jump_forward_dec_depth
    jmp .jump_forward_loop

.jump_forward_inc_depth:
    inc rcx
    jmp .jump_forward_loop

.jump_forward_dec_depth:
    dec rcx
    jnz .jump_forward_loop
    inc rsi
    jmp .interpreter_loop

.skip_forward:
    inc rsi
    jmp .interpreter_loop

.jump_back:
    cmp byte ptr [rdi], 0
    je .skip_back 

    mov rcx, 1

.jump_back_loop:
    dec rsi

    mov al, [rsi]
    cmp al, ']'
    je .jump_back_inc_depth

    cmp al, '['
    je .jump_back_dec_depth
    jmp .jump_back_loop

.jump_back_inc_depth:
    inc rcx
    jmp .jump_back_loop

.jump_back_dec_depth:
    dec rcx
    jnz .jump_back_loop
    inc rsi
    jmp .interpreter_loop

.skip_back:
    inc rsi
    jmp .interpreter_loop
