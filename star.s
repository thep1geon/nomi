    .text
    .globl main
main:
    pushq      %rbp
    movq       %rsp, %rbp
    movq       $97, %rdi
    call       toupper
    movq       %rax, %rdi
    call       putchar
    movq       $97, %rdi
    call       putchar
    movq       $32, %rdi
    call       putchar
    movq       $98, %rdi
    call       toupper
    movq       %rax, %rdi
    call       putchar
    movq       $98, %rdi
    call       putchar
    movq       $32, %rdi
    call       putchar
    movq       $99, %rdi
    call       toupper
    movq       %rax, %rdi
    call       putchar
    movq       $99, %rdi
    call       putchar
    movq       $32, %rdi
    call       putchar
    movq       $10, %rdi
    call       putchar
    popq       %rbp
    ret
