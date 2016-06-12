;; -*- Mode: nasm -*-

;; These only work for 64-bit Linux (on x86, obviously).

;; The Linux x86-64 syscall ABI looks like this:
;; EAX = syscall number
;; RDI, RSI, RDX, R10, R8, R9 = parameters
;; Kernel destroys RCX, R11

%assign SYSCALL_WRITE 1
%assign SYSCALL_MMAP  9
%assign SYSCALL_EXIT  60

%assign MAP_PRIVATE   0x02
%assign MAP_FIXED     0x10
%assign MAP_ANONYMOUS 0x20

%assign PROT_READ     0x1
%assign PROT_WRITE    0x2

;; EOF
