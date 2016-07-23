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
;; GPR_PTR0 a string to print
;; Clobbers:
;; GPR_INT2, GPR_INT6, GPR_PTR2
write:
  prologue 0

  mov   rdi, FILENO_STDOUT
  lea   rsi, [DEREF(GPR_PTR0) + STRING.DATA]
  movzx rdx, word [DEREF(GPR_PTR0) + OBJ.SIZE]
  sub   rdx, STRING.DATA
  mov   eax, SYSCALL_WRITE
  syscall

  xor GPR_PTR2, GPR_PTR2        ; destroyed by syscall

  ret_gc


;; Reverse a string in place
;; Input:
;; GPR_PTR0 the string to reverse
;; Output:
;; GPR_PTR0 the same string
reverse_string:

  mov   GPR_INT0, STRING.DATA
  movzx GPR_INT1, word [DEREF(GPR_PTR0) + OBJ.SIZE]

.loop:
  dec GPR_INT1
  cmp GPR_INT0, GPR_INT1
  jae .ret

  mov GPR_INT2b, [DEREF(GPR_PTR0) + GPR_INT0]
  mov GPR_INT3b, [DEREF(GPR_PTR0) + GPR_INT1]
  mov [DEREF(GPR_PTR0) + GPR_INT0], GPR_INT3b
  mov [DEREF(GPR_PTR0) + GPR_INT1], GPR_INT2b

  inc GPR_INT0
  jmp .loop

.ret:
  jmp LINK

;; Convert an integer to a string
;; Input:
;; GPR_INT0 the integer to convert
;; Output:
;; GPR_PTR0 the string object
int_to_string:
  mov GPR_INT1, LINK
  allocate GPR_PTR0, STRING, 20
  mov LINK, GPR_INT1

  mov GPR_INT2, 0               ; index into string
  mov GPR_INT3, 10              ; base
.next_digit:
  xor GPR_INT1, GPR_INT1
  div GPR_INT3
  lea GPR_INT1, [GPR_INT1 + '0']
  mov [DEREF(GPR_PTR0) + STRING.DATA + GPR_INT2], GPR_INT1b
  lea GPR_INT2, [GPR_INT2 + 1]
  test GPR_INT0, GPR_INT0
  jnz .next_digit

  mov GPR_INT0, 20
  sub GPR_INT0, GPR_INT2

  sub word [DEREF(GPR_PTR0) + OBJ.SIZE], GPR_INT0w
  jmp reverse_string

;; Create a cons object
;; Input:
;; GPR_PTR0 the 'first' part of the cons
;; GPR_PTR1 the 'rest' part of the cons
;; Output:
;; GPR_PTR0 a pointer to the cons object
cons:
  allocate GPR_PTR3, CONS, 0
  mov [DEREF(GPR_PTR3) + CONS.FIRST], GPR_PTR0
  mov [DEREF(GPR_PTR3) + CONS.REST],  GPR_PTR1
  mov GPR_PTR0, GPR_PTR3
  jmp LINK

;; Compute the fibonacci sequence in the braindead recursive way to have a
;; benchmark for function call performance.
;; Input:
;; GPR_INT0 the index of the fibonacci number to calcucate
;; Output:
;; GPR_INT0 the fibonacci number
fibonacci:
  cmp GPR_INT0, 1
  ja .non_trivial
  jmp LINK
.non_trivial:

  prologue 1

  ; This is a bit convoluted, because we can only store tagged values on the
  ; stack.

  ; XXX Make this function use GPR_PTR0 as parameter. This saves all the
  ; conversions between tagged and untagged.

  MOV_INT_TO_PTR GPR_PTR0, GPR_INT0
  mov LOCAL_VAR(0), GPR_PTR0
  dec GPR_INT0
  call_gc fibonacci

  MOV_INT_TO_PTR GPR_PTR0, GPR_INT0
  xchg LOCAL_VAR(0), GPR_PTR0

  MOV_PTR_TO_INT GPR_INT0, GPR_PTR0
  sub GPR_INT0, 2
  call_gc fibonacci
  mov GPR_PTR0, LOCAL_VAR(0)
  MOV_PTR_TO_INT GPR_INT1, GPR_PTR0

  add GPR_INT0, GPR_INT1
  ret_gc

main:
  prologue 0

  mov GPR_INT0, 40
  call_gc fibonacci
  call_gc int_to_string
  call_gc write

  ret_gc

;; EOF
