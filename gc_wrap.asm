;; -*- Mode: nasm -*-

DEFAULT REL
BITS 64

%include "gc.inc"

GLOBAL garbage_collect
EXTERN _c_stack
EXTERN c_collect

SECTION .bss

;; Storage for garbage collection roots. FP and 4 GPR_PTR registers.
_gc_roots:
  resq 5


;; All integer registers that are not GC pointers.
_gc_nonroots:
  resq 8

SECTION .text

garbage_collect:
  ; Nothing here yet.

  mov [_gc_roots + 0x00], FP
  mov [_gc_roots + 0x08], GPR_PTR0
  mov [_gc_roots + 0x10], GPR_PTR1
  mov [_gc_roots + 0x18], GPR_PTR2
  mov [_gc_roots + 0x20], GPR_PTR3

  mov [_gc_nonroots + 0x00], LINK
  mov [_gc_nonroots + 0x08], GPR_INT0
  mov [_gc_nonroots + 0x10], GPR_INT1
  mov [_gc_nonroots + 0x18], GPR_INT2
  mov [_gc_nonroots + 0x20], GPR_INT3
  mov [_gc_nonroots + 0x28], GPR_INT4
  mov [_gc_nonroots + 0x30], GPR_INT5
  mov [_gc_nonroots + 0x38], GPR_INT6

  and ALLOC, ~(HEAP_SIZE - 1)     ; Beginning of current allocation area
  mov rdx, FROM_SPACE
  cmp ALLOC, rdx
  mov rcx, TO_SPACE
  je .skip
  xchg rdx, rcx
.skip:

  mov rsp, [_c_stack]

  lea rdi, [_gc_roots]
  mov rsi, 5
  mov r8,  HEAP_SIZE
  ; c_collect(uint64_t *root_array, size_t roots, void *from, void *to, size_t heap_size)

  call c_collect

  ; We get our new allocation pointer back
  mov ALLOC, rax
  and rax, ~(HEAP_SIZE - 1)
  lea ALLOC_END, [rax + HEAP_SIZE]

  mov FP,       [_gc_roots + 0x00]
  mov GPR_PTR0, [_gc_roots + 0x08]
  mov GPR_PTR1, [_gc_roots + 0x10]
  mov GPR_PTR2, [_gc_roots + 0x18]
  mov GPR_PTR3, [_gc_roots + 0x20]

  mov LINK,     [_gc_nonroots + 0x00]
  mov GPR_INT0, [_gc_nonroots + 0x08]
  mov GPR_INT1, [_gc_nonroots + 0x10]
  mov GPR_INT2, [_gc_nonroots + 0x18]
  mov GPR_INT3, [_gc_nonroots + 0x20]
  mov GPR_INT4, [_gc_nonroots + 0x28]
  mov GPR_INT5, [_gc_nonroots + 0x30]
  mov GPR_INT6, [_gc_nonroots + 0x38]

  jmp LINK

;; EOF
