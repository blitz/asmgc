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

%define FROM_SPACE    (1<<30)
%define TO_SPACE      FROM_SPACE + 2*HEAP_SIZE


  ;; We use our registers like this:
  ;; RAX, RDX, RCX, RBX = general purpose non-pointer values
%define GPR_INT0 rax
%define GPR_INT1 rdx
%define GPR_INT2 rcx
%define GPR_INT3 rbx

  ;; RSI = frame pointer register
%define GPR_FP   rbp

  ;; RDI = link register
%define LINK     rdi

  ;; RSP = allocation area
%define ALLOC     rsp
%define ALLOC_END r8

  ;; R9 to r15 are for pointer values
%define GPR_PTR0  r9
%define GPR_PTR1  r10
%define GPR_PTR2  r11
%define GPR_PTR3  r12
%define GPR_PTR4  r13
%define GPR_PTR5  r14
%define GPR_PTR6  r15

  ;; Allocate the given amount of bytes and return a pointer in RAX.
  ;; Output:
  ;; GPR_PTR0 = pointer to allocated space
  ;; LINK clobbered
%macro allocate 1
%%again:
  lea GPR_PTR0, [ALLOC + %1]
  lea LINK, [%%again]
  cmp GPR_PTR0, ALLOC_END
  jae garbage_collect
  xchg GPR_PTR0, ALLOC
%%enough_space:
%endmacro

%macro call_gc 1
  lea LINK, [%%return]
  jmp %1
%%return:
%endmacro


  SECTION .rodata

hello:
  db "hello", 10, 0


  SECTION .text

garbage_collect:
  ;; XXX Implement me.
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
  cmp rax, rdi
  jne die
  ret

_start:

  ;; Allocate heap
  mov rdi, FROM_SPACE
  mov rsi, HEAP_SIZE
  call mmap
  mov rdi, TO_SPACE
  call mmap

  ;; Bail out, if we didn't get our memory.

  ;; We keep our current allocation pointer in RSP.
  mov rsp, FROM_SPACE

  ;; The end of our allocation area is in RBP.
  mov rbp, TO_SPACE

  ;; ...

  allocate 24


  mov eax, SYSCALL_EXIT
  mov edi, 0
  syscall
