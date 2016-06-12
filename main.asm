;; -*- Mode: nasm -*-

DEFAULT REL
BITS 64

%include "syscalls.inc"
%include "gc.inc"

GLOBAL _start
EXTERN garbage_collect

SECTION .rodata

;; Nothing here yet

SECTION .text

die:
  ud2a

;; Still uses the stack, as this is before we set up our GC scheme.
;; Input:
;; RDI = address to map (saved across calls)
;; RSI = size in bytes  (saved across calls)
;; Output:
;; all clobbered, except RDI/RSI
mmap:
  mov eax, SYSCALL_MMAP
  mov rdx, PROT_READ | PROT_WRITE
  mov r10, MAP_ANONYMOUS | MAP_FIXED | MAP_PRIVATE
  mov r8, -1
  mov r9, 0
  syscall
  ; Bail out, if we didn't get our memory.
  cmp rax, rdi
  jne die
  ret

_start:

  ; Allocate heap
  mov rdi, FROM_SPACE
  mov rsi, HEAP_SIZE
  call mmap
  mov rdi, TO_SPACE
  call mmap

  ; We keep our current allocation pointer in RSP.
  mov rsp, FROM_SPACE

  ; The end of our allocation area is in RBP.
  mov rbp, TO_SPACE

  mov FP, 0
  call_gc main

exit:
  mov eax, SYSCALL_EXIT
  mov edi, 0
  syscall
  ud2a


main:
  prologue 0

  ; Nothing to do yet

  ret_gc

;; EOF
