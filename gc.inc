;; -*- Mode: nasm -*-

%assign HEAP_SIZE     1<<21

%assign FROM_SPACE    1<<30
%assign TO_SPACE      FROM_SPACE + 2*HEAP_SIZE

;; We use our registers like this:
;; RAX, RDX, RCX, RBX and R13-R15 = general purpose non-pointer values
%define GPR_INT0  rax
%define GPR_INT0b al
%define GPR_INT0w ax
%define GPR_INT1  rdx
%define GPR_INT1b dl
%define GPR_INT2  rcx
%define GPR_INT2b cl
%define GPR_INT3  rbx
%define GPR_INT3b bl
%define GPR_INT4  r13
%define GPR_INT5  r14
%define GPR_INT6  r15

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
       resd 1                   ; padding
ENDSTRUC

;; The different object types
%define OBJ_TYPE_FRAME   0
%define OBJ_TYPE_CONS    1
%define OBJ_TYPE_STRING  2

;; Layout of function frame
STRUC FRAME, OBJ_size
.LAST_FRAME: resq 1
.LINK:       resq 1
.LOCAL_VAR:
ENDSTRUC

;; Layout of list element (CONS)
STRUC CONS, OBJ_size
.FIRST:      resq 1
.REST:       resq 1
ENDSTRUC

;; A non-null terminated string
STRUC STRING, OBJ_size
.DATA:
ENDSTRUC

;; Allocate the given amount of bytes (parameter 1) and return a pointer in GPR_PTR0. The memory is marked with the given type (parameter 2).
;; Input:
;; Macro parameter 1 = register (needs to be one of GPR_PTR*)
;; Macro parameter 2 = type
;; Macro parameter 3 = additional payload (usually 0, except for variable length objects)
;; Output:
;; pointer to allocated space in requested register
;; LINK clobbered
%macro allocate 3
%%again:
  lea %1, [ALLOC + OBJ_size + %2_size + %3]
  cmp %1, ALLOC_END
  lea LINK, [%%again]
  jb %%nogc
  xor %1, %1                    ; clear invalid pointer
  jmp garbage_collect
%%nogc:
  mov dword [ALLOC + OBJ.SIZE], (OBJ_size + %2_size + %3) | (OBJ_TYPE_%2 << 16)
  xchg %1, ALLOC
%endmacro

;; Generate a function prologue with the given bytes of additional memory in the function frame.
;; Input:
;; LINK the link pointer to store in the function frame
;; FP   the frame pointer to store in the function frame
;; Macro parameters:
;; 1 - additional QWORDS of storage
;; 2 - pointer bitmap (a 1 for every local variable that is a pointer)
;; Output:
;; FP   the new function frame
;; Clobbers GPR_PTR3, GPR_INT5
%macro prologue 2
  mov  GPR_INT5, LINK
  xchg GPR_PTR3, FP
%if %1
  allocate FP, FRAME, (1 + %1) * 8
%else
  allocate FP, FRAME, 0
%endif
  mov [FP + FRAME.LAST_FRAME], GPR_PTR3
  mov [FP + FRAME.LINK], GPR_INT5
%if %1
  mov qword [FP + FRAME.LOCAL_VAR], %2
%endif

%endmacro

;; Return a memory expression for the given local variable (starting with 0)
%define LOCAL_VAR(n) [FP + FRAME.LOCAL_VAR + 8*(n + 1)]

%macro call_gc 1
  lea LINK, [%%return]
  jmp %1
%%return:
%endmacro

;; Deallocates a function frame
%macro epilogue 0
  mov LINK, [FP + FRAME.LINK]
  mov FP,   [FP + FRAME.LAST_FRAME]
%endmacro

;; Returns from a function with a frame
%macro ret_gc 0
  epilogue
  jmp LINK
%endmacro

;; EOF
