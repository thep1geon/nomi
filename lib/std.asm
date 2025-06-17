public sys_exit
; Function
;
;   args:
;       rdi - exit code
;   stack:
;       n/a
;   
; Note:
;   No effort is made here to preserve the return address since we are
;   going to exit the program anyay. This is the only function which doesn't
;   handle this
sys_exit:
    mov     rax, 0x3c   ; syscall #60 - exit
    syscall
    
public _start
; Function
;
;   args:
;       n/a (yet)
;   stack:
;       n/a
;
; Note:
;   The entry point of the program. This will eventuall be the minimal run-time
;   as we continue to add features to the language.
_start:
    ; Other initialization stuff will go here eventually
    call    main        ; Call the main function
    mov     rdi, rax    ; Move the exit value of rax into rdi
    call    sys_exit    ; Exit the program with whatever main returned with
