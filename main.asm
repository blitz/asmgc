;; -*- Mode: nasm -*-

DEFAULT REL
BITS 64

%include "syscalls.inc"
%include "gc.inc"

GLOBAL main
EXTERN garbage_collect

SECTION .rodata

hello_str: db "hello", 10
world_str: db "world", 10


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

  ret_gc


main:
  prologue 0

  lea GPR_INT0, [hello_str]
  mov GPR_INT1, 6
  call_gc write

  lea GPR_INT0, [world_str]
  mov GPR_INT1, 6
  call_gc write

  ret_gc

;; EOF
