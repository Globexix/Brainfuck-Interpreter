.intel_syntax noprefix
.global elf_header
.global program_header

.section .rodata

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
    