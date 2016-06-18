;; -*- Mode: nasm -*-

DEFAULT REL
BITS 64

%include "syscalls.inc"
%include "gc.inc"

GLOBAL _start
GLOBAL _c_stack

EXTERN garbage_collect
EXTERN main

SECTION .bss

;; Contains a pointer to the original C stack
_c_stack:  resq 1

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

  ; We need a real stack later when we want to call into C. Let's use the initial stack.
  mov [_c_stack], rsp

  ; Allocate heap
  mov rdi, FROM_SPACE
  mov rsi, HEAP_SIZE
  call mmap
  mov rdi, TO_SPACE
  call mmap

  ; Initialize the allocator
  mov ALLOC,     FROM_SPACE
  mov ALLOC_END, FROM_SPACE + HEAP_SIZE

  ; Clear garbage in pointer registers to avoid confusing the GC
  xor GPR_PTR0, GPR_PTR0
  xor GPR_PTR1, GPR_PTR1
  xor GPR_PTR2, GPR_PTR2
  xor GPR_PTR3, GPR_PTR3

  xor FP, FP
  call_gc main

exit:
  mov rdi, GPR_INT0
  mov eax, SYSCALL_EXIT
  syscall
  ud2a

;; EOF
