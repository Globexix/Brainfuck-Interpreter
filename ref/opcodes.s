# hex-lookup reference
# as -o opcodes.o opcodes.s && objdump -d opcodes.o -M intel
.intel_syntax noprefix
inc rdi               # >
dec rdi               # <
inc byte ptr [rdi]    # +
dec byte ptr [rdi]    # -

# sys write
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

ret
