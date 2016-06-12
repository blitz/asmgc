  DEFAULT REL
  BITS 64

  GLOBAL _start

  ;; Syscall ABI
  ;; EAX = syscall number
  ;; parameters in RDI, RSI, RDX, RCX, R8, R9

  ;; Destroyed in addition to parameters: RAX, R10
  ;; Return values: RAX, RDX

  %define syscall_write 1
  %define syscall_exit  60


  SECTION .rodata

hello:
  db "hello", 10, 0


  SECTION .text

_start:

  mov eax, syscall_write
  mov edi, 0
  lea esi, [hello]
  mov edx, 6
  syscall

  mov eax, syscall_exit
  mov edi, 0
  syscall
