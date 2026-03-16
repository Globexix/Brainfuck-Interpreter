# bf-asm

A brainfuck interpreter written in x86-64 assembly (Linux).

## Usage

```bash
./brainfuck program.bf
```

## Building

```bash
as --64 -o brainfuck.o brainfuck.s && ld -o brainfuck brainfuck.o
```

## Supported instructions

| Instruction | Description |
|---|---|
| `+` | Increment current cell |
| `-` | Decrement current cell |
| `>` | Move pointer right |
| `<` | Move pointer left |
| `.` | Output current cell as ASCII |
| `,` | Read one byte from stdin |
| `[` | Jump forward if current cell is zero |
| `]` | Jump back if current cell is nonzero |