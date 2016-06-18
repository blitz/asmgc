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
  prologue 0

  mov rdi, FILENO_STDOUT
  mov rsi, GPR_INT0
  ; mov rdx, GPR_INT1 (pointless)
  mov eax, SYSCALL_WRITE
  syscall

  xor GPR_PTR2, GPR_PTR2        ; destroyed by syscall

  ret_gc


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

  prologue 8

  mov [FP + FRAME.LOCAL_VAR + 0], GPR_INT0
  dec GPR_INT0
  call_gc fibonacci
  mov GPR_INT1, GPR_INT0        ; result
  mov GPR_INT0, [FP + FRAME.LOCAL_VAR + 0]
  mov [FP + FRAME.LOCAL_VAR + 0], GPR_INT1
  sub GPR_INT0, 2
  call_gc fibonacci
  add GPR_INT0, [FP + FRAME.LOCAL_VAR + 0]
  ret_gc

main:
  prologue 0

  mov GPR_INT0, 45
  call_gc fibonacci

  ret_gc

;; EOF
