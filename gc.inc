;; -*- Mode: nasm -*-

%assign HEAP_SIZE     1<<21

%assign FROM_SPACE    1<<30
%assign TO_SPACE      FROM_SPACE + 2*HEAP_SIZE

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

;; EOF
