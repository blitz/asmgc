;; -*- Mode: nasm -*-

DEFAULT REL
BITS 64

%include "syscalls.inc"

GLOBAL _start

%define HEAP_SIZE     (1<<21)

%define FROM_SPACE    (1<<30)
%define TO_SPACE      FROM_SPACE + 2*HEAP_SIZE


;; We use our registers like this:
;; RAX, RDX, RCX, RBX and R13-R15 = general purpose non-pointer values
%define GPR_INT0 rax
%define GPR_INT1 rdx
%define GPR_INT2 rcx
%define GPR_INT3 rbx
%define GPR_INT4 r13
%define GPR_INT5 r14
%define GPR_INT6 r15

;; RSI = frame pointer register
%define FP       rbp

;; RDI = link register
%define LINK     rdi

;; RSP = allocation area
%define ALLOC     rsp
%define ALLOC_END r8

;; R9 to r12 are for pointer values
%define GPR_PTR0  r9
%define GPR_PTR1  r10
%define GPR_PTR2  r11
%define GPR_PTR3  r12


;; Layout of heap object
%define OBJ_SIZE         0
%define OBJ_TYPE         4

%define OBJ_HEADER_SIZE  (OBJ_TYPE + 4)

;; The different object types
%define OBJ_TYPE_FRAME   0

;; Layout of function frame
%define FRAME_LAST_FRAME OBJ_HEADER_SIZE
%define FRAME_LINK       (OBJ_HEADER_SIZE + 8)

%define FRAME_HEADER_SIZE (FRAME_LINK+8)

;; Allocate the given amount of bytes (parameter 1) and return a pointer in GPR_PTR0. The memory is marked with the given type (parameter 2).
;; Output:
;; GPR_PTR0 = pointer to allocated space
;; LINK clobbered
%macro allocate 2
  %%again:
  lea GPR_PTR0, [ALLOC + %1]
  lea LINK, [%%again]
  cmp GPR_PTR0, ALLOC_END
  jae garbage_collect
  xchg GPR_PTR0, ALLOC
  mov dword [GPR_PTR0 + OBJ_SIZE], %1
  mov dword [GPR_PTR0 + OBJ_TYPE], %2
  %%enough_space:
%endmacro

;; Generate a function prologue with the given bytes (parameter 1) of additional memory in the function frame.
;; Input:
;; LINK the link pointer to store in the function frame
;; FP   the frame pointer to store in the function frame
;; Output:
;; FP   the new function frame
;; Clobbers GPR_PTR0, GPR_INT5, GPR_INT6
%macro prologue 1
  mov GPR_INT5, LINK
  allocate (FRAME_HEADER_SIZE + %1), OBJ_TYPE_FRAME
  mov [GPR_PTR0 + FRAME_LAST_FRAME], FP
  mov [GPR_PTR0 + FRAME_LINK], GPR_INT5
  mov FP, GPR_PTR0
%endmacro

%macro call_gc 1
  lea LINK, [%%return]
  jmp %1
  %%return:
%endmacro

;; Returns from a function.
%macro ret_gc 0
  mov LINK, [FP + FRAME_LINK]
  mov FP,   [FP + FRAME_LAST_FRAME]
  jmp LINK
%endmacro

SECTION .rodata

;; Nothing here yet

SECTION .text

garbage_collect:
  ; Nothing here yet.
  ; FALLTHROUGH
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
