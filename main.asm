;; -*- Mode: nasm -*-

DEFAULT REL
BITS 64

%include "syscalls.inc"
%include "gc.inc"

GLOBAL main
EXTERN garbage_collect

SECTION .rodata

SECTION .text

;; Write string to STDOUT.
;; Input:
;; GPR_INT0 (rax) = pointer to buffer
;; GPR_INT1 (rdx) = length of buffer
;; Clobbers:
;; GPR_INT2, GPR_INT6, GPR_PTR2
write:
  prologue 0, 0

  mov rdi, FILENO_STDOUT
  mov rsi, GPR_INT0
  ; mov rdx, GPR_INT1 (pointless)
  mov eax, SYSCALL_WRITE
  syscall

  xor GPR_PTR2, GPR_PTR2        ; destroyed by syscall

  ret_gc

;; Create a cons object
;; Input:
;; GPR_PTR0 the 'first' part of the cons
;; GPR_PTR1 the 'rest' part of the cons
;; Output:
;; GPR_PTR0 a pointer to the cons object
cons:
  allocate GPR_PTR3, CONS, 0
  mov [GPR_PTR3 + CONS.FIRST], GPR_PTR0
  mov [GPR_PTR3 + CONS.REST],  GPR_PTR1
  mov GPR_PTR0, GPR_PTR3
  jmp LINK

;; Compute the fibonacci sequence in the braindead recursive way to have a
;; benchmark for function call performance.
;; Input:
;; GPR_INT0 the index of the fibonacci number to calucate
;; Output:
;; GPR_INT0 the fibonacci number
fibonacci:
  cmp GPR_INT0, 1
  ja .non_trivial
  jmp LINK
.non_trivial:

  prologue 1, 0

  mov LOCAL_VAR(0), GPR_INT0
  dec GPR_INT0
  call_gc fibonacci
  xchg LOCAL_VAR(0), GPR_INT0
  sub GPR_INT0, 2
  call_gc fibonacci
  add GPR_INT0, LOCAL_VAR(0)
  ret_gc

main:
  prologue 0, 0

  mov GPR_INT0, 40
  call_gc fibonacci

  ret_gc

;; EOF
