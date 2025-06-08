format ELF64

section '.text' executable

exit:
    mov     rdi, rax
    mov     rax, 60
    syscall

public _start

_start:

    mov     rax, 42
    call    exit
