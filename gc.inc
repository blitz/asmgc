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

;; RBP = frame pointer register
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
STRUC OBJ
.SIZE: resw 1                   ; <64 KB objects for now
.TYPE: resw 1
ENDSTRUC

;; The different object types
%define OBJ_TYPE_FRAME   0

;; Layout of function frame
STRUC FRAME, OBJ_size
.LAST_FRAME: resq 1
.LINK:       resq 1
ENDSTRUC

;; Allocate the given amount of bytes (parameter 1) and return a pointer in GPR_PTR0. The memory is marked with the given type (parameter 2).
;; Input:
;; Macro parameter 1 = register (needs to be one of GPR_PTR*)
;; Macro parameter 2 = size
;; Macro parameter 3 = type
;; Output:
;; pointer to allocated space in requested register
;; LINK clobbered
%macro allocate 3
  %%again:
  lea %1, [ALLOC + %2]
  lea LINK, [%%again]
  cmp %1, ALLOC_END
  jae garbage_collect
  xchg %1, ALLOC
  mov dword [%1 + OBJ.SIZE], %2 | (%3 << 16)
  %%enough_space:
%endmacro

;; Generate a function prologue with the given bytes (parameter 1) of additional memory in the function frame.
;; Input:
;; LINK the link pointer to store in the function frame
;; FP   the frame pointer to store in the function frame
;; Output:
;; FP   the new function frame
;; Clobbers GPR_PTR3, GPR_INT5
%macro prologue 1
  mov GPR_INT5, LINK
  allocate GPR_PTR3, (FRAME_size + %1), OBJ_TYPE_FRAME
  mov [GPR_PTR3 + FRAME.LAST_FRAME], FP
  mov [GPR_PTR3 + FRAME.LINK], GPR_INT5
  mov FP, GPR_PTR3
%endmacro

%macro call_gc 1
  lea LINK, [%%return]
  jmp %1
  %%return:
%endmacro

;; Returns from a function.
%macro ret_gc 0
  mov LINK, [FP + FRAME.LINK]
  mov FP,   [FP + FRAME.LAST_FRAME]
  jmp LINK
%endmacro

;; EOF
