;; -*- Mode: nasm -*-

DEFAULT REL
BITS 64

%include "syscalls.inc"
%include "gc.inc"

GLOBAL _start
GLOBAL _c_stack

EXTERN garbage_collect

SECTION .rodata

hello_str: db "hello", 10
world_str: db "world", 10

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
