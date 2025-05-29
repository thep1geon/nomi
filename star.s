    .text
    .globl main
main:
    pushq      %rbp
    movq       %rsp, %rbp
    pushq      $65
    popq       %rdi
    call       putchar
    popq       %rbp
    ret
