  DEFAULT REL
  BITS 64

  GLOBAL _start

  ;; Syscall ABI
  ;; EAX = syscall number
  ;; parameters in RDI, RSI, RDX, R10, R8, R9

  ;; Kernel destroys RCX, R11

  %define SYSCALL_WRITE 1
  %define SYSCALL_MMAP  9
  %define SYSCALL_EXIT  60

  %define MAP_PRIVATE   0x02
  %define MAP_FIXED     0x10
  %define MAP_ANONYMOUS 0x20

  %define PROT_READ     0x1
  %define PROT_WRITE    0x2

  %define HEAP_SIZE     (1<<21)

  %define FROM_SPACE    1<<30
  %define TO_SPACE      FROM_SPACE + HEAP_SIZE


  SECTION .rodata

hello:
  db "hello", 10, 0


  SECTION .text

die:
  ud2a

_start:

  ;; Allocate heap
  mov eax, SYSCALL_MMAP
  mov rdi, FROM_SPACE
  mov rsi, 2*HEAP_SIZE
  mov rdx, PROT_READ | PROT_WRITE
  mov r10, MAP_ANONYMOUS | MAP_FIXED | MAP_PRIVATE
  mov r8, -1
  mov r9, 0
  syscall

  ;; Bail out, if we didn't get our memory
  cmp rax, FROM_SPACE
  jne die

  ;; We keep our current allocation pointer in RSP
  mov rsp, FROM_SPACE

  ;; ...

  mov eax, SYSCALL_EXIT
  mov edi, 0
  syscall
